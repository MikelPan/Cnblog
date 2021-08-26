### 账号恢复
#### mysql root密码忘记
修改mysql启动文件，加上跳过权限步骤--skip-grant-tables
```bash
## 修改启动文件
vim /usr/lib/systemd/system/mysqld.service
# Start main service
ExecStart=/usr/sbin/mysqld --skip-grant-tables --daemonize --pid-file=/var/run/mysqld/mysqld.pid $MYSQLD_OPTS
## 重启mysql
systemctl daemon-reload
systemctl restart mysqld
## 重启配置账号密码
mysql -uroot -h127.0.0.1 -p;
update user set authentication_string=PASSWORD("yfgj@2020#admin") where user="root";
flush privileges;
exit;
## 退出重新登录
mysql -uroot -h127.0.0.1 -p
```
### 表锁
#### 查看表锁情况
```sql
mysql> show status like 'Table%';
+----------------------------+----------+
| Variable_name              | Value    |
+----------------------------+----------+
| Table_locks_immediate      | 34843148 |
| Table_locks_waited         | 0        |
| Table_open_cache_hits      | 71       |
| Table_open_cache_misses    | 61       |
| Table_open_cache_overflows | 61       |
+----------------------------+----------+
5 rows in set (0.05 sec)

-- Table_locks_immediate 指的是能够立即获得表级锁的次数
-- Table_locks_waited 指的是不能立即获取表级锁而需要等待的次数，如果数量越大，说明锁等待多，有锁抢占情况
```
#### 查看正在被锁的表
```sql
mysql> show open tables where In_use;
Empty set (0.06 sec)
-- 查看当前进程
mysql> show processlist;
```
#### 系统表锁查询
```sql
select r.trx_isolation_level, r.trx_id waiting_trx_id,r.trx_mysql_thread_id waiting_trx_thread,
r.trx_state waiting_trx_state,lr.lock_mode waiting_trx_lock_mode,lr.lock_type waiting_trx_lock_type,
lr.lock_table waiting_trx_lock_table,lr.lock_index waiting_trx_lock_index,r.trx_query waiting_trx_query,
b.trx_id blocking_trx_id,b.trx_mysql_thread_id blocking_trx_thread,b.trx_state blocking_trx_state,
lb.lock_mode blocking_trx_lock_mode,lb.lock_type blocking_trx_lock_type,lb.lock_table blocking_trx_lock_table,
lb.lock_index blocking_trx_lock_index,b.trx_query blocking_query
from information_schema.innodb_lock_waits w inner join information_schema.innodb_trx b on b.trx_id=w.blocking_trx_id
inner join information_schema.innodb_trx r on r.trx_id=w.requesting_trx_id
inner join information_schema.innodb_locks lb on lb.lock_trx_id=w.blocking_trx_id
inner join information_schema.innodb_locks lr on lr.lock_trx_id=w.requesting_trx_id \G

-- 说明
information_shcema下的三张表（通过这三张表可以更新监控当前事物并且分析存在的锁问题）
—— innodb_trx （ 打印innodb内核中的当前活跃（ACTIVE）事务）
—— innodb_locks （ 打印当前状态产生的innodb锁 仅在有锁等待时打印）
—— innodb_lock_waits （打印当前状态产生的innodb锁等待 仅在有锁等待时打印）

1) innodb_trx表结构说明 （摘取最能说明问题的8个字段）
字段名 说明
trx_id innodb存储引擎内部唯一的事物ID
trx_state 当前事物状态（running和lock wait两种状态）
trx_started 事物的开始时间
trx_requested_lock_id 等待事物的锁ID，如trx_state的状态为Lock wait，那么该值带表当前事物等待之前事物占用资源的ID，若trx_state不是Lock wait 则该值为NULL
trx_wait_started 事物等待的开始时间
trx_weight 事物的权重，在innodb存储引擎中，当发生死锁需要回滚的时，innodb存储引擎会选择该值最小的进行回滚
trx_mysql_thread_id mysql中的线程id, 即show processlist显示的结果
trx_query 事物运行的SQL语句

2）innodb_locks表结构说明
字段名 说明
lock_id 锁的ID
lock_trx_id 事物的ID
lock_mode 锁的模式（S锁与X锁两种模式）
lock_type 锁的类型 表锁还是行锁（RECORD）
lock_table 要加锁的表
lock_index 锁住的索引
lock_space 锁住对象的space id
lock_page 事物锁定页的数量，若是表锁则该值为NULL
lock_rec 事物锁定行的数量，若是表锁则该值为NULL
lock_data 事物锁定记录主键值，若是表锁则该值为NULL（此选项不可信）

3）innodb_lock_waits表结构说明
字段名 说明
requesting_trx_id 申请锁资源的事物ID
requested_lock_id 申请的锁的ID
blocking_trx_id 阻塞其他事物的事物ID
blocking_lock_id 阻塞其他锁的锁ID
```