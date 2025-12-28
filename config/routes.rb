# frozen_string_literal: true

Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  image_resources :avatars
  image_resources :post_images

  # Uploads
  resources :uploads

  # Search discussions
  get "/search/:query.:format" => "discussions#search", as: :formatted_search_with_query
  get "/search/:query" => "discussions#search", as: :search_with_query
  match "/search" => "discussions#search", as: :search, via: %i[get post]

  # Search posts
  get "/posts/search/:query" => "posts#search"
  match "/posts/search" => "posts#search", as: :search_posts, via: %i[get post]

  # Sessions
  resource :session, only: %i[new create destroy]

  # Registrations
  resources :registrations, only: %i[new create]

  controller :registrations do
    constraints(token: %r{[^?/]+}) do
      get "/registrations/new/:token" => :new, as: :new_registration_by_token
    end
  end

  # Users
  resources :users, only: [:index], controller: "users/lists" do
    collection do
      get "online"
      get "deactivated"
      get "recently_joined"
      get "admins"
      get "top_posters"
    end

    resource :invites, only: %i[create destroy], controller: "users/invites"
  end

  resources :user_links, only: %i[index] do
    get "all", on: :collection
  end

  resources(:user_profiles,
            only: %i[show update],
            path: "users/profile",
            controller: "users/profiles",
            constraints: { id: %r{[^?/]+} }) do
    member do
      get "edit(/:page)", action: :edit, as: :edit
      post "mute"
      post "unmute"
    end

    resources :discussions, only: :index, controller: "users/discussions" do
      collection do
        get "participated"
        get "participated/:page", action: :participated
        get "/:page", action: :index
      end
    end

    resources :posts, only: :index, controller: "users/posts" do
      get "/:page", action: :index, on: :collection
    end
  end

  resource :password_reset, only: %i[new create show update]

  # Discussions
  get "/discussions/:id(/:page)(.:format)" => "discussions#show",
      as: :discussion,
      constraints: { id: %r{\d[^/.]*}, page: /\d+/ }

  resources :discussions, except: [:show] do
    member do
      get "mark_as_read"
    end

    collection do
      get "participated"
      get "search"
      get "following"
      get "favorites"
      get "hidden"
      get "popular"
      get "popular/:days(/:page)", action: :popular, as: :popular_days
      get "archive/:page", action: :index, as: :paged
    end

    # Relationship management
    resource :relationship, only: [], controller: "discussion_relationships" do
      post :follow
      delete :follow, action: :unfollow, as: :unfollow
      post :favorite
      delete :favorite, action: :unfavorite, as: :unfavorite
      post :hide
      delete :hide, action: :unhide, as: :unhide
    end

    # Posts
    resources :posts, only: %i[edit create update], controller: "exchange_posts" do
      collection do
        get "count"
        get "since/:index", action: :since, as: :since
        post "preview"
        get "search"
      end
    end
  end

  # Conversations
  get "/conversations/:id(/:page)(.:format)" => "conversations#show",
      as: :conversation,
      constraints: { id: %r{\d[^/.]*}, page: /\d+/ }

  resources :conversations, except: [:show] do
    member do
      get "mark_as_read"
      get "mute"
      get "unmute"
    end

    collection do
      get "contact_moderators", action: :new, defaults: { moderators: true }
      get "new/with/:username", action: :new, as: :new_with
      get "archive/:page", action: :index, as: :paged
    end

    resources :participants, only: %i[create destroy], controller: "conversation_participants"

    resources :posts, only: %i[edit create update], controller: "exchange_posts" do
      collection do
        get "count"
        get "since/:index", action: :since, as: :since
        post "preview"
        get "search"
      end
    end
  end

  # Invites
  resources :invites do
    get "all", on: :collection
    get "accept", on: :member
  end

  namespace :admin do
    resource :configuration
  end
  get "admin" => "admin/configurations#show", as: :admin

  # Help pages
  get "help" => "help#index", as: :help
  get "help/keyboard" => "help#keyboard", as: :keyboard_help
  get "help/code-of-conduct" => "help#code_of_conduct", as: :code_of_conduct_help

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
