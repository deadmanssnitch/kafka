# frozen_string_literal: true

require "spec_helper"
require "kafka/ffi/admin"

RSpec.describe Kafka::FFI::Admin::DeleteConsumerGroupOffsets do
  specify ".new" do
    list = Kafka::FFI::TopicPartitionList.new

    req = Kafka::FFI::Admin::DeleteConsumerGroupOffsets.new("group-name", list)
    expect(req).not_to be(nil)

    req.destroy
  ensure
    list.destroy
  end
end
