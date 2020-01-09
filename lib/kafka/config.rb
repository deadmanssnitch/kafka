# frozen_string_literal: true

module Kafka
  class Config
    def initialize(opts = {})
      @opts = opts
    end

    def native
      conf = Kafka::FFI.rd_kafka_conf_new

      @opts.each do |name, value|
        conf.set(name, value)
      end

      conf
    end
  end
end
