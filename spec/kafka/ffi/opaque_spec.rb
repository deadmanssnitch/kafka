# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kafka::FFI::Opaque do
  specify "creating an Opaque registers it" do
    value = Object.new

    opaque = Kafka::FFI::Opaque.new(value)
    expect(opaque.value).to be(value)
    expect(opaque.pointer).not_to be(nil)

    fetched = Kafka::FFI::Opaque.from_native(opaque.pointer, nil)
    expect(fetched).to be(opaque)
  end

  specify "freeing a Opaque removes it from the registry" do
    value = Object.new

    opaque = Kafka::FFI::Opaque.new(value)
    expect(opaque.value).to be(value)
    expect(opaque.pointer).not_to be(nil)

    ptr = opaque.pointer

    expect { opaque.free }
      .to change { Kafka::FFI::Opaque.from_native(ptr, nil) }.to(nil)
  end

  specify ".to_native converts nil to NULL" do
    expect(Kafka::FFI::Opaque.to_native(nil, nil))
      .to eq(::FFI::Pointer::NULL)
  end
end
