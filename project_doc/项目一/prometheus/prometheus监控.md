### 环境准备
- 安装组件

| 序号 | 外网IP | 内网IP | 主机名  | 安装软件 | 安装方式 |
| ---- | ---- | ---- | ---- | ---- | ---- | ---- |
| 1 | 106.53.153.19 | 172.16.0.5 | rabbitmq-node01 | node_export | 二进制 |
| 2 | 106.52.212.134 | 172.16.0.12 | rabbitmq-node02 | node_export<br>prometheus<br>alertmanager | 二进制 |
| 3 | 42.193.143.225 | 172.16.0.15 | rabbitmq-node03 | node_export<br>grafana | 二进制 |
| 4 | 106.55.37.185 | 172.16.0.5 | node01 | node_export<br>cadivsor<br>prometheus-notify | 容器版 |
| 5 | 106.53.151.174 | 172.16.0.7 | node02 | node_export<br>cadivsor<br>prometheus-notify | 容器版 |
| 6 | 159.75.103.164 | 172.16.0.13 | node03 | node_export<br>grafana<br>prometheus-notify | 容器版 |
| 7 | 81.71.23.120 | 172.16.0.16 | node04 | node_export<br>grafana<br>prometheus-notify | 容器版 |

### Prometheus 安装
#### 安装
- 下载二进制包
```bash
https://github.com/prometheus/prometheus/releases/download/v2.24.1/prometheus-2.24.1.linux-amd64.tar.gz -P /usr/local/src
```
- 安装
```bash
# 解压
tar zxvf /usr/local/src/prometheus-2.24.1.linux-amd64.tar.gz 
mv /usr/local/src/prometheus-2.24.1.linux-amd64 /usr/local/prometheus
```

- 创建用户并授权
```bash
# 创建用户
useradd prometheus -d /var/lib/prometheus -s /sbin/nologin
# 授权
chown -R prometheus:prometheus /usr/local/prometheus /var/lib/prometheus
```
#### 启动
- 启动
```bash
# 创建服务自启
cat > /usr/lib/systemd/system/prometheus.service <<EOF
[Unit]
Description=Prometheus Monitoring System
After=network.target
 
[Service]
User=prometheus
ExecStart=/usr/local/prometheus/prometheus \
  --config.file=/usr/local/prometheus/prometheus.yml \
  --web.listen-address=:9090 \
  --storage.tsdb.retention=15d \
  --storage.tsdb.path=/var/lib/prometheus \
  --log.level=info
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
# 启动
systemctl enable prometheus
systemctl start prometheus
```
- 编写监控规则
```bash
# 放在rules目录
[root@rabbitmq-node02 prometheus]# pwd
/usr/local/prometheus
[root@rabbitmq-node02 prometheus]# tree
.
├── console_libraries
│   ├── menu.lib
│   └── prom.lib
├── consoles
│   ├── index.html.example
│   ├── node-cpu.html
│   ├── node-disk.html
│   ├── node.html
│   ├── node-overview.html
│   ├── prometheus.html
│   └── prometheus-overview.html
├── LICENSE
├── node_export.yml
├── NOTICE
├── prometheus
├── prometheus.yml
├── prometheus.yml.bak
├── promtool
└── rules
    ├── docker.yml
    └── node_export.yml
# 配置prometheus.yml
cat > prometheus.yml <<- 'EOF'
# my global config
global:
  scrape_interval:     15s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
  evaluation_interval: 15s # Evaluate rules every 15 seconds. The default is every 1 minute.
  # scrape_timeout is set to the global default (10s).

# Alertmanager configuration
alerting:
  alertmanagers:
  - static_configs:
    - targets:
      - localhost:9093

# Load rules once and periodically evaluate them according to the global 'evaluation_interval'.
rule_files:
  - "rules/*.yml"

# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
  # The job name is added as a label `job=<job_name>` to any timeseries scraped from this config.
  - job_name: 'prometheus'

    # metrics_path defaults to '/metrics'
    # scheme defaults to 'http'.

    static_configs:
    - targets: ['localhost:9090']

  - job_name: 'alertmanager'

    static_configs:
    - targets:
      - 'localhost:9093'

  - job_name: 'node-export'

    static_configs:
    - targets:
      - 'rabbitmq-node01:9100'
      - 'rabbitmq-node02:9100'
      - 'rabbitmq-node03:9100'
      - 'node01:9100'
      - 'node02:9100'
      - 'node03:9100'
      - 'node04:9100'

  - job_name: 'grafana'

    static_configs:
    - targets:
      - 'rabbitmq-node03:3000'

  - job_name: 'rabbitmq'

    static_configs:
    - targets:
      - 'rabbitmq-node01:15692'
      - 'rabbitmq-node02:15692'
      - 'rabbitmq-node03:15692'

  - job_name: 'cadvisor'

    static_configs:
    - targets:
      - 'node01:8080'
      - 'node02:8080'
      - 'node03:8080'
      - 'node04:8080'
EOF
```


