# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kafka do
  it "has a version number" do
    expect(Kafka::VERSION).not_to be nil
  end
end
