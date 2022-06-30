# frozen_string_literal: true

require "bundler/setup"
require "securerandom"
require "timeout"
require "open3"

# Require supporting files in spec/support
Dir[File.join(__dir__, "support/**/*.rb")].sort.each { |f| require f }

# Require the library after all of the support files are loaded. Specifically
# after simplecov is started otherwise some files incorrectly show no coverage.
require "kafka"

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
      # Start with `rake kafka:up`
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

      # Decrease log level to hide CONFWARN messages
      "log_level" => 3,
    }

    Kafka::Config.new(defaults.merge(options))
  end

  # with_topic creates a named topic for use in tests, passing the name of the
  # topic to the block. with_topic handles all of the API calls to clean up the
  # topic at the end of the block.
  #
  # @param topic [String] Name of the topic to create. Generates a random topic
  #   name if not provided.
  # @param partitions [Integer] Number of partitions for the topic
  #
  # @yield [topic]
  # @yieldparam topic [String] name of the topic
  def with_topic(topic = SecureRandom.uuid, partitions: 3)
    if !block_given?
      raise ArgumentError, "with_topic requires a block"
    end

    # Tests are run against a cluster of 1 so the replication factor can't go
    # above 1.
    replicas = 1

    # TODO: Can we reuse the same admin client across multiple tests?
    admin = Kafka::Admin.new(config)

    begin
      admin.create_topic(topic, partitions, replicas, wait: true, timeout: nil)

      yield(topic)
    ensure
      admin.delete_topic(topic)
      admin.destroy
    end
  end

  # Wait for consumer to be assigned partitions to consume.
  #
  # @param consumer [#assignments] Consumer to wait for assignments for.
  # @param topic [String] Wait for assignments for this topic. Default is any
  #   assignment.
  # @param timeout [Integer] Max time to wait in milliseconds
  #
  # @raise [Timeout::Error] Waiting timed out
  def wait_for_assignments(consumer, topic: nil, timeout: 10000)
    Timeout.timeout(timeout / 1000.0) do
      loop do
        assignments = consumer.assignments

        if assignments.any?
          if topic.nil? || !assignments[topic].nil?
            return
          end
        end

        sleep 0.25
      end
    end
  end

  # publish shells out to kafkacat to write a message to the specified topic.
  # We use kafkacat to make sure we use a well behaving client to verify that
  # the gem itself is well behaving.
  #
  # @param topic [String] Name of the topic to publish to
  # @param payload [String] Content of the message to publish
  # @param key [String, nil] Partitioning key
  # @param partition [Integer, nil] Partition to publish to. Use -1 to publish
  #   to a random partition.
  def publish(topic, payload, key: nil, partition: -1)
    cmd = Shellwords.join(
      [
        "kafkacat", "-P",
        "-b", "127.0.0.1:9092",
        "-t", topic,

        # Publish to a specific partition (default to random partitioner)
        "-p", (partition || -1),
      ].tap do |c|
        if key
          c.push("-k", key)
        end
      end,
    )

    out, status = Open3.capture2e(cmd, stdin_data: payload)
    if !status.success?
      expect(status).to be_success, out
    end

    nil
  end

  # Fetch reads `count` messages from the given topic starting at `offset`.
  #
  # @param topic [String] Name of the topic to consume from
  # @param count [Integer] Number of messages to read
  # @param offset [String, int] Offset or relative offset to start at.
  #    beginning | end | stored
  #    <value>   (absolute offset)
  #    -<value>  (relative offset from end)
  #    s@<value> (timestamp in ms to start at)
  #    e@<value> (timestamp in ms to stop at (not included))
  # @param timeout [Number] Wait timeout in seconds
  def fetch(topic, count: 1, offset: -1, timeout: 4)
    cmd = Shellwords.join([
      # Use timeout to limit how long kafkacat can wait for messages to be
      # visible. This usually happens quickly but is proving to be quite
      # variable.
      "timeout", timeout,

      # Call kafkacat to fetch message(s)
      "kafkacat", "-C", "-q",
      "-b", "127.0.0.1:9092",
      "-t", topic,
      "-o", offset,

      # Fetch at most `count` messages
      "-c", count,

      # Print the message(s) out as JSON so we get metadata as well as the
      # payload.
      "-J",
    ])

    # Exit 124 is returned by `timeout` when the command times out.
    out, err, status = Open3.capture3(cmd)
    if !status.success? && status.exitstatus != 124
      expect(status).to be_success, err
    end

    out.each_line.filter_map do |line|
      next if line.empty?

      KafkacatMessage.new(line)
    end
  end

  # Consume uses the high level balanced consumer to read messages from one or
  # more topics as the given consumer group. Consume will commit the offsets
  # for any messages read by the group.
  #
  # @param group [String] Consumer group id
  # @param topic [String, Array<String>] Name of the topic(s) to consume from
  # @param count [Integer] Number of messages to read
  # @param offset [String, int] Offset or relative offset to start at.
  #    beginning | end | stored
  #    <value>   (absolute offset)
  #    -<value>  (relative offset from end)
  #    s@<value> (timestamp in ms to start at)
  #    e@<value> (timestamp in ms to stop at (not included))
  # @param timeout [Number] Maximum time to wait in seconds
  def consume(group, topics, count: 1, offset: -1, timeout: 4)
    cmd = Shellwords.join([
      # Use timeout to limit how long kafkacat can wait for messages to be
      # visible. This usually happens quickly but is proving to be quite
      # variable.
      "timeout", timeout,

      # Call kafkacat to fetch message(s)
      "kafkacat", "-C", "-q",
      "-b", "127.0.0.1:9092",
      "-o", offset,

      # Fetch at most `count` messages
      "-c", count,

      # Print the message(s) out as JSON so we get metadata as well as the
      # payload.
      "-J",

      # Use the high level consumer group subscribed to the set of topics.
      "-G", group, *Array(topics),
    ])

    out, err, status = Open3.capture3(cmd)
    if !status.success?
      # Exit 124 is returned by `timeout` when the command times out.
      if status.exitstatus == 124
        raise Timeout::Error, "consume exceeded timeout of #{timeout} seconds"
      end

      expect(status).to be_success, err
    end

    out.each_line.filter_map do |line|
      next if line.empty?

      KafkacatMessage.new(line)
    end
  end
end
