# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kafka::FFI::Admin::ConfigEntry do
  specify "#name" do
    resource = Kafka::FFI::Admin::ConfigResource.new(:topic, "events")
    resource.set_config("bootstrap.servers", "localhost:9092")

    config = resource.configs.first
    expect(config.name).to eq("bootstrap.servers")
  ensure
    resource.destroy
  end

  specify "#value" do
    resource = Kafka::FFI::Admin::ConfigResource.new(:topic, "events")
    resource.set_config("bootstrap.servers", "localhost:9092")

    config = resource.configs.first
    expect(config.value).to eq("localhost:9092")
  ensure
    resource.destroy
  end

  specify "#source" do
    resource = Kafka::FFI::Admin::ConfigResource.new(:topic, "events")
    resource.set_config("bootstrap.servers", "localhost:9092")

    config = resource.configs.first
    expect(config.source).to eq(:unknown_config)
  ensure
    resource.destroy
  end

  specify "#is_read_only" do
    resource = Kafka::FFI::Admin::ConfigResource.new(:topic, "events")
    resource.set_config("bootstrap.servers", "localhost:9092")

    config = resource.configs.first
    expect(config.is_read_only).to eq(false)
  ensure
    resource.destroy
  end

  specify "#is_default" do
    resource = Kafka::FFI::Admin::ConfigResource.new(:topic, "events")
    resource.set_config("bootstrap.servers", "localhost:9092")

    config = resource.configs.first
    expect(config.is_default).to eq(false)
  ensure
    resource.destroy
  end

  specify "#is_sensitive" do
    resource = Kafka::FFI::Admin::ConfigResource.new(:topic, "events")
    resource.set_config("bootstrap.servers", "localhost:9092")

    config = resource.configs.first
    expect(config.is_sensitive).to eq(false)
  ensure
    resource.destroy
  end

  specify "#is_synonym" do
    resource = Kafka::FFI::Admin::ConfigResource.new(:topic, "events")
    resource.set_config("bootstrap.servers", "localhost:9092")

    config = resource.configs.first
    expect(config.is_synonym).to eq(false)
  ensure
    resource.destroy
  end
end
