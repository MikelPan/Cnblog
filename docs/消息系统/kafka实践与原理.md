## Kafka体系架构

- 若干Producer
- 若干Broker
- 若干Consumer
- 一个Zookeeper集群

其中Zookeeper是Kafka用来负责元数据的管理、控制器的选举。Producer将消息发送到Broker，Broker负责将消息存储到磁盘中，而Consumer负责从Broker订阅并消费消息。

![kafka架构](https://tc.ctq6.cn/tc/kafka%E6%9E%B6%E6%9E%84.jpg)

（1）Producer：生产者负责创建消息，将其投递到Kafka中。

（2）Customer：消费者连接到Kafak上并接收消息，进而进行相应的业务逻辑处理

（3）Broker：服务代理节点，独立的Kafak服务节点或实例

（4）Topic：Kafka中的消息以主题为单位进行归类，生产者将消息发送到特定的主题，消费者负责订阅并进行消费

（5）Partition：一个分区属于单个主题，分区在存储层面是一个可以追加的日志（Log）文件，消息被追加到分区的日志文件的时候会分配一个特定的偏移量（offset）。offset是消息在分区中的唯一标识，offset不跨越分区，kafka保证分区有序。每一条消息被发送到broker之前，根据分区规则存储，一个主题可以跨分区，这样就解决了横向拓展问题，不会受到单台机器I/O限制。

   (6)  Zookeeper 集群:（负责管理 broker 组成的 Kafka 集群管理、选举 leader，rebalance 等操作）

### 多分区副本机制

分区中的多副本机制：增加副本可以提高容灾能力，同一分区中不同副本中保存相同的消息（同一时刻副本之间并非完全相同），副本是一主多从的关系，leader副本负责处理读写请求，follovwer负责与leader副本同步消息。副本处于不同的broker中，当leader出现故障，从follower中重新选主副本对外提供服务。



![kafka架构 (1)](https://tc.ctq6.cn/tc/kafka%E6%9E%B6%E6%9E%84%20(2).jpg)



Kafka集群中有4个broker，其中一个主题中分区3个，副本3个，每个分区中有1个leader和2个follower，生产者和消费者只与leader交互，follower副本只负责消息同步。

Customer使用拉（Pull）模式从服务端拉取消息，并且保存消费的具体位置，当消费者宕机后恢复上线可以根据之前保存的消费位置重新拉取需要的消息进行消费。

#### 分区多副本管理机制

分区中所有副本统称为AR，所有与leader副本保持一定同步的副本包括leader副本组成ISR，ISR是AR集合的一个子集，消息先发送给leader副本，然后follower副本从leader副本中同步消息。与leader副本同步滞后过多的副本不包括leader副本组成OSR

leader副本负责维护和跟踪ISR集合中所有的follower副本滞后状态，当follower副本落后太多或失效时，leader副本会把它从ISR集合中剔除。如果OSR副本追上了leader副本，那么leader副本将把它从OSR集合中转移到ISR集合。默认情况下，当leader副本发生故障时，只有在ISR集合中的副本才有资格被选择为新的leader。

Follower周期性地向leader发送FetchRequest请求，发送时间间隔配置在replica.fetch.wait.max.ms中，默认值为500

各Partition的leader负责维护ISR列表并将ISR的变更同步至ZooKeeper，被移出ISR的Follower会继续向leader发FetchRequest请求，试图再次跟上leader重新进入ISR

ISR中所有副本都跟上了leader，通常只有ISR里的成员才可能被选为leader

![](https://static001.geekbang.org/infoq/71/7151047ee2d674082674106f4033db0a.png)

##### Unclean领导者选主

当Kafka中unclean.leader.election.enable配置为true(默认值为false)且ISR中所有副本均宕机的情况下，才允许ISR外的副本被选为leader，此时会丢失部分已应答的数据

开启 Unclean 领导者选举可能会造成数据丢失，但好处是，它使得分区 leader 副本一直存在，不至于停止对外提供服务，因此提升了高可用性，反之，禁止 Unclean 领导者选举的好处在于维护了数据的一致性，避免了消息丢失，但牺牲了高可用性

##### ACK机制

##### 故障恢复机制

首先需要在集群所有Broker中选出一个Controller，负责各Partition的leader选举以及Replica的重新分配

当出现leader故障后，Controller会将leader/Follower的变动通知到需为此作出响应的Broker。

Kafka使用ZooKeeper存储Broker、Topic等状态数据，Kafka集群中的Controller和Broker会在ZooKeeper指定节点上注册Watcher(事件监听器)，以便在特定事件触发时，由ZooKeeper将事件通知到对应Broker

**Broker**

当Broker发生故障后，由Controller负责选举受影响Partition的新leader并通知到相关Broker

- 当Broker出现故障与ZooKeeper断开连接后，该Broker在ZooKeeper对应的znode会自动被删除，ZooKeeper会触发Controller注册在该节点的Watcher
- Controller从ZooKeeper的/brokers/ids节点上获取宕机Broker上的所有Partition
- Controller再从ZooKeeper的/brokers/topics获取所有Partition当前的ISR
- 对于宕机Broker是leader的Partition，Controller从ISR中选择幸存的Broker作为新leader
- 最后Controller通过leaderAndIsrRequest请求向的Broker发送leaderAndISRRequest请求

![kafkaBroker故障 (1)](https://tc.ctq6.cn/tc/kafkaBroker%E6%95%85%E9%9A%9C%20(1).jpg)

**Controller**

集群中的Controller也会出现故障，因此Kafka让所有Broker都在ZooKeeper的Controller节点上注册一个Watcher

Controller发生故障时对应的Controller临时节点会自动删除，此时注册在其上的Watcher会被触发，所有活着的Broker都会去竞选成为新的Controller(即创建新的Controller节点，由ZooKeeper保证只会有一个创建成功)

竞选成功者即为新的Controller

#### 分区多副本同步机制

第一条消息的offset为0，最后一条消息offset为8，offset为9的消息用虚线框表示，代表下一条待写入的消息。日志文件的HW为6，表示消费者只能拉取到offset在0至5之间的消息，offset为6的消息对消费者是不可见的，LEO标识当前日志文件中下一条待写入消息的offset，LEO大小相当于当前日志分区中最后一条消息的offset值加1。分区ISR集合中的每个副本都会维护自己的LEO，而ISR集合中最小的LEO即为分区的HW，对消费者而言，只能消费HW之前的消息。

![kafka架构 (4)](https://tc.ctq6.cn/tc/kafka%E6%9E%B6%E6%9E%84%20(4).jpg)



#### 分区副本同步过程

![](https://tc.ctq6.cn/tc/kafka%E6%9E%B6%E6%9E%84%20(3).jpg)

分区中的ISR集合含有三个副本，即一个leader副本和2个follower副本，此时分区的LEO和HW都为3，消息3和消息4从是生产者发出后被先存入leader副本，在消息写入leader副本后，follower副本会发送拉取请求来拉取消息3和消息4以进行消息同步。

在某一时刻，follower1完全跟上了leader副本而follower2只同步了消息3，如此leader的LEO为5，follower1的LEO为5，follower2的LEO为4，当前分区的HW取最小值为4，此时消费者可以消费到offset为0到3之间的消息。

Kafka 的复制机制既不是完全的同步复制，也不是单纯的异步复制。事实上，同步复制要求所有能工作的 follower 都复制完，这条消息才会被 commit，这种复制方式极大的影响了吞吐率。而异步复制方式下，follower 异步的从 leader 复制数据，数据只要被 leader 写入 log 就被认为已经 commit，这种情况下如果 follower 都还没有复制完，落后于 leader 时，突然 leader 宕机，则会丢失数据。而 Kafka 的这种使用 ISR 的方式则很好的均衡了确保数据不丢失以及吞吐率。

## 消费者

### 分区消费

消费者（Consumer）负责订阅 Kafka 中的主题（Topic），并且从订阅的主题上拉取消息。与其他一些消息中间件不同的是：在 Kafka 的消费理念中还有一层消费组（Consumer Group）的概念，每个消费者都有一个对应的消费组。当消息发布到主题后，只会被投递给订阅它的每个消费组中的一个消费者。

如图 10 所示，某个主题中共有 4 个分区（Partition）：P0、P1、P2、P3。有两个消费组 A 和 B 都订阅了这个主题，消费组 A 中有 4 个消费者（C0、C1、C2 和 C3），消费组 B 中有 2 个消费者（C4 和 C5）。按照 Kafka 默认的规则，最后的分配结果是消费组 A 中的每一个消费者分配到 1 个分区，消费组 B 中的每一个消费者分配到 2 个分区，两个消费组之间互不影响。每个消费者只能消费所分配到的分区中的消息。换言之，每一个分区只能被一个消费组中的一个消费者所消费。

![](https://static001.geekbang.org/infoq/b4/b49bfbda71189136892069bff1406b03.png)

### 消费者消费方式

**消费者采用pull（拉）模式从broker中读取数据。**

为什么不采用push（推，_填鸭式教学_）的模式给消费者数据呢？首先回想下咱们上学学习不就是各种填鸭式教学吗？不管你三七二十一，就是按照教学进度给你灌输知识，能不能接受是你的事，并美其名曰：优胜略汰！

这种push方式在kafka架构里显然是不合理的，比如一个broker有多个消费者，它们的消费速率不同，一昧的push只会给消费者带来拒绝服务以及网络拥塞等风险。而kafka显然不可能去放弃速率低的消费者，因此kafka采用了pull的模式，可以根据消费者的消费能力以适当的速率消费broker里的消息。

当然让消费者去pull数据自然也是有缺点的。同样联想上学的场景，如果把学习主动权全部交给学生，那有些学生想学的东西老师那里没有怎么办？那他不就陷入了一辈子就在那不断求索，然而别的也啥都学的这个死循环的状态了。kafka也是这样，采用pull模式后，如果kafka没有数据，消费者可能会陷入循环中，一直返回空数据。为了解决这个问题，Kafka消费者在消费数据时会传入一个时长参数timeout，如果当前没有数据可供消费，消费者会等待一段时间之后再返回，这段时长即为timeout

### 消费者分区策略

一个consumer group中有多个consumer，一个 topic有多个partition，所以肯定会涉及到partition的分配问题，即确定每个partition由哪个consumer来消费，这就是分区分配策略（Partition Assignment Strategy）

#### 消费者分配分区的前提条件

在这个消费逻辑设定下，假设目前某消费组内只有一个消费者C0，订阅了一个topic，这个topic包含6个分区，也就是说这个消费者C0订阅了6个分区，这时候可能会发生下列三种情况：

1. 如果这时候消费者组内**新增**了一个**消费者**C1，这个时候就需要把之前分配给C0的6个分区拿出来3个分配给C1；
2. 如果这时候这个topic**多了一些分区**，就要按照某种策略，把多出来的分区分配给C0和C1；
3. 如果这时候C1**消费者挂掉了或者退出**了，不在消费者组里了，那所有的分区需要再次分配给C0。

#### **RangeAssignor分区策略**

PartitionAssignor接口用于用户定义实现分区分配算法，以实现Consumer之间的分区分配。消费组的成员订阅它们感兴趣的Topic并将这种订阅关系传递给作为订阅组协调者的Broker。协调者选择其中的一个消费者来执行这个消费组的分区分配并将分配结果转发给消费组内所有的消费者。Kafka默认采用RangeAssignor的分配算法。

RangeAssignor对每个Topic进行独立的分区分配。对于每一个Topic，首先对分区按照分区ID进行排序，然后订阅这个Topic的消费组的消费者再进行排序，之后尽量均衡的将分区分配给消费者。这里只能是尽量均衡，因为分区数可能无法被消费者数量整除，那么有一些消费者就会多分配到一些分区。

![](https://tc.ctq6.cn/tc/471426-20191209102424360-253172662.png)

RangeAssignor策略的原理是按照消费者总数和分区总数进行整除运算来获得一个跨度，然后将分区按照跨度进行平均分配，以保证分区尽可能均匀地分配给所有的消费者。对于每一个Topic，RangeAssignor策略会将消费组内所有订阅这个Topic的消费者按照名称的字典序排序，然后为每个消费者划分固定的分区范围，如果不够平均分配，那么字典序靠前的消费者会被多分配一个分区。

这种分配方式明显的一个问题是随着消费者订阅的Topic的数量的增加，不均衡的问题会越来越严重，比如上图中4个分区3个消费者的场景，C0会多分配一个分区。如果此时再订阅一个分区数为4的Topic，那么C0又会比C1、C2多分配一个分区，这样C0总共就比C1、C2多分配两个分区了，而且随着Topic的增加，这个情况会越来越严重。

分配结果：

```bash
订阅2个Topic，每个Topic4个分区，共3个Consumer
C0：[T0P0，T0P1，T1P0，T1P1]
C1：[T0P2，T1P2]
C2：[T0P3，T1P3]
```

#### **RoundRobinAssignor分区策略**

RoundRobinAssignor的分配策略是将消费组内订阅的所有Topic的分区及所有消费者进行排序后尽量均衡的分配（RangeAssignor是针对单个Topic的分区进行排序分配的）。如果消费组内，消费者订阅的Topic列表是相同的（每个消费者都订阅了相同的Topic），那么分配结果是尽量均衡的（消费者之间分配到的分区数的差值不会超过1）。如果订阅的Topic列表是不同的，那么分配结果是不保证“尽量均衡”的，因为某些消费者不参与一些Topic的分配。

![](https://tc.ctq6.cn/tc/471426-20191209102433794-271086275.png)



相对于RangeAssignor，在订阅多个Topic的情况下，RoundRobinAssignor的方式能消费者之间尽量均衡的分配到分区（分配到的分区数的差值不会超过1——RangeAssignor的分配策略可能随着订阅的Topic越来越多，差值越来越大）。

对于订阅组内消费者订阅Topic不一致的情况：假设有三个消费者分别为C0、C1、C2，有3个Topic T0、T1、T2，分别拥有1、2、3个分区，并且C0订阅T0，C1订阅T0和T1，C2订阅T0、T1、T0，那么RoundRobinAssignor的分配结果如下

![](https://tc.ctq6.cn/tc/471426-20191209102807170-1473124202.png)

#### StickyAssignor分区策略

从字面意义上看，Sticky是“粘性的”，可以理解为分配结果是带“粘性的”——每一次分配变更相对上一次分配做最少的变动（上一次的结果是有粘性的），其目标有两点：

1. **分区的分配尽量的均衡**

2. **每一次重分配的结果尽量与上一次分配结果保持一致**

当这两个目标发生冲突时，优先保证第一个目标。第一个目标是每个分配算法都尽量尝试去完成的，而第二个目标才真正体现出StickyAssignor特性的。

我们先来看预期分配的结构，后续再具体分析StickyAssignor的算法实现。

例如：

- 有3个Consumer：C0、C1、C2
- 有4个Topic：T0、T1、T2、T3，每个Topic有2个分区
- 所有Consumer都订阅了这4个分区

StickyAssignor的分配结果如下图所示（增加RoundRobinAssignor分配作为对比）

![](https://tc.ctq6.cn/tc/471426-20191209102905581-326828874.png)

上面的例子中，Sticky模式原来分配给C0、C2的分区都没有发生变动，且最终C0、C1达到的均衡的目的。

再举一个例子：

- 有3个Consumer：C0、C1、C2
- 3个Topic：T0、T1、T2，它们分别有1、2、3个分区
- C0订阅T0；C1订阅T0、T1；C2订阅T0、T1、T2

分配结果如下图所示：

![](https://tc.ctq6.cn/tc/471426-20191209102918430-511071749.png)

从以上两个例子的分配结果可以看出，StickyAssignor是比RangeAssignor和RoundRobinAssignor更好的分配方式，不过它的实现也更加的复杂。

##### 实现

StickyAssignor的实现代码是RangeAssignor和RoundRobinAssignor的十倍，复杂度则远远在十倍以上。目前基本没有看到对这块源码实现的分析。

StickyAssignor分配算法的核心逻辑如下：

```bash
1. 先构建出当前的分配状态：currentAssignment
	1、如果currentAssignment为空，则是全新的分配
2. 构建出partition2AllPotentialConsumers和consumer2AllPotentialPartitions两个辅助后续分配的数据结构
	1、partition2AllPotentialConsumers是一个Map<TopicPartition, List<String>>，记录着每个Partition可以分配给哪些Consumer
	2、consumer2AllPotentialPartitions是一个Map<String, List<TopicPartition>>，记录着每个Consumer可以分配的Partition列表
3. 补全currentAssignment，将不属于currentAssignment的Consumer添加进去（如果新增了一个Consumer，这个Consumer上一次是没参与分配的，新添加进去分配的Partition列表为空）
	1、如果不是初次分配，并且每个Consumer订阅是相同的：
		1、对Consumer按照它所分配的Partition数进行排序
		2、按照上一步的排序结果，将每个Consumer分配的分区插入到List中（List就是排序后的分区）
		3、将不属于任何Consumer的分区加入List中
	2、否则：分区之间按照可以被分配的Consumer的数量进行排序
4. 构建出currentPartitionConsumer来用于辅助的分配，currentPartitionConsumer记录了当前每个Partition分配给了哪个Consumer——就是把currentAssignment从Consumer作为Key转换到Partition作为Key用于辅助分配
5. 对所有分区进行排序（排序结果为sortedPartitions），排序有两种规则：
6. 构造unassignedPartitions记录所有要被分配的分区（初始为上一步排序过的所有分区，后续进行调整：将已分配的，不需要移除了Partition从unassignedPartitions中移除）
7. 进行分区调整，来达到分区分配均衡的目的；分区的Rebalance包含多个步骤
	1、将上一步未分配的分区（unassignedPartitions）分配出去。分配的策略是：按照当前的分配结果，每一次分配时将分区分配给订阅了对应Topic的Consumer列表中拥有的分区最少的那一个Consumer
	2、校验每一个分区是否需要调整，如果分区不需要调整，则从sortedPartitions中移除。分区是否可以被调整的规则是：如果这个分区是否在partition2AllPotentialConsumers中属于两个或超过两个Consumer。
	3、校验每个Consumer是否需要调整被分配的分区，如果不能调整，则将这个Consumer从sortedCurrentSubscriptions中移除，不参与后续的重分配。判断是否调整的规则是：如果当前Consumer分配的分区数少于它可以被分配的最大分区数，或者它的分区满足上一条规则。
	4、将以上步骤中获取的可以进行重分配的分区，进行重新的分配。每次分配时都进行校验，如果当前已经达到了均衡的状态，则终止调整。均衡状态的判断依据是Consumer之间分配的分区数量的差值不超过1；或者所有Consumer已经拿到了它可以被分配的分区之后仍无法达到均衡的上一个条件（比如c1订阅t1，c2订阅t2，t1 t2分区数相差超过1，此时没法重新调整）。如果不满足上面两个条件，且一个Consumer所分配的分区数少于同一个Topic的其他订阅者分配到的所有分区的情况，那么还可以继续调整，属于不满足均衡的情况——比如上文中RoundRobinAssignor的最后一个例子。
```

## 生产者

#### 生产者分区策略

```java
private int partition(ProducerRecord<K, V> record, byte[] serializedKey, byte[] serializedValue, Cluster cluster) {
   Integer partition = record.partition();
   return partition != null ?partition :partitioner.partition(record.topic(),   record.key(), serializedKey, record.value(), serializedValue, cluster);
}
```

如果 record 指定了分区策略，则指定的分区策略会被使用。如果没有指定分区策略，就使用默认的 DefaultPartitioner 分区策略。我们可以在创建 KafkaProducer 时传入 Partitioner 的实现类来实现自定义分区。

**默认区分策略**

Kafka 的默认分区策略可以分为两种情况：消息 Key 为 null、消息 Key 不为 null。这里说的 key 就是我们将消息丢入 Kafka 时传入的一个参数。

```java
public int partition(String topic, Object key, byte[] keyBytes, Object value, byte[] valueBytes, Cluster cluster) {
    List<PartitionInfo> partitions = cluster.partitionsForTopic(topic);
    int numPartitions = partitions.size();
    if (keyBytes == null) {
        // key 为空的情况
        int nextValue = nextValue(topic);
        List<PartitionInfo> availablePartitions = cluster.availablePartitionsForTopic(topic);
        if (availablePartitions.size() > 0) {
            int part = Utils.toPositive(nextValue) % availablePartitions.size();
            return availablePartitions.get(part).partition();
        } else {
            // no partitions are available, give a non-available partition
            return Utils.toPositive(nextValue) % numPartitions;
        }
    } else {
        // key 不为空的情况
        return Utils.toPositive(Utils.murmur2(keyBytes)) % numPartitions;
    }
}
```

如果 key 为 null，则先根据 topic 名获取上次计算分区时使用的一个整数并加一。

接着判断 topic 的可用分区数是否大于 0，如果大于 0 则使用获取的 nextValue 的值和可用分区数进行取模操作。 如果 topic 的可用分区数小于等于 0，则用获取的 nextValue 的值和总分区数进行取模操作（其实就是随机选择了一个不可用分区）。

```java
int nextValue = nextValue(topic);
List<PartitionInfo> availablePartitions = cluster.availablePartitionsForTopic(topic);
if (availablePartitions.size() > 0) {
    int part = Utils.toPositive(nextValue) % availablePartitions.size();
    return availablePartitions.get(part).partition();
} else {
    // no partitions are available, give a non-available partition
    return Utils.toPositive(nextValue) % numPartitions;
}
```

如果消息 Key 不为 null，就是根据 hash 算法 murmur2 就算出 key 的 hash 值，然后和分区数进行取模运算。

```java
return Utils.toPositive(Utils.murmur2(keyBytes)) % numPartitions;
```

对于 Kafka 生产者来说，如果指定了分区策略类，那么会按照分区策略类执行。如果不手动指定分区选择策略类，则会使用默认的分区策略类（DefaultPartitioner）。

在默认分区策略下，如果不指定消息的 key，则消息发送到的分区是随着时间不停变换的。
如果指定了消息的 key，则会根据消息的 hash 值和 topic 的分区数取模来获取分区的。

如果应用有消息顺序性的需要，则可以通过指定消息的 key 和自定义分区类来将符合某种规则的消息发送到同一个分区。同一个分区消息是有序的，同一个分区只有一个消费者就可以保证消息的顺序性消费。

## 日志存储

### 日志文件布局

![kafka架构 (5)](https://tc.ctq6.cn/tc/kafka%E6%9E%B6%E6%9E%84%20(5).jpg)



如果分区规则设置的合理，那么所有的消息可以均匀的分布到不同的分区中，这样就可以实现水平拓展。

### 日志索引

偏移量索引文件用来建立消息偏移量（offset）到物理地址之间的映射关系，方便快速定位消息所在的物理文件位置；

时间戳索引文件则根据指定的时间戳（timestamp）来查找对应的偏移量信息。

**日志段文件切分条件**

- 当前日志分段文件的大小超过了 broker 端参数 log.segment.bytes 配置的值。log.segment.bytes参数的默认值为1073741824，即1GB
- 当前日志分段中消息的最大时间戳与当前系统的时间戳的差值大于log.roll.ms或log.roll.hours参数配置的值。如果同时配置了log.roll.ms和log.roll.hours参数，那么log.roll.ms的优先级高。默认情况下，只配置了log.roll.hours参数，其值为168，即7天
- 偏移量索引文件或时间戳索引文件的大小达到broker端参数log.index.size.max.bytes配置的值。log.index.size.max.bytes的默认值为10485760，即10MB
- 追加的消息的偏移量与当前日志分段的偏移量之间的差值大于Integer.MAX_VALUE，即要追加的消息的偏移量不能转变为相对偏移量（offset-baseOffset＞Integer.MAX_VALUE）

#### 偏移量索引

## Kafka 高性能

### 顺序写mmap

因为硬盘是机械结构，每次读写都会**寻址**，**写入**，其中寻址是一个“机械动作”，它是最耗时的。

所以随机I/O会让硬盘重复机械动作比较耗时，顺序I/O的寻址速度就比较快了。

为了提高读写硬盘的速度，Kafka就是使用**顺序I/O**。每条消息都被append到该Partition中，属于**顺序写磁盘**，因此效率非常高

#### 零拷贝

Kafka服务器在响应客户端读取数据的时候，底层使用的是**ZeroCopy**技术，也就是数据只在内核空间传输，数据不会到达用户空间。

常规的I/O操作：

![IO操作](https://tc.ctq6.cn/tc/IO%E6%93%8D%E4%BD%9C.jpg)

1. 文件在磁盘中的数据被拷贝到内核缓冲区
2. 从内核缓冲区拷贝到用户缓冲区
3. 用户缓冲区拷贝到内核与Socket相关的缓冲区
4. 数据从Socket缓冲区拷贝到相关协议引擎发送出去

Kafka实现零拷贝是这样的：

![kafkaIO操作](https://tc.ctq6.cn/tc/kafkaIO%E6%93%8D%E4%BD%9C.jpg)

1. 文件在磁盘中的数据被拷贝到内核缓冲区
2. 从内核缓冲区拷贝到与Socket相关的缓冲区
3. 数据从Socket缓冲区拷贝到相关协议引擎发送出去

## Kafka 高可用搭建

### 系统环境准备

### Zookeeper集群部署

### Kafka进群部署









