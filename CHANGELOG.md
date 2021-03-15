## Unreleased

* BREAKING: Kafka::FFI::Client#metadata now returns Kafka::Metadata::Cluster
* BREAKING: Kafka::FFI::Client#group_list now returns array of Kafka::Metadata::Group
* BREAKING: Removed Kafka::LIBRDKAFKA_VERSION and Kafka::LIBRDKAFKA_CHECKSUM
* BREAKING: FFI Consumer, Producer, and Client now require a config
* BREAKING: Kafka::FFI::Config.get with a callback key will return the callback
* BREAKING: Kafka::FFI::Event#messages no longer allows passing a block
* BREAKING: Kafka::FFI::Error is no longer an exception class
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
