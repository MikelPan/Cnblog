### 一、mysql冷备及恢复
#### 1.1、冷备
```shell
# 停止mysql
mysqladmin -uroot -proot123 shutdown
# 拷贝数据文件
scp -r /data/mysql root@back ip:/root
cp -r /data/mysql /本地新目录
```
#### 1.2、恢复
将已经备份的数据目录替换到原有的目录, 重启mysql服务

### 二、mysql热备及恢复
#### 2.1、mysqldump备份及恢复
1、mysqldump 参数说明
- --single-transaction

用于保证InnoDB备份数据时的一致性，配合RR隔离级别一起使用；当发起事务时，读取一个数据的快照，直到备份结束，都不会读取到本事务开始之后提交的任何数据

- --all-databases （-A）

  备份所有的数据库

- --master-data

  该值有两个，如果等于1，在备份文件中添加一个CHANGE MASTER的语句，如果等于2，在备份的文件中添加一个CHANGE MASTER的语句，并在语句前添加注释

2、mysqldump备份与恢复

- 备份全库
```mysql
mysqldump --single-transaction -uroot -proot123 -A > all.sql
mysqldump --single-transaction -uroot -proot123 --set-gtid-purged=OFF -A > all.sql # 开启gtid同步
mysqldump --single-transaction -uroot -proot123 --skip-gtids -A > all.sql # 开启gtid同步
```
- 恢复全库
```mysql
mysql -uroot -proot123 < all.sql
```
- 备份单个库
```mysql
mysqldump --single-transaction -uroot -proot123 db1 > db1.sql
```
- 恢复单个库
```mysql
mysql -uroot -proot123 db1 < db1.sql

# 如果db1 不存在，需要到数据库中创建数据库db1
create database db1
```
- 备份单表
```mysql
mysqldump --single-transaction -uroot -proot123 db1 t >t.sql
```
- 恢复单表
```mysql
mysql -uroot -proot123 db1 < t.sql
```
- 备份db1库t表中的表结构信息
```mysql
mysqldump --single-transcation -uroot -proot123 db1 t -d > t.sql
```
- 备份db1库t表中的数据信息
```mysql
mysqldump --single-transcation -uroot -proot123 db1 t -t > t.sql
```
- 备份db1库t表中id>3 的记录
```mysql
mysqldump --single-transcation -uroot -proot123 db1 t --where="id>3" > t.sql
```
3、select ... into outfile
- 备份tt 表中的数据全部导出到/tmp目录下
```mysql
select * from tt into outfile '/tmp/tt.sql'
```
- load data 导入数据
```mysql
# 删除数据
delete from tt
load data infile '/tmp/tt.sql' into table db1.tt
# 在服务器上直接执行导入数据
mysql -uroot -proot123 -e "load data infile '/tmp/test1.sql' into table db1.test1"
```
4、mydumper
- mydumper安装
```shell
# 安装依赖
yum install -y glib2-devel mysql-devel zlib-devel pcre-devel openssl-devel
# 安装mydumper
wget https://github.com/maxbube/mydumper/releases/download/v0.9.5/mydumper-0.9.5-2.el7.x86_64.rpm
yum install -y mydumper-0.9.5-2.el7.x86_64.rpm
```
- mydumper备份
```shell
# 备份全库
mydumper -u root -p root123 -h host -P port -o /data/backup
# 还原全库
myloader -u root -p root123 -h host -P port -d /data/backup
```
- mydumper备份db1库下tt表
```shell
# 备份
mydumper -u root -p root123 -h host -P port -B db1 -T tt -o /data/backup
# 恢复
myloader -u root -p root123 -h host -P port -B db1 -o tt -d /data/backup
```
5、XtraBackup备份
- XtraBackup 安装
```shell
下载地址： https://www.percona.com/downloads/Percona-XtraBackup-LATEST/
# 安装8.0
wget https://www.percona.com/downloads/Percona-XtraBackup-LATEST/Percona-XtraBackup-8.0.4/binary/redhat/7/x86_64/percona-xtrabackup-80-8.0.4-1.el7.x86_64.rpm
yum install -y percona-xtrabackup-80-8.0.4-1.el7.x86_64.rpm
# 安装2.4
wget https://www.percona.com/downloads/Percona-XtraBackup-2.4/Percona-XtraBackup-2.4.13/binary/redhat/7/x86_64/percona-xtrabackup-24-2.4.13-1.el7.x86_64.rpm
yum install -y  percona-xtrabackup-24-2.4.13-1.el7.x86_64.rpm
```
- 全备
```shell
# 创建备份用户名和密码
create user 'repl'@'192.168.5.%' identified by 'repl@back'
# 添加权限
grant reload,lock tables,replication client,process,super on *.* to 'repl'@'192.168.5.%'
# 添加权限最小化
grant reload,lock tables,replication client,process on *.* to 'replback'@'localhost' identified by 'repl@2019#back';
flush privileges
# 创建备份目录
mkdir -p /data/mysql_backup
# 备份
innobackupex --defaults-file=/etc/my.cnf --no-timestamp --user repl --host 172.16.5.123 --password Password1 /data/mysql_back/all-20190216bak
# 流试压缩备份
innobackupex --defaults-file=/etc/my.cnf --no-timestamp --user replback --host 192.168.0.12 --password  --stream=tar /work/Monitoring | gzip - > /work/Monitoring/all-20190528.tgz
```

