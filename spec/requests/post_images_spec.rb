# frozen_string_literal: true

require "rails_helper"

RSpec.describe "PostImages" do
  it_behaves_like "a DynamicImage controller", :post_image
end
