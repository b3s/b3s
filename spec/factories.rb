# frozen_string_literal: true

FactoryBot.define do
  factory :avatar do
    file do
      Rack::Test::UploadedFile.new(
        Rails.root.join("spec/support/pink.png"),
        "image/png"
      )
    end
  end

  factory :conversation_relationship do
    user
    conversation
  end

  factory :discussion_relationship do
    user
    discussion
  end

  factory :exchange_moderator do
    exchange factory: %i[discussion]
    user
  end

  factory :exchange_view do
    user
    exchange
    post { exchange.posts.first }
  end

  factory :exchange do
    sequence(:title)  { |n| "Exchange #{n}" }
    sequence(:body)   { |n| "First post of exchange #{n}" }
    poster factory: %i[user]
    posts_count { 1 }

    # Discussions
    factory :discussion, class: "discussion" do
      sequence(:title)  { |n| "Discussion #{n}" }
      sequence(:body)   { |n| "First post of discussion #{n}" }

      factory :closed_discussion do
        closer factory: %i[user]
        closed { true }
      end
    end

    # Conversations
    factory :conversation, class: "conversation" do
      sequence(:title)  { |n| "Conversation #{n}" }
      sequence(:body)   { |n| "First post of conversation #{n}" }
    end
  end

  factory :invite do
    email
    user

    trait :expired do
      expires_at { 2.days.ago }
    end
  end

  factory :post_image do
    file do
      Rack::Test::UploadedFile.new(
        Rails.root.join("spec/support/pink.png"),
        "image/png"
      )
    end
  end

  factory :post do
    sequence(:body) { |n| "Post body #{n}" }
    exchange factory: %i[discussion]
    user
  end

  factory :user do
    sequence(:username)   { |n| "lonelygirl#{n}" }
    sequence(:realname)   { |n| "B3S User #{n}" }
    email
    password              { "Correct Horse Battery Staple" }
    password_confirmation { "Correct Horse Battery Staple" }
    description           { "Hi, I'm #{realname}!" }
    sequence(:location)   { |n| "Location #{n}" }

    admin { false }
    user_admin { false }
    moderator { false }
    status { :active }

    trait :admin do
      admin { true }
    end

    trait :moderator do
      moderator { true }
    end

    trait :user_admin do
      user_admin { true }
    end

    trait :banned do
      status { :banned }
    end

    trait :with_avatar do
      avatar
    end
  end

  factory :user_link do
    user
    sequence(:label) { |n| "Service #{n}" }
    sequence(:name) { |n| "username#{n}" }
  end

  sequence :email do |n|
    "person#{n}@example.com"
  end
end
