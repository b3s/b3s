# frozen_string_literal: true

require "rails_helper"

RSpec.describe DeletePostsJob do
  subject(:perform) { described_class.new.perform(user.id) }

  let(:user) { create(:user) }
  let!(:post) { create(:post, user:) }

  describe "#perform" do
    it "marks the posts as deleted" do
      expect { perform }.to change { post.reload.deleted? }.from(false).to(true)
    end

    it "updates the public posts count" do
      expect { perform }.to change { user.reload.public_posts_count }.to(0)
    end

    it "bumps updated_at, expiring cached post fragments" do
      expect { Timecop.freeze(1.hour.from_now) { perform } }
        .to(change { post.reload.updated_at })
    end

    context "when the user does not exist" do
      subject(:perform) { described_class.new.perform(999_999) }

      it "does not raise an error" do
        expect { perform }.not_to raise_error
      end
    end

    context "when a post is invalid" do
      before do
        post.skip_preprocess = true
        post.body = ""
        post.save(validate: false)
      end

      it "marks it as deleted" do
        expect { perform }
          .to change { post.reload.deleted? }.from(false).to(true)
      end
    end
  end
end
