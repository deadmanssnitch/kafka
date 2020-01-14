# frozen_string_literal: true

require "json"

RSpec.configure do
  class KafkacatMessage
    attr_reader :topic
    attr_reader :partition
    attr_reader :payload
    attr_reader :key
    attr_reader :offset
    attr_reader :timestamp
    attr_reader :headers

    def initialize(json)
      raw = JSON.parse(json)

      @topic = raw["topic"]
      @key = raw["key"]
      @partition = raw["partition"]
      @offset = raw["offset"]
      @payload = raw["payload"]
      @timestamp = raw["ts"]

      @headers = {}

      (raw["headers"] || []).each_slice(2).each do |k, v|
        @headers[k] ||= []
        @headers[k] << v
      end
    end
  end
end
