## Canal Admin 架构

- **Instance**：对应 Canal Server 里的 Instance，一个最小的订阅 MySQL 的队列。
- **Server**：对应 Canal Server，一个 Server 里可以包含多个 Instance，Canal Server 负责订阅 MySQL 的 binlog 数据，可以将数据输出到消息队列或者为 Canal Adapter 提供消息消费。原本 Canal Server 运行所需要的 canal.properties 和 instance.properties 配置文件可以在 Canal Admin WebUI 上进行统一运维，每个  Canal Server 只需要以最基本的配置启动。 (例如 Canal Admin 的地址，以及访问配置的账号、密码即可)
- **集群**：对应一组 Canal Server，通过 Zookeeper 协调主备实现 Canal Server HA 的高可用。

![Canal Admin 高可用集群使用教程](https://static001.geekbang.org/infoq/5c/5ce071f6ae33a4ec139bbf8403fa5b01.png)

## 机器规划

### 准备工作

1、mysql创建同步账号

```bash
# 创建同步账号
CREATE USER canal IDENTIFIED BY 'canal';
GRANT SELECT, REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'canal'@'%';
FLUSH PRIVILEGES;
```

2、mysql开启binlog

```bash
[mysqld]
...
log_bin           = binlog 目录
binlog_format     = row
```

3、部署zookeeper集群

Canal Server 和 Canal Adapter 依赖 Zookeeper 实现 HA 高可用。

### 部署zookeeper集群

#### 集群角色

Zookeeper 集群模式一共有三种类型的角色：

- **Leader**: 处理所有的事务请求(写请求)，可以处理读请求，集群中只能有一个Leader。
- **Follower**:只能处理读请求，同时作为Leader的候选节点，即如果Leader宕机，Follower节点要参与到新的Leader选举中，有可能成为新的Leader节点。
- **Observer**:只能处理读请求。不能参与选举。

#### 环境说明

本例搭建的是伪集群模式，即一台机器上启动四个zookeeper实例组成集群，真正的集群模式无非就是实例IP地址不同，搭建方法没有区别。

![](https://mmbiz.qpic.cn/mmbiz_png/vvsibFWkwqHrHqRwoIjtG2G0wXRw1bC9Ux4s8YJrBobP50SjUHZ7Micc0GYQLaDZhMlZqfDY4kNoibZg0zp29k7Cg/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

其中1个leader,2个follower,1个observer。

#### 配置Java环境

```bash
[root@localhost ~]# java -version
java version "1.8.0_251"
Java(TM) SE Runtime Environment (build 1.8.0_251-b08)
Java HotSpot(TM) 64-Bit Server VM (build 25.251-b08, mixed mode)
```

#### 下载zookeeper安装包

下载链接： https://zookeeper.apache.org/releases.html

测试版本为：https://dlcdn.apache.org/zookeeper/zookeeper-3.7.0/apache-zookeeper-3.7.0-bin.tar.gz

```bash
tar -xzvf apache-zookeeper-3.7.0-bin.tar.gz -C /usr/local/zookeeper
```

#### 创建数据目录

```bash
mkdir -p /usr/local/zookeeper-cluster/zk1
mkdir -p /usr/local/zookeeper-cluster/zk2
mkdir -p /usr/local/zookeeper-cluster/zk3
mkdir -p /usr/local/zookeeper-cluster/zk4
```

#### 编辑配置文件

这里只列出zk1的配置文件，其余3个配置文件只需要修改dataDir和clientPort即可。

```bash
tickTime=2000 
initLimit=10
syncLimit=5
dataDir=/usr/local/zookeeper-cluster/zk1  #根据实例修改zk1,zk2,zk3,zk4
clientPort=2181 #根据实例修改2181,2182,2183,2184
server.1=127.0.0.1:2001:3001:participant
server.2=127.0.0.1:2002:3002:participant
server.3=127.0.0.1:2003:3003:participant
server.4=127.0.0.1:2004:3004:observer
```

配置说明：

- **tickTime**:用于配置Zookeeper中最小时间单位的长度，单位是毫秒，很多运行时的时间间隔都是使用tickTime的倍数来表示的。

- **initLimit**:该参数用于配置Leader服务器等待Follower启动，并完成数据同步的时间。Follower服务器在启动过程中，会与Leader建立连接并完成数据的同步，从而确定自己对外提供服务的起始状态。Leader服务器允许Follower在initLimit时间内完成这个工作。

- **syncLimit**:Leader与Follower心跳检测的最大延时时间。

- **dataDir**:顾名思义就是 Zookeeper保存数据的目录，默认情况下，Zookeeper 将写数据的日志文件也保存在这个目录里。

- **clientPort**:这个端口就是客户端连接Zookeeper服务器的端口，Zookeeper会监听这个端口，接受客户端的访问请求。

- **server.A=B:C:D:E**:

- - A 是一个数字，表示这个是第几号服务器;
  - B 是这个服务器的ip地址;
  - C 表示的是这个服务器与集群中的 Leader 服务器交换信息的端口;
  - D 表示的是万一集群中的 Leader 服务器挂了，需要一个端口来重新进行选举，选出一个新 的 Leader，而这个端口就是用来执行选举时服务器相互通信的端口。如果是伪集群的配置方式，由于B都是一样，所以不同的 Zookeeper 实例通信端口号不能一样，所以要给 它们分配不同的端口号。
  - E 如果需要通过添加不参与集群选举Observer节点，可以在E的位置，添加observer标识。

#### 标识Server Id

在前面指定的dataDir目录下，根据不同的实例添加名为myid的文件，内容为实例ID

```bash
echo 1 > /usr/local/zookeeper-cluster/zk1/myid
echo 2 > /usr/lcoal/zookeeper-cluster/zk2/myid
echo 3 > /usr/local/zookeeper-cluster/zk3/myid
echo 4 > /usr/local/zookeeper-cluster/zk4/myid
```

#### 查看目录结构

```bash
[root@lcoalhost zookeeper-cluster]# tree /usr/local/zookeeper-cluster
.
├── zk1
│   ├── myid
│   └── zoo.cfg
├── zk2
│   ├── myid
│   └── zoo.cfg
├── zk3
│   ├── myid
│   └── zoo.cfg
└── zk4
    ├── myid
    └── zoo.cfg

4 directories, 8 files
```

#### 启动4个zookeeper实例

启动之前可以先将zookeeper脚本的目录添加到PATH路径，目的是可以在任意目录下运行zookeeper脚本。编辑/etc/profile，添加如下内容

```bash
export ZK_HOME=/usr/local/apache-zookeeper-3.5.8-bin/bin
export PATH=$PATH:$ZK_HOME
```

编辑完成后source /etc/profile使其生效

```bash
zkServer.sh start /usr/local/zookeeper-cluster/zk1/zoo.cfg 
zkServer.sh start /usr/local/zookeeper-cluster/zk2/zoo.cfg 
zkServer.sh start /usr/lcoal/zookeeper-cluster/zk3/zoo.cfg 
zkServer.sh start /usr/local/zookeeper-cluster/zk4/zoo.cfg 
```

####  查看集群角色

```bash
[root@localhost zookeeper-cluster]# zkServer.sh status zk1/zoo.cfg
/usr/bin/java
ZooKeeper JMX enabled by default
Using config: zk1/zoo.cfg
Client port found: 2181. Client address: localhost.
Mode: follower
[root@localhost zookeeper-cluster]# zkServer.sh status zk2/zoo.cfg
/usr/bin/java
ZooKeeper JMX enabled by default
Using config: zk2/zoo.cfg
Client port found: 2182. Client address: localhost.
Mode: leader
[root@localhost zookeeper-cluster]# zkServer.sh status zk3/zoo.cfg
/usr/bin/java
ZooKeeper JMX enabled by default
Using config: zk3/zoo.cfg
Client port found: 2183. Client address: localhost.
Mode: follower
[root@localhost zookeeper-cluster]# zkServer.sh status zk4/zoo.cfg
/usr/bin/java
ZooKeeper JMX enabled by default
Using config: zk4/zoo.cfg
Client port found: 2184. Client address: localhost.
Mode: observer
[root@localhost zookeeper-cluster]# ls
```

#### 连接集群

```bash
zkCli.sh  -server 127.0.0.1:2181

#可以通过 查看/zookeeper/config 节点数据来查看集群配置
[zk: 127.0.0.1:2181(CONNECTED) 1] get /zookeeper/config
server.1=127.0.0.1:2001:3001:participant
server.2=127.0.0.1:2002:3002:participant
server.3=127.0.0.1:2003:3003:participant
server.4=127.0.0.1:2004:3004:observer
version=0
```

## 部署 Canal Admin

### 下载解压包

```bash
wget https://github.com/alibaba/canal/releases/download/canal-1.1.5/canal.admin-1.1.5.tar.gz -P /usr/local/src
mkdir -pv /usr/local/cacal-admin
tar -xzvf /usr/local/src/canal.admin-1.1.5.tar.gz -C /usr/local/canal-admin
```

### 初始化Canal Admin元数据库

初始化 SQL 脚本里会默认创建名为 canal_manager 的数据库，canal_manager.sql 脚本存放在解压后的 conf 目录下

```bash
#登录 MySQL
mysql -hlocalhost:3306 -uroot -p123456
#初始化元数据库
source /usr/local/canal-admin/conf/canal_manager.sql
```

### Canal Admin 配置文件

修改配置文件 vim /usr/local/canal-admin/conf/application.yml：

```bash
#Canal Admin Web 界面端口
server:
  port: 8089
spring:
  jackson:
    date-format: yyyy-MM-dd HH:mm:ss
    time-zone: GMT+8

#元数据库连接信息
spring.datasource:
  address: localhost:3306
  database: canal_manager
  username: root
  password: 123456
  driver-class-name: com.mysql.jdbc.Driver
  url: jdbc:mysql://${spring.datasource.address}/${spring.datasource.database}?useUnicode=true&characterEncoding=UTF-8&useSSL=false
  hikari:
    maximum-pool-size: 30
    minimum-idle: 1

#Canal Server 加入 Canal Admin 使用的密码
canal:
  adminUser: admin
  adminPasswd: admin
```

### 启动Canal Admin

```bash
sh /usr/local/canal-admin/bin/startup.sh
```

## 添加 Canal Server 节点

### 下载并解压压缩包

```bash
wget https://github.com/alibaba/canal/releases/download/canal-1.1.5/canal.deployer-1.1.5.tar.gz -P /usr/local/src
mkdir -p /usr/local/canal-server
tar -xzvf /usr/local/src/canal.deployer-1.1.5.tar.gz -C /usr/local/canal-server
```

### Canal Server 配置文件

因为这里使用 Canal Admin 部署集群，所以 Canal Server 节点只需要配置 Canal Admin 的连接信息即可，真正的配置文件统一通过 Canal Admin 界面来管理。编辑  vim /usr/local/canal-server/conf/canal_local.properties 文件：

```bash
#Canal Server 地址
canal.register.ip = 11.8.36.104

#Canal Admin 连接信息
canal.admin.manager = 11.8.36.104:8089
canal.admin.port = 11110
canal.admin.user = admin
#mysql5 类型 MD5 加密结果 -- admin
canal.admin.passwd = 4ACFE3202A5FF5CF467898FC58AAB1D615029441

#自动注册
canal.admin.register.auto = true
#集群名
canal.admin.register.cluster = canal-cluster-1
#Canal Server 名字
canal.admin.register.name = canal-server-1
```

另一台 Canal Server 也是一样的方式配置，修改 `canal.register.ip = 11.8.36.105` 和 `canal.admin.register.name = canal-server-2 `即可。

## Canal Admin 创建集群

进入 Canal Admin 集群管理页面，点击新建集群，添加集群名称和 Zookeeper 地址

载入集群配置模板。

载入配置后先不用修改配置，点击保存。

注意载入集群配置必须在 Canal Server 添加进集群之前做，否则 Canal Server 会无法加入集群，有以下报错：

#### 启动Canal Server

local 参数表示使用 canal_local.properties 配置启动 Canal Server。

```bash
sh /usr/local/canal-server/bin/startup.sh local
```

在 Canal Admin 上查看注册的 Canal Server。

 ## MySQL 同步 MySQL

### Canal Properties 配置

在集群管理界面选择相应的集群，选择操作，点击主配置对 canal.properties 进行配置。

MySQL 同步数据到 MySQL 比较麻烦，需要先将源 MySQL 的数据同步到 Canal Server 中内置的消息队列中（或者外部 Kafka,RabbitMQ 等消息队列），然后通过 Canal Adapter 去消费消息队列中的消息再写入目标 MySQL。

集群模式下，虽然有多个 Canal Server，但是只有一个是处于 running 状态，客户端连接的时候会查询 Zookeeper 节点获取并连接处于 running 状态的 Canal Server。

```bash
#Zookeeper 地址
canal.zkServers = 127.0.0.1:2181,127.0.0.1:3181,127.0.0.1:4181
#tcp, kafka, rocketMQ, rabbitMQ
canal.serverMode = tcp
# 此配置需要修改成 default-instance
canal.instance.global.spring.xml = classpath:spring/default-instance.xml

#TSDB 设置
canal.instance.tsdb.enable = true
canal.instance.tsdb.url = jdbc:mysql://11.8.36.104:3306/canal_tsdb
canal.instance.tsdb.dbUsername = root
canal.instance.tsdb.dbPassword = 123456
#使用外部 MySQL 存储表结构变更信息
canal.instance.tsdb.spring.xml = classpath:spring/tsdb/mysql-tsdb.xml
```

Canal Server 默认情况下把源库对表结构修改的记录存储在本地 H2 数据库中，当 Canal Server 主备切换后会导致新的 Canal Server 无法正常同步数据，因此修改 TSDB 的设置将外部 MySQL 数据库作为 Canal Server 存储表结构变更信息的库

```bash
create database canal_tsdb;
```



