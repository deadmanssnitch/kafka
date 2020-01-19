# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kafka::FFI::GroupInfo do
  # Hackery to be able to set string fields
  def set_string_field(field, struct, value)
    offset = struct.offset_of(field)
    value = ::FFI::MemoryPointer.from_string(value)

    struct.pointer.put_pointer(offset, value)
  end

  specify "#group" do
    info = Kafka::FFI::GroupInfo.new

    set_string_field(:group, info, "group-name")
    expect(info.group).to eq("group-name")
    expect(info.name).to eq("group-name")
  end

  specify "#error" do
    info = Kafka::FFI::GroupInfo.new

    info[:err] = :ok
    expect(info.error).to eq(nil)

    info[:err] = -100
    expect(info.error).to eq(Kafka::ResponseError.new(-100))
  end

  specify "#state" do
    info = Kafka::FFI::GroupInfo.new

    set_string_field(:state, info, "Empty")
    expect(info.state).to eq("Empty")
  end

  specify "#protocol_type" do
    info = Kafka::FFI::GroupInfo.new

    set_string_field(:protocol_type, info, "range")
    expect(info.protocol_type).to eq("range")
  end

  specify "#protocol" do
    info = Kafka::FFI::GroupInfo.new

    set_string_field(:protocol, info, "consumer")
    expect(info.protocol).to eq("consumer")
  end
end
