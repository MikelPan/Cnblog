### mongo简介及安装
#### mongo介绍
MongoDB 是由C++语言编写的，是一个基于分布式文件存储的开源数据库系统。

在高负载的情况下，添加更多的节点，可以保证服务器性能。

```bash
# 创建角色
db.createUser({
  user : 'admin',
  pwd : 'xxxxx',
  roles : [
    'clusterAdmin',
    'dbAdminAnyDatabase',
    'userAdminAnyDatabase',
    'readWriteAnyDatabase'
  ]
})
# 创建数据库
use DATABASE_NAME
# 插入数据
db.runoob.insert({"name":"你家人来找你了"})
# 删除数据
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
#### mongosh 使用
```bash
# 下载
wget https://downloads.mongodb.com/compass/mongosh-0.1.0-linux.tgz
# 连接
主节点: mongo mongodb://mongodb0.example.com.local:27017
从节点: mongo mongodb://mongodb1.example.com.local:27017
副本集: mongo "mongodb://mongodb0.example.com.local:27017,mongodb1.example.com.local:27017,mongodb2.xample.com.local:27017/?replicaSet=replA"
```　
