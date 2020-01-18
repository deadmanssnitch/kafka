# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kafka::FFI::Admin::ConfigResource do
  specify ".new" do
    resource = Kafka::FFI::Admin::ConfigResource.new(:topic, "events")
    expect(resource).to be_a(Kafka::FFI::Admin::ConfigResource)
  ensure
    resource.destroy
  end

  specify "#configs" do
    resource = Kafka::FFI::Admin::ConfigResource.new(:broker, "1001")
    expect(resource.configs).to eq(nil)

    resource.set_config("bootstrap.servers", "127.0.0.1:9092")
    configs = resource.configs
    expect(configs.size).to eq(1)
    expect(configs[0].name).to eq("bootstrap.servers")
    expect(configs[0].value).to eq("127.0.0.1:9092")
  ensure
    resource.destroy
  end

  specify "#type" do
    Kafka::FFI.enum_type(:resource_type).symbols.each do |type|
      resource = Kafka::FFI::Admin::ConfigResource.new(type, "name")
      expect(resource.type).to eq(type)
    ensure
      resource.destroy
    end
  end

  specify "#name" do
    resource = Kafka::FFI::Admin::ConfigResource.new(:group, "web")
    expect(resource.name).to eq("web")
  ensure
    resource.destroy
  end

  specify "#error" do
    resource = Kafka::FFI::Admin::ConfigResource.new(:broker, "1001")
    expect(resource.error).to eq(nil)
  ensure
    resource.destroy
  end

  specify "#error_string" do
    resource = Kafka::FFI::Admin::ConfigResource.new(:broker, "1001")
    expect(resource.error_string).to eq(nil)
  ensure
    resource.destroy
  end
end
