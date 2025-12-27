# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Help" do
  subject { response }

  let(:user) { create(:user) }

  before { login_as(user) }

  describe "GET /help" do
    before { get help_path }

    it { is_expected.to redirect_to(keyboard_help_url) }
  end

  describe "GET /help/keyboard" do
    before { get keyboard_help_path }

    it { is_expected.to have_http_status(:success) }

    it "includes keyboard shortcuts in the response" do
      expect(response.body).to include("Keyboard")
    end
  end

  describe "GET /help/code_of_conduct" do
    before do
      allow(B3S.config).to(
        receive(:code_of_conduct).and_return("# Code of Conduct\n\nBe nice.")
      )
      get code_of_conduct_help_path
    end

    it_behaves_like "authentication is required"

    it { is_expected.to have_http_status(:success) }

    it "includes code of conduct heading in the response" do
      expect(response.body).to include("Code of Conduct")
    end
  end
end
