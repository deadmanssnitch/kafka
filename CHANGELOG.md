## Unreleased

* Fixes DeliveryReport#error? and DeliveryReport#successful? being swapped
* Fixes Kafka::FFI::Client#cluster_id being incorrectly bound
* Adds all current RD_KAFKA_RESP_ERR_ constants
* Adds Kafka::QueueFullError for when producer queue is full

## 0.5.1 / 2020-01-22

* Kafka::Consumer now uses poll_set_consumer instead of a Poller thread
* Add #latency to DeliverReport to get how long message took to be delivered.

## 0.5.0 / 2020-01-21

* Initial release!
