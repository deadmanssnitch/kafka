# frozen_string_literal: true

require "spec_helper"
require "securerandom"
require "kafka/consumer"

RSpec.describe Kafka::Consumer do
  it "can consume messages from a topic" do
    consumer = Kafka::Consumer.new(config)

    with_topic do |topic|
      consumer.subscribe(topic)

      publish(topic, "test")

      while consumer.assignments[topic].nil?
        sleep 0.25
      end

      received =
        consumer.poll do |msg|
          expect(msg.payload).to eq("test")

          true
        end

      expect(received).to be(true)
    ensure
      consumer.close
    end
  end
end