### mongo 副本集搭建

#### MongoDB主备+仲裁的基本结构如下

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

#### 部署过程如下

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
for i in `seq 1 3`;do docker run --rm -itd --privileged=true  --name mongo_vm_$i mongo_vm:v1 /usr/sbin/init;done
# 查询ip地址
for i in `seq 1 3`;do docker inspect mongo_vm_$i -f {{.NetworkSettings.Networks.bridge.IPAddress}};done
# 删除机器
for i in `seq 1 3`;do docker stop mongo_vm_$i mongo_vm:v1;done
# 服务器信息
mongo01  172.17.0.3   Primary
mongo02  172.17.0.4   Secondary
mongo03  172.17.0.5   Secondary
# 清除known_hosts
for i in `seq 1 3`;do docker exec -it mongo_vm_$i -- > /root/.ssh/known_hosts;done
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
    - name: configure hosts
      shell: |
        cat >> /etc/hosts <<- 'EOF'
        # mongo
        172.17.0.3 mongo01
        172.17.0.4 mongo02
        172.17.0.5 mongo03
        EOF
      tags:
      - install

    - name: download mongo
      shell: wget https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-4.0.4.tgz -P /usr/local/src
      tags:
      - install
    
    - name: unarchive
      unarchive:
        src: /usr/local/src/mongodb-linux-x86_64-4.0.4.tgz
        dest: /usr/local/src
        mode: 0755
        copy: no
      tags:
      - install

    - name: mkdir dir
      file:
        path: "{{ item }}"
        state: directory
      with_items:
      - "/usr/local/mongo"
      - "/data/mongo/db"
      tags:
      - install

    - name: create log file
      file:
        path: "{{ item }}/mongod.log"
        state: touch
      with_items:
      - "/data/mongo"
      tags:
      - log
      - install

    - name: copy files
      shell: mv "{{ item }}"/* /usr/local/mongo/
      with_items:
      - "/usr/local/src/mongodb-linux-x86_64-4.0.4"
      tags:
      - install

    - name: configure env 
      shell: |
        echo 'export PATH=/usr/local/mongo/bin:$PATH' >> /etc/profile
        source /etc/profile
      tags:
      - env
      - install

    - name: configure conf file
      shell: |
        cat > /data/mongo/mongodb.cnf <<- 'EOF'
        systemLog:
          destination: file
          logAppend: true
          path: /data/mongo/mongod.log
        net:
          port: 27017
          bindIp: 0.0.0.0
        storage:
          dbPath: /data/mongo/db
        journal:
          enabled: true
        processManagement:
          fork: true
          pidFilePath: /data/mongo/mongod.pid
        security:
          authorization: enabled
          keyFile: data/mongo/keyfile
          clusterAuthMode: keyFile
        replication:
          replSetName: rs0
        EOF
      tags:
      - conf
      - install

    - name: reboot to start
      shell: |
        cat > /etc/systemd/system/mongod.service <<- 'EOF'
        [Unit]
        Description=mongodb
        After=network.target remote-fs.target nss-lookup.target

        [Service]
        Type=forking
        ExecStart=/usr/local/mongo/bin/mongod --config /data/mongo/mongodb.cnf
        ExecReload=/bin/kill -s HUP $MAINPID
        ExecStop=/usr/local/mongo/bin/mongod --shutdown --config /data/mongo/mongodb.cnf
        PrivateTmp=true
        [Install]
        WantedBy=multi-user.target
        EOF
        systemctl enable mongod.servcie
        systemctl start mongod
      tags:
      - start
      - install
EOF
#ansible-playbook deploy.yml --tags start
ansible-playbook deploy.yml --tags install
# 配置mongo 副本集
## 登陆主节点
mongo
use admin
rs.initiate({_id:'rs0',members: [{ _id: 0 , host: "mongo01:27017"}]})
## 添加次节点
rs.add('mongo02:27017')
rs.add('mongo03:27017')
## 查看配置
rs.conf()
{
	"_id" : "rs0",
	"version" : 3,
	"protocolVersion" : NumberLong(1),
	"writeConcernMajorityJournalDefault" : true,
	"members" : [
		{
			"_id" : 0,
			"host" : "mongo01:27017",
			"arbiterOnly" : false,
			"buildIndexes" : true,
			"hidden" : false,
			"priority" : 1,
			"tags" : {
			},
			"slaveDelay" : NumberLong(0),
			"votes" : 1
		},
		{
			"_id" : 1,
			"host" : "mongo02:27017",
			"arbiterOnly" : false,
			"buildIndexes" : true,
			"hidden" : false,
			"priority" : 1,
			"tags" : {
			},
			"slaveDelay" : NumberLong(0),
			"votes" : 1
		},
		{
			"_id" : 2,
			"host" : "mongo03:27017",
			"arbiterOnly" : false,
			"buildIndexes" : true,
			"hidden" : false,
			"priority" : 1,
			"tags" : {
			},
			"slaveDelay" : NumberLong(0),
			"votes" : 1
		}
	],
	"settings" : {
		"chainingAllowed" : true,
		"heartbeatIntervalMillis" : 2000,
		"heartbeatTimeoutSecs" : 10,
		"electionTimeoutMillis" : 10000,
		"catchUpTimeoutMillis" : -1,
		"catchUpTakeoverDelayMillis" : 30000,
		"getLastErrorModes" : {
		},
		"getLastErrorDefaults" : {
			"w" : 1,
			"wtimeout" : 0
		},
		"replicaSetId" : ObjectId("5fa74da8ebc391934052afbc")
	}
}
## 查看各节点状态
rs.status()
一个主节点，两个从节点
{
	"set" : "rs0",
	"date" : ISODate("2020-11-08T01:49:51.705Z"),
	"myState" : 1,
	"term" : NumberLong(1),
	"syncingTo" : "",
	"syncSourceHost" : "",
	"syncSourceId" : -1,
	"heartbeatIntervalMillis" : NumberLong(2000),
	"optimes" : {
		"lastCommittedOpTime" : {
			"ts" : Timestamp(1604800185, 1),
			"t" : NumberLong(1)
		},
		"readConcernMajorityOpTime" : {
			"ts" : Timestamp(1604800185, 1),
			"t" : NumberLong(1)
		},
		"appliedOpTime" : {
			"ts" : Timestamp(1604800185, 1),
			"t" : NumberLong(1)
		},
		"durableOpTime" : {
			"ts" : Timestamp(1604800185, 1),
			"t" : NumberLong(1)
		}
	},
	"lastStableCheckpointTimestamp" : Timestamp(1604800155, 1),
	"members" : [
		{
			"_id" : 0,
			"name" : "mongo01:27017",
			"health" : 1,
			"state" : 1,
			"stateStr" : "PRIMARY",
			"uptime" : 366,
			"optime" : {
				"ts" : Timestamp(1604800185, 1),
				"t" : NumberLong(1)
			},
			"optimeDate" : ISODate("2020-11-08T01:49:45Z"),
			"syncingTo" : "",
			"syncSourceHost" : "",
			"syncSourceId" : -1,
			"infoMessage" : "",
			"electionTime" : Timestamp(1604799913, 1),
			"electionDate" : ISODate("2020-11-08T01:45:13Z"),
			"configVersion" : 3,
			"self" : true,
			"lastHeartbeatMessage" : ""
		},
		{
			"_id" : 1,
			"name" : "mongo02:27017",
			"health" : 1,
			"state" : 2,
			"stateStr" : "SECONDARY",
			"uptime" : 184,
			"optime" : {
				"ts" : Timestamp(1604800185, 1),
				"t" : NumberLong(1)
			},
			"optimeDurable" : {
				"ts" : Timestamp(1604800185, 1),
				"t" : NumberLong(1)
			},
			"optimeDate" : ISODate("2020-11-08T01:49:45Z"),
			"optimeDurableDate" : ISODate("2020-11-08T01:49:45Z"),
			"lastHeartbeat" : ISODate("2020-11-08T01:49:51.380Z"),
			"lastHeartbeatRecv" : ISODate("2020-11-08T01:49:51.381Z"),
			"pingMs" : NumberLong(0),
			"lastHeartbeatMessage" : "",
			"syncingTo" : "mongo01:27017",
			"syncSourceHost" : "mongo01:27017",
			"syncSourceId" : 0,
			"infoMessage" : "",
			"configVersion" : 3
		},
		{
			"_id" : 2,
			"name" : "mongo03:27017",
			"health" : 1,
			"state" : 2,
			"stateStr" : "SECONDARY",
			"uptime" : 112,
			"optime" : {
				"ts" : Timestamp(1604800185, 1),
				"t" : NumberLong(1)
			},
			"optimeDurable" : {
				"ts" : Timestamp(1604800185, 1),
				"t" : NumberLong(1)
			},
			"optimeDate" : ISODate("2020-11-08T01:49:45Z"),
			"optimeDurableDate" : ISODate("2020-11-08T01:49:45Z"),
			"lastHeartbeat" : ISODate("2020-11-08T01:49:51.570Z"),
			"lastHeartbeatRecv" : ISODate("2020-11-08T01:49:50.191Z"),
			"pingMs" : NumberLong(0),
			"lastHeartbeatMessage" : "",
			"syncingTo" : "mongo02:27017",
			"syncSourceHost" : "mongo02:27017",
			"syncSourceId" : 1,
			"infoMessage" : "",
			"configVersion" : 3
		}
	],
	"ok" : 1,
	"operationTime" : Timestamp(1604800185, 1),
	"$clusterTime" : {
		"clusterTime" : Timestamp(1604800185, 1),
		"signature" : {
			"hash" : BinData(0,"AAAAAAAAAAAAAAAAAAAAAAAAAAA="),
			"keyId" : NumberLong(0)
		}
	}
}
## 配置从节点读
### 直接查询报错
rs0:SECONDARY> show dbs
2020-11-08T01:54:54.250+0000 E QUERY    [js] Error: listDatabases failed:{
	"operationTime" : Timestamp(1604800485, 1),
	"ok" : 0,
	"errmsg" : "not master and slaveOk=false",
	"code" : 13435,
	"codeName" : "NotMasterNoSlaveOk",
	"$clusterTime" : {
		"clusterTime" : Timestamp(1604800485, 1),
		"signature" : {
			"hash" : BinData(0,"AAAAAAAAAAAAAAAAAAAAAAAAAAA="),
			"keyId" : NumberLong(0)
		}
	}
} :
_getErrorWithCode@src/mongo/shell/utils.js:25:13
Mongo.prototype.getDBs@src/mongo/shell/mongo.js:67:1
shellHelper.show@src/mongo/shell/utils.js:876:19
shellHelper@src/mongo/shell/utils.js:766:15
@(shellhelp2):1:1
### 开启slave读写
rs0:SECONDARY> rs.slaveOk()
rs0:SECONDARY> show dbs
admin   0.000GB
config  0.000GB
local   0.000GB
## 配置安全访问
### 主节点创建账号
use admin
db.createUser({
  user : 'admin',
  pwd : '123456',
  roles : [
    'root'
  ]
})
### 生成keyfile
openssl rand -base64 90 -out /data/mongo/keyfile
### 并复制到其它两个节点
scp /data/mongo/keyfile  mongo02:/data/mongo/
scp /data/mongo/keyfile  mongo03:/data/mongo/
chmod 600 /data/mongo/keyfile
### 修改配置文件
security:
   authorization: "enabled" 
   keyFile: '/data/mongo/keyfile'
   clusterAuthMode: "keyFile"
### 重启
systemctl restart mongod
```

##### 故障模拟
###### 主节点宕机，次节点选主
```bash
# 停止其中一台节点
## 停止一台
systemctl stop mongo01
## 登陆查看节点状态
rs.status()
```