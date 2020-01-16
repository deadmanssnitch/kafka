# frozen_string_literal: true

require "ffi"

module Kafka::FFI
  # OpaquePointer pointer provides a common pattern where we receive a pointer
  # to a struct but don't care about the structure and need to pass it to
  # functions. OpaquePointer gives type safety by checking types before
  # converting.
  #
  # @note Kafka has several options for `opaque` pointers that get passed to
  #   callbacks. Those opaque pointers are not related to this opaque pointer.
  class OpaquePointer
    extend ::FFI::DataConverter

    # @attr pointer [FFI::Pointer] Pointer to the implementing class
    attr_reader :pointer

    class << self
      # Convert from a FFI::Pointer to the implementing class.
      #
      # @param value [FFI::Pointer]
      #
      # @return [nil] Passed ::FFI::Pointer::NULL
      # @return Instance of the class backed by the pointer.
      def from_native(value, _ctx)
        if !value.is_a?(::FFI::Pointer)
          raise TypeError, "from_native can only convert from a ::FFI::Pointer to #{self}"
        end

        # The equivalent of a native NULL pointer is nil.
        if value.null?
          return nil
        end

        obj = allocate
        obj.send(:initialize, value)
        obj
      end

      # Convert from a Kafka::FFI type to a native FFI type.
      #
      # @param value [Object] Instance to retrieve a pointer for.
      #
      # @return [FFI::Pointer] Pointer to the opaque struct
      def to_native(value, _ctx)
        if value.nil?
          return ::FFI::Pointer::NULL
        end

        if !value.is_a?(self)
          raise TypeError, "expected a kind of #{self}, was #{value.class}"
        end

        value.pointer
      end

      # Provide ::FFI::Struct API compatility for consistency with
      # attach_function is called with an OpaquePointer.
      def by_ref
        self
      end

      def inherited(subclass)
        subclass.native_type :pointer
      end
    end

    def initialize(pointer)
      @pointer = pointer
    end
  end
end
