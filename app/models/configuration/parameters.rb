# frozen_string_literal: true

class Configuration
  module Parameters
    extend ActiveSupport::Concern

    included do
      parameter :forum_name, :string, "B3S"
      parameter :forum_short_name, :string, "B3S"
      parameter :forum_title, :string, "B3S"
      parameter :public_browsing, :boolean, false
      parameter :signups_allowed, :boolean, true
      parameter :domain_names, :string
      parameter :mail_sender, :string

      # Customization
      parameter :code_of_conduct, :string
      parameter(
        :emoticons,
        :string,
        "smiley laughing blush heart_eyes kissing_heart flushed worried " \
        "grimacing cry angry heart star +1 -1"
      )

      # Integration
      parameter :google_analytics, :string
      parameter :amazon_associates_id, :string

      # Theme
      parameter :default_theme, :string, "default"
      parameter :default_mobile_theme, :string, "default"
    end
  end
end
