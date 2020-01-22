# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kafka::Producer::DeliveryReport do
  let(:message) do
    double(Kafka::FFI::Message, {
      error: nil,
      offset: nil,
      topic: nil,
      partition: nil,
      latency: nil,
    })
  end

  specify "#new" do
    report = Kafka::Producer::DeliveryReport.new
    expect(report.error).to be(nil)
    expect(report.topic).to be(nil)
    expect(report.offset).to be(nil)
    expect(report.partition).to be(nil)
    expect(report.latency).to be(nil)

    expect(report).not_to be_received
    expect(report).not_to be_error
    expect(report).not_to be_successful
  end

  specify "#done" do
    expect(message).to receive(:error).and_return(Kafka::ResponseError.new(-185))
    expect(message).to receive(:offset).and_return(100)
    expect(message).to receive(:topic).and_return("events")
    expect(message).to receive(:partition).and_return(4)
    expect(message).to receive(:latency).and_return(123445)

    report = Kafka::Producer::DeliveryReport.new

    # Create a Thread that will wait for the report to finish
    returned = Queue.new
    waiter = Thread.new { report.wait; returned << true }

    # Wait until the waiting thread has blocked on `wait`
    Timeout.timeout(1) do
      while waiter.status != "sleep"
        sleep 0.1
      end
    end

    expect(report.done(message)).to eq(nil)

    success = Timeout.timeout(1) { returned.pop }
    expect(success).to be(true)

    expect(report.error).not_to be(nil)
    expect(report.error.code).to eq(-185)
    expect(report.offset).to eq(100)
    expect(report.topic).to eq("events")
    expect(report.partition).to eq(4)
    expect(report.latency).to eq(123445)
  end

  specify "#error? and #successful? are both false when report is still waiting" do
    report = Kafka::Producer::DeliveryReport.new
    expect(report.error?).to be(false)
    expect(report.successful?).to be(false)
  end

  specify "#error? and successful? are accurate when error was received" do
    expect(message).to receive(:error).and_return(Kafka::ResponseError.new(5))

    report = Kafka::Producer::DeliveryReport.new
    report.done(message)

    # error? and successful? return opposites
    expect(report.error?).to be(true)
    expect(report.successful?).to be(false)
  end

  specify "#error? and #successful? are accurate when successfully delivered" do
    expect(message).to receive(:error).and_return(nil)

    report = Kafka::Producer::DeliveryReport.new
    report.done(message)

    expect(report.error?).to be(false)
    expect(report.successful?).to be(true)
  end
end
