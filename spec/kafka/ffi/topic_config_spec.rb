# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kafka::FFI::TopicConfig do
  specify "#set" do
    config = Kafka::FFI::TopicConfig.new

    expect(config.set("request.timeout.ms", "1000")).to eq(nil)
    expect(config.get("request.timeout.ms")).to eq("1000")

    # Unknown
    expect { config.set("asdfasdf", "50000") }
      .to raise_error(Kafka::FFI::UnknownConfigKey)

    # Invalid value
    expect { config.set("delivery.timeout.ms", "eleventy bits") }
      .to raise_error(Kafka::FFI::InvalidConfigValue)
  ensure
    config.destroy
  end

  specify "#get" do
    config = Kafka::FFI::TopicConfig.new

    # Get a default
    expect(config.get("request.required.acks")).to eq("-1")

    # Set then get
    config.set("request.required.acks", "2")
    expect(config.get("request.required.acks")).to eq("2")

    # Get a key without a default
    expect(config.get("partitioner_cb")).to eq(:unknown)

    # Get an unknown key
    expect(config.get("asdfasdf")).to eq(:unknown)
  ensure
    config.destroy
  end

  specify "#dup" do
    config = Kafka::FFI::TopicConfig.new
    config.set("request.required.acks", "1")

    clone = config.dup
    clone.set("request.required.acks", "3")

    expect(config.get("request.required.acks")).to eq("1")
    expect(clone.get("request.required.acks")).to eq("3")
  ensure
    config.destroy
    clone.destroy if clone
  end

  specify "#set_partitioner_cb" do
    config = Kafka::FFI::TopicConfig.new
    expect(config.get("partitioner_cb")).to eq(:unknown)

    config.set_partitioner_cb do |_topic, _key, _, _parts|
      0
    end

    # Will return the address of the method. The best we can test is that it
    # was set since there isn't a way to trigger the callback at this level.
    expect(config.get("partitioner_cb")).not_to eq(:unknown)
  ensure
    config.destroy
  end
end
