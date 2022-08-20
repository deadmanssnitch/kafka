# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "kafka"

config = Kafka::Config.new({
  "bootstrap.servers": "127.0.0.1:9092",
  "group.id": "ruby-kafka-test",

  # Disable automatic offsit commits, requiring the consumer to call commit on
  # the consumer. Commits keep track of what messages have been processed to
  # reduce replays of messages.
  "enable.auto.commit": false,
})

# Initialize a topic with 8 partitions and 1 replica per partition. This is
# only for testing, a replication factor of 1 is not generally recommended for
# production.
admin = Kafka::Admin.new(config)
admin.create_topic("ruby_test_topic", 8, 1)
admin.close

@run = true
trap("INT")  { @run = false }
trap("TERM") { @run = false }

4.times.map do |i|
  # While librdkafka is thread safe, it doesn't make sense to have multiple
  # threads polling a single consumer as they will end up just taking turns
  # consuming the next available message.
  #
  # To get better coverage it is better to have a consumer per thread. Be aware
  # that having more threads than partitions will cause some to sit idle
  # waiting for a consumer to fail. At most there can be one consumer per
  # partition for a topic actively receiving messages.
  Thread.new do
    con = Kafka::Consumer.new(config)
    con.subscribe("ruby_test_topic")

    while @run
      con.poll(timeout: 500) do |msg|
        # Requires Ruby 2.5. Most efficient way to convert from a millisecond
        # timestamp to a Time.
        ts = Time.at(0, msg.timestamp, :millisecond).utc

        puts format("%2d: %4d %8d %s %s %s => %s", i, msg.partition, msg.offset, msg.key, ts, msg.headers, msg.payload)

        con.commit(msg, async: true)
      end
    end

    con.close
  end
end.map(&:join)