- 全备恢复
```shell
# 校验
innobackupex --defaults-file=/etc/my.cnf --user repl --host 172.16.5.123 --password repl --apply-log /data/mysql_back/all-20190216bak
# 停止mysql
mysqladmin -uroot -proot123 shutdown
# 数据拷贝
mv /data/mysql /data/mysql_back
cd  /data/
mv all-20190216bak/ mysql
chown -R mysql:mysql mysql
# 启动mysql
mysqld_safe --defaults-file=/etc/my.cnf &
```
- 增量备份
```shell
# 创建全备
innobackupex --defaults-file=/etc/my.cnf --no-timestamp --user repl --host 172.16.5.123 --password Password1 /data/mysql_back/all-20190216bak
# 创建增量备份
innobackupex --defaults-file=/etc/my.cnf --no-timestamp --user repl --host 172.16.5.123 --password Password1 --incremental /data/mysql_back/all-20190217incr --incremental-basedir=/data/mysql_back/all-20190216bak
```
- 增量恢复
```shell
# 恢复全备
innobackupex --defaults-file=/etc/my.cnf --no-timestamp --user repl --host 172.16.5.123 --password Password1 --apply-log --redo-only /data/mysql_back/all-20190216bak
# 恢复增量备份
innobackupex --defaults-file=/etc/my.cnf --no-timestamp --user repl --host 172.16.5.123 --password Password1 --apply-log --redo-only /data/mysql_back/all-20190216bak --incremental-dir=/data/mysql_back/all-20190217incr
# 将新的全备文件进行一次性恢复
innobackupex --defaults-file=/etc/my.cnf --no-timestamp --user repl --host 172.16.5.123 --password Password1 --apply-log /data/mysql_back/all-20190216bak
# 停止mysql
mysqladmin -uroot -proot123 shutdown
# 数据拷贝
mv /data/mysql /data/mysql_back
cd /data
mv all-20190216bak/ mysql
chown -R mysql:mysql mysql
# 启动mysql
mysqld_safe --defaults-file=/etc/my.cnf &
```
### 三、msyql误删恢复
#### 3.1、使用binlog2sql删除表恢复
##### 安装binlog2sql软件
```shell
# 安装pip
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
python get-pip.py
git clone https://github.com/danfengcao/binlog2sql.git && cd binlog2sql
pip install -r requirements.txt
# 修改my.cnf配置文件
max_binlog_size = 1G
binlog_row_image = full
# 添加权限
create user 'binlog2sql'@'172.16.5.%' identified by 'Password1'
GRANT SELECT, REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'binlog2sql'@'172.16.5.%'
flush privileges
```
##### 使用binlog2sql解析mysql

**解析出标准SQL**
```mysql
python binlog2sql/binlog2sql.py -h172.16.5.123 -P3306 -ubinlog2sql -pPassword1 -dtest -t test_account --start-file='mysql-bin.000008'
```

##### 选项

**mysql连接配置**

-h host; -P port; -u user; -p password

**解析模式**

--stop-never 持续解析binlog。可选。默认False，同步至执行命令时最新的binlog位置。

-K, --no-primary-key 对INSERT语句去除主键。可选。默认False

-B, --flashback 生成回滚SQL，可解析大文件，不受内存限制。可选。默认False。与stop-never或no-primary-key不能同时添加。

--back-interval -B模式下，每打印一千行回滚SQL，加一句SLEEP多少秒，如不想加SLEEP，请设为0。可选。默认1.0。

**解析范围控制**

--start-file 起始解析文件，只需文件名，无需全路径 。必须。

