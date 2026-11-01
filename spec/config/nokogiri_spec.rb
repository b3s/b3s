# frozen_string_literal: true

require "rails_helper"

describe Nokogiri do
  it "loads the libxml2 version it was compiled against" do
    libxml = described_class::VERSION_INFO["libxml"]
    expect(libxml["loaded"]).to eq(libxml["compiled"])
  end
end
