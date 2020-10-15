## 配置反向代理
### 创建加密认证
```bash
# 创建密码文件
cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 24
yum install -y http-tools
htpasswd -bc /usr/local/nginx/conf.d/passwd admin `cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 24`
chmod 400 /usr/local/nginx/conf.d/passwd
chown nginx /usr/local/nginx/conf.d/passwd
# 添加加密配置
server {
    listen 80;
    server_name _;
    location / {
        root html;
        index index.html index.htm;
        auth_basic "admin";
        auth_basic_user_file /usr/local/nginx/conf.d/passwd;
    }
    access_log off;
}
# 重新加载nginx
service nginx reload
```

### upstream配置
upstream apigateway{
    server ip:port weight=1 max_fails=2 fail_timeout=10s;
}
### proxy 配置
```bash
proxy_set _header Host $host;
proxy_set _header X-Forwarded-For $remode_addr;
proxy_connect_timeout 60;
proxy_sent_timeout 60;
proxy_read_timeout 60;
proxy_buffer_size 4k;
proxy_buffers 4 32k;
proxy_busy_buffers_size 64k;
proxy_temp_file_write_size 64k;
proxy_http_version 1.1;
proxy_set_header Connection "";
proxy_next_upstream invalid_header error timeout http_500 http_502 http_503 http_504;
```
[官方文档说明](http://nginx.org/en/docs/http/ngx_http_proxy_module.html)

### http nginx.conf 主配置文件
```bash
# 掩藏版本号
server_tokens off;
# 客户端请求文件大小
client_max_body_size  10m;

```
### nginx 模块使用
#### nginx_upstream_check_module 模块使用
```bash
# nginx_upstream_check_module 模块所支持的指令含义
Syntax:  check interval=milliseconds [fall=count] [rise=count] [timeout=milliseconds] [default_down=true|false] 
[type=tcp|http|ssl_hello|mysql|ajp] [port=check_port]

Default: 如果没有配置参数，默认值是：interval=30000 fall=5 rise=2 timeout=1000 default_down=true type=tcp
Context: upstream
 
# 该指令可以打开后端服务器的健康检查功能。指令后面的参数意义是：
1、interval：向后端发送的健康检查包的间隔。
2、fall(fall_count): 如果连续失败次数达到fall_count，服务器就被认为是down。
3、rise(rise_count): 如果连续成功次数达到rise_count，服务器就被认为是up。
4、timeout: 后端健康请求的超时时间，单位毫秒。
5、default_down: 设定初始时服务器的状态，如果是true，就说明默认是down的，如果是false，就是up的。默认值是true，也就是一开始服务器认为是不可用，要等健康检查包达到一定成功次数以后才会被认为是健康的。
6、type：健康检查包的类型，现在支持以下多种类型：
- tcp：简单的tcp连接，如果连接成功，就说明后端正常。
- ssl_hello：发送一个初始的SSL hello包并接受服务器的SSL hello包。
- http：发送HTTP请求，通过后端的回复包的状态来判断后端是否存活。
- mysql: 向mysql服务器连接，通过接收服务器的greeting包来判断后端是否存活。
- ajp：向后端发送AJP协议的Cping包，通过接收Cpong包来判断后端是否存活。
- port: 指定后端服务器的检查端口。你可以指定不同于真实服务的后端服务器的端口，比如后端提供的是443端口的应用，你可以去检查80端口的状态来判断后端健康状况。默认是0，表示跟后端server提供真实服务的端口一样。该选项出现于Tengine-1.4.0。
 
 
Syntax: check_keepalive_requests request_num
Default: 1
Context: upstream
该指令可以配置一个连接发送的请求数，其默认值为1，表示Tengine完成1次请求后即关闭连接。
 
Syntax: check_http_send http_packet
Default: "GET / HTTP/1.0\r\n\r\n"
Context: upstream
该指令可以配置http健康检查包发送的请求内容。为了减少传输数据量，推荐采用"HEAD"方法。
 
当采用长连接进行健康检查时，需在该指令中添加keep-alive请求头，如："HEAD / HTTP/1.1\r\nConnection: keep-alive\r\n\r\n"。 同时，在采用"GET"方法的情况下，请求uri的size不宜过大，确保可以在1个interval内传输完成，否则会被健康检查模块视为后端服务器或网络异常。
Syntax: check_http_expect_alive [ http_2xx | http_3xx | http_4xx | http_5xx ]
Default: http_2xx | http_3xx
Context: upstream
该指令指定HTTP回复的成功状态，默认认为2XX和3XX的状态是健康的。
 
Syntax: check_shm_size size
Default: 1M
Context: http
所有的后端服务器健康检查状态都存于共享内存中，该指令可以设置共享内存的大小。默认是1M，如果你有1千台以上的服务器并在配置的时候出现了错误，就可能需要扩大该内存的大小。
 
Syntax: check_status [html|csv|json]
Default: check_status html
Context: location
显示服务器的健康状态页面。该指令需要在http块中配置。
 
在Tengine-1.4.0以后，可以配置显示页面的格式。支持的格式有: html、csv、 json。默认类型是html。
也可以通过请求的参数来指定格式，假设‘/status’是你状态页面的URL， format参数改变页面的格式，比如：
/status?format=html
/status?format=csv
/status?format=json
 
同时你也可以通过status参数来获取相同服务器状态的列表，比如：
/status?format=html&status=down
/status?format=csv&status=up
 
下面是一个状态配置的范例：
http {
      server {
         location /nstatus {
             check_status;
             access_log off;
             #allow IP;
             #deny all;
         }
      }
}
```
#### nginx upstream check module 安装
```bash
# 安装
git clone https://github.com/yaoweibin/nginx_upstream_check_module.git
cd nginx_upstream_check_module
patch -p1 < /path/to/nginx_http_upstream_check_module/check_1.16.1+.patch
./configure --add-module=/path/to/nginx_http_upstream_check_module
make -j 3 && make install
# 配置
upstream cluster {

    # simple round-robin
    server 192.168.3.12:8080 weight=5 max_fails=3 fail_timeout=10s;
    server 192.168.3.13:8080 weight=5 max_fails=3 fail_timeout=10s;

    #check interval=3000 rise=2 fall=5 timeout=1000 type=http default_down=false;
    #check_keepalive_requests 100;
    #check_http_send "HEAD / HTTP/1.1\r\nConnection: keep-alive\r\n\r\n";
    #check_http_expect_alive http_2xx http_3xx;
}
```
### nginx 安装
```bash
# 下载
cd /usr/local/src
wget https://github.com/yaoweibin/nginx_upstream_check_module/archive/master.zip
unzip master.zip
# 下载nginx
wget http://nginx.org/download/nginx-1.19.2.tar.gz
tar -zxvf nginx-1.19.2.tar.gz
cd nginx-1.19.2
patch -p1 < ../nginx_upstream_check_module-master/check_1.9.2+.patch
# 编译安装
./configure --prefix=/usr/local/nginx \
    --with-http_flv_module \
    --add-module=../nginx_upstream_check_module-master/
    --user=nginx \
    --group=nginx \
    --prefix=/usr/local/nginx \
    --pid-path=/var/run/nginx.pid \
    --lock-path=/var/run/nginx.lock \
    --error-log-path=/var/log/nginx/error.log \
    --http-log-path=/var/log/nginx/access.log \
    --with-http_gzip_static_module \
    --with-http_stub_status_module \
    --with-http_ssl_module \
    --with-pcre \
    --with-file-aio \
    --with-http_realip_module \
    --without-http_scgi_module \
    --without-http_uwsgi_module \
    --without-http_fastcgi_module \
    --with-pcre=/usr/local/src/pcre-8.35 
&& make -j 3 && make install
# nginx 配置
vim /usr/local/nginx/conf/domain.conf
upstream LB-WWW {
      server 192.168.1.101:80; 
      server 192.168.1.102:80;
      check interval=3000 rise=2 fall=5 timeout=1000 type=http;
      check_keepalive_requests 100;
      check_http_send "HEAD / HTTP/1.1\r\nConnection: keep-alive\r\n\r\n";
      check_http_expect_alive http_2xx http_3xx;
    }
server {
     listen       80;
     server_name  www.wangshibo.com;
     access_log  /usr/local/nginx/logs/www-access.log main;
     error_log  /usr/local/nginx/logs/www-error.log;
     location / {
         proxy_pass http://LB-WWW;
         proxy_redirect off ;
         proxy_set_header Host $host;
         proxy_set_header X-Real-IP $remote_addr;
         proxy_set_header REMOTE-HOST $remote_addr;
         proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
         proxy_connect_timeout 300;         
         proxy_send_timeout 300;           
         proxy_read_timeout 600;             
         proxy_buffer_size 256k;             
         proxy_buffers 4 256k;              
         proxy_busy_buffers_size 256k;       
         proxy_temp_file_write_size 256k;    
         proxy_next_upstream error timeout invalid_header http_500 http_503 http_502 http_404 http_504;
         proxy_max_temp_file_size 128m;
         proxy_cache mycache;                            
         proxy_cache_valid 200 302 60m;                  
         proxy_cache_valid 404 1m;
        }
    location /ngstatus {
         check_status;
         access_log off;
         #allow IP;
         #deny all;
       }
}
```

### nginx location 配置
#### location 介绍
- location 是在 server 块中配置，用来通过匹配接收的uri来实现分类处理不同的请求，如反向代理，取静态文件等
- location 在 server 块中可以有多个，且是有顺序的，会被第一个匹配的 location 处理
#### localtion 匹配规则
- location [ = | ~ | ~* | ^~ ] uri { … }
- location @name { … }
##### "=" 精确匹配
内容要同表达式完全一致才匹配成功
```conf
location = / {
    ....
}
# 只匹配http://abc.com
# http://abc.com [匹配成功]
# http://abc.com/index [匹配失败]
```
##### "~"，大小写敏感
```conf
location ~ /Example/ {
  .....
}
#http://abc.com/Example/ [匹配成功]
#http://abc.com/example/ [匹配失败]
```
##### "~*"，大小写忽略
```conf
location ~* /Example/ {
  .....
}
# 则会忽略 uri 部分的大小写
#http://abc.com/test/Example/ [匹配成功]
#http://abc.com/example/ [匹配成功]
```
##### "^~"，只匹配以 uri 开头
```conf
location ^~ /index/ {
  .....
}
#以 /img/ 开头的请求，都会匹配上
#http://abc.com/index/index.page  [匹配成功]
#http://abc.com/error/error.page [匹配失败]
```
##### "@"，nginx内部跳转
```conf
location /index/ {
  error_page 404 @index_error;
}
location @index_error {
  .....
}
#以 /index/ 开头的请求，如果链接的状态为 404。则会匹配到 @index_error 这条规则上。
```
##### 不加任何规则
- 不加任何规则则时，默认是大小写敏感，前缀匹配，相当于加了“~”与“^~”
- 只有 / 表示匹配所有uri
```conf
location /index/ {
  ......
}
#http://abc.com/index  [匹配成功]
#http://abc.com/index/index.page  [匹配成功]
#http://abc.com/test/index  [匹配失败]
#http://abc.com/Index  [匹配失败]
# 匹配到所有uri
location / {
  ......
}
```

#### 配置实例
*正则匹配，location ~ /.*/event*
- location path后带/将会截断location中配置的path向上游发起请求
- location path后不带/将会带着location中配置的path向上游发起请求

不带/实际请求地址为：http://localhost/*/event/a.html
```conf
location ~ /.*/event {
        proxy_pass http://localhost$request_uri;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
       }
```
带/实际请求地址为: http://localhost/a.html
```conf
location ~ /.*/event/ {
        proxy_pass http://localhost$request_uri;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
       }
```

#### 变量使用
*使用变量匹配，位于server 块*

内置变量如下
```bash
$arg_参数名    在location中获取客户端请求的参数xx?name=123  那$arg_name就是对应的值123
$args, 请求中的参数字符串 比如 name=123&age=24
$content_length, HTTP请求信息里的"Content-Length"
$content_type, 请求信息里的"Content-Type"
$host, 请求信息中的"Host"，如果请求中没有Host行，则等于设置的服务器名
$request_method, 请求的方法，比如"GET"、"POST"等
$remote_addr, 客户端地址
$remote_port, 客户端端口号
$remote_user, 客户端用户名，认证用;
$request_filename, 当前请求的文件路径名
$request_uri, 请求的URI，带参数
$query_string, 与$args相同
$scheme, 所用的协议，比如http或者是https，比如rewrite  ^(.+)$  $scheme://example.com$1  redirect
$server_protocol, 请求的协议版本，"HTTP/1.0"或"HTTP/1.1"
$server_addr, 服务器地址
$server_name, 请求到达的服务器名
$server_port, 请求到达的服务器端口号
$uri, 请求的URI，可能和最初的值有不同，比如经过重定向之类的
$http_header参数名  可以用来获得header的值，比如$http_user_agent 就是获取header中的UA
```
变量使用
```conf
service {
    listen 80;
    server_name  localhost;
    if ( $request_uri = '/application/manage/list/accesswechat' ) {
       set $uri_weixin 1;
    }
    if ( $host = 'dev.01member.com' ) {
       set $uri_weixin "${uri_weixin}1";
    }
    if ( $scheme = 'http' ) {
       set $uri_weixin "${uri_weixin}1";
    }
    # 重写跳转地址
    #if ( $uri_weixin = '111') {
    #   rewrite ^ http://dev.01member.com$request_uri;
    #}
    location / {
        if ( $uri_weixin = '111' ) {
            proxy_pass http://localhost;
        }
    }
}
```
使用if时，proxy_pass 不能带URI parent，例如以下示例会报错
```conf
service {
    server_name  localhost;
    if ( $request_uri = '/application/manage/list/accesswechat' ) {
       set $uri_weixin 1;
    }
    if ( $host = 'dev.01member.com' ) {
       set $uri_weixin "${uri_weixin}1";
    }
    if ( $scheme = 'http' ) {
       set $uri_weixin "${uri_weixin}1";
    }
    # 重写跳转地址
    #if ( $uri_weixin = '111') {
    #   rewrite ^ http://dev.01member.com$request_uri;
    #}
    location / {
        if ( $uri_weixin = '111' ) {
            proxy_pass http://localhost/;
        }
    }
}
```













