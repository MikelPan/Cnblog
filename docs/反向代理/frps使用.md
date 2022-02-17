### frp 简介

​	[frp](https://java-er.com/blog/tag/frp/) 让本地局域网的机器可以暴露到公网，简单的说就是在世界的任何地方，你可以访问家里开着的那台电脑。
FRP 支持 TCP、UDP、HTTP、HTTPS， 就是说不仅仅限于本地web服务器可以暴露，整台机器都可以暴露，windows的远程控制，mac和linux的ssh都可以被暴露。

配置 FRP 服务端的前提条件是需要一台具有**公网 IP **的设备，得益于 **FRP** 是 Go 语言开发的，具有良好的跨平台特性。你可以在 Windows、Linux、MacOS、ARM等几乎任何可联网设备上部署。

### frp 架构

![](https://mingyue-1300243549.cos.ap-chengdu.myqcloud.com/picgo/20191205/frp-index.png)

### frp 原理



### frp 使用systemd管理

#### 安装frps
```bash
wget https://github.com/fatedier/frp/releases/download/v0.37.0/frp_0.37.0_linux_amd64.tar.gz -P /usr/local/src

```

#### 配置服务端frps

```bash
# 复制进程
cp /usr/local/src/frp/frps /usr/local/bin/frps
cp frps.ini /etc/frp/frps.ini
# 拷贝配置文件
cp frps.ini /etc/frp/frps.ini
# 服务端配置文件说明
cat > /etc/frp/frps.ini <<- 'EOF'
[common]
bind_port = 7000
vhost_http_port = 8000
#subdomain_host = 01member.com
log_level = debug
pool_count = 0
dashboard_addr = 0.0.0.0
dashboard_port = 7500
dashboard_user = admin
dashboard_pwd = 123456
EOF
# 配置systemd管理
cat > /usr/lib/systemd/system/frps.service <<- 'EOF'
[Unit]
Description=frps
After=network.target

[Service]
TimeoutStartSec=30
ExecStart=/usr/local/bin/frps -c /etc/frp/frps.ini
ExecStop=/bin/kill $MAINPID
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
# 启动
systemctl enable frps
systemctl start frps
systemctl status frps
```

#### 配置客户端frpc

```bash
# 复制进程
cp /usr/local/src/frp/frpc /usr/local/bin/frpc
# 拷贝配置文件
cp /usr/local/src/frp/frpc.ini /etc/frp/frpc.ini
# 客户端配置文件说明
cat > /etc/frp/frpc.ini <<- 'EOF'
[common]
server_addr = 10.100.29.41
server_port = 7000

[ssh]
type = tcp
local_ip = 10.20.127.65
local_port = 6667
remote_port = 6667
EOF

# 配置systemd管理
cat > /usr/lib/systemd/system/frpc.service <<- 'EOF'
[Unit]
Description=frpc
After=network.target

[Service]
TimeoutStartSec=30
ExecStart=/usr/local/bin/frpc -c /etc/frp/frpc.ini
ExecStop=/bin/kill $MAINPID
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
# 启动
systemctl enable frpc
systemctl start frpc
systemctl status frpc
```

### 配置域名转发



