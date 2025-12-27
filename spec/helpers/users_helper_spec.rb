# frozen_string_literal: true

require "rails_helper"

describe UsersHelper do
  describe "#users_tab" do
    subject { helper.users_tab(name, path, options) }

    let(:name) { "Stuff" }
    let(:path) { "/users/stuff" }
    let(:options) { { action: "stuff" } }

    context "without options" do
      let(:output) { '<li class="tab"><a href="/users/stuff">Stuff</a></li>' }

      it { is_expected.to eq(output) }
    end

    context "with class" do
      let(:options) { { class: "foo" } }
      let(:output) do
        '<li class="tab foo"><a href="/users/stuff">Stuff</a></li>'
      end

      it { is_expected.to eq(output) }
    end

    context "when action matches params" do
      let(:output) do
        '<li class="tab active"><a href="/users/stuff">Stuff</a></li>'
      end

      before do
        allow(helper).to(
          receive(:params)
            .and_return(controller: "users/lists", action: "stuff")
        )
      end

      it { is_expected.to eq(output) }
    end
  end
end
