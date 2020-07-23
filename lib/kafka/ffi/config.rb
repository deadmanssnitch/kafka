# frozen_string_literal: true

require "ffi"
require "kafka/ffi/opaque_pointer"

module Kafka::FFI
  class Config < OpaquePointer
    def self.new
      Kafka::FFI.rd_kafka_conf_new
    end

    def initialize(ptr)
      super(ptr)

      # Set recommended keys to identify the client to operators to help
      # diagnose issues.
      set("client.software.name", "kafka-ruby")
      set("client.software.version", software_version)

      # Maintain references to all of the set callbacks to avoid them being
      # garbage collected.
      @callbacks = {}
    end

    # Set the config option at `key` to `value`. The configuration options
    # match those used by librdkafka (and the Java client).
    #
    # @see https://github.com/edenhill/librdkafka/blob/master/CONFIGURATION.md
    #
    # @param key [String] Configuration key
    # @param value [String] Value to set
    #
    # @raise [Kafka::FFI::UnknownConfigKey]
    # @raise [Kafka::FFI::InvalidConfigValue]
    def set(key, value)
      key = key.to_s
      value = value.to_s

      error = ::FFI::MemoryPointer.new(:char, 512)
      result = ::Kafka::FFI.rd_kafka_conf_set(self, key, value, error, error.size)

      # See config_result enum in ffi.rb
      case result
      when :ok
        nil
      when :unknown
        raise Kafka::FFI::UnknownConfigKey.new(key, value, error.read_string)
      when :invalid
        raise Kafka::FFI::InvalidConfigValue.new(key, value, error.read_string)
      end
    ensure
      error.free if error
    end

    # Get the current config value for the given key.
    #
    # @param key [String] Config key to fetch the setting for.
    #
    # @return [String, Block, :unknown] Value for the key or :unknown if not already
    #   set. Calling get with a callback config key will return the configured
    #   callback.
    def get(key)
      key = key.to_s

      case key
      when "background_event_cb"          then return @callbacks.fetch(:background_event_cb, :unknown)
      when "dr_msg_cb"                    then return @callbacks.fetch(:dr_msg_cb, :unknown)
      when "consume_cb"                   then return @callbacks.fetch(:consume_cb, :unknown)
      when "rebalance_cb"                 then return @callbacks.fetch(:rebalance_cb, :unknown)
      when "offset_commit_cb"             then return @callbacks.fetch(:offset_commit_cb, :unknown)
      when "error_cb"                     then return @callbacks.fetch(:error_cb, :unknown)
      when "throttle_cb"                  then return @callbacks.fetch(:throttle_cb, :unknown)
      when "log_cb"                       then return @callbacks.fetch(:log_cb, :unknown)
      when "stats_cb"                     then return @callbacks.fetch(:stats_cb, :unknown)
      when "oauthbearer_token_refresh_cb" then return @callbacks.fetch(:oauthbearer_token_refresh_cb, :unknown)
      when "socket_cb"                    then return @callbacks.fetch(:socket_cb, :unknown)
      when "connect_cb"                   then return @callbacks.fetch(:connect_cb, :unknown)
      when "closesocket_cb"               then return @callbacks.fetch(:closesocket_cb, :unknown)
      when "open_cb"                      then return @callbacks.fetch(:open_cb, :unknown)
      when "ssl.certificate.verify_cb"    then return @callbacks.fetch(:ssl_cert_verify_cb, :unknown)
      end

      # Will contain the size of the value at key
      begin
        size = ::FFI::MemoryPointer.new(:size_t)

        # Make an initial request for the size of the buffer we need to
        # allocate. When the buffer is not large enough rd_kafka_conf_get will
        # reallocate the buffer which would cause a segfault.
        err = ::Kafka::FFI.rd_kafka_conf_get(self, key, ::FFI::Pointer::NULL, size)
        if err != :ok
          return err
        end

        begin
          # Allocate a string long enough to contain the whole value.
          value = ::FFI::MemoryPointer.new(:char, size.read(:size_t))
          err = ::Kafka::FFI.rd_kafka_conf_get(self, key, value, size)
          if err != :ok
            return err
          end

          value.read_string
        ensure
          value.free
        end
      ensure
        size.free
      end
    end

    # Duplicate the current config
    #
    # @return [Config] Duplicated config
    def dup
      ::Kafka::FFI.rd_kafka_conf_dup(self)
    end

    # Duplicate the config but do not copy any config options that match the
    # filtered keys.
    def dup_filter(*filter)
      ptr = ::FFI::MemoryPointer.new(:pointer, filter.length)

      ptr.write_array_of_pointer(
        filter.map { |str| ::FFI::MemoryPointer.from_string(str) },
      )

      ::Kafka::FFI.rd_kafka_conf_dup_filter(self, filter.length, ptr)
    ensure
      ptr.free
    end

    # rubocop:disable Naming/AccessorMethodName
    #   Disabled to allow matching librdkafka naming convention

    # Enable event sourcing. Convenience method to set the `enabled_events`
    # option as an integer.
    #
    # @example Set events using event symbol names
    #   config.set_events([ :delivery, :log, :fetch ])
    #
    # @example Set events using event constants
    #   config.set_events([ RD_KAFKA_EVENT_DR, RD_KAFKA_EVENT_LOG ])
    #
    # @param events_mask [Integer, Array<Symbol, Integer>] Bitmask of events to
    #   enable during queue poll.
    def set_events(events_mask)
      mask = events_mask

      # Support setting events
      if events_mask.is_a?(Array)
        mask = 0
        enum = ::Kafka::FFI.enum_type(:event_type)

        events_mask.each do |val|
          case val
          when Integer then mask |= val
          when Symbol  then mask |= (enum[val] || 0)
          end
        end
      end

      ::Kafka::FFI.rd_kafka_conf_set_events(self, mask)
    end

    # Set the callback that will be used for events published to the background
    # queue. This enables a background thread that runs internal to librdkafka
    # and can be used as a standard receiver for APIs that take a queue.
    #
    # @see Client#get_background_queue
    #
    # @note The application is responsible for calling #destroy on the event.
    # @note The application must not call #destroy on the Client inside the
    #   callback.
    #
    # @yield [client, event, opaque] Called when a event is received by the
    #   queue.
    # @yieldparam client [Client] Kafka Client for the event
    # @yieldparam event [Event] The event that occurred
    # @yieldparam opaque [::FFI::Pointer] Pointer to the configuration's opaque
    #   pointer that was set via set_opaque.
    def set_background_event_cb(&block)
      @callbacks[:background_event_cb] = block
      ::Kafka::FFI.rd_kafka_conf_set_background_event_cb(self, &block)
    end
    alias background_event_cb= set_background_event_cb

    # Set delivery report callback for the config. The delivery report callback
    # will be called once for each message accepted by Producer#produce. The
    # Message will have #error set in the event of a producer error.
    #
    # The callback is called when a message is successfully produced or if
    # librdkafka encountered a permanent failure.
    #
    # @note Producer only
    #
    # @yield [client, message, opaque] Called for each Message produced.
    # @yieldparam client [Client] Kafka Client for the event
    # @yieldparam message [Message] Message that was produced
    # @yieldparam opaque [::FFI::Pointer] Pointer to the configuration's opaque
    #   pointer that was set via set_opaque.
    def set_dr_msg_cb(&block)
      @callbacks[:dr_msg_cb] = block
      ::Kafka::FFI.rd_kafka_conf_set_dr_msg_cb(self, &block)
    end
    alias dr_msg_cb= set_dr_msg_cb

    # Set consume callback for use with consumer_poll.
    #
    # @note Consumer only
    #
    # @yield [message, opaque]
    # @yieldparam message [Message]
    # @yieldparam opaque [::FFI::Pointer]
    def set_consume_cb(&block)
      @callbacks[:consume_cb] = block
      ::Kafka::FFI.rd_kafka_conf_set_consume_cb(self, &block)
    end
    alias consume_cb= set_consume_cb

    # Set rebalance callback for use with consumer group balancing. Setting the
    # rebalance callback will turn off librdkafka's automatic handling of
    # assignment/revocation and delegates the responsibility to the
    # application's callback.
    #
    # @see rdkafka.h rd_kafka_conf_set_rebalance_cb
    # @note Consumer only
    #
    # @yield [client, error, partitions, opaque]
    # @yieldparam client [Client]
    # @yieldparam error [RD_KAFKA_RESP_ERR__ASSIGN_PARTITIONS] Callback
    #   contains new assignments for the consumer.
    # @yieldparam error [RD_KAFKA_RESP_ERR__REVOKE_PARTITIONS] Callback
    #   contains revocation of assignments for the consumer.
    # @yieldparam error [Integer] Other error code
    # @yieldparam partitions [TopicPartitionList] Set of partitions to assign
    #   or revoke.
    def set_rebalance_cb(&block)
      @callbacks[:rebalance_cb] = block
      ::Kafka::FFI.rd_kafka_conf_set_rebalance_cb(self, &block)
    end
    alias rebalance_cb= set_rebalance_cb

    # Set offset commit callback which is called when offsets are committed by
    # the consumer.
    #
    # @note Consumer only
    #
    # @yield [client, error, offets]
    # @yieldparam client [Client]
    # @yieldparam error [RD_KAFKA_RESP_ERR__NO_OFFSET] No partitions had valid
    #   offsets to commit. This should not be considered an error.
    # @yieldparam error [Integer] Error committing the offsets
    # @yieldparam offsets [TopicPartitionList] Committed offsets
    def set_offset_commit_cb(&block)
      @callbacks[:offset_commit_cb] = block
      ::Kafka::FFI.rd_kafka_conf_set_offset_commit_cb(self, &block)
    end
    alias offset_commit_cb= set_offset_commit_cb

    # Set error callback that is used by librdkafka to signal warnings and
    # errors back to the application. These errors should generally be
    # considered informational and non-permanent, librdkafka will try to
    # recover from all types of errors.
    #
    # @yield [client, error, reason, opaque]
    # @yieldparam client [Client]
    # @yieldparam error [RD_KAFKA_RESP_ERR__FATAL] Fatal error occurred
    # @yieldparam error [Integer] Other error occurred
    # @yieldparam reason [String]
    # @yieldparam opaque [::FFI::Pointer]
    def set_error_cb(&block)
      @callbacks[:error_cb] = block
      ::Kafka::FFI.rd_kafka_conf_set_error_cb(self, &block)
    end
    alias error_cb= set_error_cb

    # Set throttle callback that is used to forward broker throttle times to
    # the application.
    #
    # @yield [client, broker_name, broker_id, throttle_ms, opaque]
    # @yieldparam client [Client]
    # @yieldparam broker_name [String]
    # @yieldparam broker_id [Integer]
    # @yieldparam throttle_ms [Integer] Throttle time in milliseconds
    # @yieldparam opaque [::FFI::Pointer]
    def set_throttle_cb(&block)
      @callbacks[:throttle_cb] = block
      ::Kafka::FFI.rd_kafka_conf_set_throttle_cb(self, &block)
    end
    alias throttle_cb= set_throttle_cb

    # Set the logging callback. By default librdkafka will print to stderr (or
    # syslog if configured).
    #
    # @note The application MUST NOT call any librdkafka APIs or do any
    #   prolonged work in a log_cb unless logs have been forwarded to a queue
    #   via set_log_queue.
    #
    # @yield [client, level, facility, message]
    # @yieldparam client [Client]
    # @yieldparam level [Integer] Log level
    # @yieldparam facility [String] Log facility
    # @yieldparam message [String] Log message
    def set_log_cb(&block)
      @callbacks[:log_cb] = block
      ::Kafka::FFI.rd_kafka_conf_set_log_cb(self, &block)
    end
    alias log_cb= set_log_cb

    # Set statistics callback that is triggered every `statistics.interval.ms`
    # with a JSON document containing connection statistics.
    #
    # @see https://github.com/edenhill/librdkafka/blob/master/STATISTICS.md
    #
    # @yield [client, json, json_len, opaque]
    # @yieldparam client [Client]
    # @yieldparam json [String] Statistics payload
    # @yieldparam json_len [Integer] Length of the JSON payload
    # @yieldparam opaque [::FFI::Pointer]
    def set_stats_cb(&block)
      @callbacks[:stats_cb] = block
      ::Kafka::FFI.rd_kafka_conf_set_stats_cb(self, &block)
    end
    alias stats_cb= set_stats_cb

    def set_oauthbearer_token_refresh_cb(&block)
      @callbacks[:oauthbearer_token_refresh_cb] = block
      ::Kafka::FFI.rd_kafka_conf_set_oauthbearer_token_refresh_cb(self, &block)
    end
    alias oauthbearer_token_refresh_cb= set_oauthbearer_token_refresh_cb

    def set_socket_cb(&block)
      @callbacks[:socket_cb] = block
      ::Kafka::FFI.rd_kafka_conf_set_socket_cb(self, &block)
    end
    alias socket_cb= set_socket_cb

    def set_connect_cb(&block)
      @callbacks[:connect_cb] = block
      ::Kafka::FFI.rd_kafka_conf_set_connect_cb(self, &block)
    end
    alias connect_cb= set_connect_cb

    def set_closesocket_cb(&block)
      @callbacks[:closesocket_cb] = block
      ::Kafka::FFI.rd_kafka_conf_set_closesocket_cb(self, &block)
    end
    alias closesocket_cb= set_closesocket_cb

    def set_open_cb(&block)
      if ::FFI::Platform.windows?
        raise Error, "set_open_cb is not available on Windows"
      end

      @callbacks[:open_cb] = block
      ::Kafka::FFI.rd_kafka_conf_set_open_cb(self, &block)
    end
    alias open_cb= set_open_cb

    def set_ssl_cert_verify_cb(&block)
      @callbacks[:ssl_cert_verify_cb] = block
      ::Kafka::FFI.rd_kafka_conf_set_ssl_cert_verify_cb(self, &block)
    end
    alias ssl_cert_verify_cb= set_ssl_cert_verify_cb

    # rubocop:enable Naming/AccessorMethodName

    # Set the certificate for secure communication with the Kafka cluster.
    #
    # @note The private key may require a password which must be specified with
    #   the `ssl.key.password` property prior to calling this function.
    #
    # @note Private and public keys, in PEM format, can be set with the
    #   `ssl.key.pem` and `ssl.certificate.pem` configuration properties.
    #
    # @param cert_type [:public, :private, :ca]
    # @param cert_enc [:pkcs12, :der, :pem]
    # @param certificate [String] Encoded certificate
    # @param certificate [nil] Clear the stored certificate
    #
    # @raise [ConfigError] Certificate was not properly encoded or librdkafka
    #   was not compiled with SSL/TLS.
    def set_ssl_cert(cert_type, cert_enc, certificate)
      error = ::FFI::MemoryPointer.new(:char, 512)

      err = ::Kafka::FFI.rd_kafka_conf_set_ssl_cert(cert_type, cert_enc, certificate, certificate.bytesize, error, error.size)
      if err != :ok
        # Property name isn't exact since this appears to have some routing
        # based on cert type to determine the exact key.
        raise ConfigError, "ssl_cert", error.read_string
      end

      nil
    ensure
      error.free
    end
    alias ssl_cert= set_ssl_cert

    # Free all resources used by the config.
    #
    # @note Never call #destroy on a Config that has been passed to
    #   Kafka::FFI.rd_kafka_new since the handle will take ownership of the
    #   config.
    def destroy
      if !pointer.null?
        ::Kafka::FFI.rd_kafka_conf_destroy(self)
      end
    end

    private

    # Default value for client.software.version
    #
    # @return [String] Kafka client version number
    def software_version
      # Format must match /^([\.\-a-zA-Z0-9])+$/ per Validation section of
      # KIP-511.
      #
      # v0.5.2-librdkafka-v1.4.0-ruby-2.6.5
      "v#{Kafka::VERSION}-librdkafka-v#{Kafka::FFI.version}-#{RUBY_ENGINE}-#{RUBY_VERSION}"
    end
  end
end
