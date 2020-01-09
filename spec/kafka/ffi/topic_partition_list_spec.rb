# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kafka::FFI::TopicPartitionList do
  specify "new initializes an empty TopicPartitionList" do
    list = Kafka::FFI::TopicPartitionList.new(5)

    expect(list[:cnt]).to eq(0)
    expect(list[:size]).to eq(5)
  ensure
    list.destroy
  end

  specify "#add" do
    list = Kafka::FFI::TopicPartitionList.new(0)

    expect { list.add("name", 1) }
      .to change { list[:cnt] }.by(1)
  ensure
    list.destroy
  end

  specify "#add_range" do
    list = Kafka::FFI::TopicPartitionList.new(0)

    # Inclusive Range
    expect { list.add_range("inclusive", 1..2) }
      .to change { list[:cnt] }.by(2)

    # Exclusive Range
    expect { list.add_range("exclusive", 5...10) }
      .to change { list[:cnt] }.by(5)

    # Lower and upper
    expect { list.add_range("lower_and_upper", 2, 5) }
      .to change { list[:cnt] }.by(4)

    # Upper is required when lower is not a range
    expect { list.add_range("error", 2) }
      .to raise_error(ArgumentError)
  ensure
    list.destroy
  end

  specify "#del" do
    list = Kafka::FFI::TopicPartitionList.new(0)

    # Deleting from an empty list succeeds but returns false
    expect(list.del("stuff", 5)).to be(false)

    list.add("stuff", 5)
    expect(list.del("stuff", 5)).to be(true)
  ensure
    list.destroy
  end

  specify "#del_by_idx" do
    list = Kafka::FFI::TopicPartitionList.new(0)

    # Deleting from an empty list returns false
    expect(list.del_by_idx(0)).to be(false)

    # Add 5 partitions (0 - 4)
    expect { list.add_range("topic", 0, 4) }
      .to change { list.size }.to 5

    # Deleting from an index that doesn't exist will return false.
    expect(list.del_by_idx(6)).to be(false)

    # Successful delete partition 3
    expect(list.del_by_idx(3)).to be(true)
    expect(list.size).to eq(4)
    expect(list.elements.map(&:partition)).not_to include(3)
  ensure
    list.destroy
  end

  specify "#copy" do
    list = Kafka::FFI::TopicPartitionList.new(0)
    list.add("topic", 100)

    clone = list.copy
    expect { clone.add("stuff", 500) }
      .not_to change { list.size }
    expect(clone.size).to eq(2)
  ensure
    list.destroy
    clone.destroy if clone
  end

  specify "#set_offset" do
    list = Kafka::FFI::TopicPartitionList.new(0)

    # TODO: Const RD_KAFKA_RESP_ERR__UNKNOWN_PARTITION
    expect(list.set_offset("topic", 5, 5000)).to eq(-190)

    list.add_range("things", 0..5)
    expect(list.set_offset("things", 3, 300)).to eq(:ok)
    expect(list.find("things", 3).offset).to eq(300)
  ensure
    list.destroy
  end

  specify "#sort" do
    list = Kafka::FFI::TopicPartitionList.new(0)
    list.add("topics", 5)
    list.add("topics", 3)
    list.add("snitches", 2)
    list.add("snitches", 20)

    # Sort the list using the default sorter
    list.sort
    expect(list.elements.map { |tp| "#{tp.topic}:#{tp.partition}" }).to eq([
      "snitches:2",
      "snitches:20",
      "topics:3",
      "topics:5",
    ])

    # Sort using a custom sorter sorting be partition from largest to smallest
    list.sort do |l, r|
      r.partition <=> l.partition
    end

    expect(list.elements.map { |tp| "#{tp.topic}:#{tp.partition}" }).to eq([
      "snitches:20",
      "topics:5",
      "topics:3",
      "snitches:2",
    ])
  ensure
    list.destroy
  end

  specify "#find" do
    list = Kafka::FFI::TopicPartitionList.new(0)
    list.add("topic", 2)

    found = list.find("ephemeral", 5)
    expect(found).to be(nil)

    found = list.find("topic", 2)
    expect(found).not_to be(nil)
    expect(found.topic).to eq("topic")
    expect(found.partition).to eq(2)
  ensure
    list.destroy
  end

  specify "#elements" do
    list = Kafka::FFI::TopicPartitionList.new(0)

    # Empty list
    expect(list.elements).to eq([])

    mapper = lambda { |tp| "#{tp.topic}:#{tp.partition}" }
    list.add("topic", 2)
    list.add("stuff", 0)

    expect(list.elements.map(&mapper)).to eq([
      "topic:2",
      "stuff:0",
    ])
  ensure
    list.destroy
  end

  specify "#destroy works with a NULL TopicPartitionList" do
    list = Kafka::FFI::TopicPartitionList.new(FFI::Pointer::NULL)
    list.destroy
  end
end
