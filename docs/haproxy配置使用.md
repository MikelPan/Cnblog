### haproxy配置文件
```shell
global
    maxconn 51200
    daemon
    uid 1000
    gid 1000
    log 127.0.0.1 local0 info
    chroot /usr/local/haproxy/
    pidfile /usr/local/haproxy/logs/haproxy.pid
    ssl-default-bind-ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE:ECDH:AES:HIGH:!NULL:!aNULL:!MD5:!ADH:!RC4:!DH:!DHE:!3DES
defaults
    option tcplog
    mode http
    option httplog
    option dontlognull
    option httpclose
    option forwardfor
    option redispatch
    retries 3
    timeout connect  5000ms
    timeout server 30000ms
    timeout client 30000ms
    balance roundrobin

listen admin
    stats enable    #启用统计页；基于默认的参数启用stats page
    bind 0.0.0.0:8888  
    mode http
    stats refresh 5s
    stats uri   /haproxy?stats（默认值）    #自定义stats page uri
    stats hide-version    #隐藏统计报告版本信息
    stats realm  HAProxy\ Statistics    #页面登陆信息
    stats auth  user:passwd    #验证账号和密码信息
    stats refresh 20s     #设定自动刷新时间间隔
    stats admin if TRUE    #如果验证通过，启用stats page 中的管理功能 
    log 127.0.0.1 local3 err
    
frontend  main
    bind *:80
    bind *:443  ssl crt /etc/haproxy/haproxy.crt
    bind *:8001  ssl crt /etc/haproxy/haproxy.crt
   
    log global
    
    # acl 规则
    acl k8s-dashboard hdr_beg(host) -i guthub.com
    use_backend dashboard if k8s-dashboard 
    
backend k8s-dashboard
    global
    server k8s-dashboard_01 127.0.0.1:8080 check     
```
### haproxy日志
```shell
# 配置日志
vim /etc/syslog.conf
local3.*        /var/log/haproxy.log  
local0.*        /var/log/haproxy.log  
SYSLOGD_OPTIONS="-r -m 0" 
systemctl restart syslog
```