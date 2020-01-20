# frozen_string_literal: true

module Kafka::FFI::Admin
  class Result < Array
    def initialize(event)
      @event = event

      super(get_results(event))
    end

    def get_results(event)
      count = ::FFI::MemoryPointer.new(:size_t)

      klass, results =
        case event.type
        when :create_topics
          [
            TopicResult,
            ::Kafka::FFI.rd_kafka_CreateTopics_result_topics(event, count),
          ]
        when :delete_topics
          [
            TopicResult,
            ::Kafka::FFI.rd_kafka_DeleteTopics_result_topics(event, count),
          ]
        when :create_partitions
          [
            TopicResult,
            ::Kafka::FFI.rd_kafka_CreateTopics_result_topics(event, count),
          ]
        when :alter_configs
          [
            ConfigResource,
            ::Kafka::FFI.rd_kafka_AlterConfigs_result_resources(event, count),
          ]
        when :describe_configs
          [
            ConfigResource,
            ::Kafka::FFI.rd_kafka_DescribeConfigs_result_resources(event, count),
          ]
        else
          raise ArgumentError, "unable to map #{event.class} to result type"
        end

      if results.null?
        return []
      end

      results = results.read_array_of_pointer(count.read(:size_t))
      results.map! { |p| klass.from_native(p, nil) }
    ensure
      count.free
    end

    def destroy
      if @event
        @event.destroy
        @event = nil
      end

      clear

      nil
    end
  end
end
