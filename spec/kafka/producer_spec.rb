# frozen_string_literal: true

require "spec_helper"
require "securerandom"
require "kafka/consumer"

RSpec.describe Kafka::Producer do
  it "can publish messages to a topic" do
    producer = Kafka::Producer.new(config)

    with_topic do |topic|
      # Publish a message and wait for it to be delivered
      result = producer.produce(topic, "[EXAMPLE CONTENT HERE]")
      result.wait(timeout: 5000)

      published = fetch(topic, count: 1)
      expect(published.length).to eq(1)
      expect(published[0].payload).to eq("[EXAMPLE CONTENT HERE]")
      expect(published[0].topic).to eq(result.topic)
      expect(published[0].offset).to eq(result.offset)
      expect(published[0].partition).to eq(result.partition)
      expect(result.error).to be(nil)
    ensure
      producer.close
    end
  end
end
