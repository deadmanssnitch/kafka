# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kafka::FFI::Admin::AdminOptions do
  specify ".new" do
    client = Kafka::FFI::Producer.new
    opts = Kafka::FFI::Admin::AdminOptions.new(client, :create_topics)

    expect(opts).to be_a(Kafka::FFI::Admin::AdminOptions)
  ensure
    opts.destroy
    client.destroy
  end

  specify "#set_request_timeout" do
    client = Kafka::FFI::Producer.new
    opts = Kafka::FFI::Admin::AdminOptions.new(client, :create_topics)

    expect { opts.set_request_timeout(900000000) }
      .to raise_error(Kafka::ResponseError, /request_timeout/)

    expect { opts.set_request_timeout(-2) }
      .to raise_error(Kafka::ResponseError, /request_timeout/)

    # Verify that we can call it with a valid timeout. There is no way to read
    # the request timeout
    opts.set_request_timeout(5000)
  ensure
    opts.destroy
    client.destroy
  end

  specify "#set_operation_timeout" do
    client = Kafka::FFI::Producer.new
    opts = Kafka::FFI::Admin::AdminOptions.new(client, :create_topics)

    expect { opts.set_operation_timeout(900000000) }
      .to raise_error(Kafka::ResponseError, /operation_timeout/)

    expect { opts.set_operation_timeout(-2) }
      .to raise_error(Kafka::ResponseError, /operation_timeout/)

    # Verify that we can call it with a valid timeout. There is no way to read
    # the operation timeout.
    opts.set_operation_timeout(5000)
  ensure
    opts.destroy
    client.destroy
  end

  specify "#set_validate_only" do
    client = Kafka::FFI::Producer.new
    opts = Kafka::FFI::Admin::AdminOptions.new(client, :create_topics)

    # Verify set_validate_only can be called, there is no way to tell if the
    # set actually occurred or not.
    opts.set_validate_only(true)
    opts.set_validate_only(false)
  ensure
    opts.destroy
    client.destroy
  end

  specify "#set_broker" do
    client = Kafka::FFI::Producer.new
    opts = Kafka::FFI::Admin::AdminOptions.new(client, :create_topics)

    # Verify set_broker can be called without segfaulting. There is no way to
    # read the value back.
    opts.set_broker(1001)
  ensure
    opts.destroy
    client.destroy
  end
end
