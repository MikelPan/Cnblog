## OpenRsty nginx 高性能web架构
### OpenResty概述
OpenResty是一个基于Nginx与Lua的高性能Web平台，集成了大量精良的Lua库、第三方模块以及大多数的依赖项，用于方便地搭建能够处理超高并发、扩展性极高的动态Web应用、Web服务和动态网关。

OpenResty通过汇聚各种设计精良的Nginx模块（主要由OpenResty团队自主开发），从而将Nginx有效地变成一个强大的通用Web应用平台。这样，Web开发人员和系统工程师可以使用Lua脚本语言调动Nginx支持的各种C以及Lua模块，快速构造出足以胜任10K乃至1000K以上单机并发连接的高性能Web应用系统。

OpenResty致力于将服务器端应用完全运行于Nginx服务器中，充分利用Nginx的事件模型进行非阻塞I/O通信，不仅仅和HTTP客户端间的网络通信是非阻塞的，与MySQL、PostgreSQL、Memcached以及Redis等众多后端之间的网络通信也是非阻塞的。

因为OpenResty软件包的维护者也是其中打包的许多Nginx模块的作者，所以Open-Resty可以确保所包含的所有组件可以可靠地协同工作.

### OpenResty 安装运行
```bash
# 安装
wget https://openresty.org/download/openresty-1.15.8.3.tar.gz -P /apps/software
tar zxvf /apps/software/openresty-1.15.8.3.tar.gz -C /usr/local/src
yum install readline-devel pcre-devel openssl-devel
cd /usr/local/src/openresty-1.15.8.3 && ./configure --prefix=/opt/openresty \
    --with-luajit \
    --without-http_redis2_module \
    --with-http_iconv_module \
    --with-http_v2_module \
    --without-http_ssi_module \
    --without-http_fastcgi_module \
    --with-http_realip_module  \
    --user openresty \
    --group openresty
make -j 3 && make install
# 添加环境变量
echo "export PATH=/opt/openresty/bin:$PATH" /etc/profile.d/openrsty.sh
source /etc/profile
# 运行
openrsty #启动
openrsty -s stop #停止
```

### Lua语言介绍



