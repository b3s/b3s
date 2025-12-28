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

  # Sessions
  resource :session, only: %i[new create destroy]

  # Registrations
  resources :registrations, only: %i[new create]

  controller :registrations do
    constraints(token: %r{[^?/]+}) do
      get "/registrations/new/:token" => :new,
          as: :new_registration_by_token
    end
  end

  # Users
  resources :users, only: [:index], controller: "users/lists" do
    collection do
      get :online
      get :deactivated
      get :recently_joined
      get :admins
      get :top_posters
    end

    resource :invites, only: %i[create destroy],
                       controller: "users/invites"
  end

  resources :user_links, only: %i[index] do
    collection do
      get "all"
    end
  end

  resources(:user_profiles,
            only: %i[show update],
            path: "users/profile",
            controller: "users/profiles",
            constraints: { id: %r{[^?/]+} }) do
    member do
      get "edit(/:page)", action: :edit, as: :edit
      post :mute
      post :unmute
    end

    resources :discussions, only: :index, controller: "users/discussions" do
      collection do
        get :participated
        get "participated/:page", action: :participated
      end
      get "/:page", action: :index, on: :collection
    end

    resources :posts, only: :index, controller: "users/posts" do
      get "/:page", action: :index, on: :collection
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
