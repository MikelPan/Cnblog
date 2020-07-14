### 一、mysql主从同步原理

Mysql主从复制也可以称为Mysql主从同步，它是构建数据库高可用集群架构的基础。它通过将一台主机的数据复制到其他一台或者多台主机上，并重新应用日志（**realy log**）中的SQL语句来实现复制功能。Mysql支持单向，双向，链式级联，异步复制，复制过程中一台服务器充当主库（master），而一个或者多个服务器充当从库（slave）

#### 1.1、主从复制功能
主从复制原理：master服务器上工作线程I/O dump thread，从服务器上两个工作线程，一个是I/O thread，另一个是SQL thread。
主库把外界接收到的SQL请求记录到自己的binlog日志中，从库的I/O thread去请求主库的binlog日志，并将得到的binlog日志写到自己的Realy log（中继日志）文件中。然后在从库上重做应用中继日志中的SQL语句。主库通过I/O dump thread 给从库I/O thread 传送binlog日志。

#### 1.2、复制中的参数详解
- log-bin：搭建主从复制，必须开启二进制日志
- server-id：mysql在同一组主从结构中的唯一标识
- sever-uuid：存放在数据目录中的auto.cnf中
- read only：设置从库为只读转态
- binglog_format: 二进制日志的格式，使用row模式
- log_salve_updates: 将master服务器上获取的数据信息记录到从服务器的二进制日志文件中
- binglog-db-db：选择性复制数据库（在主库上使用）
- binglog-ignore-db： 忽略某个库的复制
- gtid_mode: gtid模式是否开启，使用gtid模式，设置gtid_mode=on
- enforce-gtid-consistency: 使用gtid复制，开启，enforce-gtid-consistency=on

