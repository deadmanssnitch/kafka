# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kafka::FFI::Producer do
  it "can produce a message" do
    payload = "Test message"
    producer = Kafka::FFI::Producer.new(config.native)

    with_topic do |topic|
      producer.produce(topic, payload)
      producer.poll # Wait for the delivery report

      msg = fetch(topic)[0]
      expect(msg).not_to be(nil)
      expect(msg.key).to eq(nil)
      expect(msg.topic).to eq(topic)
      expect(msg.payload).to eq(payload)
    end
  ensure
    producer.flush
    producer.destroy
  end

  # Verify that the partition argument is applied to publication.
  it "can produce a message to a specific partition" do
    cfg = config("partitioner": "murmur2")
    producer = Kafka::FFI::Producer.new(cfg.native)

    with_topic(partitions: 5) do |topic|
      # murmur2 maps to partitions: 1, 1, 2, 3
      keys = [ "foo", "key", "cron", "snitches" ]

      keys.each do |key|
        producer.produce(topic, "test", partition: 4, key: key)
      end
      producer.poll

      msg = fetch(topic, count: 4)
      expect(msg.map(&:partition)).to eq([4, 4, 4, 4])
      expect(msg.map(&:key)).to eq(keys)
    end
  ensure
    producer.flush
    producer.destroy
  end

  it "sends message headers" do
    producer = Kafka::FFI::Producer.new(config.native)

    # Producev causes the headers to be owned by librdkafka instead of the
    # application.
    headers = Kafka::FFI::Message::Header.new
    headers.add("token", "c2354d53d2")
    headers.add("source", "web")
    headers.add("source", "user")

    with_topic do |topic|
      producer.produce(topic, "test", headers: headers)
      producer.poll

      msg = fetch(topic)[0]
      expect(msg.headers).to eq({
        "token" => ["c2354d53d2"],
        "source" => [ "web", "user" ],
      })
    end
  ensure
    producer.flush
    producer.destroy
  end
end
