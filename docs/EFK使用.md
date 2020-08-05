#### 一、安装java环境
```shell
# 下载jdk软件包
wget https://download.oracle.com/otn/java/jdk/8u212-b10/59066701cf1a433da9770636fbc4c9aa/jdk-8u212-linux-x64.tar.gz
tar zxvf jdk-8u212-linux-x64.tar.gz -C /usr/local/src
mv /usr/local/src/jdk-8u212 /usr/local/jdk-8u212
# 配置java环境变量
cat >> /etc/prifile <<EOF
JAVA_HOME=/usr/local/jdk1.8.0_212/
JRE_HOME=$JAVA_HOME/jre
CLASS_PATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar:$JRE_HOME/lib
PATH=$PATH:$JAVA_HOME/bin:$JRE_HOME/bin
export JAVA_HOME JRE_HOME CLASS_PATH PATH
EOF
source /etc/profile
```
#### 二、安装elastic
```shell
# 下载elastic
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.0.1-linux-x86_64.tar.gz
tar zxvf elasticsearch-7.8.0-linux-x86_64.tar.gz -C /usr/local/src
mv /usr/local/src/elasticsearch-7.8.0 /usr/lcoal/elasticsearch-7.8.0
# 创建账户，目录
groupadd elastic
useradd -r -g elastic -s /bin/bash elastic
chown -R elastic. /usr/lcoal/elasticsearch-7.8.0
mkdir /var/lib/elasticsearch
mkdir /var/log/elasticsearch
chown -R elastic. /var/lib/elasticsearch
chown -R elastic. /var/log/elasticsearch
# 配置环境变量
cat >> /etc/profile/elastic.sh <<EOF
echo "PATH=$PATH:/usr/local/elasticsearch-7.8.0/bin" >> /etc/profile.d/elastic.sh
EOF
source /etc/profile
# 修改配置文件
vim /usr/local/elasticsearch-7.8.0/config/elasticsearch.yml
------------------------------------start----------------------------------------------
# es config
cluster.name: scrm_es_cluster
node.name: node-1
path.data: /data/elasticsearch/data
path.logs: /data/elasticsearch/logs
network.host: 0.0.0.0
http.port: 9200
discovery.seed_hosts: ["127.0.0.1"]
cluster.initial_master_nodes: ["node-1"]
-------------------------------------end-----------------------------------------------
# 启动elastic
su elastic && elasticsearch -d
```
#### 三、安装kibana
```shell
# 下载kinaba
wget https://artifacts.elastic.co/downloads/kibana/kibana-7.8.0-linux-x86_64.tar.gz
tar zxvf kibana-7.8.0 -C /usr/local/src
mv /usr/local/src/kibana-7.8.0 /usr/local/kibana-7.8.0
# 修改配置文件
vim /usr/local/src/kibana-7.8.0/config/kibana.yml
-------------------------------------------start----------------------------------------
elasticsearch.url: "http://0.0.0.0:9200"
server.host: "0.0.0.0"
kibana.index: ".kibana"
-------------------------------------------end-------------------------------------------
# 启动kibana
su elastic /usr/local/kibana-7.8.0/bin/kibana &
```
#### 四、安装filebeat
```shell
# 下载filebeat
wget https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-7.8.0-linux-x86_64.tar.gz
tar zxvf filebeat-7.8.0-linux-x86_64.tar.gz -C /usr/local
mv /usr/local/filebeat-7.8.0-linux-x86_64 /usr/local/filebeat-7.8.0
# 修改配置文件
vim /usr/local/filebeat-7.8.0/filebeat.yml
-----------------------------------start-----------------------------------------------
filebeat.prospectors:
- type: log
  enabled: true
  paths:
    - "/data/logs/*/*/*/*.log"
    - "/data/logs/*/*/*"
    - "/data/logs/*/*"
    - "/data/logs/*"

  # 标识字段
  fields:
    service: 
    env: uat
  
  # 过滤日志
  exclude_lines: ['DEBUG']
  include_lines: ['ERR', 'WARN', 'INFO']
  exclude_files: ['debug']
  multiline.pattern: '^[[:space:]]+(at|\.{3})\b|^Caused by:'
  multiline.negate: true
  multiline.match: after

  # json格式
  json.keys_under_root: true
  json.add_error_key: true
  json.message_key: log
  json.overwrite_keys: true
  
# 数据输出目标地址
output.elasticsearch:
  hosts: ["lcoalhost:9200"]
  indices:
    - index: "xxx-%{+yyyy.MM.dd}"
      when.and:
        - contains:
            log.file.path: "xxx"
        - contains:
            env: ""
    - index: "xxxx-%{+yyyy.MM.dd}"
      when.and:
        - contains:
            log.file.path: "xxxx"
        - contains:
            env: ""
    - index: "xxxxx-%{+yyyy.MM.dd}"
      when.and:
        - contains:
            log.file.path: "xxxx"
        - contains:
            env: ""
    - index: "xxxx-%{+yyyy.MM.dd}"
      when.and:
        - contains:
            log.file.path: "xxx"
        - contains:
            env: ""
    - index: "xxxx-%{+yyyy.MM.dd}"
      when.and:
        - contains:
            log.file.path: "xxxx"
        - contains:
            env: ""
    - index: "xxxx-%{+yyyy.MM.dd}"
      when.and:
        - contains:
            log.file.path: "xxxx"
        - contains:
            env: ""
    - index: "xxx-%{+yyyy.MM.dd}"
      when.and:
        - contains:
            log.file.path: "xxxx"
        - contains:
            env: ""
    - index: "xxxx-%{+yyyy.MM.dd}"
      when.and:
        - contains:
            log.file.path: "xxxx"
        - contains:
            env: ""
    - index: "xxxx-%{+yyyy.MM.dd}"
      when.and:
        - contains:
            log.file.path: "xxxxx"
        - contains:
            env: ""
    - index: "xxxx-%{+yyyy.MM.dd}"
      when.and:
        - contains:
            log.file.path: "xxxx"
        - contains:
            env: ""
    - index: "xxxx-%{+yyyy.MM.dd}"
      when.and:
        - contains:
            log.file.path: "xxxx"
        - contains:
            env: ""
    - index: "xxxxx-%{+yyyy.MM.dd}"
      when.and:
        - contains:
            log.file.path: "xxxxx"
        - contains:
            env: ""
    - index: "xxxx-%{+yyyy.MM.dd}"
      when.and:
        - contains:
            log.file.path: "xxxxx"
        - contains:
            env: ""

logging.level: debug
--------------------------------------end---------------------------------------------
# 启动filebeat
./usr/local/filebeat-7.0.1/filebeat -c /usr/local/filebeat-7.0.1/filebeat.yml
```