### Alertmanager 安装
#### 安装
- 下载二进制包
```bash
https://github.com/prometheus/alertmanager/releases/download/v0.21.0/alertmanager-0.21.0.linux-amd64.tar.gz -P /usr/local/src
```
- 安装
```bash
# 解压
tar zxvf /usr/local/src/alertmanager-0.21.0.linux-amd64.tar.gz 
# 安装
mv /usr/local/src/alertmanager-0.21.0.linux-amd64 /usr/local/alertmanager 
```

- 创建数据目录
```bash
mkdir -pv /var/lib/alertmanager
```

- 授权
```bash
chown -R prometheus:prometheus /usr/local/alertmanager /var/lib/alertmanager
```

#### 启动
- 添加启动服务
```bash
cat > /usr/lib/systemd/system/alertmanager.service <<- 'EOF'
[Unit]
Description=Alertmanager
After=network.target

[Service]
User=prometheus
ExecStart=/usr/local/alertmanager/alertmanager \
    --config.file=/usr/local/alertmanager/alertmanager.yml \
    --web.listen-address=:9093 \
    --data.retention=120h \
    --storage.path=/var/lib/alertmanager \
    --log.level=info
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
```
- 启动
```bash
# 配置开机启动
systemctl enable alertmanager
# 启动
systemctl start alertmanager
```

- 配置
```bash
cat > alertmanager.yml <<- 'EOF'
global:
  resolve_timeout: 5m

route:
  group_by: ['alertname']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'web.hook'
receivers:
- name: 'web.hook'
  webhook_configs:
  - url: 'http://172.16.0.5:5000/prometheus'
inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'dev', 'instance']
EOF
```

### Grafana 安装
#### 安装
- 下载rpm包
```bash
wget https://dl.grafana.com/oss/release/grafana-7.3.7-1.x86_64.rpm -P /usr/local/src
```
- 安装
```bash
yum localinstall /usr/local/src/grafana-7.3.7-1.x86_64.rpm
```
#### 启动
- 启动
```bash
# 配置开机启动
systemctl enable grafana
# 启动服务
systemctl start grafana
# 外部访问
http://localhost:3000 账号密码： admin whI0ioyQKWkBBaOwlxlJPKeH
```

#### 配置grafana
- 导入面板
```bash
# docker 数据源
docker.json
# mq 面板
oviewer.json
elangmem.json
# node_export
node_export.json
```

