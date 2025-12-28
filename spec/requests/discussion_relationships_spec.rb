# frozen_string_literal: true

require "rails_helper"

RSpec.describe "DiscussionRelationships" do
  subject { response }

  let(:user) { create(:user) }
  let(:discussion) { create(:discussion) }
  let(:relationship) { user.discussion_relationships.find_by(discussion:) }

  before { login_as(user) }

  describe "POST /discussions/:discussion_id/relationship/follow" do
    before { post follow_discussion_relationship_path(discussion, page: 2) }

    it_behaves_like "authentication is required"

    specify { expect(relationship.following?).to be(true) }
    it { is_expected.to redirect_to(discussion_url(discussion, page: 2)) }
  end

  describe "DELETE /discussions/:discussion_id/relationship/follow" do
    before { delete unfollow_discussion_relationship_path(discussion, page: 2) }

    it_behaves_like "authentication is required"

    specify { expect(relationship.following?).to be(false) }
    it { is_expected.to redirect_to(discussions_url) }
  end

  describe "POST /discussions/:discussion_id/relationship/favorite" do
    before { post favorite_discussion_relationship_path(discussion, page: 2) }

    it_behaves_like "authentication is required"

    specify { expect(relationship.favorite?).to be(true) }
    it { is_expected.to redirect_to(discussion_url(discussion, page: 2)) }
  end

  describe "DELETE /discussions/:discussion_id/relationship/favorite" do
    before { delete unfavorite_discussion_relationship_path(discussion, page: 2) }

    it_behaves_like "authentication is required"

    specify { expect(relationship.favorite?).to be(false) }
    it { is_expected.to redirect_to(discussions_url) }
  end

  describe "POST /discussions/:discussion_id/relationship/hide" do
    before { post hide_discussion_relationship_path(discussion, page: 2) }

    it_behaves_like "authentication is required"

    specify { expect(relationship.hidden?).to be(true) }
    it { is_expected.to redirect_to(discussions_url) }
  end

  describe "DELETE /discussions/:discussion_id/relationship/hide" do
    before { delete unhide_discussion_relationship_path(discussion, page: 2) }

    it_behaves_like "authentication is required"

    specify { expect(relationship.hidden?).to be(false) }
    it { is_expected.to redirect_to(discussion_url(discussion, page: 2)) }
  end
end
