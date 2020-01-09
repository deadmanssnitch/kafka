# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kafka::FFI::Client do
  specify "#config" do
    config = config("client.id": "test")

    client = Kafka::FFI::Client.new(:producer, config.native)
    expect(client.config.get("client.id")).to eq("test")
  end

  specify "#default_topic_conf_dup" do
    client = Kafka::FFI::Client.new(:consumer)

    topic_conf = client.default_topic_conf_dup
    expect(topic_conf).not_to be(nil)
    expect(topic_conf.get("auto.commit.enable")).to eq("true")
  end
end
