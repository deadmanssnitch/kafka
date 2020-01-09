# frozen_string_literal: true

require "ffi"

module Kafka::FFI
  class TopicPartition < ::FFI::Struct
    layout(
      :topic,         :string,
      :partition,     :int32,
      :offset,        :int64,
      :metadata,      :pointer,
      :metadata_size, :size_t,
      :opaque,        :pointer,
      :err,           :error_code,
      :_private,      :pointer # DO NOT TOUCH. Internal to librdkafka
    )

    # @return [:ok, Integer] :ok on success and a RD_KAFKA_RESP_ERR_* code on
    #   an error. Will only be set under certain circumstances.
    def error
      self[:err]
    end

    # @return [String] Name of the topic
    def topic
      self[:topic]
    end

    # @return [Integer] Partition number
    def partition
      self[:partition]
    end

    # @return [Integer] Known offset for the consumer group for topic +
    #   partition.
    def offset
      self[:offset]
    end
  end
end
