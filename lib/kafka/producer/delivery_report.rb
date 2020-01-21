# frozen_string_literal: true

class Kafka::Producer
  class DeliveryReport
    # @return [nil] Delivery was successful or report has not been received
    #   yet.
    # @return [Kafka::ResponseError] Error delivering the Message.
    attr_reader :error

    # @return [nil] Report has not been received yet
    # @return [String] Name of the topic Message was delivered to.
    attr_reader :topic

    # @return [nil] Report has not been received yet
    # @return [Integer] Offset for the message on partition.
    attr_reader :offset

    # @return [nil] Report has not been received yet
    # @return [Integer] Partition the message was delivered to.
    attr_reader :partition

    # Initializes a new DeliveryReport
    #
    # @param block [Proc] Callback to call with the DeliveryReport when it is
    #   received from the cluster.
    def initialize(&block)
      @mutex = Mutex.new
      @waiter = ConditionVariable.new

      @error = nil
      @topic = nil
      @offset = nil
      @partition = nil
      @callback = block

      # Will be set to true by a call to #done. Fast out for any callers to
      # #wait that may come in after done has already been called.
      @done = false
    end

    # Returns true when the report has been received back from the kafka
    # cluster.
    #
    # @return [Boolean] True when the server has reported back on the
    #   delivery.
    def received?
      @done
    end

    # @return [Boolean] Is the report for an error?
    def error?
      error.nil?
    end

    # Returns if the delivery was successful
    #
    # @return [Boolean] True when the report was delivered to the cluster
    #   successfully.
    def successful?
      !error
    end

    # @private
    #
    # Set the response based on the message and notify anyone waiting on the
    # result.
    #
    # @param message [Kafka::FFI::Message]
    def done(message)
      @mutex.synchronize do
        @error = message.error

        @offset = message.offset
        @topic = message.topic
        @partition = message.partition

        @done = true
        @waiter.broadcast

        remove_instance_variable(:@mutex)
        remove_instance_variable(:@waiter)
      end

      if @callback
        @callback.call(self)
      end
    end

    # Wait for a report to be received for the delivery from the cluster.
    #
    # @param timeout [Integer] Maximum time to wait in milliseconds.
    #
    # @raise [Kafka::ResponseError<RD_KAFKA_RESP_ERR__TIMED_OUT>] No report
    #   received before timeout.
    def wait(timeout: 5000)
      # Fast out since the delivery report has already been reported back from
      # the cluster.
      if @done
        return
      end

      @mutex.synchronize do
        # Convert from milliseconds to seconds to match Ruby's API. Takes
        # milliseconds to be consistent with librdkafka APIs.
        if timeout
          timeout /= 1000.0
        end

        @waiter.wait(@mutex, timeout)

        # No report was received for the message before we timed out waiting.
        if !@done
          raise ::Kafka::ResponseError, ::Kafka::FFI::RD_KAFKA_RESP_ERR__TIMED_OUT
        end
      end

      nil
    end
  end
end
