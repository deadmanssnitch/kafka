# frozen_string_literal: true

require "ffi"

module Kafka::FFI::Admin
  class TopicResult
    # @attr topic [String] Name of the topic the TopicResult is for.
    attr_reader :topic

    # @attr error [nil] Topic action was successful
    # @attr error [Kafka::ResponseError] Action on the cluster for this
    #   action failed.
    attr_reader :error

    def initialize(struct)
      # Convenience conversion to the underlying struct. The methods that
      # return a TopicStruct grab the data when it is in scope but that data
      # has been freed by the time it is returned to the caller.
      #
      # See Kafka::FFI::Admin::Client
      if struct.is_a?(::FFI::Pointer)
        struct = Struct.new(struct)
      end

      @topic = struct[:topic]

      # RD_KAFKA_RESP_ERR__NO_ERROR
      if struct[:err] != 0
        @error = ::Kafka::ResponseError.new(struct[:err])
      end
    end

    def to_s
      format("<%s topic=%s error=%s>", self.class, topic, error)
    end

    class Struct < ::FFI::Struct
      layout(
        :topic,  :string,
        :err,    :int,
        :errstr, :string,
        :data,   :char
      )
    end
  end
end
