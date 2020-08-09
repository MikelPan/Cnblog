### Prometheus 介绍
#### Prometheus 安装
```bash
# 下载prometheus
wget https://github.com/prometheus/prometheus/releases/download/v2.20.0-rc.0/prometheus-2.20.0-rc.0.linux-amd64.tar.gz -P /apps/software
# 下载alertmanager
wget https://github.com/prometheus/alertmanager/releases/download/v0.21.0/alertmanager-0.21.0.linux-amd64.tar.gz -P /apps/software
# 下载blackbox_export
wget https://github.com/prometheus/blackbox_exporter/releases/download/v0.17.0/blackbox_exporter-0.17.0.linux-amd64.tar.gz -P /apps/software
# 下载node_export
wget https://github.com/prometheus/node_exporter/releases/download/v1.0.1/node_exporter-1.0.1.linux-amd64.tar.gz -P /apps/softwware
# 安装prometheus
mv /usr/local/prometheus-2.20.0-rc.0.linux-amd64 /usr/local/prometheus
cd /usr/local/prometheus && ./prometheus --config.file=/usr/local/prometheus/prometheus.yml &
# 添加开机启动
cat > /usr/lib/systemd/system/prometheus.service <<EOF
[Unit]
Description=Prometheus Monitoring System
Documentation=Prometheus Monitoring System
 
[Service]
ExecStart=/usr/local/prometheus/prometheus \
  --config.file=/usr/local/prometheus/prometheus.yml \
  --web.listen-address=:9090 \
  --storage.tsdb.retention=1d \
  --storage.tsdb.path=/var/lib/prometheus \
  --log.level=info
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl enable prometheus
systemctl start prometheus
```
#### 安装node_export
```bash
# 安装node_export
mv /usr/local/node_exporter-1.0.1.linux-amd64/ /usr/local/node_exporter 
# 添加开机启动
cat > /usr/lib/systemd/system/node_exporter.service <<EOF
[Unit]
Description=Node Exporter Monitoring System
Documentation=Node Exporter Monitoring System
 
[Service]
ExecStart=/usr/local/node_exporter/node_exporter \
  --web.listen-address=:9100 \
  --log.level=info 
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
# 配置prometheus
- job_name: "node"
    static_configs:
      - targets:
        - "localhost:port" 
        labels:
          env: "xxxx"
```

### Ｇrafana 介绍
#### Grafana　安装
```bash
# 下载
## 二进制
wget https://dl.grafana.com/oss/release/grafana-7.1.0.linux-amd64.tar.gz
tar -zxvf grafana-7.1.0.linux-amd64.tar.gz
## rpm包
wget https://dl.grafana.com/oss/release/grafana-7.1.0-1.x86_64.rpm
# 安装grafana
sudo yum install grafana-7.1.0-1.x86_64.rpm
# 配置开机启动
systemctl enable grafana-server
systemctl start grafana-server
```
#### grafana配置
```bash
# 接入prometheus

```
### Loki日志收集
#### Loki架构说明
#### Loki安装
```bash
# 下载
官方地址　https://github.com/grafana/loki/releases
## loki下载
wget https://github.com/grafana/loki/releases/download/v1.5.0/loki-linux-amd64.zip -P /apps/software
## promtail下载
wget https://github.com/grafana/loki/releases/download/v1.5.0/promtail-linux-amd64.zip -P /apps/software
## loki 配置文件
wget https://raw.githubusercontent.com/grafana/loki/master/cmd/loki/loki-local-config.yaml
## promtail　配置文件
wget https://raw.githubusercontent.com/grafana/loki/master/cmd/promtail/promtail-local-config.yaml
#启动loki
cd /usr/local/loki && ./loki-linux-amd64 -config.file=loki-local-config.yaml
cd /usr/local/loki && ./promtail-local-config -config.file=promtail-local-config.yaml
# 容器部署
docker run -d --name grafana-loki -v $(pwd):/mnt/config -p 3100:3100 grafana/loki:1.5.0 -config.file=/mnt/config/loki-local-config.yaml
docker run -d --name grafana-loki-promtail -v $(pwd):/mnt/config -v /root/data/logs:/data/logs grafana/promtail:1.5.0 -config.file=/mnt/config/promtail-local-config.yaml
```

#### loki配置
##### loki配置
```yml
auth_enabled: false

server:
  http_listen_port: 3100
  grpc_listen_port: 9095
  grpc_server_max_recv_msg_size: 8000000
  grpc_server_max_send_msg_size: 6000000

ingester:
  lifecycler:
    address: 127.0.0.1
    ring:
      kvstore:
        store: inmemory
      replication_factor: 1
    final_sleep: 0s
  chunk_idle_period: 5m
  chunk_retain_period: 30s
  max_transfer_retries: 0

frontend:
  max_outstanding_per_tenant: 1000

query_range:
  split_queries_by_interval: 30s

schema_config:
  configs:
    - from: 2018-04-15
      store: boltdb
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 168h
  
storage_config:
  boltdb:
    directory: /tmp/loki/index

  filesystem:
    directory: /tmp/loki/chunks

limits_config:
  enforce_metric_name: false
  reject_old_samples: true
  reject_old_samples_max_age: 168h
  ingestion_rate_mb: 15

chunk_store_config:
  max_look_back_period: 0s

table_manager:
  retention_deletes_enabled: false
  retention_period: 0s
```
##### promtail配置
```yml
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://localhost:port/loki/api/v1/push

scrape_configs:
- job_name: system  
  pipeline_stages:
  - match:
    selector: '{job="xxxx"}'
    stages:
    - regex:
        expression: ''
    - metrics:
        
  static_configs:
  - targets:
      - localhost
    labels:
      job: xxxxx
      __path__: /path/*/*/*
```
#### promtail启动脚本
```bash
#!/bin/bash

workdir=$(cd $(dirname $0); pwd)
docker container stop grafana-loki-promtail
docker container rm grafana-loki-promtail
docker run -d \
    --name grafana-loki-promtail \
    -p 9080:9080 \
    -v ${workdir}:/mnt/config \
    -v /data/logs:/data/logs grafana/promtail:1.5.0 \
    -config.file=/mnt/config/promtail-local-config.yaml
```