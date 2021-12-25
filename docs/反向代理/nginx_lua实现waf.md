### WAF产生的背景
过去企业通常会采用防火墙，作为安全保障的第一道防线；当时的防火墙只是在第三层（网络层）有效的阻断一些数据包；而随着web应用的功能越来越丰富的时候，Web服务器因为其强大的计算能力，处理性能，蕴含较高的价值，成为主要的被攻击目标（第七层应用层）而传统防火墙在阻止利用应用程序漏洞进行的攻击方面，却没有办法；在此背景下，WAF(Web Application Firewall）应运而生。

### 什么是WAF
Web 应用防火墙 (WAF-Web Application Firewall) 旨在保护 Web 应用免受各类应用层攻击，例如跨站点脚本 (XSS)、SQL 注入，以及 cookie 中毒等应用是您重要数据的网关，因此针对应用发起的攻击就成为了造成漏洞的主要原因有了 WAF 就可以拦截一系列企图通过入侵系统来泄漏数据的攻击。

### 工作原理
![](https://cdn9.52xs.com.cn/d/2021090409085712.png)

1、用户通过浏览器向Web服务器发送网页请求
2、用户的请求到达Web服务器之前，WAF对用户的请求过滤
3、WAF拿到用户的HTTP请求参数去跟配置文件定义的规则做比较，如果匹配上就返回403拒绝，否则放行。
4、WEB服务器响应用户请求，把页面数据返回给用户。

### WAF作用
waf是通过执行一系列针对HTTP/HTTPS的安全策略来专门为Web应用提供保护的一款产品

### WAF和传统防火墙的区别
1.传统防火墙是工作在网络层(第三层)和传输层(第四层)
2.WAF是工作在应用层(第七层)
3.传统防火墙更多是对IP和端口进行过滤
4.WAF是对HTTP请求进行过滤，包括URL，IP，User-Agent等等。

### WAF和DDos
![](https://cdn9.52xs.com.cn/d/article/20210904/26323.jpg)

DDos的全称是Distributed Denial of service主要依靠一组计算机来发起对一个单一的目标系统的请求，从而造成目标系统资源耗尽而拒绝正常的请求

根据OSI网络模型，最常见的DDos有三类，第三层（网络层）DDos、第四层（传输层）DDos和第七层（应用层）DDos

WAF主要处理第七层DDos攻击，它在处理第七层DDos攻击时会比其它防护手段更高效一些WAF会对HTTP流量做详细的分析，这样WAF就能针对正常的访问请求进行建模，然后使用这些模型来区分正常的请求和攻击者使用机器人或者脚本触发的请求。

### Nginx WAF功能
- 支持IP白名单和黑名单功能，直接将黑名单的IP访问拒绝（新增cdip功能支持ip段）
- 支持URL白名单，将不需要过滤的URL进行定义
- 支持User-Agent的过滤，匹配自定义规则中的条目，然后进行处理
- 支持CC攻击防护，单个URL指定时间的访问次数，超过设定值（新增针对不同域名）
- 支持Cookie过滤，匹配自定义规则中的条目，然后进行处理
- 支持URL过滤，匹配自定义规则中的条目，如果用户请求的URL包含这些
- 支持URL参数过滤，原理同上
- 支持日志记录，将所有拒绝的操作，记录到日志中去
- 新增支持拉黑缓存（默认600秒）

### Nginx Waf防护流程
if whiteip() then
elseif blockip() then
elseif denycc() then
elseif ngx.var.http_Acunetix_Aspect then
    ngx.exit(444)
elseif ngx.var.http_X_Scan_Memo then
    ngx.exit(444)
elseif whiteurl() then
elseif ua() then
elseif url() then
elseif args() then
elseif cookie() then
elseif PostCheck then

- 检查IP白名单,通过就不检测;
- 检查IP黑名单，不通过即拒绝;
- 检查CC攻击，匹配即拒绝
- 检查http_Acunetix_Aspect扫描是否开启
- 检查http_X_Scan_Memo扫描是否开启
- 检查白名单URL检查;
- 检查UA，UA不通过即拒绝；
- 检查URL参数检查；
- 检查cookie；
- 检查post；

### 基于Nginx实现WAF
#### 安装依赖包
```bash
yum -y install gcc gcc-c++ autoconf automake make unzip
yum -y install zlib zlib-devel openssl openssl-devel pcre pcre-devel
```

#### 安装LuaJIT2.0
LuaJIT是Lua的即时编译器，简单来说，LuaJIT是一个高效的Lua虚拟机

```bash
# 进入目录
cd /usr/local/src

# 下载LuaJIT2.1
wget https://github.com/openresty/luajit2/archive/refs/heads/v2.1-agentzh.zip

# 解压
unzip v2.1-agentzh.zip && cd luajit2-2.1-agentzh

# 编译
make -j 3

# 安装
make install PREFIX=/usr/local/lj2

# 建立软连接
ln -sf /usr/local/lj2/lib/libluajit-5.1.so.2 /lib64/libluajit-5.1.so.2

# 添加环境变量
export LUAJIT_LIB=/usr/local/lj2/lib
export LUAJIT_INC=/usr/local/lj2/include/luajit-2.1
```

#### 安装ngx_devel_kit
kit模块是一个拓展nginx服务器核心功能的模块，第三方模块开发可以基于它来快速实现

```bash
# 进入目录
cd /usr/local/src

# 下载
wget https://github.com/vision5/ngx_devel_kit/archive/refs/tags/v0.3.1.tar.gz -O ngx_devel_kit.tar.gz

# 解压
tar zxxf ngx_devel_kit.tar.gz
```

#### 安装lua-nginx-module
ngx_lua_module 是一个nginx http模块，它把 lua 解析器内嵌到 nginx，用来解析并执行lua 语言编写的网页后台脚本。

ngx_lua模块的原理

1. 每个worker（工作进程）创建一个Lua VM，worker内所有协程共享VM；
2. 将Nginx I/O原语封装后注入 Lua VM，允许Lua代码直接访问；
3. 每个外部请求都由一个Lua协程处理，协程之间数据隔离；
4. Lua代码调用I/O操作等异步接口时，会挂起当前协程（并保护上下文数据），而不阻塞worker；
5. I/O等异步操作完成时还原相关协程上下文数据，并继续运行。

```bash
# 进入目录
cd /usr/local/src

# 下载
wget https://github.com/openresty/lua-nginx-module/archive/refs/tags/v0.10.14.zip

# 解压
unzip v0.10.14.zip
```

#### 安装nginx
```bash
# 进入目录
cd /usr/local/src

# 下载
wget http://nginx.org/download/nginx-1.21.0.tar.gz

# 解压
tar zxvf nginx-1.21.0.tar.gz

# 添加用户
groupadd nginx
useradd -g nginx nginx -s /sbin/nologin

# 编译
./configure --prefix=/usr/local/nginx \
    --with-http_ssl_module \
    --with-http_flv_module \
    --with-http_stub_status_module \
    --with-http_gzip_static_module \
    --with-http_realip_module \
    --with-pcre \
    --add-module=/usr/local/src/lua-nginx-module-0.10.14 \
    --add-module=/usr/local/src/ngx_devel_kit-0.3.1 \
    --with-stream \
    --user=nginx \
    --group=nginx \
    --pid-path=/var/run/nginx.pid \
    --lock-path=/var/run/nginx.lock \
    --error-log-path=/var/log/nginx/error.log \
    --http-log-path=/var/log/nginx/access.log \
    --with-pcre \
    --with-file-aio \
    --without-http_scgi_module \
    --without-http_uwsgi_module \
    --without-http_fastcgi_module

# 安装
make -j 3 && make install

# 修改配置(server 块添加配置)
vim /usr/local/nginx/conf/nginx.conf
location /lua {
    default_type 'text/plain';
 
    content_by_lua 'ngx.say("hello, lua")';
}

# 配置开机启动
cat > /usr/lib/systemd/system/nginx.service <<- 'EOF'
[Unit]
Description=The nginx HTTP and reverse proxy server
After=network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
PIDFile=/var/run/nginx.pid
# Nginx will fail to start if /run/nginx.pid already exists but has the wrong
# SELinux context. This might happen when running `nginx -t` from the cmdline.
# https://bugzilla.redhat.com/show_bug.cgi?id=1268621
ExecStartPre=/usr/bin/rm -f /var/run/nginx.pid
ExecStartPre=/usr/local/nginx/sbin/nginx -t
ExecStart=/usr/local/nginx/sbin/nginx
ExecReload=/bin/kill -s HUP $MAINPID
KillSignal=SIGQUIT
TimeoutStopSec=5
KillMode=process
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
# 启动nginx
systemctl start nginx
```

#### 安装nginx_lua_waf
```bash
# 进入目录
cd /usr/local/src

# 下载
wget https://github.com/loveshell/ngx_lua_waf/archive/refs/heads/master.zip

# 解压
unzip master.zip -d /usr/local/nginx/conf

# 更改目录名
mv /usr/local/nginx/conf/ngx_lua_waf-master /usr/local/nginx/conf/waf

# 创建攻击日志目录
mkdir -pv /usr/local/nginx/logs/hack
chown nginx /usr/local/nginx/logs/hack

# nginx http段添加配置
lua_package_path "/usr/local/nginx/conf/waf/?.lua";
lua_shared_dict limit 10m;
init_by_lua_file  /usr/local/nginx/conf/waf/init.lua;
access_by_lua_file /usr/local/nginx/conf/waf/waf.lua;

# 查看waf配置
cat /usr/local/nginx/conf/waf/config.lua
# 规则存放路径
RulePath = "/usr/local/nginx/conf/waf/wafconf/"
# 是否开启攻击信息记录，需要配置logdir
attacklog = "on"
# log存储目录，该目录需要用户自己新建，切需要nginx用户的可写权限
logdir = "/usr/local/nginx/logs/hack/"
# 是否拦截url访问
UrlDeny="on"
# 是否拦截后重定向
Redirect="on"
# 是否拦截cookie攻击
CookieMatch="on"
# 是否拦截post攻击
postMatch="on"
# 是否开启URL白名单
whiteModule="on"
# 填写不允许上传文件后缀类型
black_fileExt={"php","jsp"}
# ip白名单，多个ip用逗号分隔
ipWhitelist={"127.0.0.1"}
# ip黑名单，多个ip用逗号分隔
ipBlocklist={"192.168.10.1"}
# 是否开启拦截cc攻击(需要nginx.conf的http段增加lua_shared_dict limit 10m;)
CCDeny="off"
# 设置cc攻击频率，单位为秒.
# 默认1分钟同一个IP只能请求同一个地址100次
CCrate="100/60"
# 告警内容
html= [[Please go away~~]]

# 重新加载nginx
systemctl reload nginx
```

#### 测试waf防火墙
curl -v 10.155.14.125/?id=<script

### nginx结合lua实现接口
```bash
# 配置接口
cat > /usr/local/nginx/conf/conf.d/luatest.conf <<- 'EOF'
server {
    listen       80;
    server_name  _;
    access_log /usr/local/nginx/logs/luatest.log;
    error_log /usr/local/nginx/logs/luatest_error.log;

    location /luatest {
        default_type "text/html";
        content_by_lua_file /usr/local/nginx/lua/luatest.lua;

    }

    location /luamysql {
        default_type "text/html";
        content_by_lua_file /usr/local/nginx/lua/luamysql.lua;

    }

}
EOF
# 编写lua脚本
cat > /usr/local/nginx/lua/luatest.lua <<- 'EOF'
local request_uri = ngx.var.request_uri;
local args = ngx.req.get_uri_args()
ngx.say("request_uri: ", request_uri);
ngx.say("decode request_uri: ",ngx.unescape_uri(request_uri))
ngx.say("ngx.md5 : ", ngx.md5("123"))
ngx.say("ngx.http_time : ", ngx.http_time(ngx.time()))
ngx.say("ngx.id: ",args.id)
EOF

cat > /usr/local/nginx/lua/luamysql.lua <<- 'EOF'
a = 5
local b =5
function joke()
    c = 5
    local d = 6
end
joke()
ngx.say(c,d)
EOF
```
