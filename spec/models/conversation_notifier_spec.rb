# frozen_string_literal: true

require "rails_helper"

describe ConversationNotifier do
  let(:url) { "http://example.com/" }
  let(:conversation) { create(:conversation) }
  let(:post) { create(:post, exchange: conversation) }
  let!(:notifier) { described_class.new(post, url) }

  before do
    Sugar.config.forum_name = "Sugar"
    Sugar.config.mail_sender = "test@example.com"
  end

  describe "#deliver_now" do
    it "delivers the emails" do
      expect { notifier.deliver_now }.to change(email_deliveries, :length)
        .by(1)
    end

    it "delivers the message to the user" do
      notifier.deliver_now
      expect(last_email.to).to eq([conversation.posts.first.user.email])
    end

    it "does not deliver to muted participants" do
      ConversationRelationship
        .where(conversation: conversation)
        .update_all(notifications: false)
      expect { notifier.deliver_now }.not_to(change(email_deliveries, :length))
    end
  end

  describe "#deliver_later" do
    it "queues the deliveries for later" do
      message_delivery = instance_double(ActionMailer::MessageDelivery)
      allow(Mailer).to receive(:new_post).and_return(message_delivery)
      allow(message_delivery).to receive(:deliver_later)
      notifier.deliver_later
      expect(message_delivery).to have_received(:deliver_later)
    end
  end
end
