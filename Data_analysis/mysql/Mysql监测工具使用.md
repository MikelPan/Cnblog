### 一、mysqldumpslow工具使用
#### 1.1、修改配置文件开启慢查询
**mysql 开启慢查询**
```shell
systemctl stop mysqld
echo -e "# 开启慢查询\nslow_query_log = 1\nslow_query_log_file = /var/lib/mysql/slow-query.log\nlong_query_time = 1\nlog_queries_not_using_indexes = 1" >>/etc/my.cnf
# 重启mysql
systemctl restart mysqld
# 登录mysql
mysql -uroot -pP@ssw0rd1
select sleep(1);
```
#### 1.2、修改变量开启慢查询
```sql
set global slow_query_log='ON';
set global slow_query_log_file='/var/lib/mysql/logs/slow.log';
set global long_query_time=1;
```
**使用mysqldumpslow 工具分析 慢查询日志**

- -s：排序方式，值如下
   c：查询次数
   t：查询时间
   l：锁定时间
   r：返回记录
   ac：平均查询次数
   al：平均锁定时间
   ar：平均返回记录书
   at：平均查询时间

- -t：top N查询

- -g：正则表达式

1、访问次数最多的5个sql语句
```shell
mysqldumpslow -s c -t 5 /var/lib/mysql/slow-query.log
----------------------------------start----------------------------------------
Reading mysql slow query log from /var/lib/mysql/slow-query.log
Count: 2  Time=1.50s (3s)  Lock=0.00s (0s)  Rows=1.0 (2),
select sleep(N)

Died at /usr/bin/mysqldumpslow line 161, <> chunk 2.
----------------------------------end-------------------------------------------
```
### 二、mysqlsla工具使用

