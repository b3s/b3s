# frozen_string_literal: true

Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  image_resources :avatars
  image_resources :post_images

  # Uploads
  resources :uploads

  # Search discussions
  get "/search/:query.:format" => "discussions#search",
      as: :formatted_search_with_query
  get "/search/:query" => "discussions#search",
      as: :search_with_query
  match "/search" => "discussions#search",
        as: :search, via: %i[get post]

  # Search posts
  get "/posts/search/:query" => "posts#search"
  match "/posts/search" => "posts#search",
        as: :search_posts, via: %i[get post]

  match "/discussions/:id/search_posts/:query" => "discussions#search_posts",
        via: %i[get post]
  match "/conversations/:id/search_posts/:query" =>
        "conversations#search_posts",
        via: %i[get post]

  # Users
  resources :users, except: %i[edit show] do
    collection do
      get "login"
      post "authenticate"
      get "logout"
      get "online"
      get "recently_joined"
      get "admins"
      get "top_posters"
      get "deactivated"
    end
  end

  resources :user_links, only: %i[index] do
    collection do
      get "all"
    end
  end

  controller :users do
    constraints(id: %r{[^?/]+}) do
      post "/users/profile/:id/mute" => :mute,
           as: :mute_user
      post "/users/profile/:id/unmute" => :unmute,
           as: :unmute_user
      post "/users/profile/:id/grant_invite" => :grant_invite,
           as: :grant_invite_user
      post "/users/profile/:id/revoke_invites" => :revoke_invites,
           as: :revoke_invites_user
      get "/users/profile/:id/edit" => :edit,
          as: :edit_user
      get "/users/profile/:id/edit/:page" => :edit,
          as: :edit_user_page
      get "/users/profile/:id" => :show,
          as: :user_profile
      get "/users/profile/:id/discussions" => :discussions,
          as: :discussions_user
      get "/users/profile/:id/discussions/:page" => :discussions
      get "/users/profile/:id/participated" => :participated,
          as: :participated_user
      get "/users/profile/:id/participated/:page" => :participated
      get "/users/profile/:id/posts" => :posts,
          as: :posts_user
      get "/users/profile/:id/posts/:page" => :posts,
          as: :paged_user_posts
      get "/users/new/:token" => :new,
          as: :new_user_by_token
    end
  end

  resource :password_reset, only: %i[new create show update]

  # Discussions
  controller :discussions do
    get "/discussions/:id(/:page)(.:format)" => :show,
        as: :discussion,
        constraints: { id: %r{\d[^/.]*}, page: /\d+/ }
    get "/discussions/popular/:days/:page" => :popular
    get "/discussions/popular/:days" => :popular
    get "/discussions/archive/:page" => :index, as: :paged_discussions
  end

  # Conversations
  controller :conversations do
    get "/conversations/contact_moderators" => :new,
        defaults: { moderators: true },
        as: :contact_moderators
    get "/conversations/:id(/:page)(.:format)" => :show,
        as: :conversation,
        constraints: { id: %r{\d[^/.]*}, page: /\d+/ }
    get "/conversations/new/with/:username" => :new,
        as: :new_conversation_with
    get "/conversations/archive/:page" => :index,
        as: :paged_conversations
  end

  %i[discussions conversations].each do |resource_type|
    resources resource_type, except: [:show] do
      member do
        get "search_posts"
        get "mark_as_read"
        if resource_type == :discussions
          get "follow"
          get "unfollow"
          get "favorite"
          get "unfavorite"
          get "hide"
          get "unhide"
        end
        if resource_type == :conversations
          post "invite_participant"
          get "mute"
          get "unmute"
        end
      end

      collection do
        if resource_type == :discussions
          get "participated"
          get "search"
          get "following"
          get "favorites"
          get "hidden"
          get "popular"
        end
      end

      # Posts
      resources :posts, only: %i[edit create update] do
        collection do
          get "count"
          get "since"
          post "preview"
        end
      end
    end
  end

  controller :conversations do
    delete "/conversations/:id/remove_participant(/:username)" =>
      :remove_participant,
           as: :remove_participant_conversation
  end

  controller :posts do
    get "/discussions/:discussion_id/posts/since/:index" => :since
    get "/conversations/:conversation_id/posts/since/:index" => :since
  end

  # Invites
  resources :invites do
    member do
      get :accept
    end
    collection do
      get :all
    end
  end

  namespace :admin do
    resource :configuration
  end
  get "admin" => "admin/configurations#show", as: :admin

  # Help pages
  get "help" => "help#index", as: :help
  get "help/keyboard" => "help#keyboard", as: :keyboard_help
  get "help/code-of-conduct" => "help#code_of_conduct",
      as: :code_of_conduct_help

  # Vanilla redirects
  controller :vanilla do
    get "/vanilla" => :discussions
    get "/vanilla/index.php" => :discussions
    get "/vanilla/comments.php" => :discussion
    get "/vanilla/account.php" => :user
  end

  mount MissionControl::Jobs::Engine, at: "/jobs"

  # Root
  root to: "discussions#index"
end
