# frozen_string_literal: true

require "spec_helper"
require "kafka/ffi/admin"

RSpec.describe Kafka::FFI::Admin::NewTopic do
  specify ".new" do
    req = Kafka::FFI::Admin::NewTopic.new("snitches", 3, 1)
    expect(req).not_to be(nil)
  ensure
    req.destroy
  end

  specify ".new with invalid options" do
    expect { Kafka::FFI::Admin::NewTopic.new("snitches", -2, 1) }
      .to raise_error(ArgumentError, /num_partitions/)
  end

  specify ".new with broker default partitions" do
    expect { Kafka::FFI::Admin::NewTopic.new(SecureRandom.uuid, -1, 1) }
      .not_to raise_error
  end

  specify "#set_replica_assignment" do
    # Can only test that call doesn't explode
    req = Kafka::FFI::Admin::NewTopic.new("topic", 1, -1)
    req.set_replica_assignment(0, [0, 1, 2])

    # Partition was not consecutive from the previous call
    expect { req.set_replica_assignment(2, [2]) }
      .to raise_error(Kafka::ResponseError)
  end

  specify "#set_config" do
    # Only thing we can test here is that set_config can be called without
    # error. There is no way to inspect it.
    req = Kafka::FFI::Admin::NewTopic.new("snitches", 3, 1)
    req.set_config("request.required.acks", "2")
  ensure
    req.destroy
  end
end
