# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kafka::FFI::Topic do
  specify "#name" do
    client = Kafka::FFI::Consumer.new(config.native)
    topic = client.topic("signals")
    expect(topic.name).to eq("signals")
  ensure
    client.destroy if client
  end
end
