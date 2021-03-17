# Overview
  
Produce messages to and consume messages from a Kafka cluster using [Confluent Python Client for Apache Kafka](https://github.com/confluentinc/confluent-kafka-python).

# Documentation

You can find the documentation and instructions for running this Python example at [https://docs.confluent.io/platform/current/tutorials/examples/clients/docs/python.html](https://docs.confluent.io/platform/current/tutorials/examples/clients/docs/python.html?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.clients-ccloud)

# ESCALATION-4768

This branch (hopefully) reproduces a Heisenbug raised in `ESCALATION-4768`, whereby intermittently, for some records, a call to `Producer.flush(timeout)` returns a non-zero result (indicating not all records were flushed in 10 seconds).  The driving program is producing a single record and then calling `flush()` in a long loop.

Steps to run:

- Create a file `config_file` with CCloud configuration and credentials.
- Run `docker build -t python-client-example .`
- Run `docker run -d --name python-client-example -it -v $(pwd)/producer.py:/producer.py -v $(pwd)/config_file:/config_file python-client-example python producer.py -f config_file -t python`
- Run either `docker logs python-client-example | tail` occassionally, or `watch docker ps -a` to look for container error or exit

The error may not occur on all runs or in all environments, and could take 10s of thousands of records before it occurs:

```
docker logs python-client-example | tail
```

```
queue_length: 0
Producing record: 38376	{"count": 38376}
queue_length: 0
Producing record: 38377	{"count": 38377}
queue_length: 1
Traceback (most recent call last):
  File "producer.py", line 72, in <module>
    raise Exception("queue_length > 0: " + str(queue_length))
Exception: queue_length > 0: 1
%4|1615940792.187|TERMINATE|rdkafka#producer-1| [thrd:app]: Producer terminating with 1 message (16 bytes) still in queue or transit: use flush() to wait for outstanding message delivery
```

Changes that were made to reproduces the bug, from the source examples code:
- Produce 100,000 records in a loop (was 10)
- Use the record count n as the record key, to avoid hitting the same partition all the time with "alice".  Unsure if this is important.
- Removed the `on_delivery=acked` callback from `producer.produce()`.  Must be timing related, as the callback doesn't do anything interesting, but I have not been able to reproduce the problem with the callback registered, but that might just require more runs.
- Replaced call to `producer.poll(0)` with `queue_length = producer.flush(10)`, checking the returned queue length and raising an exception when non-zero.
