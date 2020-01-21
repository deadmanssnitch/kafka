# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kafka::FFI do
  specify "#features" do
    features = Kafka::FFI.features
    expect(features).not_to be_empty
    expect(features).to include("ssl")
  end
end
