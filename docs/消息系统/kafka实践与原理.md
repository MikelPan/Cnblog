### kafka架构

#### Kafka体系架构

- 若干Producer
- 若干Broker
- 若干Consumer
- 一个Zookeeper集群

其中Zookeeper是Kafka用来负责元数据的管理、控制器的选举。Producer将消息发送到Broker，Broker负责将消息存储到磁盘中，而Consumer负责从Broker订阅并消费消息。

![kafka架构](/Users/admin/Downloads/kafka架构.jpg)

（1）Producer：生产者负责创建消息，将其投递到Kafka中。

（2）Customer：消费者连接到Kafak上并接收消息，进而进行相应的业务逻辑处理

（3）Broker：服务代理节点，独立的Kafak服务节点或实例

（4）Topic：Kafka中的消息以主题为单位进行归类，生产者将消息发送到特定的主题，消费者负责订阅并进行消费

（5）Partition：一个分区属于单个主题，分区在存储层面是一个可以追加的日志（Log）文件，消息被追加到分区的日志文件的时候会分配一个特定的偏移量（offset）。offset是消息在分区中的唯一标识，offset不跨越分区，kafka保证分区有序。每一条消息被发送到broker之前，根据分区规则存储，一个主题可以跨分区，这样就解决了横向拓展问题，不会受到单台机器I/O限制。

   (6)  Zookeeper 集群:（负责管理 broker 组成的 Kafka 集群管理、选举 leader，rebalance 等操作）

#### 多分区副本机制

分区中的多副本机制：增加副本可以提高容灾能力，同一分区中不同副本中保存相同的消息（同一时刻副本之间并非完全相同），副本是一主多从的关系，leader副本负责处理读写请求，follovwer负责与leader副本同步消息。副本处于不同的broker中，当leader出现故障，从follower中重新选主副本对外提供服务。



![kafka架构 (1)](/Users/admin/Downloads/kafka架构 (2).jpg)



Kafka集群中有4个broker，其中一个主题中分区3个，副本3个，每个分区中有1个leader和2个follower，生产者和消费者只与leader交互，follower副本只负责消息同步。

Customer使用拉（Pull）模式从服务端拉取消息，并且保存消费的具体位置，当消费者宕机后恢复上线可以根据之前保存的消费位置重新拉取需要的消息进行消费。

#### 分区多副本管理机制

分区中所有副本统称为AR，所有与leader副本保持一定同步的副本包括leader副本组成ISR，ISR是AR集合的一个子集，消息先发送给leader副本，然后follower副本从leader副本中同步消息。与leader副本同步滞后过多的副本不包括leader副本组成OSR

leader副本负责维护和跟踪ISR集合中所有的follower副本滞后状态，当follower副本落后太多或失效时，leader副本会把它从ISR集合中剔除。如果OSR副本追上了leader副本，那么leader副本将把它从OSR集合中转移到ISR集合。默认情况下，当leader副本发生故障时，只有在ISR集合中的副本才有资格被选择为新的leader。

![](https://static001.geekbang.org/infoq/71/7151047ee2d674082674106f4033db0a.png)

#### 分区多副本同步机制

第一条消息的offset为0，最后一条消息offset为8，offset为9的消息用虚线框表示，代表下一条待写入的消息。日志文件的HW为6，表示消费者只能拉取到offset在0至5之间的消息，offset为6的消息对消费者是不可见的，LEO标识当前日志文件中下一条待写入消息的offset，LEO大小相当于当前日志分区中最后一条消息的offset值加1。分区ISR集合中的每个副本都会维护自己的LEO，而ISR集合中最小的LEO即为分区的HW，对消费者而言，只能消费HW之前的消息。

![kafka架构 (4)](/Users/admin/Downloads/kafka架构 (4).jpg)



#### 分区副本同步过程

![](/Users/admin/Downloads/kafka架构 (3).jpg)

分区中的ISR集合含有三个副本，即一个leader副本和2个follower副本，此时分区的LEO和HW都为3，消息3和消息4从是生产者发出后被先存入leader副本，在消息写入leader副本后，follower副本会发送拉取请求来拉取消息3和消息4以进行消息同步。

在某一时刻，follower1完全跟上了leader副本而follower2只同步了消息3，如此leader的LEO为5，follower1的LEO为5，follower2的LEO为4，当前分区的HW取最小值为4，此时消费者可以消费到offset为0到3之间的消息。

Kafka 的复制机制既不是完全的同步复制，也不是单纯的异步复制。事实上，同步复制要求所有能工作的 follower 都复制完，这条消息才会被 commit，这种复制方式极大的影响了吞吐率。而异步复制方式下，follower 异步的从 leader 复制数据，数据只要被 leader 写入 log 就被认为已经 commit，这种情况下如果 follower 都还没有复制完，落后于 leader 时，突然 leader 宕机，则会丢失数据。而 Kafka 的这种使用 ISR 的方式则很好的均衡了确保数据不丢失以及吞吐率。

#### 分区消费

消费者（Consumer）负责订阅 Kafka 中的主题（Topic），并且从订阅的主题上拉取消息。与其他一些消息中间件不同的是：在 Kafka 的消费理念中还有一层消费组（Consumer Group）的概念，每个消费者都有一个对应的消费组。当消息发布到主题后，只会被投递给订阅它的每个消费组中的一个消费者。

如图 10 所示，某个主题中共有 4 个分区（Partition）：P0、P1、P2、P3。有两个消费组 A 和 B 都订阅了这个主题，消费组 A 中有 4 个消费者（C0、C1、C2 和 C3），消费组 B 中有 2 个消费者（C4 和 C5）。按照 Kafka 默认的规则，最后的分配结果是消费组 A 中的每一个消费者分配到 1 个分区，消费组 B 中的每一个消费者分配到 2 个分区，两个消费组之间互不影响。每个消费者只能消费所分配到的分区中的消息。换言之，每一个分区只能被一个消费组中的一个消费者所消费。

![](https://static001.geekbang.org/infoq/b4/b49bfbda71189136892069bff1406b03.png)

### 日志存储

#### 日志文件布局

![kafka架构 (5)](/Users/admin/Downloads/kafka架构 (5).jpg)



如果分区规则设置的合理，那么所有的消息可以均匀的分布到不同的分区中，这样就可以实现水平拓展。

