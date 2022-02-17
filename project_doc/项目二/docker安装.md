#### 硬件准备

| 序号 | 外网IP         | 内网IP      | 主机名          | 服务器登录              | 安装软件|
| ---- | -------------- | ----------- | --------------- | ----------------------- |
| 1    | N/A  | node01  | rl-server1 | ssh root@N/A | docker<br>docker-compose<br>mysql-client<br>redis-cli<br>rabbitmq|
| 2    | N/A | node02 | rl-server2 | ssh root@N/A | docker<br>docker-compose|
| 3    | N/A | node03 | rl-server3 | ssh root@N/A |docker<br>docker-compose|

#### 服务器初始化
```bash
# 主机名配
hostnamectl set-hostname rl-server1
hostnamectl set-hostname rl-server2
hostnamectl set-hostname rl-server3
# 配置hosts
cat >> /etc/hosts <<- 'EOF'
# hosts
IP rl-server1
IP rl-server2
IP rl-server3
EOF
```
#### docker 安装
```bash
# 安装docker
curl -sL https://gitee.com/YunFeiGuoJi/Cnblog/blob/master/shell/Scripts/docker_install.sh|sh
# 开启ipv4转发
vim /etc/sysctl.conf
net.ipv4.ip_forward = 1
sysctl -p
```

#### 安装redis-cli

```bash
# 安装redis-cli
curl -sL https://gitee.com/YunFeiGuoJi/Cnblog/raw/master/shell/Scripts/redis-cli_install.sh|sh
```

#### 安装mysql-client

```bash
# 安装mysql-client
curl -sL https://gitee.com/YunFeiGuoJi/Cnblog/raw/master/shell/Scripts/mysql-client_install.sh|sh
```
