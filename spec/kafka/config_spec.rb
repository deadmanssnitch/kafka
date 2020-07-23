# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kafka::Config do
  specify "#on_rebalance" do
    config = Kafka::Config.new
    callback = ->(client, err, tpl, opaque) {}

    expect { config.on_rebalance(&callback) }
      .to change { config.to_ffi.get("rebalance_cb") }.from(:unknown).to(callback)
  end
end
