# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReactivateUserJob do
  let(:user) do
    Timecop.freeze(2.hours.ago) do
      create(:user, status: :hiatus, banned_until: 1.hour.from_now)
    end
  end

  describe "#perform" do
    context "when user exists and is eligible for reactivation" do
      it "reactivates the user" do
        expect { described_class.new.perform(user.id) }
          .to change { user.reload.status }
          .from("hiatus")
          .to("active")
      end
    end

    context "when user does not exist" do
      it "does not raise an error" do
        expect { described_class.new.perform(999_999) }.not_to raise_error
      end
    end

    context "when user is not eligible for reactivation" do
      let(:user) do
        create(:user, status: :hiatus, banned_until: 1.hour.from_now)
      end

      it "does not reactivate the user" do
        expect { described_class.new.perform(user.id) }
          .not_to(change { user.reload.status })
      end
    end

    context "when user is already active" do
      let(:user) { create(:user, status: :active) }

      it "does not change the user status" do
        expect { described_class.new.perform(user.id) }
          .not_to(change { user.reload.status })
      end
    end
  end
end
