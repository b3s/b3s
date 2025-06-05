# frozen_string_literal: true

require "rails_helper"

describe Admin::ConfigurationsController do
  let(:admin) { create(:user, :admin) }

  it_requires_admin_for %w[show edit update]

  context "when logged in as admin" do
    before { login(admin) }

    describe "show" do
      before { get :show }

      it "redirects to edit" do
        expect(response).to redirect_to(edit_admin_configuration_url)
      end
    end

    describe "edit" do
      before { get :edit }

      it { is_expected.to respond_with(:success) }
      it { is_expected.to render_template(:edit) }
      specify { expect(flash[:notice]).to be_nil }
    end

    describe "update" do
      before do
        patch :update,
              params: { configuration: { forum_name: "New Forum Name" } }
      end

      specify { expect(flash[:notice]).to be_nil }

      it "updates the forum configuration" do
        expect(B3S.config.forum_name).to eq("New Forum Name")
      end

      it "redirects back to edit" do
        expect(response).to redirect_to(edit_admin_configuration_url)
      end
    end
  end
end
