# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kafka::FFI::Event do
  # fetch does the necessary dance in order to obtain a `fetch` event. The
  # process requires polling from a topic partition queue after publishing a
  # message to the queue's topic/partition combination (toppar).
  #
  # @yield [Kafka::FFI::Event] RD_KAFKA_EVENT_FETCH
  def fetch
    with_topic(partitions: 1) do |topic|
      client = Kafka::FFI::Consumer.new(config)
      client.subscribe(topic)

      wait_for_assignments(client)

      queue = client.get_partition_queue(topic, 0)
      queue.forward(nil)

      publish(topic, "test", partition: 0)

      # Polling from the topic queue will return a `fetch` event with messages.
      event = queue.poll(timeout: 5000)
      expect(event).not_to be(nil)

      begin
        yield(event)
      ensure
        event.destroy
      end
    ensure
      client.destroy
    end
  end

  specify "#type" do
    fetch do |event|
      expect(event.type).to eq(:fetch)
    end
  end

  specify "#name" do
    fetch do |event|
      expect(event.name).to eq("Fetch")
    end
  end

  specify "#messages" do
    fetch do |event|
      messages = event.messages
      expect(messages.size).to eq(1)
      expect(messages[0].payload).to eq("test")
    end
  end
end
