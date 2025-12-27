# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Users::Lists" do
  subject { response }

  let(:user) { create(:user) }

  before { login_as(user) }

  describe "GET /users" do
    before { get users_path }

    it_behaves_like "authentication is required"

    it { is_expected.to have_http_status(:success) }

    it "includes the user in the response" do
      expect(response.body).to include(user.username)
    end
  end

  describe "GET /users.json" do
    before { get users_path(format: :json) }

    it "renders JSON" do
      expect(response.parsed_body).to be_a(Array)
    end
  end

  describe "GET /users/online" do
    before { get online_users_path }

    it_behaves_like "authentication is required"

    it { is_expected.to have_http_status(:success) }

    it "includes online users heading in the response" do
      expect(response.body).to include("Online")
    end
  end

  describe "GET /users/online.json" do
    before { get online_users_path(format: :json) }

    it "renders JSON" do
      expect(response.parsed_body).to be_a(Array)
    end
  end

  describe "GET /users/deactivated" do
    before { get deactivated_users_path }

    it_behaves_like "authentication is required"

    it { is_expected.to have_http_status(:success) }
  end

  describe "GET /users/deactivated.json" do
    before { get deactivated_users_path(format: :json) }

    it "renders JSON" do
      expect(response.parsed_body).to be_a(Array)
    end
  end

  describe "GET /users/recently_joined" do
    before { get recently_joined_users_path }

    it_behaves_like "authentication is required"

    it { is_expected.to have_http_status(:success) }

    it "includes users in the response" do
      expect(response.body).to include(user.username)
    end
  end

  describe "GET /users/recently_joined.json" do
    before { get recently_joined_users_path(format: :json) }

    it "renders JSON" do
      expect(response.parsed_body).to be_a(Array)
    end
  end

  describe "GET /users/admins" do
    before { get admins_users_path }

    it_behaves_like "authentication is required"

    it { is_expected.to have_http_status(:success) }

    it "includes admins heading in the response" do
      expect(response.body).to include("Admins")
    end
  end

  describe "GET /users/admins.json" do
    before { get admins_users_path(format: :json) }

    it "renders JSON" do
      expect(response.parsed_body).to be_a(Array)
    end
  end

  describe "GET /users/top_posters" do
    before { get top_posters_users_path }

    it_behaves_like "authentication is required"

    it { is_expected.to have_http_status(:success) }

    it "includes top posters heading in the response" do
      expect(response.body).to include("posters")
    end
  end

  describe "GET /users/top_posters.json" do
    before { get top_posters_users_path(format: :json) }

    it "renders JSON" do
      expect(response.parsed_body).to be_a(Array)
    end
  end
end
