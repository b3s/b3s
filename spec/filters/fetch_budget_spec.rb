# frozen_string_literal: true

require "rails_helper"

describe FetchBudget do
  let(:budget) { described_class.new }
  let(:clock) { { now: 0.0 } }

  before do
    allow(Process).to receive(:clock_gettime).and_call_original
    allow(Process).to receive(:clock_gettime).with(Process::CLOCK_MONOTONIC) { clock[:now] }
  end

  describe "#spend?" do
    context "when under the fetch limit" do
      before { 24.times { budget.spend? } }

      it { expect(budget.spend?).to be(true) }
    end

    context "when over the fetch limit" do
      before { 25.times { budget.spend? } }

      it { expect(budget.spend?).to be(false) }
    end

    context "when the render budget has run out" do
      before do
        budget.spend?
        clock[:now] += 6
      end

      it { expect(budget.spend?).to be(false) }
    end

    context "when the render budget has not run out" do
      before do
        budget.spend?
        clock[:now] += 5
      end

      it { expect(budget.spend?).to be(true) }
    end
  end
end
