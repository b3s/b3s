# frozen_string_literal: true

class UserResource
  include Alba::Resource
  include Rails.application.routes.url_helpers
  include DynamicImage::Helper

  attributes :id, :username, :realname, :latitude, :longitude, :inviter_id,
             :last_active, :created_at, :description, :admin, :moderator,
             :user_admin, :location, :banned_until, :status

  many :user_links, proc { |ul| ul.sort_by(&:position) },
       resource: UserLinkResource
end
