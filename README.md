# Kafka

[![Build Status](https://travis-ci.com/deadmanssnitch/kafka.svg?branch=master)](https://travis-ci.com/deadmanssnitch/kafka)

Kafka provides both a generalized producer and consumer for [Apache Kafka](https://kafka.apache.org)
as well as a set of bindings to [librdkafka](https://github.com/edenhill/librdkafka) to build
specialized integrations.

## :rotating_light: Project Status: Alpha :rotating_light:

This project is currently of ALPHA quality. The APIs are still in flux and
changes will happen that may break your application. There are also probably a
number of subtle (and not so subtle) bugs. Since this relies heavily on binding
to librdkafka through FFI there are probably code paths which will cause
segfaults or memory corruption.

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

TODO: Write usage instructions here

## Development

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version, push
git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

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
