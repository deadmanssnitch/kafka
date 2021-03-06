## 0.6.0 - Unreleased

This release has several breaking changes that, normally, would require a major
version bump. Most of the changes affect the Kafka::FFI module and should have
a little to no impact on anyone using the higher level APIs. There remains a
large surface area of librdkafka to implement and we don't plan to commit to
API stability until we're close to feature parity.

* BREAKING: Kafka::FFI::Client#metadata now returns Kafka::Metadata::Cluster
* BREAKING: Kafka::FFI::Client#group_list now returns array of Kafka::Metadata::Group
* BREAKING: Removed Kafka::LIBRDKAFKA_VERSION and Kafka::LIBRDKAFKA_CHECKSUM
* BREAKING: FFI Consumer, Producer, and Client now require a config
* BREAKING: Kafka::FFI::Config.get with a callback key will return the callback
* BREAKING: Kafka::FFI::Event has be split into multiple subtypes
* BREAKING: Kafka::FFI::Event#messages no longer allows passing a block
* BREAKING: Kafka::FFI::Error is no longer an exception class
* BREAKING: Kafka::FFI::Client admin operations now return result types
* Update librdkafka to 1.6.1
* Fixes Kafka::FFI::Consumer#commit_message
* Adds kip-511 for client name and version
* Adds bindings for fnv1a partitioners
* Adds Kakfa::FFI::Queue#consume
* Adds on_rebalance support to Kafka::Config

### Removal of Kafka::LIBRDKAFKA_VERSION

Prefer to use Kafka::FFI.version to get the current version of librdkafka.

### Change to Kafka::FFI::Error

Librdkafka 1.5.0 introduced a new error type for the Transaction API that
appears to be getting use in new APIs instead of the response error code. All
exceptions in Kafka::FFI now extend from Kafka::Error instead of
Kafka::FFI::Error.

### Kafka::FFI::Client admin operations now return result types

Previously the admin API operations would return only the results of the
operation (e.g. create_topics returns TopicResults). This turned out not to be
a good mapping for all Admin API calls and makes it impossible to retrieve
other information from the returned event. The result types now extend from
Event similarly to how they are represented in librdkafka which gives access to
the full context of the response.

## 0.5.2 / 2020-01-27

* Fixes DeliveryReport#error? and DeliveryReport#successful? being swapped
* Fixes Kafka::FFI::Client#cluster_id being incorrectly bound
* Fixes naming issues in Message#headers and Message#detach_headers
* Fixes naming issue in Config#set_ssl_cert
* Fixes passing nil for a Kafka::FFI::Opaque
* Adds all current RD_KAFKA_RESP_ERR_ constants
* Adds Kafka::QueueFullError for when producer queue is full
* Adds bindings for built in partitioners

## 0.5.1 / 2020-01-22

* Kafka::Consumer now uses poll_set_consumer instead of a Poller thread
* Add #latency to DeliverReport to get how long message took to be delivered.

## 0.5.0 / 2020-01-21

* Initial release!
