### 硬件准备

### 安装haproxy
```bash
# 安装
yum install -y haproxy
# 配置
cat > /etc/haproxy/haproxy.cfg <<- 'EOF'
global
   log 127.0.0.1 local3 info         #在本机记录日志
   maxconn 65535                     #每个进程可用的最大连接数
   chroot /var/lib/haproxy         #haproxy 安装目录
   uid 188                            #运行haproxy的用户uid（cat /etc/passwd 查看，这里是nobody的uid）
   gid 188                           #运行haproxy的用户组id（cat /etc/passwd 查看，这里是nobody组id）
   daemon                            #以后台守护进程运行
   pidfile /var/run/haproxy.pid
   stats socket /var/lib/haproxy/stats

defaults
   log global
   mode tcp                         #运行模式 tcp、 http、 health
   retries 3                         #三次连接失败，则判断服务不可用
   option redispatch                 #如果后端有服务器宕机，强制切换到正常服务器
   maxconn 65535                     #每个进程可用的最大连接数
   contimeout 5s
   # 客户端空闲超时时间为60秒，过了该时间，HA发起重连机制
   clitimeout 60s
   # 服务端连接超时时间为15秒，过了该时间，HA发起重连机制
   srvtimeout 15s


frontend http-in                     #自定义描述信息
   mode http                         #运行模式 tcp、 http、 health
   maxconn 65535                     #每个进程可用的最大连接数
   bind :80                          #监听 80 端口
   log global
   option httplog
   option httpclose                  #每次请求完毕后主动关闭 http 通道
   acl is_a hdr_beg(host) -i web1.mikel.top        #规则设置，-i 后面是要访问的域名
   acl is_b hdr_beg(host) -i web2.mikel.top        #如果多个域名，就写多个规则，一规则对应一个域名；即后面有多个域名，就写 is_c、 is-d….，这个名字可以随意起。但要与下面的use_backend 对应
   use_backend web-server if is_a    #如果访问 is_a 设置的域名，就负载均衡到下面backend 设置的对应 web-server 上。web-server所负载的域名要都部署到下面的web01和web02上。如果是不同的域名部署到不同的机器上，就定义不同的web-server。
   use_backend web-server if is_b

backend web-server
   mode http
   balance roundrobin                #设置负载均衡模式，source 保存 session 值，roundrobin 轮询模式
   cookie SERVERID insert indirect nocache
   option httpclose
   option forwardfor
   server web01 172.16.0.6:5000 weight 1 cookie 3 check inter 2000 rise 2 fall 5
   server web02 172.16.0.9:5000 weight 1 cookie 4 check inter 2000 rise 2 fall 5

listen status_page
   mode http
   bind :8000
   stats admin if TRUE
   stats uri /haproxy                #统计页面 URL 路径
   stats refresh 30s                 #统计页面自动刷新时间
   #stats realm itlihao\ welcome        #统计页面输入密码框提示信息
   stats auth admin:dxInCtFianKtL]36   #统计页面用户名和密码
   stats hide-version                 #隐藏统计页面上 HAProxy 版本信息
EOF
# 启动
yum install -y haproxy
```

### 安装keepalived
```bash
# 配置文件
cat > /etc/keepalived/keepalived.conf <<- 'EOF'
! Configuration File for keepalived
global_defs {
  notification_email {
    root@localhost
    }

notification_email_from keepalived@localhost
smtp_server 127.0.0.1
smtp_connect_timeout 30
router_id HAproxy237
script_user root
enable_script_security
}

vrrp_script chk_haproxy {                                   #HAproxy 服务监控脚本
  script "/etc/keepalived/check_haproxy.sh"
  interval 2
  weight 2
}

vrrp_instance VI_1 {
  state BACKUP
  nopreempt
  interface eth0
  virtual_router_id 51
  priority 100
  unicast_src_ip 172.16.0.6  # 配置单播的源地址
  unicast_peer { 
      172.16.0.9       #配置单播的目标地址
  } 
  advert_int 1
  authentication {
    auth_type PASS
    auth_pass 1111
}
  track_script {
    chk_haproxy
}
virtual_ipaddress {
    172.16.0.10
}
!notify_master "/etc/keepalived/clean_arp.sh 182.148.15.239"
}
EOF
## BACKUP
cat > /etc/keepalived/keepalived.conf <<- 'EOF'
! Configuration File for keepalived
global_defs {
  notification_email {
    root@localhost
    }

notification_email_from keepalived@localhost
smtp_server 127.0.0.1
smtp_connect_timeout 30
router_id HAproxy237
script_user root
enable_script_security
}

vrrp_script chk_haproxy {                                   #HAproxy 服务监控脚本
  script "/etc/keepalived/check_haproxy.sh"
  interval 2
  weight 2
}

vrrp_instance VI_1 {
  state BACKUP
  nopreempt
  interface eth0
  virtual_router_id 51
  priority 100
  unicast_src_ip 172.16.0.9  # 配置单播的源地址
  unicast_peer { 
      172.16.0.6       #配置单播的目标地址
  } 
  advert_int 1
  authentication {
    auth_type PASS
    auth_pass 1111
}
  track_script {
    chk_haproxy
}
virtual_ipaddress {
    172.16.0.10
}
!notify_master "/etc/keepalived/clean_arp.sh 182.148.15.239"
}
EOF
# 检测脚本
cat > /etc/keepalived/check_nginx.sh <<- 'EOF'
#!/bin/bash
A=`ps -C haproxy --no-header | wc -l`
if [ $A -eq 0 ]
then
    systemctl restart haproxy
    sleep 3
    if [ `ps -C haproxy --no-header | wc -l ` -eq 0 ]
    then
        systemctl restart stop
    fi
fi
EOF
# 启动
yum install -y keepalived
```

### 安装docker 环境
```bash
curl -s https://gitee.com/YunFeiGuoJi/Cnblog/raw/master/shell/Scripts/docker_install.sh |sh
```

### 创建后端服务
```bash
# 编写flsk脚本
cat > app.py <<- 'EOF'
from flask import Flask
app = Flask(__name__)

@app.route('/')
def hello_world():
    return 'Hello World!'

if __name__ == '__main__':
    app.run(host='0.0.0.0')
EOF
# 构建镜像
cat > build_image.sh <<- 'EOF'
#!/usr/bin/env bash
mkdir -pv /usr/local/src/Dockerfile/tools
cp /root/app.py /usr/local/src/Dockerfile/tools
# 创建dockerfile
cat > /usr/local/src/Dockerfile/Dockerfile-web1 <<- 'eof'
FROM python:3.8.3-alpine3.12
WORKDIR /apps
COPY tools /apps/tools
RUN ls /apps/tools \
    && pip3 install pipreqs \
    && pipreqs tools/ --encoding=utf8 --force \
    && pip3 install -r tools/requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
ENTRYPOINT ["python3","/apps/tools/app.py"]
CMD ["runserver"]
eof
# build 镜像
cd /usr/local/src/Dockerfile
docker build -t dockerplyx/service:web1-v1.0 -f Dockerfile-web1 --no-cache .
EOF
# 创建docker 启动脚本
cat > web2_restart.sh <<- 'EOF'
#!/usr/bin/env bash
docker stop web2
docker rm web2
docker run --name web2 \
    --restart=always \
    -p 5000:5000  \
    -v /root/app.py:/apps/tools/app.py \
    -d dockerplyx/service:web1-v1.0
EOF
```

