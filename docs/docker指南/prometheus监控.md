### cadvisor 安装
```bash
# 拉取镜像
docker pull google/cadvisor:latest

# 运行
cat > cadvisor_restart.sh <<- 'EOF'
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

# 修改挂载
sudo mount -o remount,rw '/sys/fs/cgroup'
sudo ln -s /sys/fs/cgroup/cpu,cpuacct /sys/fs/cgroup/cpuacct,cpu

# 添加ipv4 转发
cat >> /etc/sysctl.conf <<- 'EOF'
net.ipv4.ip_forward = 1
EOF

# 外部访问
curl -v http://IP:8080/metrics
curl -v http://IP:8080/docker
curl -v http://IP:8080/containers
```
### prometheus 安装

### alertmanager 安装
### grafana 安装
### node_export 安装
```bash
# 下载镜像
docker pull prom/node-exporter

# 创建容器
cat > node-exporter_restart.sh <<- 'EOF'
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
```
