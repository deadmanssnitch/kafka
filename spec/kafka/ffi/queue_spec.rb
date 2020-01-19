# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kafka::FFI::Queue do
  specify "#new" do
    client = Kafka::FFI::Consumer.new
    queue = Kafka::FFI::Queue.new(client)

    expect(queue).not_to be(nil)
    expect(queue).to be_a(Kafka::FFI::Queue)
  ensure
    client.destroy
    queue.destroy if queue
  end

  specify "#poll" do
    client = Kafka::FFI::Consumer.new
    queue = client.get_main_queue
    callback = lambda { |e| }

    # Calling poll works
    expect(queue.poll(timeout: 5, &callback))
      .to be(nil)

    # Requires a block
    expect { queue.poll }.to raise_error(ArgumentError)
  ensure
    client.destroy
    queue.destroy if queue
  end

  specify "#forward" do
    client = Kafka::FFI::Consumer.new

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
    client = Kafka::FFI::Consumer.new
    queue = Kafka::FFI::Queue.new(client)

    expect(queue.length).to eq(0)
  ensure
    client.destroy
    queue.destroy if queue
  end
end
