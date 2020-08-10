### skywalking 介绍
### skywalking　安装
#### 安装es
```bash
# 下载

# 修改系统配置
echo "vm.max_map_count=262144" > /etc/sysctl.conf
sysctl -p
# 安装elastic
## 创建账户数据目录
groupadd elastic
useradd -r -g elastic -s /bin/bash elastic
chown -R elastic. /usr/local/elasticsearch-7.8.0
mkdir -pv /data/elasticsearch/data
mkdir -pv /data/elasticsearch/logs
chown -R elastic. /data/elasticsearch
chown -R elastic. /data/elasticsearch
chown -R elastic. /usr/local/elasticsearch-7.8.0
## 添加es配置
cp /usr/local/elasticsearch-7.8.0/config/elasticsearch.yml /usr/local/elasticsearch-7.8.0/config/elasticsearch.yml.bak
cat >> /usr/local/elasticsearch-7.8.0/config/elasticsearch.yml <<EOF
# es config
cluster.name: scrm_es_cluster
node.name: node-1
path.data: /data/elasticsearch/data
path.logs: /data/elasticsearch/logs
network.host: 10.100.0.1
http.port: 9200
discovery.seed_hosts: ["127.0.0.1"]
cluster.initial_master_nodes: ["node-1"]
EOF
```
#### 安装es head
```bash
# 安装git
yum install -y git
# 安装npm
yum install -y npm
npm install -g cnpm --registry=https://registry.npm.taobao.org
npm config set registry https://registry.npm.taobao.org
# 安装es head
cd /usr/local && git clone git://github.com/mobz/elasticsearch-head.git
cd elasticsearch-head && npm install && /usr/bin/nohup npm run start &
```

#### 安装skywalking
```bash
# 下载skywalking
wget https://mirrors.tuna.tsinghua.edu.cn/apache/skywalking/8.0.0/apache-skywalking-apm-es7-8.0.0.tar.gz -P /apps/software
# 解压
cd /apps/software && tar zxvf apache-skywalking-apm-es7-8.0.0.tar.gz -C /usr/local
# 修改配置
## 备份初始配置
cp /usr/local/apache-skywalking-apm-bin-es7/config/application.yml /usr/local/apache-skywalking-apm-bin-es7/config/application.yml.back
## 修改配置
vim /usr/local/apache-skywalking-apm-bin-es7/config/application.yml
storage:
  #selector: ${SW_STORAGE:h2}
  selector: elasticsearch7
  elasticsearch:
    nameSpace: ${SW_NAMESPACE:"scrm_es_cluster"}
    clusterNodes: ${SW_STORAGE_ES_CLUSTER_NODES:localhost:9200}
# 启动oapserver
/usr/local/apache-skywalking-apm-bin-es7/bin/oapService.sh
# 启动webappserver
## 修改监听端口
sed -i 's/8080/9400/g' /usr/local/apache-skywalking-apm-bin-es7/webapp/webapp.yml
## 启动webappserver
/usr/local/apache-skywalking-apm-bin-es7/bin/webappService.sh
```
#### 安装skywalking　agent数据采集
```bash
# 拷贝agent 包
scp -r /usr/local/apache-skywalking-apm-bin-es7/agent root@localhost:/apps/srv
# 运行jar包
/usr/bin/nohup jar -Dskywalking.agent.service_name=$package_name -Dskywalking.agent.instance_name=${package_name}_$HOSTNAME -Dskywalking.collector.backend_service=$skywalking_service:11800 -javaagent:/apps/srv/agent/skywalking-agent.jar -jar test.jar > /apps/srv/test.log 2>&1 &
```
#### 安装skywalking 报警
##### 制作Dockerfile
```bash
cat > Dockerfile <<EOF
#FROM registry.szcasic.com/python/flask:2.7.17-alpine3.10
#FROM registry.cn-shenzhen.aliyuncs.com/k8s-kubeadm/python2-flask:2.7.17-alpine3.10

WORKDIR /apps
COPY ./app.py /apps

CMD ["python","app.py"]
EOF
```
#### 查询es数据
```bash
# 查询集群运行情况
curl -v 'localhost:9200/_cat/health?v'
# 查询索引
curl -v 'localhost:9200/_cat/indices?v'
# 查询数据
curl -v 'localhost:9200/cpm-20200723/_search?pretty=true'
```





