# frozen_string_literal: true

require "spec_helper"
require "securerandom"

RSpec.describe Kafka::FFI::Admin::Client do
  specify "#create_topics" do
    client = Kafka::FFI::Admin::Client.new(config.native)

    topics = [
      Kafka::FFI::Admin::NewTopic.new(SecureRandom.uuid, 3, 1),
      Kafka::FFI::Admin::NewTopic.new(SecureRandom.uuid, 1, 1),
    ]

    result = client.create_topics(topics)
    expect(result.length).to eq(2)
    expect(result.map(&:error)).to eq([nil, nil])
  ensure
    topics.each(&:destroy)
    client.destroy
  end

  specify "#delete_topics" do
    client = Kafka::FFI::Admin::Client.new(config.native)
    topic = SecureRandom.uuid

    delete = Kafka::FFI::Admin::DeleteTopic.new(topic)
    result = client.delete_topics(delete)
    expect(result.length).to eq(1)
    expect(result[0].error.code).to eq(3) # RD_KAFKA_RESP_ERROR_UNKNOWN_TOPIC
    delete.destroy

    create = Kafka::FFI::Admin::NewTopic.new(topic, 1, 1)
    client.create_topics(create)
    sleep 2

    delete = Kafka::FFI::Admin::DeleteTopic.new(topic)
    result = client.delete_topics(delete)
    expect(result.length).to eq(1)
    expect(result[0].topic).to eq(topic)
    expect(result[0].error).to eq(nil)
  ensure
    client.destroy
    create.destroy if create
    delete.destroy if delete
  end
end
