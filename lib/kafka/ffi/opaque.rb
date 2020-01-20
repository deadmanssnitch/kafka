# frozen_string_literal: true

module Kafka::FFI
  # Opaque provides a safe mechanism for providing Ruby objects as opaque
  # pointers.
  #
  # Opaque pointers are used heavily in librdkafka to allow for passing
  # references to application state into callbacks, configs, and other
  # contexts. Ruby's garbage collector cannot check for references held in
  # external FFI memory and will garbage collect objects that are otherwise not
  # referenced leading to a segmentation fault.
  #
  # Opaque solves this by allocated a memory address which is used as a hash
  # key to look up the Ruby object when needed. This keeps a reference to the
  # object in Ruby so it is not garbage collected. This method allows for Ruby
  # objects to be moved in memory during compaction (in Ruby 2.7+) compared to
  # storing a referece to a Ruby object.
  class Opaque
    extend ::FFI::DataConverter
    native_type :pointer

    # Registry holds references to all known Opaque instances in the system
    # keyed by the pointer address associated with it.
    @registry = {}

    class << self
      # Register the Opaque the registry, keeping a reference to it to avoid it
      # being garbage collected. This will replace any existing Opaque with the
      # same address.
      #
      # @param opaque [Opaque]
      def register(opaque)
        @registry[opaque.pointer.address] = opaque
      end

      # Remove the Opaque from the registry, putting it back in contention for
      # garbage collection.
      #
      # @param opaque [Opaque]
      def remove(opaque)
        @registry.delete(opaque.pointer.address)
      end

      # @param value [Opaque]
      def to_native(value, _ctx)
        value.pointer
      end

      # @param value [FFI::Pointer]
      def from_native(value, _ctx)
        if value.null?
          return nil
        end

        @registry.fetch(value.address, nil)
      end
    end

    attr_reader :value
    attr_reader :pointer

    def initialize(value)
      @value = value
      @pointer = ::FFI::MemoryPointer.new(:int8)

      Opaque.register(self)
    end

    # Free releases the pointer back to the system and removes the Opaque from
    # the registry. free should only be called when the Opaque is no longer
    # stored in librdkafka as it frees the backing pointer which could cause a
    # segfault if still referenced.
    def free
      Opaque.remove(self)
      @pointer.free

      @value = nil
      @pointer = nil
    end
  end
end
