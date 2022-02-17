#### 硬件准备

| 序号 | 外网IP         | 内网IP      | 主机名          | 服务器登录              |
| ---- | -------------- | ----------- | --------------- | ----------------------- |
| 1    | N/A  | N/A  | k8s-master1 | ssh k8s-master1  |
| 2    | N/A | N/A | k8s-master2 | ssh k8s-master2 |

#### 服务器初始化

```bash
# 主机名配置
hostnamectl set-hostname k8s-master1
hostnamectl set-hostname k8s-master2
# 配置hosts
cat >> /etc/hosts <<- 'EOF'
# hosts
IP k8s-master1
IP k8s-master2
EOF
# ansible 管理主机
## 安装ansible
yum install -y ansible
## 配置主机
cat >> /etc/ansible/hosts <<- 'EOF'
[node]
node01
node02
EOF
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
    server k8s-master1 IP:5000 check inter 5000 rise 2 fall 2
    server k8s-master2 IP:5001 check inter 5000 rise 2 fall 2
        
# 配置 haproxy web 监控，查看统计信息
listen admin_status
    bind *:8100
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
    router_id k8s-master1 ##标识节点的字符串，通常为hostname
    vrrp_skip_check_adv_addr
    vrrp_strict
    vrrp_garp_interval 0
    vrrp_gna_interval 0
}

vrrp_script chk_haproxy{
    script "/etc/keepalived/haproxy_check.sh"   ## 执行脚本位置
    interval 2  ##检查时间间隔
    weight -20 ##如果条件成立则权重减20
}

vrrp_instance VI_1 {
    state MASTER ##主节点为MASTER,备份节点为BACKUP
    interface eth0 ##绑定虚拟ip的网络接口(网卡)
    virtual_router_id 13    ##虚拟路由id号，主备节点相同
    #mcast_src_ip node01 ##本机ip地址
    priority 200 ##优先级(0-254)
    #nopreempt
    advert_int 1    ##组播信息发送间隔，两个节点必须一致,默认1s
    authentication {    ##认证匹配
        auth_type PASS
        auth_pass bhz
    }
    track_script {
        chk_haproxy
    }
    virtual_ipaddress {
        外网IP dev eth0 label ha:net ##虚拟ip,可以指定多个
    }
}
EOF
## 备节点
cat > /etc/keepalived/keepalived.conf <<- 'EOF'
! Configuration File for keepalived

global defs {
    router_id  k8s-master2 ##标识节点的字符串，通常为hostname
    vrrp_skip_check_adv_addr
    vrrp_strict
    vrrp_garp_interval 0
    vrrp_gna_interval 0
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
    mcast_src_ip ndoe03 ##本机ip地址
    priority 100 ##优先级(0-254)
    #nopreempt
    advert_int 1    ##组播信息发送间隔，两个节点必须一致,默认1s
    authentication {    ##认证匹配
        auth_type PASS
        auth_pass bhz
    }
    track_script {
        chk_haproxy
    }
    virtual_ipaddress {
        外网IP dev eth0 label ha:net ##虚拟ip,可以指定多个
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