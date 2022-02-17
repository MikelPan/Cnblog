### 配置启动yml文件
```yml
# ksql docker-compose 
---
version: '3.8'

services:
  zookeeper:
    image: confluentinc/cp-zookeeper:6.2.0
    hostname: zookeeper
    container_name: zookeeper
    ports:
      - "2181:2181"
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
      ZOOKEEPER_TICK_TIME: 2000
    networks:
      - "yfgj_net"
    deploy:
      mode: replicated
      replicas: 1
      placement:
        constraints: [node.role == manager]
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
        window: 120s

  broker:
    image: confluentinc/cp-kafka:6.2.0
    hostname: broker
    container_name: broker
    depends_on:
      - zookeeper
    ports:
      - "29092:29092"
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: 'zookeeper:2181'
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://broker:9092,PLAINTEXT_HOST://localhost:29092
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
      KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS: 0
      KAFKA_TRANSACTION_STATE_LOG_MIN_ISR: 1
      KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR: 1
    networks:
      - "yfgj_net"
    deploy:
      mode: replicated
      replicas: 1
      placement:
        constraints: [node.role == manager]
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
        window: 120s

  ksqldb-server:
    image: confluentinc/ksqldb-server:0.21.0
    hostname: ksqldb-server
    container_name: ksqldb-server
    depends_on:
      - broker
    ports:
      - "8088:8088"
    environment:
      KSQL_LISTENERS: http://0.0.0.0:8088
      KSQL_BOOTSTRAP_SERVERS: broker:9092
      KSQL_KSQL_LOGGING_PROCESSING_STREAM_AUTO_CREATE: "true"
      KSQL_KSQL_LOGGING_PROCESSING_TOPIC_AUTO_CREATE: "true"
    networks:
      - "yfgj_net"
    deploy:
      mode: replicated
      replicas: 1
      placement:
        constraints: [node.role == manager]
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
        window: 120s

  ksqldb-cli:
    image: confluentinc/ksqldb-cli:0.21.0
    container_name: ksqldb-cli
    depends_on:
      - broker
      - ksqldb-server
    entrypoint: /bin/sh
    tty: true
    networks:
      - "yfgj_net"
    deploy:
      mode: replicated
      replicas: 1
      placement:
        constraints: [node.role == manager]
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
        window: 120s

networks:
  yfgj_net:
    external: true
    name: yfgj_net
```

### 启动容器
```bash
docker stack deploy ksqldb 
```

### 启动ksqlDB的交互式cli
```bash
docker exec -it ksqldb-cli ksql http://ksqldb-server:8088
```

### 创建流
- kafka_topic -流底层的 Kafka 主题的名称。在这种情况下，它会被自动创建，因为它还不存在，但流也可以在已经存在的主题上创建
- value_format -存储在 Kafka 主题中的消息的编码。对于 JSON 编码，每一行都将存储为一个 JSON 对象，其键/值是列名/值。例如：{"profileId": "c2309eec", "latitude": 37.7877, "longitude": -122.4205}
- partitions -为location主题创建的分区数。请注意，已存在的主题不需要此参数

```bash
CREATE STREAM riderLocations (profileId VARCHAR, latitude DOUBLE, longitude DOUBLE)
  WITH (kafka_topic='locations', value_format='json', partitions=1);
```

### 对流进行推送查询

现在，让我们对流运行推送查询。使用交互式 CLI 会话运行给定的查询。
此查询将输出来自riderLocations流中坐标在山景城5 英里范围内的所有行。
这是您可能觉得有点陌生的第一件事，因为查询在终止之前永远不会返回。当事件被写入到RiderLocations流时，它将永久地将输出行推送到客户端。
现在让这个查询在 CLI 会话中运行。接下来，我们要将一些数据写入riderLocations流中，以便查询开始生成输出。

```bash
SELECT * FROM riderLocations
  WHERE GEO_DISTANCE(latitude, longitude, 37.4133, -122.1162) <= 5 EMIT CHANGES;
```







