# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kafka::FFI::Config do
  specify "new initializes a Config in librdkafka" do
    config = Kafka::FFI::Config.new
    expect(config).not_to be(nil)
  ensure
    config.destroy
  end

  specify "#dup" do
    config = Kafka::FFI::Config.new
    config.set("client.id", "original")

    clone = config.dup
    clone.set("client.id", "clone")

    expect(config.get("client.id")).to eq("original")
    expect(clone.get("client.id")).to eq("clone")
  ensure
    config.destroy
    clone.destroy if clone
  end

  specify "#dup_filter" do
    config = Kafka::FFI::Config.new
    config.set("client.id", "original")
    config.set("group.id", "the-group")
    config.set("message.max.bytes", "5000")

    # Create a clone that does not copy the client.id or group.id
    clone = config.dup_filter("client.id", "group.id")
    expect(clone.get("message.max.bytes")).to eq("5000")
    expect(clone.get("client.id")).not_to eq("original")
    expect(clone.get("group.id")).not_to eq("the-group")
  ensure
    config.destroy
    clone.destroy if clone
  end

  specify "#set" do
    config = Kafka::FFI::Config.new

    # Set then Get
    expect(config.set("client.id", "Snitcher")).to eq(nil)
    expect(config.get("client.id")).to eq("Snitcher")

    # Unknown
    expect { config.set("asdfasdf", "50000") }
      .to raise_error(Kafka::FFI::UnknownConfigKey)

    # Invalid value
    expect { config.set("message.max.bytes", "eleventy bits") }
      .to raise_error(Kafka::FFI::InvalidConfigValue)
  end

  specify "#get" do
    config = Kafka::FFI::Config.new
    config.set("client.id", "Ruby")

    # Reading an existing value
    expect(config.get("client.id")).to eq("Ruby")

    # Write a value longer than the default buffer size (512)
    value = "V" * 600
    expect(config.set("client.id", value)).to eq(nil)
    expect(config.get("client.id")).to eq(value)

    # Unknown config value
    expect(config.get("lkajsdlkj")).to eq(:unknown)

    # Value without a default
    expect(config.get("metadata.broker.list")).to eq(:unknown)
  ensure
    config.destroy
  end

  specify "#dup" do
    config = Kafka::FFI::Config.new
    config.set("client.id", "Ruby")

    # Duplicate the config and change the client.id
    clone = config.dup
    clone.set("client.id", "dupe")

    expect(config.get("client.id")).to eq("Ruby")
    expect(clone.get("client.id")).to eq("dupe")
  ensure
    config.destroy
    clone.destroy if clone
  end

  specify "#set_events" do
    config = Kafka::FFI::Config.new

    # Allows setting the events as a bitmask
    mask = Kafka::FFI::RD_KAFKA_EVENT_DR | Kafka::FFI::RD_KAFKA_EVENT_FETCH
    config.set_events(mask)
    expect(config.get("enabled_events")).to eq(mask.to_s)

    # Allows setting the events as an array of symbols
    config.set_events([:stats, :log])
    expect(config.get("enabled_events")).to eq(
      (Kafka::FFI::RD_KAFKA_EVENT_STATS | Kafka::FFI::RD_KAFKA_EVENT_LOG).to_s,
    )

    # Allows setting as an array of integer constants
    mask = [
      ::Kafka::FFI::RD_KAFKA_EVENT_OFFSET_COMMIT,
      ::Kafka::FFI::RD_KAFKA_EVENT_ERROR,
    ]
    config.set_events(mask)
    expect(config.get("enabled_events")).to eq(mask.inject(0) { |v, m| v | m }.to_s)
  ensure
    config.destroy
  end

  specify "#set_background_event_cb" do
    config = Kafka::FFI::Config.new
    callback = lambda {}

    expect { config.set_background_event_cb(&callback) }
      .to change { config.get("background_event_cb") }.from(:unknown)
  ensure
    config.destroy
  end

  specify "#set_dr_msg_cb" do
    config = Kafka::FFI::Config.new
    callback = lambda {}

    expect { config.set_dr_msg_cb(&callback) }
      .to change { config.get("dr_msg_cb") }.from(:unknown)
  ensure
    config.destroy
  end

  specify "#set_consume_cb" do
    config = Kafka::FFI::Config.new
    callback = lambda {}

    expect { config.set_consume_cb(&callback) }
      .to change { config.get("consume_cb") }.from(:unknown)
  ensure
    config.destroy
  end

  specify "#set_rebalance_cb" do
    config = Kafka::FFI::Config.new
    callback = lambda {}

    expect { config.set_rebalance_cb(&callback) }
      .to change { config.get("rebalance_cb") }.from(:unknown)
  ensure
    config.destroy
  end

  specify "#set_offset_commit_cb" do
    config = Kafka::FFI::Config.new
    callback = lambda {}

    expect { config.set_offset_commit_cb(&callback) }
      .to change { config.get("offset_commit_cb") }.from(:unknown)
  ensure
    config.destroy
  end

  specify "#set_error_cb" do
    config = Kafka::FFI::Config.new
    callback = lambda {}

    expect { config.set_error_cb(&callback) }
      .to change { config.get("error_cb") }.from(:unknown)
  ensure
    config.destroy
  end

  specify "#set_throttle_cb" do
    config = Kafka::FFI::Config.new
    callback = lambda {}

    expect { config.set_throttle_cb(&callback) }
      .to change { config.get("throttle_cb") }.from(:unknown)
  ensure
    config.destroy
  end

  specify "#set_log_cb" do
    config = Kafka::FFI::Config.new
    callback = lambda {}

    expect { config.set_log_cb(&callback) }
      .to change { config.get("log_cb") }
  ensure
    config.destroy
  end

  specify "#set_stats_cb" do
    config = Kafka::FFI::Config.new
    callback = lambda {}

    expect { config.set_stats_cb(&callback) }
      .to change { config.get("stats_cb") }.from(:unknown)
  ensure
    config.destroy
  end

  specify "#set_oauthbearer_token_refresh_cb" do
    config = Kafka::FFI::Config.new
    callback = lambda {}

    expect { config.set_oauthbearer_token_refresh_cb(&callback) }
      .to change { config.get("oauthbearer_token_refresh_cb") }.from(:unknown)
  ensure
    config.destroy
  end

  specify "#set_socket_cb" do
    config = Kafka::FFI::Config.new
    callback = lambda {}

    expect { config.set_socket_cb(&callback) }
      .to change { config.get("socket_cb") }
  ensure
    config.destroy
  end

  specify "#set_connect_cb" do
    config = Kafka::FFI::Config.new
    callback = lambda {}

    expect { config.set_connect_cb(&callback) }
      .to change { config.get("connect_cb") }.from(:unknown)
  ensure
    config.destroy
  end

  specify "#set_closesocket_cb" do
    config = Kafka::FFI::Config.new
    callback = lambda {}

    expect { config.set_closesocket_cb(&callback) }
      .to change { config.get("closesocket_cb") }.from(:unknown)
  ensure
    config.destroy
  end

  specify "#set_open_cb" do
    config = Kafka::FFI::Config.new
    callback = lambda {}

    expect { config.set_open_cb(&callback) }
      .to change { config.get("open_cb") }
  ensure
    config.destroy
  end

  specify "#set_ssl_cert_verify_cb" do
    config = Kafka::FFI::Config.new
    callback = lambda {}

    expect { config.set_ssl_cert_verify_cb(&callback) }
      .to change { config.get("ssl.certificate.verify_cb") }.from(:unknown)
  ensure
    config.destroy
  end
end
