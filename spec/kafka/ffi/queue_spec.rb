# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kafka::FFI::Queue do
  specify "#new" do
    client = Kafka::FFI::Consumer.new(config)
    queue = Kafka::FFI::Queue.new(client)

    expect(queue).not_to be(nil)
    expect(queue).to be_a(Kafka::FFI::Queue)
  ensure
    client.destroy
    queue.destroy if queue
  end

  specify "#poll" do
    client = Kafka::FFI::Consumer.new(config)
    queue = client.get_main_queue
    callback = lambda { |e| }

    # Calling poll works
    expect(queue.poll(timeout: 5, &callback))
      .to be(nil)
  ensure
    client.destroy
    queue.destroy if queue
  end

  specify "#consume" do
    with_topic(partitions: 1) do |topic|
      client = Kafka::FFI::Consumer.new(config)
      client.subscribe(topic)

      wait_for_assignments(client)

      begin
        # Grab the partition queue and disable any forwarding to ensure messags
        # arrive on the queue.
        queue = client.get_partition_queue(topic, 0)
        queue.forward(nil)

        # Publish a test message after forwarding is disabled to ensure it's
        # routed to the queue.
        publish(topic, "test", partition: 0)

        received =
          queue.consume(2000) do |msg|
            expect(msg.topic).to eq(topic)
            expect(msg.partition).to eq(0)
            expect(msg.payload).to eq("test")

            true
          end

        expect(received).to be(true)
      ensure
        queue.destroy
      end
    ensure
      client.destroy
    end
  end

  specify "#consume block exceptions are raised to caller" do
    with_topic(partitions: 1) do |topic|
      client = Kafka::FFI::Consumer.new(config)
      client.subscribe(topic)

      wait_for_assignments(client)

      begin
        queue = client.get_partition_queue(topic, 0)
        queue.forward(nil)

        publish(topic, "error", partition: 0)

        expect { queue.consume(2000) { raise "Error" } }
          .to raise_error(StandardError, "Error")
      ensure
        queue.destroy
      end
    ensure
      client.destroy
    end
  end

  specify "#consume timeout returns nil" do
    with_topic(partitions: 1) do |topic|
      client = Kafka::FFI::Consumer.new(config)
      client.subscribe(topic)

      wait_for_assignments(client)

      begin
        queue = client.get_partition_queue(topic, 0)
        queue.forward(nil)

        # This test does not publish to the topic so there are no messages to
        # consume.
        received = queue.consume(5) { raise "Block should not be called" }
        expect(received).to be(nil)
      ensure
        queue.destroy
      end
    ensure
      client.destroy
    end
  end

  specify "#forward" do
    client = Kafka::FFI::Consumer.new(config)

    main = client.get_main_queue
    queue = Kafka::FFI::Queue.new(client)

    # Can be called. A lot of these tests are just exorcising that the function
    # attachments are correct.
    main.forward(queue)

    # Nil to disable forwarding
    main.forward(nil)
  ensure
    client.destroy
    main.destroy if main
    queue.destroy if queue
  end

  specify "#length" do
    client = Kafka::FFI::Consumer.new(config)
    queue = Kafka::FFI::Queue.new(client)

    expect(queue.length).to eq(0)
  ensure
    client.destroy
    queue.destroy if queue
  end
end
