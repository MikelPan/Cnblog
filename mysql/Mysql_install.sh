#!/bin/bash
# 创建用户
groupadd mysql
useradd -r -g mysql -s /bin/false mysql
# 创建数据目录
mkdir -p /data/mysql3306/{mysql,binlog,slowlog,tmp,log,run,conf}
mkdir -p /usr/local/mysql
chown -R mysql. /data/mysql3306
chown -R mysql. /usr/local/mysql
#### 写入配置文件
cat > /data/msyql3306/config/my.cnf <<EOF
[client]
port            = 3306
socket          =/data/mysql3306/run/mysql.sock

[mysql]
prompt="\u@node01\R:\m:\s [\d]> "   #  XXXX主机名
no-auto-rehash
socket=/data/mysql3306/run/mysql.sock

[mysqld]
####: for global
user                                =mysql                          #	mysql
basedir                             =/usr/local/mysql/              #	/usr/local/mysql/
datadir                             =/data/mysql3306/mysql    #	/usr/local/mysql/data
server_id                           =1                       #	0
socket                              =/data/mysql3306/run/mysql.sock
pid-file                            =/data/mysql3306/run/mysq.pid
port                                =3306                          #	3375
character_set_server                =utf8mb4                           #	latin1
explicit_defaults_for_timestamp     =off                            #    off
log_timestamps                      =system                         #	utc
read_only                           =0                              #	off
skip_name_resolve                   =1                              #   0
max_allowed_packet = 32M
lower_case_table_names              =1                              #	0
secure_file_priv                    =                               #	null
open_files_limit                    =65536                          #   1024
thread_stack = 512K
external-locking = FALSE
max_allowed_packet = 32M
sort_buffer_size = 4M
join_buffer_size = 4M
thread_cache_size = 768
max_connections                     =2000                           #   151
thread_cache_size                   =64                             #   9
table_open_cache                    =81920                          #   2000
table_definition_cache              =4096                           #   1400
table_open_cache_instances          =64                             #   16
max_prepared_stmt_count             =1048576                        #

####: for binlog
binlog_format                       =row                          #	row
log-bin                             =/data/mysql3306/binlog/mysql-bin
log-bin-index                       =/data/mysql3306/binlog/mysql-bin.index                      #	off
binlog_rows_query_log_events        =on                             #	off
log_slave_updates                   =on                             #	off
expire_logs_days                    =7                              #	0
binlog_cache_size                   =65536                          #	65536(64k)
#binlog_checksum                    =none                           #	CRC32
sync_binlog                         =0                              #	1
slave-preserve-commit-order         =ON                             #

####: for error-log
log_error                           =/data/mysql3306/log/error.log                        #	/usr/local/mysql/data/localhost.localdomain.err

general_log                         =off                            #   off
general_log_file                    =/data/mysql3306/log/general.log                    #   hostname.log

####: for slow query log
slow_query_log                      =on                             #    off
slow_query_log_file                 =/data/mysql3306/slowlog/slow.log                       #    hostname.log
log_queries_not_using_indexes       =on                             #    off
long_query_time                     =5                       #    10.000000
log_throttle_queries_not_using_indexes = 60
min_examined_row_limit = 100
log_slow_admin_statements = 1
log_slow_slave_statements = 1
####: for gtid
gtid_mode                           =on                            #	off
enforce_gtid_consistency            =on                            #	off


####: for replication
skip_slave_start                    =1                              #
master_info_repository              =table                         #	file
relay_log_info_repository           =table                         #	file
#relay_log_recovery                 =1
slave_parallel_type                 =logical_clock                 #    database | LOGICAL_CLOCK
slave_parallel_workers              =4                             #    0
#rpl_semi_sync_master_enabled       =1                             #    0
#rpl_semi_sync_slave_enabled        =1                             #    0
#rpl_semi_sync_master_timeout       =1000                          #    1000(1 second)
#plugin_load_add                    =semisync_master.so            #
#plugin_load_add                    =semisync_slave.so             #
#binlog_group_commit_sync_delay     =100                           #    500(0.05%秒)、默认值0
#binlog_group_commit_sync_no_delay_count = 10                       #    0

explicit_defaults_for_timestamp = 1
innodb_thread_concurrency = 0
innodb_sync_spin_loops = 100
innodb_spin_wait_delay = 30

transaction_isolation = REPEATABLE-READ
#innodb_additional_mem_pool_size = 16M
innodb_buffer_pool_size = 2000M
innodb_buffer_pool_instances = 4
innodb_buffer_pool_load_at_startup = 1
innodb_buffer_pool_dump_at_shutdown = 1
innodb_data_file_path = ibdata1:1G:autoextend
innodb_flush_log_at_trx_commit = 1
innodb_log_buffer_size = 32M
innodb_log_file_size = 2G
innodb_log_files_in_group = 2
innodb_max_undo_log_size = 4G
innodb_undo_directory = /data/mysql3306/undolog
innodb_undo_tablespaces = 95

