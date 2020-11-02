## mongo使用详解

### mongodb账户权限管理

```bash
# 创建角色
db.createUser({
  user : 'admin',
  pwd : 'xxxxx',
  roles : [
    'clusterAdmin',
    'dbAdminAnyDatabase',
    'userAdminAnyDatabase',
    'readWriteAnyDatabase'
  ]
})
# 创建数据库
use DATABASE_NAME
# 插入数据
db.runoob.insert({"name":"你家人来找你了"})
# 删除数据
use runoob
db.dropDatabase()
# 删除集合
db.createCollection("runoob") 
show tables 
db.collection.drop()
db.runoob.drop()
show tables
# 创建固定集合
db.createCollection("mycol", { capped : true, autoIndexId : true, size : 
   6142800, max : 10000 } )
```
### mongosh 使用

```bash
# 下载
wget https://downloads.mongodb.com/compass/mongosh-0.1.0-linux.tgz
# 连接
主节点: mongo mongodb://mongodb0.example.com.local:27017
从节点: mongo mongodb://mongodb1.example.com.local:27017
副本集: mongo "mongodb://mongodb0.example.com.local:27017,mongodb1.example.com.local:27017,mongodb2.xample.com.local:27017/?replicaSet=replA"
```

### mongo分布式集群

MongoDB 有三种集群部署模式，分别为主从复制（Master-Slaver）、副本集（Replica Set）和分片（Sharding）模式。
- Master-Slaver 是一种主从副本的模式，目前已经不推荐使用。
- Replica Set 模式取代了 Master-Slaver 模式，是一种互为主从的关系。Replica Set 将数据复制多份保存，不同服务器保存同一份数据，在出现故障时自动切换，实现故障转移，在实际生产中非常实用。
- Sharding 模式适合处理大量数据，它将数据分开存储，不同服务器保存不同的数据，所有服务器数据的总和即为整个数据集


<font color=#A52A2A>Sharding 模式追求的是高性能，而且是三种集群中最复杂的。在实际生产环境中，通常将 Replica Set 和 Sharding 两种技术结合使用。</font>

#### 主从复制

主从复制是 MongoDB 中最简单的数据库同步备份的集群技术，其基本的设置方式是建立一个主节点（Primary）和一个或多个从节点（Secondary）。

这种方式比单节点的可用性好很多，可用于备份、故障恢复、读扩展等。集群中的主从节点均运行 MongoDB 实例，完成数据的存储、查询与修改操作。

主从复制模式的集群中只能有一个主节点，主节点提供所有的增、删、查、改服务，从节点不提供任何服务，但是可以通过设置使从节点提供查询服务，这样可以减少主节点的压力。

另外，每个从节点要知道主节点的地址，主节点记录在其上的所有操作，从节点定期轮询主节点获取这些操作，然后对自己的数据副本执行这些操作，从而保证从节点的数据与主节点一致。

在主从复制的集群中，当主节点出现故障时，只能人工介入，指定新的主节点，从节点不会自动升级为主节点。同时，在这段时间内，该集群架构只能处于只读状态。

#### 副本集

此集群拥有一个主节点和多个从节点，这一点与主从复制模式类似，且主从节点所负责的工作也类似，但是副本集与主从复制的区别在于：当集群中主节点发生故障时，副本集可以自动投票，选举出新的主节点，并引导其余的从节点连接新的主节点，而且这个过程对应用是透明的。

MongoDB 副本集使用的是 N 个 mongod 节点构建的具备自动容错功能、自动恢复功能的高可用方案。在副本集中，任何节点都可作为主节点，但为了维持数据一致性，只能有一个主节点。

主节点负责数据的写入和更新，并在更新数据的同时，将操作信息写入名为 oplog 的日志文件当中。主节点还负责指定其他节点为从节点，并设置从节点数据的可读性，从而让从节点来分担集群读取数据的压力。

另外，从节点会定时轮询读取 oplog 日志，根据日志内容同步更新自身的数据，保持与主节点一致。

