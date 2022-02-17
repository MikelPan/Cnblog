#### 硬件准备

| 序号 | 外网IP         | 内网IP      | 主机名          | 服务器登录              |
| ---- | -------------- | ----------- | --------------- | ----------------------- |
| 1    | N/A  | N/A  | Rabbitmq-node01 | ssh root@N/A  |
| 2    | N/A | N/A | Rabbitmq-node02 | ssh root@N/A |
| 3    | N/A | N/A | Rabbitmq-node03 | ssh root@N/A |

#### 服务器初始化

```bash
# 主机名配置
hostnamectl set-hostname rabbitmq-node01
hostnamectl set-hostname rabbitmq-node02
hostnamectl set-hostname rabbitmq-node03
# 配置hosts
cat >> /etc/hosts <<- 'EOF'
# hosts
node01 rabbitmq-node01
node02 rabbitmq-node02
node03 rabbitmq-node03
EOF
# ansible 管理主机
## 安装ansible
yum install -y ansible
## 配置主机
cat >> /etc/ansible/hosts <<- 'EOF'
[rabbitmq]
node01
node02
node03
EOF
```

### 安装

#### shell 脚本编写

```bash
# 安装mq脚本
cat > /etc/ansible/roles/rabbitmq/files/rabbitmq_install.sh <<- 'EOF'
#!/usr/bin/env bash
# 下载erlang
wget --content-disposition https://packagecloud.io/rabbitmq/erlang/packages/el/7/erlang-23.0.2-1.el7.x86_64.rpm/download.rpm -P /usr/local/src
# 拷贝到另外两台服务器
scp /usr/local/src/erlang-23.0.2-1.el7.x86_64.rpm root@rabbitmq-node02,3:/usr/local/src
# 三台机器上安装erlang
yum localinstall -y erlang-23.0.2-1.el7.x86_64.rpm
ssh root@node02 'yum localinstall -y erlang-23.0.2-1.el7.x86_64.rpm'
ssh root@node03 'yum localinstall -y erlang-23.0.2-1.el7.x86_64.rpm'
# 下载ｍｑ
wget https://github.com/rabbitmq/rabbitmq-server/releases/download/v3.8.5/rabbitmq-server-3.8.5-1.el7.noarch.rpm
# 拷贝mq至另外两台机器
scp /usr/local/src/rabbitmq-server-3.8.5-1.el7.noarch.rpm root@rabbitmq-node02,3:/usr/local/src 
# 三台机器导入key
rpm --import https://www.rabbitmq.com/rabbitmq-release-signing-key.asc
ssh root@node02 'rpm --import https://www.rabbitmq.com/rabbitmq-release-signing-key.asc'
ssh root@node03 'rpm --import https://www.rabbitmq.com/rabbitmq-release-signing-key.asc'
# 三台安装ｍｑ
yum localinstall rabbitmq-server-3.8.5-1.el7.noarch.rpm
ssh root@node02 'yum localinstall rabbitmq-server-3.8.5-1.el7.noarch.rpm'
ssh root@node03 'yum localinstall rabbitmq-server-3.8.5-1.el7.noarch.rpm'
# 配置开机启动
systemctl enable rabbitmq-server
ssh root@node02 'systemctl enable rabbitmq-server'
ssh root@node03 'systemctl enable rabbitmq-server'
# 启动
systemctl start rabbitmq-server
ssh root@node02 'systemctl start rabbitmq-server'
ssh root@node03 'systemctl start rabbitmq-server'
EOF
```

#### mq集群初始化
```bash
# 拷贝cookie
scp /var/lib/rabbitmq/.erlang.cookie root@rabbitmq-node02,3:/var/lib/rabbitmq/.erlang.cookie
# 添加权限
chown -R rabbitmq:rabbitmq /var/lib/rabbitmq
ssh root@node02 'chown -R rabbitmq:rabbitmq /var/lib/rabbitmq'
ssh root@node03 'chown -R rabbitmq:rabbitmq /var/lib/rabbitmq'
# 其他节点重启
systemctl restart rabbitmq-server

## 节点2上操作
rabbitmqctl stop_app 
rabbitmqctl reset 
rabbitmqctl join_cluster --ram rabbit@rabbitmq-node02
rabbitmqctl start_app
## 节点3上执行
rabbitmqctl stop_app 
rabbitmqctl reset 
rabbitmqctl join_cluster  rabbit@rabbitmq-node03
rabbitmqctl start_app
# 节点1上操作配置镜像队列
rabbitmqctl set_policy ha-all "^" '{"ha-mode":"all"}'
```

### Rabbitmq 权限管理

```bash
# 启用管理端控制台
rabbitmq-plugins enable rabbitmq_management
ssh root@node02 'rabbitmq-plugins enable rabbitmq_management'
ssh root@node03 'rabbitmq-plugins enable rabbitmq_management'
# mq配置账号
rabbitmqctl add_user admin Wx7CoNh9FuxARi4j3az91st5
rabbitmqctl set_user_tags admnin administrator
rabbitmqctl add_vhost rabbitmq_master
rabbitmqctl set_permissions -p rabbitmq_master admin ".*" ".*" ".*"
# 开启prometheus监控插件
rabbitmq-plugins enable rabbitmq_prometheus
访问 http://localhost:15692/metrics
```

### haproxy 安装

