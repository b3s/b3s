# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Configurations" do
  subject { response }

  let(:user) { create(:user, :admin) }

  before { login_as(user) }

  describe "GET /admin/configuration" do
    before { get admin_configuration_path }

    it { is_expected.to redirect_to(edit_admin_configuration_url) }
  end

  describe "GET /admin/configuration/edit" do
    before { get edit_admin_configuration_path }

    it { is_expected.to have_http_status(:success) }

    it "does not set flash" do
      expect(flash[:notice]).to be_nil
    end
  end

  describe "PATCH /admin/configuration" do
    before do
      patch admin_configuration_path,
            params: { configuration: { forum_name: "New Forum Name" } }
    end

    it "does not set flash" do
      expect(flash[:notice]).to be_nil
    end

    it "updates the forum configuration" do
      expect(B3S.config.forum_name).to eq("New Forum Name")
    end

    it { is_expected.to redirect_to(edit_admin_configuration_url) }
  end
end
