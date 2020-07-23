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

    # @return [nil] The TopicPartition does not have an error set
    # @return [Kafka::ResponseError] Error for this topic occurred related to
    #   the action the TopicPartition (or TopicPartitionList) was passed to.
    def error
      if self[:err] != :ok
        ::Kafka::ResponseError.new(self[:err])
      end
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

    def inspect
      "#<Kafka::FFI::TopicPartition error=#{error.inspect} topic=#{topic.inspect} partition=#{partition} offset=#{offset}>"
    end
  end
end