--start-position/--start-pos 起始解析位置。可选。默认为start-file的起始位置。

--stop-file/--end-file 终止解析文件。可选。默认为start-file同一个文件。若解析模式为stop-never，此选项失效。

--stop-position/--end-pos 终止解析位置。可选。默认为stop-file的最末位置；若解析模式为stop-never，此选项失效。

--start-datetime 起始解析时间，格式'%Y-%m-%d %H:%M:%S'。可选。默认不过滤。

--stop-datetime 终止解析时间，格式'%Y-%m-%d %H:%M:%S'。可选。默认不过滤。

**对象过滤**

-d, --databases 只解析目标db的sql，多个库用空格隔开，如-d db1 db2。可选。默认为空。

-t, --tables 只解析目标table的sql，多张表用空格隔开，如-t tbl1 tbl2。可选。默认为空。

--only-dml 只解析dml，忽略ddl。可选。默认False。

--sql-type 只解析指定类型，支持INSERT, UPDATE, DELETE。多个类型用空格隔开，如--sql-type INSERT DELETE。可选。默认为增删改都解析。用了此参数但没填任何类型，则三者都不解析。

##### 应用案例

**误删除整张表数据，需要紧急回滚**

```shell
# 查看表数据
select count（1） from auth_menu;
+----------+
| count(1) |
+----------+
|       42 |
+----------+
# 清楚记录
delete from auth_menu;
# 查看记录
+----------+
| count(1) |
+----------+
|        0 |
+----------+
```
**恢复数据步骤**

1、查看binlog日志
```shell
show master status;
+------------------+----------+--------------+------------------+---------------------------------------------+
| File             | Position | Binlog_Do_DB | Binlog_Ignore_DB | Executed_Gtid_Set                           |
+------------------+----------+--------------+------------------+---------------------------------------------+
| mysql-bin.000012 |     3005 |              |                  | be9d0501-30fb-11e9-b2ec-000c29e37447:1-4085 |
+------------------+----------+--------------+------------------+---------------------------------------------+
```
2、通过大致时间定位binlog位置
```shell
python binlog2sql/binlog2sql.py -h172.16.5.123 -P3306 -ubinlog2sql -pPassword1 -dtest -tauth_menu --start-file='mysql-bin.000012' --start-datetime='2019-02-19 15:33:00' --stop-datetime='2019-02-19 15:40:00'
# 输出
#start 902 end 2974 time 2019-02-19 15:35:36
```
3、过滤生成要回滚的sql
```shell
python binlog2sql/binlog2sql.py -h172.16.5.123 -P3306 -ubinlog2sql -pPassword1 -dtest -tauth_menu --start-file='mysql-bin.000012' --start-position=902 --stop-position=2974 -B > rollback.sql | cat
```
4、执行回滚语句，并检查是否正确
```shell
# 执行回滚语句
mysql -uroot -p < rollback.sql
# 登录数据库查看记录条数
mysql -uroot -p
select count(1) from auth_menu;
+----------+
| count(1) |
+----------+
|       42 |
+----------+
```
#### 3.2、使用binlog恢复误删除表
1、删除表
```shell
delete from auth_menu;
```
2、全备库
```shell
mysqldump -uroot -pPassword1 --single-transaction  --master-data=2 db1 > /root/db.sql
# 查看post
cat db.sql |grep -i "change"
-- CHANGE MASTER TO MASTER_LOG_FILE='mysql-bin.000012', MASTER_LOG_POS=28945;
```
##### 3、 解析binlog
```shell
# 通过binlog
mysqlbinlog -vv --base64-output=DECODE-ROWS --start-position=28945 -d db1 mysql-bin.000012 > /root/test1.sql
# 通过grep
mysqlbinlog -vv --base64-output=decode-rows  server08-relay-bin.000752 | grep -C 60 '503948823'
```
#### 3.3、使用mysqlfrm恢复数据表结构
```shell
# 下载安装mysqlfrm
wget https://cdn.mysql.com/archives/mysql-utilities/mysql-utilities-1.6.5-1.el7.noarch.rpm
# 获取表结构
mysqlfrm --diagnostic ./frm/
# 创建表结构
# 卸载表空间
ALTER TABLE 表名 DISCARD TABLESPACE
systemctl stop mysqld
# 拷贝ibd文件到数据目录
chmod -R mysql. /data
systemctl start mysqld
# 装载表空间
ALTER TABLE 表名 IMPORT TABLESPACE
```