# frozen_string_literal: true

require "ffi"
require "kafka/ffi/opaque_pointer"

module Kafka::FFI
  class Message::Header < OpaquePointer
    def self.new(count = 0)
      if count.is_a?(::FFI::Pointer)
        return super(count)
      end

      ::Kafka::FFI.rd_kafka_headers_new(count)
    end

    # Count returns the number of headers in the set.
    #
    # @return [Integer] Number of headers
    def count
      ::Kafka::FFI.rd_kafka_header_cnt(self)
    end
    alias size count
    alias length count

    # Add header with name and value.
    #
    # @param name [String] Header key name
    # @param value [#to_s, nil] Header key value
    #
    # @raise [ResponseError] Error that occurred adding the header
    def add(name, value)
      name = name.to_s

      value_size = 0
      if value
        value = value.to_s
        value_size = value.bytesize
      end

      err = ::Kafka::FFI.rd_kafka_header_add(self, name, name.length, value, value_size)
      if err != :ok
        raise ResponseError, err
      end

      nil
    end

    # Make a copy of the headers list
    #
    # @return [Header] Copy of the headers
    def copy
      ::Kafka::FFI.rd_kafka_headers_copy(self)
    end

    # Remove all headers with the given name.
    #
    # @param name [String] Header key name to remove
    #
    # @raise [ResponseError] Error that occurred removing the header
    # @raise [ResponseError<RD_KAFKA_RESP_ERR__READ_ONLY>] Header is read only.
    def remove(name)
      name = name.to_s

      err = ::Kafka::FFI.rd_kafka_header_remove(self, name)
      case err
      when :ok
        nil
      when ::Kafka::FFI::RD_KAFKA_RESP_ERR__NOENT
        # Header field does not exist. Just return nil since the effect (key
        # doesn't exist) is the same.
        nil
      else
        raise ResponseError, err
      end
    end

    # Retrieve all headers that match the given name
    #
    # @param name [String] Header key name
    #
    # @raise [ResponseError] Error that occurred retrieving the header values
    #
    # @return [Array<String, nil>] List of values for the header
    def get(name)
      name = name.to_s

      idx = 0
      values = []

      value = ::FFI::MemoryPointer.new(:pointer)
      size  = ::FFI::MemoryPointer.new(:pointer)

      loop do
        err = ::Kafka::FFI.rd_kafka_header_get(self, idx, name, value, size)

        case err
        when :ok
          # Read the returned value and add it to the result list.
          idx += 1
          ptr = value.read_pointer

          values << (ptr.null? ? nil : ptr.read_string(size.read(:size_t)))
        when ::Kafka::FFI::RD_KAFKA_RESP_ERR__NOENT
          # Reached the end of the list of values so break and return the set
          # of found values.
          break
        else
          raise ResponseError, err
        end
      end

      values
    ensure
      value.free if value
      size.free if size
    end

    # rubocop:disable Naming/AccessorMethodName

    # Retrieve all of the headers and their values
    #
    # @raise [ResponseError] Error if occurred retrieving the headers.
    #
    # @return [Hash<String, Array<String>>] Set of header keys and their values
    # @return [Hash{}] Header is empty
    def get_all
      name  = ::FFI::MemoryPointer.new(:pointer)
      value = ::FFI::MemoryPointer.new(:pointer)
      size  = ::FFI::MemoryPointer.new(:pointer)

      idx = 0
      result = {}

      loop do
        err = ::Kafka::FFI.rd_kafka_header_get_all(self, idx, name, value, size)

        case err
        when :ok
          # Read the returned value and add it to the result list.
          idx += 1

          key = name.read_pointer.read_string
          val = value.read_pointer

          result[key] ||= []
          result[key] << (val.null? ? nil : val.read_string(size.read(:size_t)))
        when ::Kafka::FFI::RD_KAFKA_RESP_ERR__NOENT
          # Reached the end of the list of values so break and return the set
          # of found values.
          break
        else
          raise ResponseError, err
        end
      end

      result
    ensure
      name.free if name
      value.free if value
      size.free if size
    end
    alias to_hash get_all
    alias to_h get_all
    # rubocop:enable Naming/AccessorMethodName

    # Find the last header in the list that matches the given name.
    #
    # @param name [String] Header key name
    #
    # @raise [ResponseError] Error that occurred retrieving the header value
    #
    # @return [String] Value of the last matching header with name
    # @return [nil] No header with that name exists
    def get_last(name)
      name  = name.to_s
      value = ::FFI::MemoryPointer.new(:pointer)
      size  = ::FFI::MemoryPointer.new(:pointer)

      err = ::Kafka::FFI.rd_kafka_header_get_last(self, name, value, size)
      if err != :ok
        # No header with that name exists so just return nil
        if err == ::Kafka::FFI::RD_KAFKA_RESP_ERR__NOENT
          return nil
        end

        raise ResponseError, err
      end

      ptr = value.read_pointer
      ptr.null? ? nil : ptr.read_string(size.read(:size_t))
    ensure
      value.free
      size.free
    end

    def destroy
      if !pointer.null?
        ::Kafka::FFI.rd_kafka_headers_destroy(self)
      end
    end
  end
end