# 根据您的服务器IOPS能力适当调整
# 一般配普通SSD盘的话，可以调整到 10000 - 20000
# 配置高端PCIe SSD卡的话，则可以调整的更高，比如 50000 - 80000
innodb_io_capacity = 4000
innodb_io_capacity_max = 8000
innodb_flush_neighbors = 0
innodb_write_io_threads = 8
innodb_read_io_threads = 8
innodb_purge_threads = 4
innodb_page_cleaners = 4
innodb_open_files = 65535
innodb_max_dirty_pages_pct = 50
innodb_flush_method = O_DIRECT
innodb_lru_scan_depth = 4000
innodb_checksum_algorithm = crc32
innodb_lock_wait_timeout = 10
innodb_rollback_on_timeout = 1
innodb_print_all_deadlocks = 1
innodb_file_per_table = 1
innodb_online_alter_log_max_size = 4G
internal_tmp_disk_storage_engine = InnoDB
innodb_stats_on_metadata = 0

# some var for MySQL 5.7
innodb_checksums = 1
#innodb_file_format = Barracuda
#innodb_file_format_max = Barracuda
query_cache_size = 0
query_cache_type = 0
innodb_undo_logs = 128

innodb_status_file = 1
# 注意: 开启 innodb_status_output & innodb_status_output_locks 后, 可能会导致log-error文件增长较快
innodb_status_output = 0
innodb_status_output_locks = 0
key_buffer_size = 32M
read_buffer_size = 8M
read_rnd_buffer_size = 4M
bulk_insert_buffer_size = 64M
lock_wait_timeout = 3600

#performance_schema
performance_schema = 1
performance_schema_instrument = '%=on'

#innodb monitor
innodb_monitor_enable="module_innodb"
innodb_monitor_enable="module_server"
innodb_monitor_enable="module_dml"
innodb_monitor_enable="module_ddl"
innodb_monitor_enable="module_trx"
innodb_monitor_enable="module_os"
innodb_monitor_enable="module_purge"
innodb_monitor_enable="module_log"
innodb_monitor_enable="module_lock"
innodb_monitor_enable="module_buffer"
innodb_monitor_enable="module_index"
innodb_monitor_enable="module_ibuf_system"
innodb_monitor_enable="module_buffer_page"
innodb_monitor_enable="module_adaptive_hash"

[mysqldump]
quick
max_allowed_packet = 32M
EOF
cat > /data/msyql3306/config/mysqld.service <<EOF
# Copyright (c) 2015, 2016, Oracle and/or its affiliates. All rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA
#
# systemd service file for MySQL forking server
#

[Unit]
Description=MySQL Server
Documentation=man:mysqld(7)
Documentation=http://dev.mysql.com/doc/refman/en/using-systemd.html
After=network.target
After=syslog.target

[Install]
WantedBy=multi-user.target

[Service]
User=mysql
Group=mysql

#Type=forking
Type=sample

PIDFile=/data/mysql3306/run/mysqld.pid

# Disable service start and stop timeout logic of systemd for mysqld service.
TimeoutSec=0

# Execute pre and post scripts as root
PermissionsStartOnly=true

# Needed to create system tables
#ExecStartPre=/usr/bin/mysqld_pre_systemd

# Start main service
ExecStart=/usr/local/mysql/bin/mysqld --daemonize --pid-file=/data/mysql3306/run/mysqld.pid $MYSQLD_OPTS

# Use this to switch malloc implementation
EnvironmentFile=-/etc/sysconfig/mysql

# Sets open_files_limit
LimitNOFILE = 65535

Restart=on-failure

RestartPreventExitStatus=1

PrivateTmp=false
EOF
#### 二、mysql二进制下载
yum install -y wget -c && wget https://cdn.mysql.com//Downloads/MySQL-5.7/mysql-5.7.26-linux-glibc2.12-x86_64.tar.gz -P /root/sofeware
tar zxf mysql-5.7.26-linux-glibc2.12-x86_64.tar.gz -C /usr/local/src
cp -r /usr/local/src/mysql-5.7.26-linux-glibc2.12-x86_64/* /usr/local/mysql
#### 配置环境变量
echo "export PATH=$PATH:/usr/local/mysql/bin" >> /etc/profile
source /etc/profile
#### 初始化
mysqld --defaults-file=/data/mysql3306/config/my.cnf --initialize --user=mysql --basedir=/usr/local/mysql --datadir=/data/mysql3306/mysql
#### 配置ssl
mysql_ssl_rsa_setup --basedir=/usr/local/mysql --datadir=/data/mysql3306/mysql
#### 开机启动
cp /data/mysql3306/config/mysqld.service /usr/lib/systemd/system/mysqld.service
systemctl enable mysqld
systemctl start