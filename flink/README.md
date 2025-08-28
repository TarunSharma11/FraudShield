# Flink Job Scaffold

Use Amazon Managed Service for Apache Flink (Kinesis Data Analytics v2) to run your Flink job.
Upload a fat JAR to the S3 bucket created by Terraform: `fraudshield-flink-artifacts-<region>/jobs/fraudshield-job.jar`.

Your job should:
- Source: Kafka (MSK) topic `transactions.raw`
- Dedup by `event_id` (TTL state)
- Async feature lookups from Redis (host from Terraform output `redis_endpoint`)
- CEP/windows for patterns
- Inference: in-JVM LightGBM (preferred) or async RPC to your model server
- Sink:
  - Kafka topic `fraud.decisions`
  - Redis key `decision:{event_id}` with TTL (e.g., 15m)
  - Timestream table `decisions`

Example pseudo-code (DataStream API):

```java
StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
env.enableCheckpointing(5000);
env.setStateBackend(new EmbeddedRocksDBStateBackend());

DataStream<Event> raw = env.addSource(kafkaSource(...));

DataStream<Event> dedup = raw
  .keyBy(e -> e.eventId)
  .process(new DedupProcessFunction(Duration.ofMinutes(10)));

DataStream<Enriched> enr = AsyncDataStream.unorderedWait(
  dedup, new RedisFeatureLookup(redisHost, 6379), 50, TimeUnit.MILLISECONDS, 100);

DataStream<Scored> scored = enr.process(new InJvmLightGBMScorer(modelPath));

DataStream<Decision> decisions = scored.process(new PolicyFunction());

decisions.addSink(kafkaSink(..., "fraud.decisions"));
decisions.addSink(new RedisDecisionSink(redisHost, 6379, Duration.ofMinutes(15)));
decisions.addSink(new TimestreamSink(timestreamClient, "fraudshield_db", "decisions"));

env.execute("FraudShield");
```

Update `terraform/kda_flink.tf` property group values if you change topic names.