在一些场景中，用户还可以使用副本集来扩展读性能，客户端有能力发送读写操作给不同的服务器，也可以在不同的数据中心获取不同的副本来扩展分布式应用的能力。

在副本集中还有一个额外的仲裁节点（不需要使用专用的硬件设备），负责在主节点发生故障时，参与选举新节点作为主节点。

副本集中的各节点会通过心跳信息来检测各自的健康状况，当主节点出现故障时，多个从节点会触发一次新的选举操作，并选举其中一个作为新的主节点。为了保证选举票数不同，副本集的节点数保持为奇数。

#### 分片

副本集可以解决主节点发生故障导致数据丢失或不可用的问题，但遇到需要存储海量数据的情况时，副本集机制就束手无策了。副本集中的一台机器可能不足以存储数据，或者说集群不足以提供可接受的读写吞吐量。这就需要用到 MongoDB 的分片（Sharding）技术，这也是 MongoDB 的另外一种集群部署模式。

分片是指将数据拆分并分散存放在不同机器上的过程。有时也用分区来表示这个概念。将数据分散到不同的机器上，不需要功能强大的大型计算机就可以存储更多的数据，处理更大的负载。

MongoDB 支持自动分片，可以使数据库架构对应用程序不可见，简化系统管理。对应用程序而言，就如同始终在使用一个单机的 MongoDB 服务器一样。

MongoDB 的分片机制允许创建一个包含许多台机器的集群，将数据子集分散在集群中，每个分片维护着一个数据集合的子集。与副本集相比，使用集群架构可以使应用程序具有更强大的数据处理能力。

构建一个 MongoDB 的分片集群，需要三个重要的组件，分别是分片服务器（Shard Server）、配置服务器（Config Server）和路由服务器（Route Server）。

Shard Server
>每个 Shard Server 都是一个 mongod 数据库实例，用于存储实际的数据块。整个数据库集合分成多个块存储在不同的 Shard Server 中。*

在实际生产中，一个 Shard Server 可由几台机器组成一个副本集来承担，防止因主节点单点故障导致整个系统崩溃。

Config Server
>这是独立的一个 mongod 进程，保存集群和分片的元数据，在集群启动最开始时建立，保存各个分片包含数据的信息。

Route Server
>这是独立的一个 mongos 进程，Route Server 在集群中可作为路由使用，客户端由此接入，让整个集群看起来像是一个单一的数据库，提供客户端应用程序和分片集群之间的接口。

Route Server 本身不保存数据，启动时从 Config Server 加载集群信息到缓存中，并将客户端的请求路由给每个 Shard Server，在各 Shard Server 返回结果后进行聚合并返回客户端。

#### mongo 副本集搭建

##### MongoDB主备+仲裁的基本结构如下

