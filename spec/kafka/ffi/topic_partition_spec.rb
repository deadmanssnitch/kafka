# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kafka::FFI::TopicPartition do
  specify "#error" do
    tp = Kafka::FFI::TopicPartition.new

    tp[:err] = :ok
    expect(tp.error).to eq(nil)

    tp[:err] = -188 # RD_KAFKA_RESP_ERR__UNKNOWN_TOPIC
    expect(tp.error).to be_a(Kafka::ResponseError)
    expect(tp.error.code).to eq(-188)
    expect(tp.error.name).to eq("RD_KAFKA_RESP_ERR__UNKNOWN_TOPIC")
  ensure
    tp.pointer.free
  end
end
