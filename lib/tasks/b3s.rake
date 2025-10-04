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
