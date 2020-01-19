# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kafka::FFI::GroupMemberInfo do
  # Hackery to be able to set string fields
  def set_string_field(field, struct, value)
    offset = struct.offset_of(field)
    value = ::FFI::MemoryPointer.from_string(value)

    struct.pointer.put_pointer(offset, value)
  end

  specify "accessors" do
    info = Kafka::FFI::GroupMemberInfo.new

    set_string_field(:member_id, info, "MemberID")
    expect(info.member_id).to eq("MemberID")

    set_string_field(:client_id, info, "CLIENT-ID")
    expect(info.client_id).to eq("CLIENT-ID")

    set_string_field(:client_host, info, "localhost")
    expect(info.client_host).to eq("localhost")

    info[:member_metadata] = ::FFI::MemoryPointer.from_string("METADATA")
    info[:member_metadata_size] = 8
    expect(info.member_metadata).to eq("METADATA")

    info[:member_assignment] = ::FFI::MemoryPointer.from_string("ASSIGNMENTS")
    info[:member_assignment_size] = 11
    expect(info.member_assignment).to eq("ASSIGNMENTS")
  end
end