### cadvisor 安装
```bash
# 拉取镜像
docker pull google/cadvisor:latest

# 创建启动脚本
cat > /usr/local/src/cadvisor_restart.sh <<- 'EOF'
#!/usr/bin/env bash
docker stop cadvisor
docker rm cadvisor
docker run --name cadvisor \
  -v /:/rootfs:ro \
  -v /var/run:/var/run:rw \
  -v /sys:/sys:ro \
  -v /var/lib/docker/:/var/lib/docker:ro \
  -v /dev/disk/:/dev/disk:ro \
  -p 0.0.0.0:8080:8080 \
  --restart=always \
  -d google/cadvisor
EOF

# 启动容器
sh -x /usr/local/src/cadvisor_restart.sh 

# 修改挂载
sudo mount -o remount,rw '/sys/fs/cgroup'
sudo ln -s /sys/fs/cgroup/cpu,cpuacct /sys/fs/cgroup/cpuacct,cpu

# 添加ipv4 转发
cat >> /etc/sysctl.conf <<- 'EOF'
net.ipv4.ip_forward = 1
EOF

# 启用转发
sysctl -p

# 外部访问
curl -v http://IP:8080/metrics
curl -v http://IP:8080/docker
curl -v http://IP:8080/containers
```

### 安装node_export
#### 安装
- 下载二进制包
```bash
# 下载
wget https://github.com/prometheus/node_exporter/releases/download/v1.0.1/node_exporter-1.0.1.linux-amd64.tar.gz -P /usr/local/src
```
- 安装
```bash
# 解压
tar zxvf /usr/local/src/node_exporter-1.0.1.linux-amd64.tar.gz
# 安装
mv /usr/local/src/node_exporter-1.0.1.linux-amd64 /usr/local/node_exporter
```
#### 启动
- 添加开机启动服务
```bash
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
scp /usr/lib/systemd/system/node_exporter.service root@rabbitmq-node02
scp /usr/lib/systemd/system/node_exporter.service root@rabbitmq-node01
```
- 启动
```bash
# 开机自启
systemctl enable node_exporter
# 启动
systemctl start node_exporter
```
#### 容器安装
```bash
# 创建容器
cat > /usr/local/src/node-exporter_restart.sh <<- 'EOF'
#!/usr/bin/env bash
docker stop node-exporter
docker rm node-exporter
docker run --name=node-exporter \
  --restart=always \
  -p 9100:9100  \
  -v /proc:/host/proc:ro \
  -v /sys:/host/sys:ro \
  -v /:/rootfs:ro \
  -d prom/node-exporter
EOF
# 启动容器
sh -x /usr/local/src/node-exporter_restart.sh
```


### 监控webhook 安装
#### Dockerfile
```bash
# 创建目录
mkdir -pv /usr/local/src/Dockerfile/tools
# 创建配置文件
cat > /usr/local/src/Dockerfile/tools/config.yaml <<- 'EOF'
---

prod:
  weixin:
    url: ''
  smtp:
    user: ''
    host: ''
    passwd: ''
    send_email: ''
    receivers_email: ''
EOF
# 创建dockerfile
cat > /usr/local/src/Dockerfile/Dockerfile-prometheus <<- 'EOF'
FROM python:3.7.9-alpine3.12
WORKDIR /apps
COPY tools /apps/tools
RUN ls /apps/tools \
    && pip3 install pipreqs \
    && pipreqs tools/ --encoding=utf8 --force \
    && pip3 install -r tools/requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
ENTRYPOINT ["python3","/apps/tools/app.py"]
CMD ["runserver"]
EOF
# build 镜像
docker build -t prometheus-webhook:flask-v1.0 -f Dockerfile-prometheus --no-cache .
```
#### 启动
```bash
# 配置启动脚本
cat > /usr/local/src/prometheus_webhook_restart.sh <<- 'EOF'
#!/usr/bin/env bash
docker stop prometheus-notifity
docker rm prometheus-notifity
docker run --name prometheus-notifity \
    --restart=always \
    -p 5000:5000  \
    -v /usr/local/src/Dockerfile/tools/config.yaml:/apps/tools/config.yaml \
    -v /usr/local/src/Dockerfile/tools/app.py:/apps/tools/app.py \
    -d dockerplyx/prometheus:prometheus-webhook-flask-v1.0
EOF
# 启动
sh -x  /usr/local/src/prometheus_webhook_restart.sh
```

#### 访问
grafana： http://42.193.143.225:3100
prometheus: http://106.52.212.134:9090
alertmanager: http://106.52.212.134:9093