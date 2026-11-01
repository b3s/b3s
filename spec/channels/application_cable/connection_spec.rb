# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationCable::Connection do
  let(:user) { create(:user) }
  let(:session_token) { user.persistence_token }

  before do
    cookies.encrypted["_b3s_session"] = {
      value: { "user_id" => user.id, "persistence_token" => session_token }
    }
  end

  context "when the session matches the user" do
    before { connect }

    it "identifies the user" do
      expect(connection.current_user).to eq(user)
    end
  end

  context "when the persistence token has been rotated" do
    let(:session_token) { User.random_persistence_token }

    it "rejects the connection" do
      expect { connect }.to have_rejected_connection
    end
  end

  context "when the user is banned" do
    let(:user) { create(:user, :banned) }

    it "rejects the connection" do
      expect { connect }.to have_rejected_connection
    end
  end
end
