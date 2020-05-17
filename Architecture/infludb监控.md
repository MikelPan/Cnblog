### infludb介绍
### telegraf安装
```bash
# yum 安装
wget https://dl.influxdata.com/telegraf/releases/telegraf-1.14.2-1.x86_64.rpm
yum localinstall -y telegraf-1.14.2-1.x86_64.rpm
systemctl start telegraf
# 二进制安装
wget https://dl.influxdata.com/telegraf/releases/telegraf-1.14.2_linux_amd64.tar.gz -P /apps/software
tar zxvf /apps/software/telegraf-1.14.2_linux_amd64.tar.gz -C /usr/local/src
```
### 配置telegraf连接influxdb
```bash
vim /etc/telegraf/telegraf.conf
# 数据源配置
[[outputs.influxdb]]
  urls = ["http://192.168.0.244:8086"]  #infulxdb地址
  database = "telegraf" #数据库
  precision = "s"
  timeout = "5s"
  username = "telegraf" #帐号
  password = "zmR6Mbup49gJ2oPm95T0o33f" #密码
# cpu配置
[[inputs.cpu]]
  ## Whether to report per-cpu stats or not
  percpu = true
  ## Whether to report total system cpu stats or not
  totalcpu = true
# 查询进程的cpu,mem
ps aux | head -1; ps aux | sort -rnk 4 | awk '{if($11 =="java" && $12 ~ /jar/){print $0}}' #安装内存排序
ps aux | head -1; ps aux | sort -rnk 4 | awk '{if($11 =="java" && $12 ~ /jar/){print $0}}' #安装cpu排序

```
### 安装chronograf
```bash
# yum安装
wget https://dl.influxdata.com/chronograf/releases/chronograf-1.8.4.x86_64.rpm
sudo yum localinstall chronograf-1.8.4.x86_64.rpm
# 二进制安装
wget https://dl.influxdata.com/chronograf/releases/chronograf-1.8.4_linux_arm64.tar.gz
tar xvfz chronograf-1.8.4_linux_amd64.tar.gz
```
wget https://dl.influxdata.com/kapacitor/releases/kapacitor-1.5.5-1.x86_64.rpm
sudo yum localinstall kapacitor-1.5.5-1.x86_64.rpm
### infludb安装
```bash
# yum安装
wget https://dl.influxdata.com/influxdb/releases/influxdb-1.8.0.x86_64.rpm
yum localinstall -y influxdb-1.8.0.x86_64.rpm
systemctl start infludb
# 二进制安装
wget https://dl.influxdata.com/influxdb/releases/influxdb-1.8.0_linux_amd64.tar.gz -P /apps/software
tar xvfz influxdb-1.8.0_linux_amd64.tar.gz -C /usr/local/src
```
### 创建数据库
```bash
# 创建密码
cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 24
influx
create database telegraf;
create user telegraf with password 'zmR6Mbup49gJ2oPm95T0o33f';
grant all on telegraf to telegraf;
CREATE RETENTION POLICY "telegraf_retention" ON "telegraf" DURATION 30d REPLICATION 1 DEFAULT;
quit
```
### 访问infludb console

### 安装grafana
```bash
# yum 安装
wget https://dl.grafana.com/oss/release/grafana-6.7.3-1.x86_64.rpm 
yum install grafana-6.7.3-1.x86_64.rpm
systemctl enable grafana-server
systemctl start grafana-server
# 二进制安装
wget https://dl.grafana.com/oss/release/grafana-6.7.3.linux-amd64.tar.gz -P /apps/software
tar -zxvf grafana-6.7.3.linux-amd64.tar.gz -C /usr/local/src
```
### 配置查询
```bash
SELECT host , pid, memory_vms, memory_rss, memory_swap, cpu_usage, cpu_time_user, process_name FROM "procstat" WHERE "host" =~ /$hostname$/ AND $timeFilter
SELECT host, pid,memory_vms, memory_rss, memory_usage,cpu_usage, cpu_time_user,num_threads,process_name FROM "procstat" WHERE "host" =~ /$hostname$/ AND $timeFilter AND process_name='java'
```