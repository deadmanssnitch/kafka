# frozen_string_literal: true

module Kafka
  class Error < StandardError; end

  require "kafka/ffi"
  require "kafka/config"
  require "kafka/version"
end
