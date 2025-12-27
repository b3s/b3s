# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Avatars" do
  it_behaves_like "a DynamicImage controller", :avatar
end