![](https://images2017.cnblogs.com/blog/907596/201711/907596-20171122210337196-303523786.png)

主节点（Primary）
>在复制集中，主节点是唯一能够接收写请求的节点。MongoDB在主节点进行写操作，并将这些操作记录到主节点的oplog中。而从节点将会从oplog复制到其本机，并将这些操作应用到自己的数据集上。（复制集最多只能拥有一个主节点）

从节点（Secondaries）
>从节点通过应用主节点传来的数据变动操作来保持其数据集与主节点一致。从节点也可以通过增加额外参数配置来对应特殊需求。例如，从节点可以是non-voting或是priority 0.

仲裁节点（ARBITER）
>仲裁节点即投票节点，其本身并不包含数据集，且也无法晋升为主节点。但是，旦当前的主节点不可用时，投票节点就会参与到新的主节点选举的投票中。仲裁节点使用最小的资源并且不要求硬件设备。投票节点的存在使得复制集可以以偶数个节点存在，而无需为复制集再新增节点 不要将投票节点运行在复制集的主节点或从节点机器上。 投票节点与其他 复制集节点的交流仅有：选举过程中的投票，心跳检测和配置数据。这些交互都是不加密的。

心跳检测
>复制集成员每两秒向复制集中其他成员进行心跳检测。如果某个节点在10秒内没有返回，那么它将被标记为不可用。

MongoDB副本集是有故障恢复功能的主从集群，由一个primary节点和一个或多个secondary节点组成：
>节点同步过程： Primary节点写入数据，Secondary通过读取Primary的oplog得到复制信息，开始复制数据并且将复制信息写入到自己的oplog。如果某个操作失败，则备份节点停止从当前数据源复制数据。如果某个备份节点由于某些原因挂掉了，当重新启动后，就会自动从oplog的最后一个操作开始同步，同步完成后，将信息写入自己的oplog，由于复制操作是先复制数据，复制完成后再写入oplog，有可能相同的操作会同步两份，不过MongoDB在设计之初就考虑到这个问题，将oplog的同一个操作执行多次，与执行一次的效果是一样的。

通俗理解：当Primary节点完成数据操作后，Secondary会做出一系列的动作保证数据的同步：
- 检查自己local库的oplog.rs集合，找出最近的时间戳。
- 检查Primary节点local库oplog.rs集合，找出大于此时间戳的记录。
- 将找到的记录插入到自己的oplog.rs集合中，并执行这些操作。

副本集的同步和主从同步一样，都是异步同步的过程，不同的是副本集有个自动故障转移的功能。其原理是：slave端从primary端获取日志，然后在自己身上完全顺序的执行日志所记录的各种操作（该日志是不记录查询操作的），这个日志就是local数据 库中的oplog.rs表，默认在64位机器上这个表是比较大的，占磁盘大小的5%，oplog.rs的大小可以在启动参数中设 定：–oplogSize 1000,单位是M。

##### 部署过程如下

```bash
# 制作dockerfile 生产机器
cat > Dockerfile <<- 'EOF'
FROM centos:7
RUN yum install wget vim net-tools htop -y \
    && cp -r /etc/yum.repos.d /etc/yum.repos.d.bak \
    && rm -f /etc/yum.repos.d/*.repo \
    && wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo \
    && wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo \
    && yum clean all && yum makecache \
    && yum install -y openssh-server \
    && mkdir /var/run/sshd \
    && echo 'root:123456' |chpasswd \
    && sed -ri 's/^#?PermitRootLogin\s+.*/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && mkdir /root/.ssh \
    && ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key
EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
EOF
docker build -t mongo_vm:v1 -f Dockerfile .
# 创建机器
for i in `seq 1 3`;do docker run --rm -itd --name mongo_vm_$i mongo_vm:v1;done
# 查询ip地址
for i in `seq 1 3`;do docker inspect mongo_vm_v1_$i -f {{.NetworkSettings.Networks.bridge.IPAddress}}
# 服务器信息
mongo01  172.17.0.3   Primary
mongo02  172.17.0.4   Secondary
mongo03  172.17.0.5   Secondary
# 配置host解析
cat >> /etc/hosts <<- 'EOF'
# mongo
172.17.0.3 mongo01
172.17.0.4 mongo02
172.17.0.5 mongo03
EOF
# 配置ssh-key
for i in `seq 3 5`;do ssh-copy-id root@172.17.0.$i;done
# 安装ansible
yum install -y ansible
cat >> /etc/ansible/hosts <<- 'EOF'
[mongo]
172.17.0.3
172.17.0.4
172.17.0.5
EOF
# 编写ansible批量安装脚本
cat > deploy.yml <<- 'EOF'
---
- hosts: mongo
  remote_user: root
  gather_facts: false
  tasks:
    - name: download mongo
      shell: wget https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-4.0.4.tgz -P /usr/local/src
    
    - name: 
      unarchive:
        src: /usr/local/src/mongodb-linux-x86_64-4.0.4.tgz
        dest: /usr/local/src
        mode: 0755
        copy: no
EOF
```

