## 1、环境准备
|序号|服务器主机名|硬件配置|外网IP地址|内网IP地址|操作系统|
|:----:|:----:|:----:|:----:|:----:|:----:|
|1|node01|8核32G|||Centos7.6|
|2|node02|8核32G|||Centos7.6|
|3|node03|8核32G|||Centos7.6|




### 创建存放数据目录
```bash
# root 账号
sudo -u hdfs hdfs dfs -mkdir /user/root
sudo -u hdfs hdfs dfs -chown root /user/root
# 非root账号
添加sudoers
sudo -u hdfs hdfs dfs -mkdir /user/root
sudo -u hdfs hdfs dfs -chown root /user/root
```
### 提交spark任务
```bash
spark-submit --class org.apache.spark.examples.SparkPi --master yarn \
--deploy-mode cluster /opt/cloudera/parcels/CDH-5.13.0-1.cdh5.13.0.p0.29/lib/spark/lib/spark-examples.jar 10
```
### 提交mapreduce应用
```bash
yarn jar /opt/cloudera/parcels/CDH-5.13.0-1.cdh5.13.0.p0.29/lib/hadoop-mapreduce/\
hadoop-mapreduce-examples-2.6.0-cdh5.13.0.jar pi 16 1000
```

### hdfs 命令使用
```bash
# 数据拷贝
sudo -u hdfs dfs -cp /user  dfs://f-xxxxxxxxxxxxxxx.cn-xxxxxxx.dfs.aliyuncs.com:10290/
# 数据迁移
sudo -u hdfs hadoop distcp hdfs://oldclusterip:8020/user  dfs://f-xxxxxxxxxxxxxxx.cn-xxxxxxx.dfs.aliyuncs.com:10290/
```


### 配置impala设置刷新元数据
- impala 配置

- hive 配置
```bash
# hive 高级配置代码段
<property>
    <name>hive.metastore.dml.events</name>
    <value>true</value>
    <description>set auto invalidate metadata on hive events</description>
</property>
# hive 客户端配置
<property>
    <name>hive.metastore.dml.events</name>
    <value>true</value>
    <description>set auto invalidate metadata on hive events</description>
</property>
# Hive Metastore Server 高级代码段
<property>
    <name>hive.metastore.notifications.add.thrift.objects</name>
    <value>true</value>
    <description>set auto invalidate metadata on hive events</description>
</property>
<property>
    <name>hive.metastore.alter.notifications.basic</name>
    <value>true</value>
    <description>set auto invalidate metadata on hive events</description>
</property>
```


### 重启flink任务
```bash
application_1630896756020_4760

curl -v -u admin:MMpyt63lZ8Jw http://datacenter-prod-cluster1-master:7180/api/v1/clusters/ddyw-datacenter-cdh-cluster/services

curl -v -u admin:MMpyt63lZ8Jw http://datacenter-prod-cluster1-master:7180/api/v1/clusters/ddyw-datacenter-cdh-cluster/services/yarn/yarnApplications

curl -v /cm/service
```
