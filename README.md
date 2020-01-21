# Kafka

[![Build Status](https://travis-ci.com/deadmanssnitch/kafka.svg?branch=master)](https://travis-ci.com/deadmanssnitch/kafka)
[![Gem Version](https://badge.fury.io/rb/kafka.svg)](https://badge.fury.io/rb/kafka)

The kafka gem provides a general producer and consumer for
[Apache Kafka](https://kafka.apache.org) using bindings to the official
[C client librdkafka](https://github.com/edenhill/librdkafka).  The `Kafka::FFI`
module implements an object oriented mapping to most of the librdkafka API,
making it easier and safer to use than calling functions directly.

## ⚠️ Project Status: Beta ⚠️

This project is currently of BETA quality. Some APIs are still in flux and may
change. There are also probably a number of subtle (and not so subtle) bugs and
memory leaks.  Since this relies heavily on binding to librdkafka through FFI
there are probably code paths which will cause segfaults or memory corruption.

Working with Kafka::FFI directly has many sharp edges which are blunted by
everything in the Kafka module.

You (yes you!) can make a difference and help make this project better. Test
against your application and traffic, implement missing functions (see
`rake ffi:missing`), work with the API and make suggestions for improvements.
All help is wanted and appreciated.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "kafka"
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install kafka

## Usage

For more examples see [the examples directory](examples/).

For a detailed introduction on librdkafka which would be useful when working
with `Kafka::FFI` directly, see 
[the librdkafka documentation](https://github.com/edenhill/librdkafka/blob/master/INTRODUCTION.md).

### Sending Message to a Topic

```ruby
require "kafka"

config = Kafka::Config.new("bootstrap.servers": "localhost:9092")
producer = Kafka::Producer.new(config)

# Asynchronously publish a JSON payload to the events topic.
event = { time: Time.now, status: "success" }
result = producer.produce("events", event.to_json)

# Wait for the delivery to confirm that publishing was successful.
# result.wait
# result.successful?
```

### Consuming Messages from a Topic

```ruby
require "kafka"

config = Kafka::Config.new({
  "bootstrap.servers": "localhost:9092",

  # Required for consumers to know what consumer group to join.
  "group.id": "web.production.eventer",
})

consumer = Kafka::Consumer.new(config)
consumer.subscribe("events")

@run = true
trap("INT")  { @run = false }
trap("TERM") { @run = false }

while @run
  consumer.poll do |message|
    puts message.payload
  end
end
```

### Configuration

Kafka has a lot of potential knobs to turn and dials to tweak. A
`Kafka::Config` uses the same configuration options as librdkafka (and most or
all from the Java client). The defaults are generally good and a fine place to
start.

[All Configuration Options](https://github.com/edenhill/librdkafka/blob/master/CONFIGURATION.md)

### Bindings

`Kafka::FFI` provides bindings to functions in
[librdkafka](https://github.com/edenhill/librdkafka/blob/master/src/rdkafka.h).
All of the names are the same and mostly have named parameters to help with
calling them. Be aware that you will need to handle some memory management to
call most functions exported in the bindings. See
[rdkafka.h](https://github.com/edenhill/librdkafka/blob/master/src/rdkafka.h)
for any questions about usage and semantics.

All classes in `Kafka::FFI` provide an object oriented mapping to the functions
exported on `Kafka::FFI.rd_kafka_*`. Most will require understanding memory
management but most should be easier to use and safe than calling into
librdkafka directly.

## Why another Kafka gem?

There are already at least two good gems for Kafka:
[ruby-kafka](https://github.com/zendesk/ruby-kafka) and
[rdkafka](https://github.com/appsignal/rdkafka-ruby). In fact we've used both
of these gems on Dead Man's Snitch for quite a while and they've been great. We
really appreciate all of the work that has gone into them :heart:.

Unfortunately, keeping up with Kafka feature and protocol changes can be a full
time job. Development on ruby-kafka has stalled for that reason and many
consumer/producer libraries are migrating away from it.

As a heartbeat and cron job monitoring service, we depend on receiving and
processing reports from jobs reliably and quickly. Failing to receive a report
could mean waking someone up at 3AM or forcing them to take time away from
family or friends to deal with a false alarm. What started as a deep dive into
rdkafka to understand how best to use it reliably, we had ideas we wanted to
implement that probably wouldn't have been a good fit for rdkafka so we decided
to start from scratch.

Our goal is to provide a stable and easy to maintain Kafka consumer / producer
for Ruby. With time as our biggest constraint it makes sense to leverage
librdkafka as it has full time maintenance and support by the team behind
Kafka. FFI makes it fast and easy to expose new librdkafka APIs as they are
added. A stable test suite means being able to meaningfully spend the limited
amount of time we have available to invest. Embracing memory management and
building clean separations between layers should reduce the burden to implement
new bindings as the rules and responsibilities of each layer are clear.

## Development

To get started with development make sure to have docker, docker-compose, and
[kafkacat](https://github.com/edenhill/kafkacat) installed as they make getting
up to speed easier.

Before running the test, start a Kafka broker instance

```console
rake kafka:up
```

Then run the tests with
```console
rake
```

When you're done shut down the Kafka instance by running:
```console
rake kafka:down
```

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/deadmanssnitch/kafka. This project is intended to be a safe,
welcoming space for collaboration, and contributors are expected to adhere to
the [code of conduct](https://github.com/deadmanssnitch/kafka/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Kafka project's codebases and issue trackers are expected to follow the
[code of conduct](https://github.com/deadmanssnitch/kafka/blob/master/CODE_OF_CONDUCT.md).
