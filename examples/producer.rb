# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "kafka"
require "securerandom"

config = Kafka::Config.new({
  "bootstrap.servers": "127.0.0.1:9092",
})

producer = Kafka::Producer.new(config)

# Initialize a topic with 8 partitions and 1 replica per partition. This is
# only for testing, a replication factor of 1 is not generally recommended for
# production.
admin = Kafka::Admin.new(config)
admin.create_topic("ruby_test_topic", 8, 1)
admin.close

@run = true
trap("INT")  { @run = false }
trap("TERM") { @run = false }

# Create several threads to publish messages to the topic. Producers are thread
# safe and can be accessed from multiple threads.
workers = 8.times.map do |i|
  Thread.new do
    while @run
      producer.produce("ruby_test_topic", "#{i}: #{SecureRandom.uuid}") do |report|
        # Wait for delivery confirmation from the cluster
        report.wait
        puts report.inspect
      end

      sleep(SecureRandom.rand % 0.2)
    end
  end
end

# Wait for all worker threads to finish
workers.each(&:join)

# Gracefully close the producer, flushing any remaining messages, and
# processing and remaining callbacks.
producer.close
