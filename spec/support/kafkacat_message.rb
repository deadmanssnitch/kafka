# frozen_string_literal: true

require "json"

class KafkacatMessage
  attr_reader :topic
  attr_reader :partition
  attr_reader :payload
  attr_reader :key
  attr_reader :offset
  attr_reader :timestamp
  attr_reader :headers
  attr_reader :latency

  def initialize(json)
    raw = JSON.parse(json)

    @topic = raw["topic"]
    @key = raw["key"]
    @partition = raw["partition"]
    @offset = raw["offset"]
    @payload = raw["payload"]
    @timestamp = raw["ts"]
    @latency = ((Time.now - Time.at(0, @timestamp, :millisecond)).to_f * 100_000).to_i

    @headers = {}

    (raw["headers"] || []).each_slice(2).each do |k, v|
      @headers[k] ||= []
      @headers[k] << v
    end
  end
end
