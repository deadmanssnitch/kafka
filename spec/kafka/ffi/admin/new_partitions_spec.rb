# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kafka::FFI::Admin::NewPartitions do
  specify ".new" do
    np = Kafka::FFI::Admin::NewPartitions.new("topic", 1)
    expect(np).to be_a(Kafka::FFI::Admin::NewPartitions)
  ensure
    np.destroy
  end

  specify ".new invalid options" do
    expect { Kafka::FFI::Admin::NewPartitions.new("topic", 0) }
      .to raise_error(ArgumentError)
  end

  specify "#set_replica_assignment" do
    np = Kafka::FFI::Admin::NewPartitions.new("topic", 5)

    expect { np.set_replica_assignment(2, [1001]) }
      .to raise_error(Kafka::ResponseError, /Partitions must be added in order/)

    # Just test that we can make the call without an error.
    np.set_replica_assignment(0, [1001, 1002])
  ensure
    np.destroy
  end
end
