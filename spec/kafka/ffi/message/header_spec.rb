# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kafka::FFI::Message::Header do
  specify ".new" do
    header = Kafka::FFI::Message::Header.new
    expect(header).not_to be(nil)
  ensure
    header.destroy
  end

  specify "#count" do
    header = Kafka::FFI::Message::Header.new(3)
    expect(header.count).to eq(0)

    expect { header.add("token", "123456") }
      .to change(header, :count).by(1)
  ensure
    header.destroy
  end

  specify "#copy" do
    header = Kafka::FFI::Message::Header.new
    header.add("meta", "data")

    copy = header.copy
    copy.add("meta", "datum")
    copy.add("new", "key")

    expect(copy.get_all).to eq({
      "meta" => ["data", "datum"],
      "new" => ["key"],
    })

    expect(header.get_all).to eq({
      "meta" => ["data"],
    })
  ensure
    header.destroy
    copy.destroy if copy
  end

  specify "#remove" do
    header = Kafka::FFI::Message::Header.new
    header.add("meta", "data")
    header.add("meta", "datum")

    expect { header.remove("meta") }
      .to change(header, :count).by(-2)

    expect(header.remove("empty")).to be(nil)
  ensure
    header.destroy
  end

  specify "#get" do
    header = Kafka::FFI::Message::Header.new
    expect(header.get("meta")).to eq([])

    # Header has one value
    header.add("meta", "data")
    expect(header.get("meta")).to eq(["data"])

    # Header has multiple values
    header.add("meta", "datum")
    expect(header.get("meta")).to eq(["data", "datum"])
  ensure
    header.destroy
  end

  specify "#get_all" do
    header = Kafka::FFI::Message::Header.new

    # Empty header
    expect(header.get_all).to eq({})

    # Header has one value
    header.add("meta", "data")
    expect(header.get_all).to eq({
      "meta" => ["data"],
    })

    # Head has multiple keys and some have multiple values
    header.add("meta", "datum")
    header.add("name", "value")
    expect(header.get_all).to eq({
      "meta" => ["data", "datum"],
      "name" => ["value"],
    })
  ensure
    header.destroy
  end

  specify "#get_last" do
    header = Kafka::FFI::Message::Header.new

    # Set + Get Last
    header.add("name", "James")
    expect(header.get_last("name")).to eq("James")

    # Adding another header with the same key. The last value added is the one
    # returned from get_last.
    header.add("name", "Oscar")
    expect(header.get_last("name")).to eq("Oscar")

    # Get a header that hasn't been set
    expect(header.get_last("foo")).to eq(nil)
  ensure
    header.destroy
  end
end
