#### 硬件准备

| 序号 | 外网IP         | 内网IP      | 主机名          | 服务器登录              | 安装软件|
| ---- | -------------- | ----------- | --------------- | ----------------------- |
| 1    | 42.192.11.152  | 172.16.0.4  | rl-server1 | ssh root@42.192.11.152 | docker<br>docker-compose<br>mysql-client<br>redis-cli<br>rabbitmq|
| 2    | 42.192.186.9 | 172.16.0.16 | rl-server2 | ssh root@42.192.186.9 | docker<br>docker-compose|
| 3    | 121.4.134.130 | 172.16.0.13 | rl-server3 | ssh root@121.4.134.130 |docker<br>docker-compose|

#### 服务器初始化
```bash
# 主机名配置
hostnamectl set-hostname rl-server1
hostnamectl set-hostname rl-server2
hostnamectl set-hostname rl-server3
# 配置hosts
cat >> /etc/hosts <<- 'EOF'
# hosts
172.16.0.4 rl-server1
172.16.0.16 rl-server2
172.16.0.13 rl-server3
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
