# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

require "fog/aws/storage"

if Rails.env.local?
  Dis::Storage.layers << Dis::Layer.new(
    Fog::Storage.new(provider: "Local", local_root: Rails.root.join("db/dis")),
    path: Rails.env
  )
end

if Rails.env.production?
  Dis::Storage.layers << Dis::Layer.new(
    Fog::Storage.new(provider: "Local",
                     local_root: Rails.root.join("storage/dis-cache")),
    cache: 2.gigabytes
  )
end

if Rails.application.credentials.aws
  Rails.application.credentials.tap do |credentials|
    Dis::Storage.layers << Dis::Layer.new(
      Fog::Storage.new(
        provider: "AWS",
        aws_access_key_id: credentials.dig(:aws, :access_key_id),
        aws_secret_access_key: credentials.dig(:aws, :secret_access_key)
      ),
      path: "b3s",
      delayed: false,
      readonly: !Rails.env.production?
    )
  end
end
