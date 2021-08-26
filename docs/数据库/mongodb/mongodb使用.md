## mongo使用详解

### mongodb适用场景
MongoDB (名称来自"humongous") 是一个可扩展的高性能，开源，模式自由，面向文档的数据库。

MongoDB的主要目标是在键/值存储方式（提供了高性能和高度伸缩性）以及传统的RDBMS系统（丰富的功能）架起一座桥梁，集两者的优势于一身。

#### 适用场景
网站数据：适合实时的插入，更新与查询，并具备网站实时数据存储所需的复制及高度伸缩性。
缓存：由于性能很高，也适合作为信息基础设施的缓存层。在系统重启之后，搭建的持久化缓存可以避免下层的数据源过载。
大尺寸、低价值的数据：使用传统的关系数据库存储一些数据时可能会比较贵，在此之前，很多程序员往往会选择传统的文件进行存储。
高伸缩性的场景：非常适合由数十或者数百台服务器组成的数据库。
用于对象及JSON数据的存储：MongoDB的BSON数据格式非常适合文档格式化的存储及查询。

#### 应用案例
京东,中国著名电商,使用MongoDB存储商品信息,支持比价和关注功能.

赶集网,中国著名分类信息网站,使用MongoDB记录pv浏览计数

奇虎360,著名病毒软件防护和移动应用平台,使用MongoBD支撑的HULK平台每天接受200亿次的查询.

百度云,使用MongoDB管理百度云盘中500亿条关于文件源信息的记录.

CERN，著名的粒子物理研究所，欧洲核子研究中心大型强子对撞机的数据使用MongoDB

纽约时报，领先的在线新闻门户网站之一，使用MongoDB

sourceforge.net，资源网站查找，创建和发布开源软件免费，使用MongoDB的后端存储

#### 不适合的场景
高度事物性的系统：例如银行或会计系统。传统的关系型数据库目前还是更适用于需要大量原子性复杂事务的应用程序。
传统的商业智能应用：针对特定问题的BI数据库会对产生高度优化的查询方式。对于此类应用，数据仓库可能是更合适的选择。
需要SQL的问题

### mongodb账户权限管理

**系统默认角色**
```bash
Read：允许用户读取指定数据库
readWrite：允许用户读写指定数据库
dbAdmin：允许用户在指定数据库中执行管理函数，如索引创建、删除，查看统计或访问system.profile
userAdmin：允许用户向system.users集合写入，可以找指定数据库里创建、删除和管理用户
clusterAdmin：只在admin数据库中可用，赋予用户所有分片和复制集相关函数的管理权限。
readAnyDatabase：只在admin数据库中可用，赋予用户所有数据库的读权限
readWriteAnyDatabase：只在admin数据库中可用，赋予用户所有数据库的读写权限
userAdminAnyDatabase：只在admin数据库中可用，赋予用户所有数据库的userAdmin权限
dbAdminAnyDatabase：只在admin数据库中可用，赋予用户所有数据库的dbAdmin权限。
root：只在admin数据库中可用。超级账号，超级权限
```

```bash
# 创建管理员角色
db.createUser({
  user : 'testadm',
  pwd : 'cLAE7MbgAsW0w13FmqSXaUbm',
  roles : [
    'clusterAdmin',
    'dbAdminAnyDatabase',
    'userAdminAnyDatabase',
    'readWriteAnyDatabase'
  ]
})

# 针对库创建角色
db.createUser({
  user : 'testadm',
  pwd : 'localhost',
  roles : [
    {
    role: "readWrite",db: "autocd-apiplatform"
    }
  ]
})

# 删除用户
use api-platform
db.system.users.remove({user: "admin"})
# admin库上创建权限
db.grantRolesToUser("admin", [ { role:"dbAdminAnyDatabase", db:"admin"} ])
db.grantRolesToUser("testadm", [ { role:"readWrite", db:"autocd-apiplatform"} ])
# 针对库创建角色
db.createUser({
  user : 'admin',
  pwd : '123456',
  roles : [
    {
    role: "dbOwner",db: "api-platform"
    }
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
### mongo 数据插入
```bash
db.testCase.insert(
  [

  ]
)
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

### mongo数据导入导出
```bash
# 安装mongo-tools工具包
# 下载地址: https://repo.mongodb.org/yum/redhat/7Server/mongodb-org/4.4/x86_64/RPMS/
wget https://repo.mongodb.org/yum/redhat/7Server/mongodb-org/4.4/x86_64/RPMS/mongodb-database-tools-100.3.1.x86_64.rpm -P /usr/local/src
wget https://repo.mongodb.org/yum/redhat/7Server/mongodb-org/4.4/x86_64/RPMS/mongodb-org-tools-4.4.6-1.el7.x86_64.rpm -P /usr/local/src
yum localinstall -y mongodb-database-tools-100.3.1.x86_64.rpm
yum localinstall -y mongodb-org-tools-4.4.6-1.el7.x86_64.rpm
# 导出集合数据 csv
mongoexport --host 10.101.5.192 --port 27017 --authenticationDatabase admin -u pankuibo@300.cn -p 123456 --db api-platform-db --collection testCase --type=csv --fields "_id,checkResponseBody,checkResponseNumber,dataInitializes,headers,isClearCookie,isDeleted,isJsonArray,lastManualResult,service,requestBody,sequence,setGlobalVars,status,testStatus,name,requestMethod,route,description,createUser,testSuiteId,projectId,testCaseType,createAt,checkResponseCode,lastUpdateTime,lastUpdateUser,parameterType" --out /tmp/testCase.json
# 导出集合数据 json
mongoexport --host 10.101.5.192 --port 27017 --authenticationDatabase admin -u pankuibo@300.cn -p 123456 --db api-platform-db --collection testCase --type=json --out /tmp/testCase.json
mongoexport --host 10.101.5.192 --port 27017 --authenticationDatabase admin -u pankuibo@300.cn -p 123456 --db api-platform-db --collection project --type=json --out /tmp/project.json
# 导入集合数据
db.testCase.find({"name" : "APP登录发送短信"})
db.testCase.deleteMany({})
mongoimport --host dds-2ze79bb2ebe6a3a42226-pub.mongodb.rds.aliyuncs.com --port 3717 -u testadm -p cLAE7MbgAsW0w13FmqSXaUbm -d autocd-apiplatform -c testCase --type=json --file testCase.json
mongoimport --host dds-2ze79bb2ebe6a3a42226-pub.mongodb.rds.aliyuncs.com --port 3717 -u testadm -p cLAE7MbgAsW0w13FmqSXaUbm -d autocd-apiplatform -c project --type=json --file project.json
# 查询mongo文档
mongo mongodb://10.101.5.192:27017/api-platform-db --authenticationDatabase admin -u pankuibo@300.cn -p 123456
mongo mongodb://dds-2ze79bb2ebe6a3a42226-pub.mongodb.rds.aliyuncs.com:3717/autocd-apiplatform --authenticationDatabase admin -u  testadm  -p cLAE7MbgAsW0w13FmqSXaUbm
db.testCase.find({"name" : "APP登录发送短信"}).pretty()
```

### mongo故障恢复


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
