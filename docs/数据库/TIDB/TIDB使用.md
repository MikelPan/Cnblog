## TIDB 数据库集群

### 一、TiDB数据介绍

#### 1.1、TiDB数据简介

TiDB 是 PingCAP 公司设计的开源分布式 HTAP (Hybrid Transactional and Analytical Processing) 数据库，结合了传统的 RDBMS 和 NoSQL 的最佳特性。TiDB 兼容 MySQL，支持无限的水平扩展，具备强一致性和高可用性。TiDB 的目标是为 OLTP (Online Transactional Processing) 和 OLAP (Online Analytical Processing) 场景提供一站式的解决方案。

TiDB 具备如下特性：

- 高度兼容 MySQL

  [大多数情况下](https://www.pingcap.com/docs-cn/sql/mysql-compatibility/)，无需修改代码即可从 MySQL 轻松迁移至 TiDB，分库分表后的 MySQL 集群亦可通过 TiDB 工具进行实时迁移。

- 水平弹性扩展

  通过简单地增加新节点即可实现 TiDB 的水平扩展，按需扩展吞吐或存储，轻松应对高并发、海量数据场景。

- 分布式事务

  TiDB 100% 支持标准的 ACID 事务。

- 真正金融级高可用

  相比于传统主从 (M-S) 复制方案，基于 Raft 的多数派选举协议可以提供金融级的 100% 数据强一致性保证，且在不丢失大多数副本的前提下，可以实现故障的自动恢复 (auto-failover)，无需人工介入。

- 一站式 HTAP 解决方案

  TiDB 作为典型的 OLTP 行存数据库，同时兼具强大的 OLAP 性能，配合 TiSpark，可提供一站式 HTAP 解决方案，一份存储同时处理 OLTP & OLAP，无需传统繁琐的 ETL 过程。

- 云原生 SQL 数据库

  TiDB 是为云而设计的数据库，支持公有云、私有云和混合云，使部署、配置和维护变得十分简单。

**TiDB Server**

TiDB Server 负责接收 SQL 请求，处理 SQL 相关的逻辑，并通过 PD 找到存储计算所需数据的 TiKV 地址，与 TiKV 交互获取数据，最终返回结果。TiDB Server 是无状态的，其本身并不存储数据，只负责计算，可以无限水平扩展，可以通过负载均衡组件（如LVS、HAProxy 或 F5）对外提供统一的接入地址。

**PD Server**

Placement Driver (简称 PD) 是整个集群的管理模块，其主要工作有三个：一是存储集群的元信息（某个 Key 存储在哪个 TiKV 节点）；二是对 TiKV 集群进行调度和负载均衡（如数据的迁移、Raft group leader 的迁移等）；三是分配全局唯一且递增的事务 ID。

PD 是一个集群，需要部署奇数个节点，一般线上推荐至少部署 3 个节点

**TiKV Server**

TiKV Server 负责存储数据，从外部看 TiKV 是一个分布式的提供事务的 Key-Value 存储引擎。存储数据的基本单位是 Region，每个 Region 负责存储一个 Key Range（从 StartKey 到 EndKey 的左闭右开区间）的数据，每个 TiKV 节点会负责多个 Region。TiKV 使用 Raft 协议做复制，保持数据的一致性和容灾。副本以 Region 为单位进行管理，不同节点上的多个 Region 构成一个 Raft Group，互为副本。数据在多个 TiKV 之间的负载均衡由 PD 调度，这里也是以 Region 为单位进行调度

**TiSpark**

TiSpark 作为 TiDB 中解决用户复杂 OLAP 需求的主要组件，将 Spark SQL 直接运行在 TiDB 存储层上，同时融合 TiKV 分布式集群的优势，并融入大数据社区生态。至此，TiDB 可以通过一套系统，同时支持 OLTP 与 OLAP，免除用户数据同步的烦恼

#### 1.2、Tidb 数据基本操作

**创建、查看和删除数据库**

```sql
CREATE DATABASE db_name [options];
CREATE DATABASE IF NOT EXISTS samp_db;
DROP DATABASE samp_db;
DROP TABLE IF EXISTS person;
CREATE INDEX person_num ON person (number);
ALTER TABLE person ADD INDEX person_num (number);
CREATE UNIQUE INDEX person_num ON person (number);
CREATE USER 'tiuser'@'localhost' IDENTIFIED BY '123456';
GRANT SELECT ON samp_db.* TO 'tiuser'@'localhost';
SHOW GRANTS for tiuser@localhost;
DROP USER 'tiuser'@'localhost';
GRANT ALL PRIVILEGES ON test.* TO 'xxxx'@'%' IDENTIFIED BY 'yyyyy';
REVOKE ALL PRIVILEGES ON `test`.* FROM 'genius'@'localhost';
SHOW GRANTS for 'root'@'%';
SELECT Insert_priv FROM mysql.user WHERE user='test' AND host='%';
FLUSH PRIVILEGES;
```

### 二、TiDB Ansible 部署

#### 2.1、安装Tidb集群基础环境

使用三台物理机搭建Tidb集群，三台机器ip 为 172.16.5.50，172.16.5.51，172.16.5.10，其中172.16.5.51作为中控机。

软件安装如下：

172.16.5.51       TiDB,PD,TiKV

172.16.5.50       TiKV

172.16.5.10       TiKV

**安装中控机软件**

```
# yum -y install epel-release git curl sshpass atop vim htop net-tools 
# yum -y install python-pip
```

**在中控机上创建 tidb 用户，并生成 ssh key**

```shell
# 创建tidb用户
useradd -m -d /home/tidb tidb && passwd tidb
# 配置tidb用户sudo权限
visudo
tidb ALL=(ALL) NOPASSWD: ALL
# 使用tidb账户生成 ssh key
su tidb && ssh-keygen -t rsa -C mikel@tidb
```

**在中控机器上下载 TiDB-Ansible**

```shell
# 下载Tidb-Ansible 版本
cd /home/tidb && git clone -b release-2.0 https://github.com/pingcap/tidb-ansible.git
# 安装ansible及依赖
cd /home/tidb/tidb-ansible/ && pip install -r ./requirements.txt
```

**在中控机上配置部署机器ssh互信及sudo 规则**

```shell
# 配置hosts.ini
su tidb && cd /home/tidb/tidb-ansible
vim hosts.ini
[servers]
172.16.5.50
172.16.5.51
172.16.5.52
[all:vars]
username = tidb
ntp_server = pool.ntp.org
# 配置ssh 互信
ansible-playbook -i hosts.ini create_users.yml -u root -k
```

**在目标机器上安装ntp服务**

```
# 中控机器上给目标主机安装ntp服务
cd /home/tidb/tidb-ansible
ansible-playbook -i hosts.ini deploy_ntp.yml -u tidb -b
```

**目标机器上调整cpufreq** 

```shell
# 查看cpupower 调节模式，目前虚拟机不支持，调节10服务器cpupower
cpupower frequency-info --governors
analyzing CPU 0:
  available cpufreq governors: Not Available
# 配置cpufreq调节模式
cpupower frequency-set --governor performance
```

**目标机器上添加数据盘ext4 文件系统挂载**

```shell
# 创建分区表
parted -s -a optimal /dev/nvme0n1 mklabel gpt -- mkpart primary ext4 1 -1
# 手动创建分区
parted  dev/sdb
mklabel gpt
mkpart primary 0KB 210GB 
# 格式化分区
mkfs.ext4 /dev/sdb
# 查看数据盘分区 UUID
[root@tidb-tikv1 ~]# lsblk -f
NAME   FSTYPE LABEL UUID                                 MOUNTPOINT
sda                                                      
├─sda1 xfs          f41c3b1b-125f-407c-81fa-5197367feb39 /boot
├─sda2 xfs          8119193b-c774-467f-a057-98329c66b3b3 /
├─sda3                                                   
└─sda5 xfs          42356bb3-911a-4dc4-b56e-815bafd08db2 /home
sdb    ext4         532697e9-970e-49d4-bdba-df386cac34d2 
# 分别在三台机器上，编辑 /etc/fstab 文件，添加 nodelalloc 挂载参数
vim /etc/fstab
UUID=8119193b-c774-467f-a057-98329c66b3b3 /                       xfs     defaults        0 0
UUID=f41c3b1b-125f-407c-81fa-5197367feb39 /boot                   xfs     defaults        0 0
UUID=42356bb3-911a-4dc4-b56e-815bafd08db2 /home                   xfs     defaults        0 0
UUID=532697e9-970e-49d4-bdba-df386cac34d2 /data                   ext4    defaults,nodelalloc,noatime   0 2
# 挂载数据盘
mkdir /data
mount -a
mount -t ext4
/dev/sdb on /data type ext4 (rw,noatime,seclabel,nodelalloc,data=ordered)
```

**分配机器资源，编辑inventory.ini 文件**

```shell
# 单机Tikv实例
Name                  HostIP                  Services
tidb-tikv1           172.16.5.50             PD1, TiDB1, TiKV1
tidb-tikv2           172.16.5.51             PD2, TiKV2
tidb-tikv3           172.16.5.52             PD3, TiKV3
# 编辑inventory.ini 文件
cd /home/tidb/tidb-ansible
vim inventory.ini
## TiDB Cluster Part
[tidb_servers]
172.16.5.50
172.16.5.51

[tikv_servers]
172.16.5.50
172.16.5.51
172.16.5.52

[pd_servers]
172.16.5.50
172.16.5.51
172.16.5.52

## Monitoring Part
# prometheus and pushgateway servers
[monitoring_servers]
172.16.5.50

# node_exporter and blackbox_exporter servers
[monitored_servers]
172.16.5.50
172.16.5.51
172.16.5.52

[all:vars]
#deploy_dir = /home/tidb/deploy
deploy_dir = /data/deploy
# 检测ssh互信
[tidb@tidb-tikv1 tidb-ansible]$ ansible -i inventory.ini all -m shell -a 'whoami'
172.16.5.51 | SUCCESS | rc=0 >>
tidb
172.16.5.52 | SUCCESS | rc=0 >>
tidb
172.16.5.50 | SUCCESS | rc=0 >>
tidb
# 检测tidb 用户 sudo 免密码配置
[tidb@tidb-tikv1 tidb-ansible]$ ansible -i inventory.ini all -m shell -a 'whoami' -b
172.16.5.52 | SUCCESS | rc=0 >>
root
172.16.5.51 | SUCCESS | rc=0 >>
root
172.16.5.50 | SUCCESS | rc=0 >>
root
# 执行 local_prepare.yml playbook，联网下载 TiDB binary 到中控机
ansible-playbook local_prepare.yml
# 初始化系统环境，修改内核参数
ansible-playbook bootstrap.yml
```

#### 2.2、安装Tidb集群

```shell
ansible-playbook deploy.yml
```

#### 2.3、启动Tidb集群

```
ansible-playbook start.yml
```

#### 2.4、测试集群

```shell
# 使用 MySQL 客户端连接测试，TCP 4000 端口是 TiDB 服务默认端口
mysql -u root -h 172.16.5.50 -P 4000
mysql> show databases;
+--------------------+
| Database           |
+--------------------+
| INFORMATION_SCHEMA |
| PERFORMANCE_SCHEMA |
| mysql              |
| test               |
+--------------------+
4 rows in set (0.00 sec)
# 通过浏览器访问监控平台
地址：http://172.16.5.51:3000 默认帐号密码是：admin/admin
```

### 三、TIDB集群扩容

#### 3.1、扩容 TiDB/TiKV 节点

```shell
# 单机Tikv实例
Name                  HostIP                  Services
tidb-tikv1           172.16.5.50             PD1, TiDB1, TiKV1
tidb-tikv2           172.16.5.51             PD2, TiKV2
tidb-tikv3           172.16.5.52             PD3, TiKV3
# 新增一台TIDB节点
添加一个 TiDB 节点（tidb-tikv4），IP 地址为 172.16.5.53
# 编辑inventory.ini 文件
cd /home/tidb/tidb-ansible
vim inventory.ini
## TiDB Cluster Part
[tidb_servers]
172.16.5.50
172.16.5.51
172.16.5.53

[tikv_servers]
172.16.5.50
172.16.5.51
172.16.5.52

[pd_servers]
172.16.5.50
172.16.5.51
172.16.5.52

## Monitoring Part
# prometheus and pushgateway servers
[monitoring_servers]
172.16.5.50

# node_exporter and blackbox_exporter servers
[monitored_servers]
172.16.5.50
172.16.5.51
172.16.5.52
172.16.5.53
# 拓扑结构如下
Name                  HostIP                  Services
tidb-tikv1           172.16.5.50             PD1, TiDB1, TiKV1
tidb-tikv2           172.16.5.51             PD2, TiKV2
tidb-tikv3           172.16.5.52             PD3, TiKV3
tidb-tikv4           172.16.5.53             TiDB2
# 初始化新增节点
ansible-playbook bootstrap.yml -l 172.16.5.53
# 部署新增节点
ansible-playbook deploy.yml -l 172.16.5.53
# 启动新节点服务
ansible-playbook start.yml -l 172.16.5.53
# 更新 Prometheus 配置并重启
ansible-playbook rolling_update_monitor.yml --tags=prometheus
```

#### 3.2、扩容PD节点

```shell
# 拓扑结构如下# 单机Tikv实例
Name                  HostIP                  Services
tidb-tikv1           172.16.5.50             PD1, TiDB1, TiKV1
tidb-tikv2           172.16.5.51             PD2, TiKV2
tidb-tikv3           172.16.5.52             PD3, TiKV3
# 新增一台PD节点
添加一个 PD 节点（tidb-pd1），IP 地址为 172.16.5.54
# 编辑inventory.ini 文件
cd /home/tidb/tidb-ansible
vim inventory.ini
## TiDB Cluster Part
[tidb_servers]
172.16.5.50
172.16.5.51

[tikv_servers]
172.16.5.50
172.16.5.51
172.16.5.52

[pd_servers]
172.16.5.50
172.16.5.51
172.16.5.52
172.16.5.54

## Monitoring Part
# prometheus and pushgateway servers
[monitoring_servers]
172.16.5.50

# node_exporter and blackbox_exporter servers
[monitored_servers]
172.16.5.50
172.16.5.51
172.16.5.52
172.16.5.54
# 拓扑结构如下
Name                  HostIP                  Services
tidb-tikv1           172.16.5.50             PD1, TiDB1, TiKV1
tidb-tikv2           172.16.5.51             PD2, TiKV2
tidb-tikv3           172.16.5.52             PD3, TiKV3
tidb-pd1             172.16.5.54             PD4
# 初始化新增节点
ansible-playbook bootstrap.yml -l 172.16.5.54
# 部署新增节点
ansible-playbook deploy.yml -l 172.16.5.54
# 登录新增的 PD 节点，编辑启动脚本：{deploy_dir}/scripts/run_pd.sh
1、移除 --initial-cluster="xxxx" \ 配置。
2、添加 --join="http://172.16.10.1:2379" \，IP 地址 （172.16.10.1） 可以是集群内现有 PD IP 地址中的任意一个。
3、在新增 PD 节点中手动启动 PD 服务：
{deploy_dir}/scripts/start_pd.sh
4、使用 pd-ctl 检查新节点是否添加成功：
/home/tidb/tidb-ansible/resources/bin/pd-ctl -u "http://172.16.10.1:2379" -d member
# 滚动升级整个集群
ansible-playbook rolling_update.yml
# 更新 Prometheus 配置并重启
ansible-playbook rolling_update_monitor.yml --tags=prometheus
```

### 四、tidb集群测试

#### 4.1、sysbench基准库测试

**sysbench安装**

```shell
# 二进制安装
curl -s https://packagecloud.io/install/repositories/akopytov/sysbench/script.rpm.sh | sudo bash
sudo yum -y install sysbench
```

**性能测试**

```shell
# cpu性能测试
sysbench --test=cpu --cpu-max-prime=20000 run
----------------------------------start----------------------------------------
Number of threads: 1
Initializing random number generator from current time
Prime numbers limit: 20000
Initializing worker threads...
Threads started!
CPU speed:
    events per second:   286.71
General statistics:
    total time:                          10.0004s
    total number of events:              2868
Latency (ms):
         min:                                    3.46
         avg:                                    3.49
         max:                                    4.49
         95th percentile:                        3.55
         sum:                                 9997.23
Threads fairness:
    events (avg/stddev):           2868.0000/0.00
    execution time (avg/stddev):   9.9972/0.00
-----------------------------------end-------------------------------------------
# 线程测试
sysbench --test=threads --num-threads=64 --thread-yields=100 --thread-locks=2 run
------------------------------------start-----------------------------------------
Number of threads: 64
Initializing random number generator from current time
Initializing worker threads...
Threads started!
General statistics:
    total time:                          10.0048s
    total number of events:              108883
Latency (ms):
         min:                                    0.05
         avg:                                    5.88
         max:                                   49.15
         95th percentile:                       17.32
         sum:                               640073.32
Threads fairness:
    events (avg/stddev):           1701.2969/36.36
    execution time (avg/stddev):   10.0011/0.00
-----------------------------------end-----------------------------------------
# 磁盘IO测试
sysbench --test=fileio --num-threads=16 --file-total-size=3G --file-test-mode=rndrw prepare
----------------------------------start-----------------------------------------
128 files, 24576Kb each, 3072Mb total
Creating files for the test...
Extra file open flags: (none)
Creating file test_file.0
Creating file test_file.1
Creating file test_file.2
Creating file test_file.3
Creating file test_file.4
Creating file test_file.5
Creating file test_file.6
Creating file test_file.7
Creating file test_file.8
Creating file test_file.9
Creating file test_file.10
Creating file test_file.11
Creating file test_file.12
Creating file test_file.13
Creating file test_file.14
Creating file test_file.15
Creating file test_file.16
Creating file test_file.17
Creating file test_file.18
Creating file test_file.19
Creating file test_file.20
Creating file test_file.21
Creating file test_file.22
Creating file test_file.23
Creating file test_file.24
Creating file test_file.25
Creating file test_file.26
Creating file test_file.27
Creating file test_file.28
Creating file test_file.29
Creating file test_file.30
Creating file test_file.31
Creating file test_file.32
Creating file test_file.33
Creating file test_file.34
Creating file test_file.35
Creating file test_file.36
Creating file test_file.37
Creating file test_file.38
Creating file test_file.39
Creating file test_file.40
Creating file test_file.41
Creating file test_file.42
Creating file test_file.43
Creating file test_file.44
Creating file test_file.45
Creating file test_file.46
Creating file test_file.47
Creating file test_file.48
Creating file test_file.49
Creating file test_file.50
Creating file test_file.51
Creating file test_file.52
Creating file test_file.53
Creating file test_file.54
Creating file test_file.55
Creating file test_file.56
Creating file test_file.57
Creating file test_file.58
Creating file test_file.59
Creating file test_file.60
Creating file test_file.61
Creating file test_file.62
Creating file test_file.63
Creating file test_file.64
Creating file test_file.65
Creating file test_file.66
Creating file test_file.67
Creating file test_file.68
Creating file test_file.69
Creating file test_file.70
Creating file test_file.71
Creating file test_file.72
Creating file test_file.73
Creating file test_file.74
Creating file test_file.75
Creating file test_file.76
Creating file test_file.77
Creating file test_file.78
Creating file test_file.79
Creating file test_file.80
Creating file test_file.81
Creating file test_file.82
Creating file test_file.83
Creating file test_file.84
Creating file test_file.85
Creating file test_file.86
Creating file test_file.87
Creating file test_file.88
Creating file test_file.89
Creating file test_file.90
Creating file test_file.91
Creating file test_file.92
Creating file test_file.93
Creating file test_file.94
Creating file test_file.95
Creating file test_file.96
Creating file test_file.97
Creating file test_file.98
Creating file test_file.99
Creating file test_file.100
Creating file test_file.101
Creating file test_file.102
Creating file test_file.103
Creating file test_file.104
Creating file test_file.105
Creating file test_file.106
Creating file test_file.107
Creating file test_file.108
Creating file test_file.109
Creating file test_file.110
Creating file test_file.111
Creating file test_file.112
Creating file test_file.113
Creating file test_file.114
Creating file test_file.115
Creating file test_file.116
Creating file test_file.117
Creating file test_file.118
Creating file test_file.119
Creating file test_file.120
Creating file test_file.121
Creating file test_file.122
Creating file test_file.123
Creating file test_file.124
Creating file test_file.125
Creating file test_file.126
Creating file test_file.127
3221225472 bytes written in 339.76 seconds (9.04 MiB/sec)
----------------------------------end------------------------------------------
sysbench --test=fileio --num-threads=16 --file-total-size=3G --file-test-mode=rndrw run
----------------------------------start-----------------------------------------
Number of threads: 16
Initializing random number generator from current time
Extra file open flags: (none)
128 files, 24MiB each
3GiB total file size
Block size 16KiB
Number of IO requests: 0
Read/Write ratio for combined random IO test: 1.50
Periodic FSYNC enabled, calling fsync() each 100 requests.
Calling fsync() at the end of test, Enabled.
Using synchronous I/O mode
Doing random r/w test
Initializing worker threads...
Threads started!
File operations:
    reads/s:                      299.19
    writes/s:                     199.46
    fsyncs/s:                     816.03
Throughput:
    read, MiB/s:                  4.67
    written, MiB/s:               3.12
General statistics:
    total time:                          10.8270s
    total number of events:              12189
Latency (ms):
         min:                                    0.00
         avg:                                   13.14
         max:                                  340.58
         95th percentile:                       92.42
         sum:                               160186.15
Threads fairness:
    events (avg/stddev):           761.8125/216.01
    execution time (avg/stddev):   10.0116/0.01
--------------------------------------end---------------------------------------
sysbench --test=fileio --num-threads=16 --file-total-size=3G --file-test-mode=rndrw cleanup
# 内存测试
sysbench --test=memory --memory-block-size=8k --memory-total-size=4G run 
------------------------------------start-----------------------------------------
Number of threads: 1
Initializing random number generator from current time
Running memory speed test with the following options:
  block size: 8KiB
  total size: 4096MiB
  operation: write
  scope: global
Initializing worker threads...
Threads started!
Total operations: 524288 (1111310.93 per second)
4096.00 MiB transferred (8682.12 MiB/sec)
General statistics:
    total time:                          0.4692s
    total number of events:              524288
Latency (ms):
         min:                                    0.00
         avg:                                    0.00
         max:                                    0.03
         95th percentile:                        0.00
         sum:                                  381.39

Threads fairness:
    events (avg/stddev):           524288.0000/0.00
    execution time (avg/stddev):   0.3814/0.00
-------------------------------------end---------------------------------------
```

#### **4.2、OLTP测试**

```shell
# 登录tidb创建测试数据库
mysql -u root -P 4000 -h 172.16.5.50
create database sbtest
# 准备测试数据
sysbench /usr/share/sysbench/oltp_common.lua --mysql-host=172.16.5.50 --mysql-port=4000 --mysql-user=root --tables=20 --table_size=20000000 --threads=100 --max-requests=0 prepare
--tables=20   # 创建20个表
--table_size=20000000   # 每个表两千万数据
--threads=100           # 使用100个线程数
---------------------------------报错信息如下------------------------------------------
FATAL: mysql_drv_query() returned error 9001 (PD server timeout[try again later]
2018/11/23 11:23:19.236 log.go:82: [warning] etcdserver: [timed out waiting for read index response]
2018/11/23 14:15:17.329 heartbeat_streams.go:97: [error] [store 1] send keepalive message fail: EOF
2018/11/23 14:14:04.603 leader.go:312: [info] leader is deleted
2018/11/23 14:14:04.603 leader.go:103: [info] pd2 is not etcd leader, skip campaign leader and check later
2018/11/23 14:21:10.071 coordinator.go:570: [info] [region 1093] send schedule command: transfer leader from store 7 to store 2
FATAL: mysql_drv_query() returned error 1105 (Information schema is out of date)
------------------------------------end-----------------------------------------------
# 调整线程数为10，表数量为10，表数据为2000000 做测试
sysbench /usr/share/sysbench/oltp_common.lua --mysql-host=172.16.5.50 --mysql-port=4000 --mysql-user=root --tables=1 --table_size=2000000 --threads=10 --max-requests=0 prepare
--------------------------------------start--------------------------------------------
FATAL: mysql_drv_query() returned error 1105 (Information schema is out of date) 超时报错
成功写入2张表，其余8张表数据并未写满，写好索引
# 对tidb集群进行读写测试
sysbench /usr/share/sysbench/oltp_read_write.lua --mysql-host=172.16.5.50 --mysql-port=4000 --mysql-user=root --tables=1 --table_size=2000000 --threads=10 --max-requests=0 run
----------------------------------------start--------------------------------------
Number of threads: 10
Initializing random number generator from current time
Initializing worker threads...
Threads started!
SQL statistics:
    queries performed:
        read:                            868
        write:                           62
        other:                           310
        total:                           1240
    transactions:                        62     (5.60 per sec.)
    queries:                             1240   (112.10 per sec.)
    ignored errors:                      0      (0.00 per sec.)
    reconnects:                          0      (0.00 per sec.)
General statistics:
    total time:                          11.0594s
    total number of events:              62
Latency (ms):
         min:                                  944.55
         avg:                                 1757.78
         max:                                 2535.05
         95th percentile:                     2320.55
         sum:                               108982.56
Threads fairness:
    events (avg/stddev):           6.2000/0.40
    execution time (avg/stddev):   10.8983/0.31
------------------------------------start----------------------------------------
# 使用mysql对比测试
mysql -uroot -P 3306 -h 172.15.5.154
create database sbtest
sysbench /usr/share/sysbench/oltp_common.lua --mysql-host=172.16.5.154 --mysql-port=3306 --mysql-user=root --mysql-password=root --tables=20 --table_size=20000000 --threads=10 --max-requests=0 prepare
使用mysql 做测试未发现报错情况

```

#### 4.3、业务数据测试

sysbench /usr/share/sysbench/oltp_read_write.lua --mysql-host=172.16.5.50 --mysql-port=4000 --mysql-user=root --tables=20 --table_size=2000000 --threads=10 --max-requests=0 run