### mongo简介及安装
#### mongo介绍
MongoDB 是由C++语言编写的，是一个基于分布式文件存储的开源数据库系统。

在高负载的情况下，添加更多的节点，可以保证服务器性能。

MongoDB 旨在为WEB应用提供可扩展的高性能数据存储解决方案。

MongoDB 将数据存储为一个文档，数据结构由键值(key=>value)对组成。MongoDB 文档类似于 JSON 对象。字段值可以包含其他文档，数组及文档数组
```shell
{
   name:"sue",
   age:23,
   status:"A",
   groups:["news","sports"]
}
```
#### mongo安装
详情见[官网](https://www.mongodb.com/download-center#community) 
```shell
# 下载二进制文件
yum install libcurl openssl
wget https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-4.0.4.tgz
# 下载地址
https://repo.mongodb.org/yum/redhat/7/mongodb-org/4.0/x86_64/RPMS/mongodb-org-server-4.0.4-1.el7.x86_64.rpm
https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-4.0.4.tgz
mkdir -pv /usr/local/mongodb
tar zxvf mongodb-linux-x86_64-4.0.4.tgz -C /usr/local/src
mv /usr/local/src/mongodb-linux-x86_64-4.0.4 /usr/local/mongodb
echo 'export PATH=/usr/local/mongodb/bin:$PATH' >> /etc/profile
source /etc/profile
# 创建mongodb数据库目录
 mkdir -pv /data/mongo/db
 mkdir -pv /data/mongo/mongodb.cnf
 mkdir -pv /data/mongo/mongo.log
 # 创建启动配置文件
 vim /data/mongo/mongodb.cnf
 ---------------------------------------start-------------------------------------
 dbpath=/data/momgo/db
 logpath=/data/momgo/momgo.log
 logappend=true
 fork=true
 port=27017
 # 启动mongo
mongod --auth -f /data/mongo/mongodb.cnf
 # 进入mongo管理控制台
mongo
# 配置开机启动
vim /etc/systemd/system/mongod.service
----------------------------------------start----------------------------------------
[Unit]
Description=mongodb
After=network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
ExecStart=/usr/local/mongodb/bin/mongod --config /servers/db/mongo/mongodb.cnf
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/usr/local/mongodb/bin/mongod --shutdown --config /servers/db/mongo/mongodb.cnf
PrivateTmp=true
[Install]
WantedBy=multi-user.target
----------------------------------------end-------------------------------------------
systemctl enable mongod.servcie
systemctl start mongod
```
#### mongodb使用
```bash
# 创建数据库
use DATABASE_NAME
# 插入数据
db.runoob.insert({"name":"你家人来找你了"})
# 删除数据库
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