```bash
# 安装haproxy
yum install gcc -y
yum install haproxy -y
# 修改配置
cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.bak

cat > /etc/haproxy/haproxy.cfg <<- 'EOF'

#logging options
global
    log 127.0.0.1 local0 info
    maxconn 5120
    chroot /var/lib/haproxy
    user haproxy
    group haproxy
    daemon
    quiet
    nbproc 20
    pidfile /var/run/haproxy.pid
    stats socket /var/lib/haproxy/stats
    
defaults
    log global
    # 使用四层代理模式,"mode http" 为7层代理模式
    mode tcp
    # if you set mode to tcp,then you must change tcplog into httplog
    option tcplog
    option dontlognull
    retries 3
    option redispatch
    maxconn 4000
    contimeout 5s
    # 客户端空闲超时时间为60秒，过了该时间，HA发起重连机制
    clitimeout 60s
    # 服务端连接超时时间为15秒，过了该时间，HA发起重连机制
    srvtimeout 15s

listen rabbitmq_cluster
    # 定义监听地址和端口，本机的5672端口
    bind 0.0.0.0:8000
    # 配置 tcp 模式
    mode tcp
    # balance url_param userid
    # balance url_param session_id check_post 64
    # 简单的轮询
    balance roundrobin
    #rabbitmq集群节点配置 #inter 每隔五秒对mq集群做健康检查，2次正确证明服务器可用，
    #2次失败证明服务器不可用，并且配置主备机制
    server rabbitmq-node01 172.16.0.4:5672 check inter 5000 rise 2 fall 2
    server rabbitmq-node02 172.16.0.12:5672 check inter 5000 rise 2 fall 2
    server rabbitmq-node03 172.16.0.15:5672 check inter 5000 rise 2 fall 2
        
# 配置 haproxy web 监控，查看统计信息
listen admin_status
    bind *:8100
    mode http
    option httplog
    mode http                      #http的7层模式
    log 127.0.0.1 local3 err       #错误日志记录
    stats refresh 5s               #每隔5秒自动刷新监控页面
    stats uri /admin?stats         #监控页面的url访问路径
    stats realm admin_status   #监控页面的提示信息
    stats auth admin:cmfGtkIzCD3s9TQEZwPqoCp1         #监控页面的用户和密码admin,可以设置多个用户名
    stats hide-version             #隐藏统计页面上的HAproxy版本信息  
    stats admin if TRUE            #手工启用/禁用,后端服务器(haproxy-1.4.9以后版本)
EOF
# 启动
systemctl enable haproxy
systemctl start haproxy
```

### keepalived 安装
```bash
# 安装
yum install -y keeplived
# 修改配置
## 主节点
cat > /etc/keepalived/keepalived.conf <<- 'EOF'
! Configuration File for keepalived

global defs {
    router_id rabbitmq-node02 ##标识节点的字符串，通常为hostname
}

vrrp_script chk_haproxy{
    script "/etc/keepalived/haproxy_check.sh"   ## 执行脚本位置
    interval 2  ##检查时间间隔
    weight -20 ##如果条件成立则权重减20
}

vrrp_instance VI_1 {
    state BACKUP ##主节点为MASTER,备份节点为BACKUP
    interface eth0 ##绑定虚拟ip的网络接口(网卡)
    virtual_router_id 13    ##虚拟路由id号，主备节点相同
    mcast_src_ip node02 ##本机ip地址
    priority 200 ##优先级(0-254)
    nopreempt
    advert_int 1    ##组播信息发送间隔，两个节点必须一致,默认1s
    authentication {    ##认证匹配
        auth_type PASS
        auth_pass bhz
    }
    track_script {
        chk_haproxy
    }
    virtual_ipaddress {
        172.16.0.200 ##虚拟ip,可以指定多个
    }
}
EOF
## 备节点
cat > /etc/keepalived/keepalived.conf <<- 'EOF'
! Configuration File for keepalived

global defs {
    router_id  rabbitmq-node03 ##标识节点的字符串，通常为hostname
}

vrrp_script chk_haproxy{
    script "/etc/keepalived/haproxy_check.sh"   ## 执行脚本位置
    interval 2  ##检查时间间隔
    weight -20 ##如果条件成立则权重减20
}

vrrp_instance VI_1 {
    state BACKUP ##主节点为MASTER,备份节点为BACKUP
    interface eth0 ##绑定虚拟ip的网络接口(网卡)
    virtual_router_id 13    ##虚拟路由id号，主备节点相同
    mcast_src_ip node03 ##本机ip地址
    priority 100 ##优先级(0-254)
    nopreempt
    advert_int 1    ##组播信息发送间隔，两个节点必须一致,默认1s
    authentication {    ##认证匹配
        auth_type PASS
        auth_pass bhz
    }
    track_script {
        chk_haproxy
    }
    virtual_ipaddress {
        172.16.0.200 ##虚拟ip,可以指定多个
    }
}
EOF
# 启动
systemctl enable keeplived
systemctl restart keeplived
```

**haproxy_check** 脚本

```bash
cat > /etc/keepalived/haproxy_check.sh <<- 'EOF'
#!/usr/bin/env bash
COUNT = `ps -C haproxy --no-header | wc -l`
if [$COUNT -eq 0];then
    systemctl restart haproxy
    sleep 2
    if[`ps -C haproxy --no-header | wc -l` -eq 0];then
        systemctl stop keepalived
    fi
fi
EOF
```

### 使用腾讯云负载均衡

由于云厂商将禁止vpc下arp宣告，故无法实现keepalived+haproxy架构实现负载均衡，需要使用云厂商提供的slb做负载均衡使用，即在页面配置负载均衡即可


