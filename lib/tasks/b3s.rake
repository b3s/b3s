# frozen_string_literal: true

namespace :b3s do
  desc "Delete all posts for a given user"
  task delete_posts: :environment do
    user = User.find_by(id: ENV.fetch("USER_ID", nil))
    unless user
      puts "Usage: #{$PROGRAM_NAME} b3s:delete_posts USER_ID=<id>"
      exit
    end

    DeletePostsJob.perform_later(user.id)
    puts "Queued deletion job for #{user.username} (#{user.posts.count} posts)"
  end

  desc "Update syntax highlighting theme"
  task update_rouge_theme: :environment do
    Rails.root.join("app/assets/stylesheets/vendor/rouge.css").open("w") do |fh|
      fh.write(Rouge::Themes::Github.render(scope: "pre.highlight"))
    end
  end

  desc "Backfill missing rendered HTML for posts (THREADS=n, DRY_RUN=1)"
  task backfill_post_html: :environment do
    dry_run = ENV["DRY_RUN"].present?
    threads = ENV.fetch("THREADS", "4").to_i.clamp(1, ActiveRecord::Base.connection_pool.size)
    backfilled = 0
    failed = 0

    render = lambda do |post|
      [post, Renderer.render(post.body, format: post.format)]
    rescue StandardError => e
      puts "Post #{post.id} failed to render: #{e.class}: #{e.message}"
      nil
    end

    Post.where(body_html: [nil, ""]).find_in_batches do |posts|
      rendered = posts.each_slice((posts.size.to_f / threads).ceil).map do |slice|
        Thread.new { Rails.application.executor.wrap { slice.filter_map(&render) } }
      end.flat_map(&:value)

      unless dry_run
        # rubocop:disable-next Rails/SkipsModelValidations
        Post.transaction do
          rendered.each { |post, html| post.update_columns(body_html: html, updated_at: Time.current) }
          User.where(id: rendered.map { |post, _| post.user_id }.uniq).touch_all
          Exchange.where(id: rendered.map { |post, _| post.exchange_id }.uniq).touch_all
        end
      end

      backfilled += rendered.size
      failed += posts.size - rendered.size
      puts "#{backfilled} posts (id #{posts.last.id})"
    end

    puts "#{dry_run ? 'Would backfill' : 'Backfilled'} #{backfilled} posts, #{failed} failed"
  end

  desc "Purge cached oEmbed responses (URL=..., OLDER_THAN_DAYS=n, DRY_RUN=1)"
  task purge_oembed_responses: :environment do
    url = ENV.fetch("URL", nil).presence
    days = ENV.fetch("OLDER_THAN_DAYS", nil).presence
    unless url || days
      abort "Usage: #{$PROGRAM_NAME} b3s:purge_oembed_responses " \
            "URL=<url> | OLDER_THAN_DAYS=<n> [DRY_RUN=1]"
    end

    dry_run = ENV["DRY_RUN"].present?
    older_than_days = Integer(days, 10) if days
    purged = OembedResponse.purge(url:, older_than_days:, dry_run:)
    puts "#{dry_run ? 'Would purge' : 'Purged'} #{purged} oEmbed responses"
  end

  desc "Scrub private data from the database"
  task scrub_private_data: :environment do
    keep_users = ENV["KEEP_USERS"].split(",").map(&:to_i)

    Conversation.delete_all
    Post.where(conversation: true).delete_all
    PasswordResetToken.delete_all

    User.all.reject { |u| keep_users.include?(u.id) }.each do |u|
      u.update(password_digest: "", persistence_token: "")
    end
  end
end
