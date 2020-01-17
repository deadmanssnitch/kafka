# frozen_string_literal: true

module Kafka
  class Config
    # Create a new Config for initializing a Kafka Consumer or Producer. This
    # config is reusable and can be used to configure multiple Consumers or
    # Producers.
    #
    # @see https://github.com/edenhill/librdkafka/blob/master/CONFIGURATION.md
    #
    # @param opts [Hash{[String, Symbol] => [String, Integer, nil, Boolean]}]
    #
    # @raise [TypeError] Value was not of the correct type
    def initialize(opts = {})
      @opts = {}
      @callbacks = {}

      # Use #set to rekey the options as strings and type check the value.
      opts.each_pair do |key, val|
        set(key, val)
      end
    end

    # Retrieve the configured value for the key.
    #
    # @return [nil] Value is not set
    # @return Configured value for the given key
    def get(key)
      @opts[key.to_s]
    end

    # Set configratuon option `key` to `value`.
    #
    # @see https://github.com/edenhill/librdkafka/blob/master/CONFIGURATION.md
    #
    # @param key [#to_s] Configuration option
    # @param value [String, Integer, Boolean, nil]
    #
    # @raise [TypeError] Value was not of the correct type
    def set(key, val)
      key = key.to_s

      @opts[key] =
        case val
        when String, Integer, true, false, nil
          val
        else
          raise TypeError, "#{key}'s value must be a String, Integer, true, or false"
        end

      nil
    end

    # Callback for the delivery status of a message published to the Kafka
    # cluster.
    #
    # @note Producer only
    #
    # @see Kafka::FFI::Config#set_dr_msg_cb
    def on_delivery_report(&block)
      @callbacks[:delivery_report] = block
    end

    # @note Consumer only
    #
    # @see Kafka::FFI::Config#set_consume_cb
    def on_consume(&block)
      @callbacks[:consume] = block
    end

    # Callback for result of automatic or manual offset commits.
    #
    # @note Consumer only
    #
    # @see Kafka::FFI::Config#set_offset_commit_cb
    def on_offset_commit(&block)
      @callbacks[:offset_commit] = block
    end

    # Callback for errors from the cluster. Most errors are informational and
    # should be ignored as librdkafka will attempt to recover. However fatal
    # errors can be reported which should cause the system to gracefully
    # shutdown.
    #
    # @see Kafka::FFI::Config#set_error_cb
    def on_error(&block)
      @callbacks[:error] = block
    end

    # Callback for when Brokers throttle a client
    #
    # @see Kafka::FFI::Config#set_throttle_cb
    def on_throttle(&block)
      @callbacks[:throttle] = block
    end

    # Callback for log messages
    #
    # @see Kafka::FFI::Config#set_log_cb
    def on_log(&block)
      @callbacks[:log] = block
    end

    # Callback for connetion stats
    #
    # @see Kafka::FFI::Config#set_stats_cb
    def on_stats(&block)
      @callbacks[:stats] = block
    end

    # Allocate and configure a new Kafka::FFI::Config that mirrors this Config.
    # The returned Kafka::FFI::Config should be either passed to initialize a
    # new Client or eventually destroyed. Once passed to a Client, the Config
    # is now owned by the Client and should not be modified or destroyed.
    #
    # @return [Kafka::FFI::Config]
    def to_ffi
      conf = Kafka::FFI.rd_kafka_conf_new

      @opts.each do |name, value|
        conf.set(name, value)
      end

      # Omitted callbacks:
      #  - background_event - Requires lower level usage
      #  - rebalance        - Requires knowing the rebalance semantics
      #  - all socket       - Unknown need at this level
      #  - ssl_cert_verify  - Currently not needed
      #  - oauthbearer_token_refresh - Unable to test
      @callbacks.each do |name, callback|
        case name
        when :delivery_report  then conf.set_dr_msg_cb(&callback)
        when :consume          then conf.set_consume_cb(&callback)
        when :offset_commit    then conf.set_offset_commit_cb(&callback)
        when :error            then conf.set_error_cb(&callback)
        when :throttle         then conf.set_throttle_cb(&callback)
        when :log              then conf.set_log_cb(&callback)
        when :stats            then conf.set_stats_cb(&callback)
        end
      end

      conf
    end
  end
end
