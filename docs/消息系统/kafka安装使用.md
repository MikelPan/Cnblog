### kafka 创建topic
```bash
./kafka-topics --create --zookeeper localhost:2181 --replication-factor 1 --partitions 3 --topic xxx
./kafka-topics --create --zookeeper localhost:2181 --replication-factor 1 --partitions 3 --topic xxxx
./kafka-topics --create --zookeeper localhost:2181 --replication-factor 1 --partitions 3 --topic xxx
```

### 查看topic内容
```bash
./kafka-console-consumer --bootstrap-server localhost:9092 --topic xxxx --from-beginning

./kafka-console-consumer --bootstrap-server localhost:9092 --topic xxxx --from-beginning

./kafka-console-consumer --bootstrap-server localhost:9092 --topic xxxxx --offset latest --partition 0

# 查看消费组
kafka-consumer-groups --bootstrap-server xxxx --list

kafka-consumer-groups --bootstrap-server xxxx --group group_name --describe

### 查看topic队列
./kafka-topics --list --zookeeper localhost:2181

kafka-console-consumer --bootstrap-server server_addr --topic production --offset 165053844 --partition 1

kafka-console-consumer --bootstrap-server server_addr --topic production --max-messages=10
```

### 修改分区
```bash
# 增加分区
./kafka-topics --alter --zookeeper localhost:2181 --partitions 3 --topic xxxx
```
### 修改topic 副本数
```json
{
    "version": 1,
    "partitions": [
        {
            "topic": "test",
            "partition": 0,
            "replicas": [
                1,
                2,
                3
            ]
        },
        {
            "topic": "test",
            "partition": 1,
            "replicas": [
                1,
                2,
                3
            ]
        },
        {
            "topic": "test",
            "partition": 2,
            "replicas": [
                1,
                2,
                3
            ]
        }
    ]
}
```
```bash
# 增加副本数
./kafka-reassign-partitions --zookeeper localhost:2181 --reassingnment-json-file test.json --execute
```

### kcat 使用
1、安装
```bash
wget https://github.com/edenhill/kcat/archive/refs/tags/1.7.0.tar.gz -P /usr/local/src
cd /usr/local/src && ./configure --prefix=/usr/local
make -j 3 && make install
```

2、查询消息
```bash
# 查询消息
kcat -b server_addr -C -t production -o s@1634659200000 -o e@1634745599000 -f 'Topic %t [%p] at offset %o key %k value %s\n'
# 查询消息
kcat -b server_addr -C -t production -o s@1634486400000 -o e@1635091199000 -f 'Topic %t [%p] at offset %o key %k time %T value %s\n' |awk '/topic/ {print $0}' > /apps/kafka_data/toptic
# topic
awk '/topic/ {print $0}' /apps/kafka_data/kfk_18_24.log > /apps/kafka_data/toptic
# topic
awk '/topic/ {print $0}' /apps/kafka_data/kfk_18_24.log > /apps/kafka_data/toptic
```