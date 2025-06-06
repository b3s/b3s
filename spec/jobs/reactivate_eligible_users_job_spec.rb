# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReactivateEligibleUsersJob do
  subject { user.status }

  let(:status) { :hiatus }
  let(:banned_until) { 1.hour.ago }
  let!(:user) do
    Timecop.freeze(banned_until - 1.hour) do
      create(:user, status:, banned_until: 1.hour.from_now)
    end
  end

  before do
    described_class.new.perform
    user.reload
  end

  context "when hiatus user has expired ban" do
    it { is_expected.to eq("active") }
  end

  context "when timeout user has expired ban" do
    let(:status) { :time_out }

    it { is_expected.to eq("active") }
  end

  context "when user has future ban date" do
    let(:banned_until) { 1.hour.from_now }

    it { is_expected.to eq("hiatus") }
  end
end
