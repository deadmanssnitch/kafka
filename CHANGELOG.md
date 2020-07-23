## Unreleased

* BREAKING: Kafka::FFI::Client#metadata now returns Kafka::Metadata::Cluster
* BREAKING: Kafka::FFI::Client#group_list now returns array of Kafka::Metadata::Group
* BREAKING: Removed Kafka::LIBRDKAFKA_VERSION and Kafka::LIBRDKAFKA_CHECKSUM
* BREAKING: FFI Consumer, Producer, and Client now require a config
* Update librdkafka to 1.5.0
* Fixes Kafka::FFI::Consumer#commit_message
* Adds kip-511 for client name and version
* Adds bindings for fnv1a partitioners
* Adds Kakfa::FFI::Queue#consume

### Removal of Kafka::LIBRDKAFKA_VERSION

Prefer to use Kafka::FFI.version to get the current version of librdkafka.

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