**mysqlsla安装**
```shell
wget http://hackmysql.com/scripts/mysqlsla-2.03.tar.gz
tar zxvf mysqlsla-2.03.tar.gz -C /usr/local/src
cd /usr/local/src/mysqlsla-2.03
yum install -y perl-ExtUtils-CBuilder perl-ExtUtils-MakeMaker
yum install -y perl-DBD-MySQL
perl Makefile.PL
make && make install
```
**mysqlsla 分析慢查询日志**
```shell
mysqlsla -lt slow -sf "+select,update,insert" -top 10 slow.log > /root/test_time.log
mysqlsla -lt slow -sf "+select,update,insert" -top 10 -sort c_sum -db databasename slow.log > /root/test_time.log
```
**通过mysqlsla 查询日志分析**
```shell
mysqlsla -lt slow -sf "+select" -top 10 /var/lib/mysql/slow-query.log
---------------------------------start--------------------------------------
Report for slow logs: /var/lib/mysql/slow-query.log
2 queries total, 1 unique
Sorted by 't_sum'
Grand Totals: Time 3 s, Lock 0 s, Rows sent 2, Rows Examined 0


______________________________________________________________________ 001 ___
Count         : 2  (100.00%)
Time          : 3.001489 s total, 1.500745 s avg, 1.000509 s to 2.00098 s max  (100.00%)
Lock Time (s) : 0 total, 0 avg, 0 to 0 max  (0.00%)
Rows sent     : 1 avg, 1 to 1 max  (100.00%)
Rows examined : 0 avg, 0 to 0 max  (0.00%)
Database      :
Users         :
	root@localhost  : 100.00% (2) of query, 100.00% (2) of all users

Query abstract:
SELECT sleep(N);

Query sample:
select sleep(1);
---------------------------------end--------------------------------------
```
### 三、pt工具使用
#### 1、pt 工具安装
```shell
#!/bin/bash
percona-toolkit-yum-install(){
# 下载最新版percona-toolkits 包
下载地址：https://www.percona.com/downloads/
wget -P /tar https://www.percona.com/downloads/percona-toolkit/3.0.12/binary/redhat/7/x86_64/percona-toolkit-3.0.12-re3a693a-el7-x86_64-bundle.tar
tar xvf /tar/percona-toolkit-3.0.12-re3a693a-el7-x86_64-bundle.tar
# 安装依赖
yum install -y perl perl-DBI perl-DBD-MySQL perl-Time-HiRes perl-IO-Socket-SSL perl-Digest-MD5
rpm -ivh percona-toolkit-3.0.12-1.el7.x86_64.rpm
}
percona-toolkit-unline-install(){
# 安装离线安装包
rpm -ivh /percona-yum/*.rpm
rpm -ivh percona-toolkit-3.0.12-1.el7.x86_64.rpm
}
--create-review-table  当使用--review参数把分析结果输出到表中时，如果没有表就自动创建
--create-history-table  当使用--history参数把分析结果输出到表中时，如果没有表就自动创建
--filter  对输入的慢查询按指定的字符串进行匹配过滤后再进行分析
--limit   限制输出结果百分比或数量，默认值是20,即将最慢的20条语句输出，如果是50%则按总响应时间占比从大到小排序，输出到总和达到50%位置截止。
--host  mysql服务器地址
--user  mysql用户名
--password  mysql用户密码
--history   将分析结果保存到表中，分析结果比较详细，下次再使用--history时，如果存在相同的语句，且查询所在的时间区间和历史表中的不同，则会记录到数据表中，可以通过查询同一CHECKSUM来比较某类型查询的历史变化。
--review 将分析结果保存到表中，这个分析只是对查询条件进行参数化，一个类型的查询一条记录，比较简单。当下次使用--review时，如果存在相同的语句分析，就不会记录到数据表中。
--output 分析结果输出类型，值可以是report(标准分析报告)、slowlog(Mysql slow log)、json、json-anon，一般使用report，以便于阅读。
--since 从什么时间开始分析，值为字符串，可以是指定的某个”yyyy-mm-dd [hh:mm:ss]”格式的时间点，也可以是简单的一个时间值：s(秒)、h(小时)、m(分钟)、d(天)，如12h就表示从12小时前开始统计。
--until 截止时间，配合—since可以分析一段时间内的慢查询
```
#### 2、percona-toolkit用法
```shell
# 查看慢查询日志
pt-query-digest slow-query.log
--------------------------------------start---------------------------------------
# 280ms user time, 40ms system time, 25.93M rss, 220.21M vsz
# Current date: Wed Jan  2 14:51:50 2019
# Hostname: localhost.localdomain
# Files: slow-query.log
# Overall: 2 total, 1 unique, 0.00 QPS, 0.01x concurrency ________________
# Time range: 2018-12-29T08:56:22 to 2018-12-29T09:04:54
# Attribute          total     min     max     avg     95%  stddev  median
# ============     ======= ======= ======= ======= ======= ======= =======
# Exec time             3s      1s      2s      2s      2s   707ms      2s
# Lock time              0       0       0       0       0       0       0
# Rows sent              2       1       1       1       1       0       1
# Rows examine           0       0       0       0       0       0       0
# Query size            30      15      15      15      15       0      15

# Profile
# Rank Query ID                           Response time Calls R/Call V/M
# ==== ================================== ============= ===== ====== =====
#    1 0x59A74D08D407B5EDF9A57DD5A41825CA 3.0015 100.0%     2 1.5007  0.33 SELECT

# Query 1: 0.00 QPS, 0.01x concurrency, ID 0x59A74D08D407B5EDF9A57DD5A41825CA at byte 565
# This item is included in the report because it matches --limit.
# Scores: V/M = 0.33
# Time range: 2018-12-29T08:56:22 to 2018-12-29T09:04:54
# Attribute    pct   total     min     max     avg     95%  stddev  median
# ============ === ======= ======= ======= ======= ======= ======= =======
# Count        100       2
# Exec time    100      3s      1s      2s      2s      2s   707ms      2s
# Lock time      0       0       0       0       0       0       0       0
# Rows sent    100       2       1       1       1       1       0       1
# Rows examine   0       0       0       0       0       0       0       0
# Query size   100      30      15      15      15      15       0      15
# String:
# Hosts        localhost
# Users        root
# Query_time distribution
#   1us
#  10us
# 100us
#   1ms
#  10ms
# 100ms
#    1s  ################################################################
#  10s+
# EXPLAIN /*!50100 PARTITIONS*/
select sleep(2)\G
-------------------------------------end-----------------------------------------
```
#### 3、pt分析慢查询
```shell
pt-query-digest  slow.log > slow_report.log
pt-query-digest  --since=12h  slow.log > slow_report2.log
pt-query-digest slow.log --since '2014-04-17 09:30:00' --until '2014-04-17 10:00:00'> > slow_report3.log
pt-query-digest--filter '$event->{fingerprint} =~ m/^select/i' slow.log>slow_report4.log
pt-query-digest--filter '($event->{user} || "") =~ m/^root/i' slow.log> slow_report5.log
pt-query-digest--filter '(($event->{Full_scan} || "") eq "yes") ||(($event->{Full_join} || "") eq "yes")' slow.log> slow_report6.log
pt-query-digest  --user=root –password=abc123 --review  h=localhost,D=test,t=query_review --create-review-table  slow.log
pt-query-digest  --user=root –password=abc123 --review  h=localhost,D=test,t=query_ history--create-review-table  slow.log_20140401
pt-query-digest  --user=root –password=abc123--review  h=localhost,D=test,t=query_history--create-review-table  slow.log_20140402
# 通过tcpdump抓取mysql的tcp协议数据，然后再分析
tcpdump -s 65535 -x -nn -q -tttt -i any -c 1000 port 3306 > mysql.tcp.txt
pt-query-digest --type tcpdump mysql.tcp.txt> slow_report9.log
# 分析binlog
mysqlbinlog mysql-bin.000093 > mysql-bin000093.sql
pt-query-digest  --type=binlog  mysql-bin000093.sql > slow_report10.log
# 分析general log
pt-query-digest  --type=genlog  localhost.log > slow_report11.log
```
#### 4、pt校验主从
```shell
# 创建账号
create user 'checksum'@'localhost' identified by 'chk123!@#';
GRANT SELECT, PROCESS, SUPER, REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'checksum'@'192.168.0.%';
create database percona;
GRANT ALL PRIVILEGES ON percona.* TO 'checksum'@'192.168.0.%';
# 默认创建表结构
CREATE TABLE `checksums` (
  `db` char(64) NOT NULL,
  `tbl` char(64) NOT NULL,
  `chunk` int(11) NOT NULL,
  `chunk_time` float DEFAULT NULL,
  `chunk_index` varchar(200) DEFAULT NULL,
  `lower_boundary` text,
  `upper_boundary` text,
  `this_crc` char(40) NOT NULL,
  `this_cnt` int(11) NOT NULL,
  `master_crc` char(40) DEFAULT NULL,
  `master_cnt` int(11) DEFAULT NULL,
  `ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`db`,`tbl`,`chunk`),
  KEY `ts_db_tbl` (`ts`,`db`,`tbl`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8
# 校验数据库
pt-table-checksum --host=172.16.5.150 --port=3306 --user=checksum --password='chk123!@#' --no-check-binlog-format  --dababases=db1
# 校验数据库(忽略mysql库)
pt-table-checksum --host=localhost --port=3306 --user=checksum --password='chk123!@#' --no-check-binlog-format --nocheck-replication-filters --ignore-databases=mysql,sys,percona
# 主从修复测试
pt-table-sync --replicate=percona.checksums h=192.168.0.12,u=checksum,p='chk123!@#' h=192.168.0.14,u=checksum,p='chk123!@#' --print
# 主从同步修复
pt-table-sync --replicate=percona.checksums h=192.168.0.12,u=checksum,p='chk123!@#' h=192.168.0.14,u=checksum,p='chk123!@#'  --execute
# 只修复从库
pt-table-sync --execute --replicate=percona.checksums --sync-to-master h=172.16.5.151,P=3306,u=checksum,p='chk123!@#'
# 登录从库检查
SELECT
*
FROM
percona.checksums
WHERE
master_cnt <> this_cnt
OR master_crc <> this_crc
OR ISNULL(master_crc) <> ISNULL(this_crc)
```
#### 5、pt热更新
```shell
# 参数说明
--user:
-u，连接的用户名

--password：
-p，连接的密码

--database：
-D，连接的数据库

--port
-P，连接数据库的端口

--host:
-h，连接的主机地址

--socket:
-S，连接的套接字文件

--ask-pass
隐式输入连接MySQL的密码

--charset
指定修改的字符集

--defaults-file
-F，读取配置文件

--alter：
结构变更语句，不需要alter table关键字。可以指定多个更改，用逗号分隔。如下场景，需要注意：
    不能用RENAME来重命名表。
    列不能通过先删除，再添加的方式进行重命名，不会将数据拷贝到新列。
    如果加入的列非空而且没有默认值，则工具会失败。即其不会为你设置一个默认值，必须显示指定。
    删除外键(drop foreign key constrain_name)时，需要指定名称_constraint_name，而不是原始的constraint_name。
    如：CONSTRAINT `fk_foo` FOREIGN KEY (`foo_id`) REFERENCES `bar` (`foo_id`)，需要指定：--alter "DROP FOREIGN KEY _fk_foo"

--alter-foreign-keys-method
如何把外键引用到新表?需要特殊处理带有外键约束的表,以保证它们可以应用到新表.当重命名表的时候,外键关系会带到重命名后的表上。
该工具有两种方法,可以自动找到子表,并修改约束关系。
    auto： 在rebuild_constraints和drop_swap两种处理方式中选择一个。
    rebuild_constraints：使用 ALTER TABLE语句先删除外键约束,然后再添加.如果子表很大的话,会导致长时间的阻塞。
    drop_swap： 执行FOREIGN_KEY_CHECKS=0,禁止外键约束,删除原表,再重命名新表。这种方式很快,也不会产生阻塞,但是有风险：
    1, 在删除原表和重命名新表的短时间内,表是不存在的,程序会返回错误。
    2, 如果重命名表出现错误,也不能回滚了.因为原表已经被删除。
    none： 类似"drop_swap"的处理方式,但是它不删除原表,并且外键关系会随着重命名转到老表上面。
--[no]check-alter
默认yes，语法解析。配合--dry-run 和 --print 一起运行，来检查是否有问题（change column，drop primary key）。

--max-lag
默认1s。每个chunk拷贝完成后，会查看所有复制Slave的延迟情况。要是延迟大于该值，则暂停复制数据，直到所有从的滞后小于这个值，使用Seconds_Behind_Master。如果有任何从滞后超过此选项的值，则该工具将睡眠--check-interval指定的时间，再检查。如果从被停止，将会永远等待，直到从开始同步，并且延迟小于该值。如果指定--check-slave-lag，该工具只检查该服务器的延迟，而不是所有服务器。

--check-slave-lag
指定一个从库的DSN连接地址,如果从库超过--max-lag参数设置的值,就会暂停操作。

--recursion-method
默认是show processlist，发现从的方法，也可以是host，但需要在从上指定report_host，通过show slave hosts来找到，可以指定none来不检查Slave。
METHOD       USES
===========  ==================
processlist  SHOW PROCESSLIST
hosts        SHOW SLAVE HOSTS
dsn=DSN      DSNs from a table
none         Do not find slaves
指定none则表示不在乎从的延迟。
--check-interval
默认是1。--max-lag检查的睡眠时间。

--[no]check-plan
默认yes。检查查询执行计划的安全性。

--[no]check-replication-filters
默认yes。如果工具检测到服务器选项中有任何复制相关的筛选，如指定binlog_ignore_db和replicate_do_db此类。发现有这样的筛选，工具会报错且退出。因为如果更新的表Master上存在，而Slave上不存在，会导致复制的失败。使用–no-check-replication-filters选项来禁用该检查。

--[no]swap-tables
默认yes。交换原始表和新表，除非你禁止--[no]drop-old-table。

--[no]drop-triggers
默认yes，删除原表上的触发器。 --no-drop-triggers 会强制开启 --no-drop-old-table 即：不删除触发器就会强制不删除原表。

--new-table-name
复制创建新表的名称，默认%T_new。

--[no]drop-new-table
默认yes。删除新表，如果复制组织表失败。

--[no]drop-old-table
默认yes。复制数据完成重命名之后，删除原表。如果有错误则会保留原表。

--max-load
默认为Threads_running=25。每个chunk拷贝完后，会检查SHOW GLOBAL STATUS的内容，检查指标是否超过了指定的阈值。如果超过，则先暂停。这里可以用逗号分隔，指定多个条件，每个条件格式： status指标=MAX_VALUE或者status指标:MAX_VALUE。如果不指定MAX_VALUE，那么工具会这只其为当前值的120%。

--critical-load
默认为Threads_running=50。用法基本与--max-load类似，如果不指定MAX_VALUE，那么工具会这只其为当前值的200%。如果超过指定值，则工具直接退出，而不是暂停。

--default-engine
默认情况下，新的表与原始表是相同的存储引擎，所以如果原来的表使用InnoDB的，那么新表将使用InnoDB的。在涉及复制某些情况下，很可能主从的存储引擎不一样。使用该选项会默认使用默认的存储引擎。

--set-vars
设置MySQL变量，多个用逗号分割。默认该工具设置的是： wait_timeout=10000 innodb_lock_wait_timeout=1 lock_wait_timeout=60

--chunk-size-limit
当需要复制的块远大于设置的chunk-size大小,就不复制.默认值是4.0，一个没有主键或唯一索引的表,块大小就是不确定的。

--chunk-time
在chunk-time执行的时间内,动态调整chunk-size的大小,以适应服务器性能的变化，该参数设置为0,或者指定chunk-size,都可以禁止动态调整。

--chunk-size
指定块的大小,默认是1000行,可以添加k,M,G后缀.这个块的大小要尽量与--chunk-time匹配，如果明确指定这个选项,那么每个块就会指定行数的大小.

--[no]check-plan
默认yes。为了安全,检查查询的执行计划.默认情况下,这个工具在执行查询之前会先EXPLAIN,以获取一次少量的数据,如果是不好的EXPLAIN,那么会获取一次大量的数据，这个工具会多次执行EXPALIN,如果EXPLAIN不同的结果,那么就会认为这个查询是不安全的。

--statistics
打印出内部事件的数目，可以看到复制数据插入的数目。

--dry-run
创建和修改新表，但不会创建触发器、复制数据、和替换原表。并不真正执行，可以看到生成的执行语句，了解其执行步骤与细节。--dry-run与--execute必须指定一个，二者相互排斥。和--print配合最佳。

--execute
确定修改表，则指定该参数。真正执行。--dry-run与--execute必须指定一个，二者相互排斥。

--print
打印SQL语句到标准输出。指定此选项可以让你看到该工具所执行的语句，和--dry-run配合最佳。

--progress
复制数据的时候打印进度报告，二部分组成：第一部分是百分比，第二部分是时间。

--quiet
-q，不把信息标准输出。
# 增加字段
pt-online-schema-change --user=root --host=172.16.5.150  --alter "ADD COLUMN content text TINYINT NOT NULL DEFAULT 0 " D=test,t=test --ask-pass --no-check-replication-filters --alter-foreign-keys-method=auto --recursion-method=none --print --execute
# 删除字段
pt-online-schema-change --user=root --host=172.16.5.150  --alter "DROP COLUMN content " D=aaa,t=test --ask-pass --no-check-replication-filters --alter-foreign-keys-method=auto --recursion-method=none --print --execute
# 修改字段
pt-online-schema-change --user=root --host=172.16.5.150  --alter "MODIFY COLUMN content TINYINT NOT NULL DEFAULT 1" D=test,t=test --no-check-replication-filters --alter-foreign-keys-method=auto --recursion-method=none --print --execute
# 字段改名
pt-online-schema-change --user=root --host=172.16.5.150  --alter "CHANGE COLUMN age address varchar(30)" D=test,t=test  --ask-pass  --no-check-alter --no-check-replication-filters --alter-foreign-keys-method=auto --recursion-method=none --print --execute
# 增加索引
pt-online-schema-change --user=root --host=172.16.5.150  --alter "ADD INDEX idx_address(id_number)" D=test,t=test  --ask-pass  --no-check-alter --no-check-replication-filters --alter-foreign-keys-method=auto --recursion-method=none --print --execute
# 删除索引
pt-online-schema-change --user=root --host=172.16.5.150  --alter "DROP INDEX idx_address" D=test,t=test --no-check-alter --no-check-replication-filters --alter-foreign-keys-method=auto --recursion-method=none --no-drop-old-table --print --execute
# 修改存储引擎
pt-online-schema-change --user=root --host=192.168.0.12  --alter "ENGINE = InnoDB" D=society_insurance_storage,t=user --ask-pass --no-check-alter --no-check-replication-filters --alter-foreign-keys-method=auto --recursion-method=none --no-drop-old-table --print --execute
```