### 二、mysql主从复制（binlog）
2.1、修改主库配置文件
```shell
vim /etc/my.cnf
[mysqld]
####: for binlog
server-id=1
binlog_format                       =row                          #     row
log-bin                             =/data/mysqlData/binlog/mysql-bin
log-bin-index                       =/data/mysqlData/binlog/mysql-bin.index                      #      off
binlog_rows_query_log_events        =on                             #   off
log_slave_updates                   =on                             #   off
expire_logs_days                    =7                              #   0
binlog_cache_size                   =65536                          #   65536(64k)
#binlog_checksum                    =none                           #  CRC32
sync_binlog                         =0                              #   1
slave-preserve-commit-order         =ON                             #
```
2.2、主库上执行操作
```shell
# 创建主从复制账号
create user 'repl'@'192.168.5.%' identified by 'repl@2019#pl';
grant replication slave on *.* to 'repl'@'192.168.5.%';
flush privileges;
# 导出主库数据
mysqldump --single-transaction -uroot -proot123 --master-data=2 --flush-logs --events --triggers --routines -A > all.sql
# 记录binlog文件和position号
head -n 30 all.sql | grep "MASTER_LOG_FILE"
head -n 30 all.sql  | grep "MASTER_LOG_POS"
# 备份文件传递到从服务器上
scp all.sql root@slave:/root/
```
2.3、修改从库的配置文件
```shell
server_id                           = 2
binlog-ignore-db                    =mysql
binlog_format                       =row
log-bin =                           =/data/mysqlData/binlog/slave1-bin
log-bin-index                       =/data/mysqlData/binlog/salve1-bin.index
log-slave-updates                   =on
expire_logs_days                    =7
sync_binlog                         = 0
relay_log                           =/data/mysqlData/relaylog/relay-bin
log_slave_updates                   =1
```
2.4、配置主从
```shell
# 导入数据
mysql -uroot -proot123 < all.sql
# 重置主从
reset slave all
# 数据库命名执行配置
CHANGE MASTER TO
MASTER_HOST='192.168.248.137',
MASTER_USER='repl',
MASTER_PASSWORD='repl@2019#pl',
MASTER_PORT=3306,
MASTER_LOG_FILE='mysql-bin.000004',
MASTER_LOG_POS=3034;
# 开启主从
start salve
# 查看主从复制状态
show slave status\G
```
### 三、mysql主从复制 （gtid）
#### 3.1、修改主库配置文件
```shell
vim /etc/my.cnf
[mysqld]
####: for binlog
server-id=1
binlog_format                       =row                          #     row
log-bin                             =/data/mysqlData/binlog/mysql-bin
log-bin-index                       =/data/mysqlData/binlog/mysql-bin.index                      #      off
binlog_rows_query_log_events        =on                             #   off
log_slave_updates                   =on                             #   off
expire_logs_days                    =7                              #   0
binlog_cache_size                   =65536                          #   65536(64k)
#binlog_checksum                    =none                           #  CRC32
sync_binlog                         =0                              #   1
slave-preserve-commit-order         =ON                             #

####: gitd
gtid-mode = ON
enforce-gtid-consistency = ON
```
#### 3.2、主库上执行操作
```shell
# 创建主从复制账号
create user 'repl'@'192.168.5.%' identified by 'repl@2019#pl'
grant replication slave *.* to 'repl'@'192.168.5.%'
flush privileges
# 导出主库数据
mysqldump --single-transaction -uroot -proot123 --opt --master-data=2 --flush-logs --events --triggers --routines -A > all.sql
```
#### 3.3、修改mysql从服务器配置
```shell
server_id                           = 2
binlog-ignore-db                    =mysql
binlog_format                       =row
log-bin =                           =/data/mysqlData/binlog/slave-bin
log-bin-index                       =/data/mysqlData/binlog/salve-bin.index
log-slave-updates                   =on
expire_logs_days                    =7
sync_binlog                         = 0
relay_log                           =/data/mysqlData/relaylog/relay-bin
read_only                           =1
log_slave_updates                   =1


####: gitd
gtid-mode = ON
enforce-gtid-consistency = ON
```
#### 3.4、配置主从
```shell
# 清空 gtid_executed
reset master
# 数据导入
mysql -uroot -proot123 < all.sql
# 配置主从
CHANGE MASTER TO
MASTER_HOST='192.168.248.137',
MASTER_USER='repl',
MASTER_PASSWORD='repl@2019#pl',
MASTER_PORT=3306,
MASTER_AUTO_POSITION = 1；
# 开启主从
start slave
# 查看主从复制状态
show slave status\G
```
#### 3.5、跳过事务
```shell
stop slave
set gtid_next='f75ae43f-3f5e-11e7-9b98-001c4297532a:20'
begin
commit
set gtid_next='AUTOMATIC'
start slave
```
### 四、mysql从传统模式改为gtid
#### 4.1、修改全局变量
```shell
1、修改enforce_gtid_consistency为warn
set global enforce_gtid_consistency=warn;
2、修改enforce_gtid_consistency为on
set global enforce_gtid_consistency=on;
3、修改gtid模式为off_permissive
set global gtid_mode=off_permissive;
4、修改gtid模式为on_permissive
set global gtid_mode=on_permissive;
5、确认从库的onging_anonymous_transaction_count参数是否为0
show global status like '%ongoing_anonymous_%';
6、开启gtid
set global gtid_mode=on;
7、开启主从复制
stop slave
change master to master_auto_position=1;
start slave
```
#### 4.2、修改my.cnf配置文件
```shell
# 主库添加配置
gtid_mode=on
enforce_gtid_consistency=on
# 主库添加配置
gtid_mode=on
enforce_gtid_consistency=on
log_slave_updates=1
```
#### 4.3、数据导出导入
```shell
# 主库数据导出
mysqldump --single-transaction -uroot -proot123 --opt --master-data=2 --flush-logs --events --triggers --routines -A > all.sql
# 从库数据导入
systemctl restart mysqld
reset 
mysql -uroot -p < all.sql
```
#### 4.4、从库开启主从
```shell
reset master
# 配置msater主机信息
CHANGE MASTER TO
MASTER_HOST='192.168.0.12',
MASTER_USER='repl',
MASTER_PASSWORD='password',
MASTER_PORT=3306,
MASTER_AUTO_POSITION = 1;
# 开启主从
start slave
```
#### 4.5、gtid跳过事件
##### 方法一
```shell
# 查看gtid_next的值
show variables like '%next%';
# 停止从库
stop slave;
# 修改gtid为下一个值
set gtid_next='6a5a698f-18eb-11e9-afa0-6c92bf45c92e:17';
begin
commit
SET GTID_NEXT="AUTOMATIC";
start slave;
show slave status;
```
##### 方法二
```shell
# 重置master
stop slave;
reset master;
SET @@GLOBAL.GTID_PURGED ='8f9e146f-0a18-11e7-810a-0050568833c8:1-4;
START SLAVE;
```
##### 方法三
```shell
# pt 忽略错误码
pt-slave-resetart -S /var/lib/mysql/mysql.sock —error-numbers=1062 --user=root --password='bc.123456'
# pt 忽略错误信息
pt-slave-resetart -S /var/lib/mysql/mysql.sock —error-numbers=1062 --user=root --password='bc.123456'
```

```