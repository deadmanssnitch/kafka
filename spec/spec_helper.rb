# frozen_string_literal: true

require "bundler/setup"
require "securerandom"
require "kafka"
require "open3"
require "json"

RSpec.configure do |config|
  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = "random"

  # See: https://github.com/edenhill/librdkafka/blob/master/CONFIGURATION.md
  def config(options = {})
    defaults = {
      # Start with `docker-compose start`
      "bootstrap.servers" => "127.0.0.1:9092",

      # Let librdkafka figure out which version of Kafka it's talking to.
      # Alternative is to specify a minimum version which would make testing
      # against different versions of Kafka difficult.
      "api.version.request" => true,

      # Unique group id for each call of config. This ensures that multiple
      # tests can't clobber the consumer group state of each other.
      "group.id" => "kafka-spec-#{SecureRandom.uuid}",

      # Always start at the beginning of the topic.
      "auto.offset.reset" => "earliest",
    }

    Kafka::Config.new(defaults.merge(options))
  end

  # publish shells out to kafkacat to write a message to the specified topic.
  # We use kafkacat to make sure we use a well behaving client to verify that
  # the gem itself is well behaving.
  #
  # @param payload [String] Content of the message to publish
  # @param key [String, nil] Partitioning key
  # @param partition [Integer, nil] Partition to publish to. Use -1 to publish
  #   to a random partition.
  # @param topic [String] Name of the topic to publish to
  def publish(payload, key: nil, partition: -1, topic: "consume_test_topic")
    cmd = Shellwords.join(
      [
        "kafkacat", "-P",
        "-b", "127.0.0.1:9092",
        "-t", topic,

        # Publish to a specific partition (-1
        "-p", (partition || -1),
      ].tap do |c|
        if key
          c.push("-k", key)
        end
      end,
    )

    out, status = Open3.capture2e(cmd, stdin_data: payload)
    if !status.success?
      puts out
      exit status.exitstatus
    end

    nil
  end

  # @param topic [String] Name of the topic to consume from
  # @param offset [String, int] Offset or relative offset to start at.
  #    beginning | end | stored
  #    <value>   (absolute offset)
  #    -<value>  (relative offset from end)
  #    s@<value> (timestamp in ms to start at)
  #    e@<value> (timestamp in ms to stop at (not included))
  def fetch(topic, count: 1, offset: -1)
    cmd = Shellwords.join([
      "kafkacat", "-C",
      "-b", "127.0.0.1:9092",
      "-t", topic,
      "-o", offset,

      # Fetch at most `count` messages
      "-c", count,

      # Exit when the last message is read. This will avoid blocking for empty
      # topics.
      "-e",

      # Print the message(s) out as JSON so we get metadata as well as the
      # payload.
      "-J",
    ])

    out, err, status = Open3.capture3(cmd)
    if !status.success?
      puts err
      exit status.exitstatus
    end

    out.each_line.map do |line|
      next if line.empty?

      # TODO: Convert to a Message
      JSON.parse(line)
    end
  end
end
