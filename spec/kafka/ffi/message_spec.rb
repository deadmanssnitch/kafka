# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kafka::FFI::Message do
  # @note Messages are created inside librdkafka so their isn't a good way to
  #       test them.

  specify "#error" do
    msg = Kafka::FFI::Message.new

    msg[:err] = :ok
    expect(msg.error).to eq(nil)

    msg[:err] = -199
    expect(msg.error).to be_a(Kafka::ResponseError)
    expect(msg.error.code).to eq(-199)
    expect(msg.error.name).to eq("RD_KAFKA_RESP_ERR__BAD_MSG")
  end
end
