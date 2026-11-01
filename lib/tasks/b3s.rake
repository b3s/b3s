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

  desc "Rewrite embedded post images as responsive picture elements"
  task rewrite_post_images: :environment do
    image_tag = %r{<img[^>]+src="/post_images/[^/"]+/[^/"]+/(\d+)-[^"]*"[^>]*>}
    dry_run = ENV["DRY_RUN"].present?
    rewritten = 0

    Post.where("body_html LIKE ?", '%"/post_images/%').find_each do |post|
      html = post[:body_html]
      next if html.include?("<picture")

      tokenized = html.gsub(image_tag) do |tag|
        image = PostImage.find_by(id: Regexp.last_match(1))
        image ? "[image:#{image.id}:#{image.content_hash}]" : tag
      end

      updated = PostImageFilter.new(tokenized).to_html
      next if updated == html

      # rubocop:disable-next Rails/SkipsModelValidations
      post.update_column(:body_html, updated) unless dry_run
      rewritten += 1
      puts "#{rewritten} posts (id #{post.id})" if (rewritten % 500).zero?
    end

    puts "#{dry_run ? 'Would rewrite' : 'Rewrote'} #{rewritten} posts"
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
        Post.transaction { rendered.each { |post, html| post.update_column(:body_html, html) } }
      end

      backfilled += rendered.size
      failed += posts.size - rendered.size
      puts "#{backfilled} posts (id #{posts.last.id})"
    end

    puts "#{dry_run ? 'Would backfill' : 'Backfilled'} #{backfilled} posts, #{failed} failed"
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
