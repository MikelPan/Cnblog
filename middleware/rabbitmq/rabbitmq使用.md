## RabbitMQ 原理介绍及配置详解
### RabbitMQ简介
RabbitMQ是流行的开源消息队列系统，是AMQP（Advanced Message Queuing Protocol高级消息队列协议）的标准实现，用erlang语言开发。RabbitMQ据说具有良好的性能和时效性，同时还能够非常好的支持集群和负载部署，非常适合在较大规模的分布式系统中使用。

Rabbit模式大概分为以下三种：单一模式、普通模式、镜像模式
单一模式：最简单的情况，非集群模式，即单实例服务。

普通模式：默认的集群模式。
queue创建之后，如果没有其它policy，则queue就会按照普通模式集群。对于Queue来说，消息实体只存在于其中一个节点，A、B两个节点仅有相同的元数据，即队列结构，但队列的元数据仅保存有一份，即创建该队列的rabbitmq节点（A节点），当A节点宕机，你可以去其B节点查看，./rabbitmqctl list_queues 发现该队列已经丢失，但声明的exchange还存在。
当消息进入A节点的Queue中后，consumer从B节点拉取时，RabbitMQ会临时在A、B间进行消息传输，把A中的消息实体取出并经过B发送给consumer。
所以consumer应尽量连接每一个节点，从中取消息。即对于同一个逻辑队列，要在多个节点建立物理Queue。否则无论consumer连A或B，出口总在A，会产生瓶颈。
该模式存在一个问题就是当A节点故障后，B节点无法取到A节点中还未消费的消息实体。
如果做了消息持久化，那么得等A节点恢复，然后才可被消费；如果没有持久化的话，队列数据就丢失了。

镜像模式：把需要的队列做成镜像队列，存在于多个节点，属于RabbitMQ的HA方案。
该模式解决了上述问题，其实质和普通模式不同之处在于，消息实体会主动在镜像节点间同步，而不是在consumer取数据时临时拉取。
该模式带来的副作用也很明显，除了降低系统性能外，如果镜像队列数量过多，加之大量的消息进入，集群内部的网络带宽将会被这种同步通讯大大消耗掉。
所以在对可靠性要求较高的场合中适用，一个队列想做成镜像队列，需要先设置policy，然后客户端创建队列的时候，rabbitmq集群根据“队列名称”自动设置是普通集群模式或镜像队列。具体如下：
队列通过策略来使能镜像。策略能在任何时刻改变，rabbitmq队列也近可能的将队列随着策略变化而变化；非镜像队列和镜像队列之间是有区别的，前者缺乏额外的镜像基础设施，没有任何slave，因此会运行得更快。
为了使队列称为镜像队列，你将会创建一个策略来匹配队列，设置策略有两个键“ha-mode和 ha-params（可选）”。

了解集群中的基本概念：
RabbitMQ的集群节点包括内存节点、磁盘节点。顾名思义内存节点就是将所有数据放在内存，磁盘节点将数据放在磁盘。不过，如前文所述，如果在投递消息时，打开了消息的持久化，那么即使是内存节点，数据还是安全的放在磁盘。
一个rabbitmq集群中可以共享user，vhost，queue，exchange等，所有的数据和状态都是必须在所有节点上复制的，一个例外是，那些当前只属于创建它的节点的消息队列，尽管它们可见且可被所有节点读取。rabbitmq节点可以动态的加入到集群中，一个节点它可以加入到集群中，也可以从集群环集群会进行一个基本的负载均衡。

集群中有两种节点：
1 内存节点：只保存状态到内存（一个例外的情况是：持久的queue的持久内容将被保存到disk）
2 磁盘节点：保存状态到内存和磁盘。
内存节点虽然不写入磁盘，但是它执行比磁盘节点要好。集群中，只需要一个磁盘节点来保存状态就足够了如果集群中只有内存节点，那么不能停止它们，否则所有的状态，消息等都会丢失。

RabitMQ的工作流程

对于RabbitMQ来说,除了这三个基本模块以外,还添加了一个模块,即交换机(Exchange).它使得生产者和消息队列之间产生了隔离,生产者将消息发送给交换机,而交换机则根据调度策略把相应的消息转发给对应的消息队列.那么RabitMQ的工作流程如下所示:

![](https://images2015.cnblogs.com/blog/972319/201703/972319-20170311161512951-1006030113.png)

交换机的主要作用是接收相应的消息并且绑定到指定的队列.交换机有四种类型,分别为Direct,topic,headers,Fanout.
- Direct是RabbitMQ默认的交换机模式,也是最简单的模式.即创建消息队列的时候,指定一个BindingKey.当发送者发送消息的时候,指定对应的Key.当Key和消息队列的BindingKey一致的时候,消息将会被发送到该消息队列中.
- topic转发信息主要是依据通配符,队列和交换机的绑定主要是依据一种模式(通配符+字符串),而当发送消息的时候,只有指定的Key和该模式相匹配的时候,消息才会被发送到该消息队列中.
- headers也是根据一个规则进行匹配,在消息队列和交换机绑定的时候会指定一组键值对规则,而发送消息的时候也会指定一组键值对规则,当两组键值对规则相匹配的时候,消息会被发送到匹配的消息队列中.
- Fanout是路由广播的形式,将会把消息发给绑定它的全部队列,即便设置了key,也会被忽略.

### RabbitMQ 虚拟主机
每一个RabbitMQ服务器都能创建虚拟消息服务器，我们称之为虚拟主机。每一个vhost本质上是一个mini版的RabbitMQ服务器，拥有自己的交换机、队列、绑定等，拥有自己的权限机制。vhost之于Rabbit就像虚拟机之于物理机一样。他们通过在各个实例间提供逻辑上分离，允许为不同的应用程序安全保密的运行数据，这很有，它既能将同一个Rabbit的众多客户区分开来，又可以避免队列和交换器的命名冲突。RabbitMQ提供了开箱即用的默认的虚拟主机“/”，如果不需要多个vhost可以直接使用这个默认的vhost，通过使用缺省的guest用户名和guest密码来访问默认的vhost。

vhost之间是相互独立的，这避免了各种命名的冲突，就像App中的沙盒的概念一样，每个沙盒是相互独立的，且只能访问自己的沙盒，以保证非法访问别的沙盒带来的安全隐患。

#### RabbitMQ 虚拟主机操作
```bash
#列举所有虚拟主机 
rabbitmqctl list_vhosts
#添加虚拟主机 
rabbitmqctl add_vhost <vhost_name>
#删除虚拟主机
rabbitmqctl delete_vhost <vhost_name>
#添加用户 
add_user <username> <password>
#设置用户标签 
set_user_tags <username> <tag>// 设置这个才能在页面上登录,tag可以为administrator, monitoring, management
#设置权限 
set_permissions [-p <vhost>] <user> <conf> <write> <read>
权限配置包括：配置(队列和交换机的创建和删除)、写(发布消息)、读(有关消息的任何操作，包括清除这个队列)
conf:一个正则表达式match哪些配置资源能够被该用户访问。
write:一个正则表达式match哪些配置资源能够被该用户读。
read:一个正则表达式match哪些配置资源能够被该用户访问。
```


![](https://imgconvert.csdnimg.cn/aHR0cDovL2ltZy5ibG9nLmNzZG4ubmV0LzIwMTcxMjA2MTg0OTQ3ODc2)



### RabbitMQ安装使用
#### 安装erlang
[下载地址](https://packagecloud.io/rabbitmq/erlang/packages/el/7/erlang-23.0.2-1.el7.x86_64.rpm)

```bash
# 下载erlang
wget --content-disposition https://packagecloud.io/rabbitmq/erlang/packages/el/7/erlang-23.0.2-1.el7.x86_64.rpm/download.rpm
# 安装erlang
yum localinstall -y erlang-23.0.2-1.el7.x86_64.rpm
```
#### 安装RabitMQ
```bash
# 下载ｍｑ
wget https://github.com/rabbitmq/rabbitmq-server/releases/download/v3.8.5/rabbitmq-server-3.8.5-1.el7.noarch.rpm
# 导入key
rpm --import https://www.rabbitmq.com/rabbitmq-release-signing-key.asc
# 安装ｍｑ
yum localinstall rabbitmq-server-3.8.5-1.el7.noarch.rpm
# 启动
systemctl start rabbitmq-server
# 配置开机启动
systemctl enable rabbitmq-server
```
#### RabbitMQ 启用管理页面
```bash
rabbitmq-plugins enable rabbitmq_management
#　配置权限
chown -R rabbitmq:rabbitmq /var/lib/rabbitmq/
# 设置管理员密码
rabbitmqctl add_user admin StrongPassword
# 分配角色
rabbitmqctl set_user_tags admin administrator
# 配置权限
rabbitmqctl set_permissions -p / admin ".*" ".*" ".*"
```

#### RabbitMQ 添加虚拟主机
权限配置是针对于vhost进行配置的，如果有多个vhost，如果某个用户需要相同的配置就要配置多次。".":匹配任何队列和交换器，"checks-.":只匹配checks-开头的队列和交换器，"":不匹配队列和交换器，
```bash
# 添加用户
rabbitmqctl add_user root root
# 分配角色
rabbitmqctl set_user_tags root administrator
# 添加虚拟主机
rabbitmqctl add_vhost my_vhost
# 设置权限
rabbitmqctl set_permissions -p my_vhost root ".*" ".*" ".*"
```


### RabbitMQ用户角色及权限控制
#### RabbitMQ的用户角色分类
- none
- management
- policymaker
- monitoring
- administrator

#### RabbitMQ各类角色描述

- none

    不能访问 management plugin

- management

    用户可以通过AMQP做的任何事外加：
    列出自己可以通过AMQP登入的virtual hosts  
    查看自己的virtual hosts中的queues, exchanges 和 bindings
    查看和关闭自己的channels 和 connections
    查看有关自己的virtual hosts的“全局”的统计信息，包含其他用户在这些virtual hosts中的活动。

- policymaker management
    可以做的任何事外加：
    查看、创建和删除自己的virtual hosts所属的policies和parameters

- monitoring  
    management可以做的任何事外加：
    列出所有virtual hosts，包括他们不能登录的virtual hosts
    查看其他用户的connections和channels
    查看节点级别的数据如clustering和memory使用情况
    查看真正的关于所有virtual hosts的全局的统计信息

- administrator   
    policymaker和monitoring可以做的任何事外加:
    创建和删除virtual hosts
    查看、创建和删除users
    查看创建和删除permissions
    关闭其他用户的connections

#### 创建用户并设置角色

可以创建管理员用户，负责整个MQ的运维，例如：
```bash
sudo rabbitmqctl add_user  user_admin  passwd_admin  
#赋予其administrator角色：
sudo rabbitmqctl set_user_tags user_admin administrator
```

可以创建RabbitMQ监控用户，负责整个MQ的监控，例如：
```bash
sudo rabbitmqctl add_user  user_monitoring  passwd_monitor 
#赋予其monitoring角色
sudo rabbitmqctl set_user_tags user_monitoring monitoring
```

可以创建某个项目的专用用户，只能访问项目自己的virtual hosts
```bash
sudo rabbitmqctl  add_user  user_proj  passwd_proj  
#赋予其monitoring角色：
sudo rabbitmqctl set_user_tags user_proj management  
```

创建和赋角色完成后查看并确认
```bash
sudo rabbitmqctl list_users
```

#### RabbitMQ权限控制

默认virtual host："/"
默认用户：guest
guest具有"/"上的全部权限，仅能有localhost访问RabbitMQ包括Plugin，建议删除或更改密码。可通过将配置文件中loopback_users置孔来取消其本地访问的限制：
[{rabbit, [{loopback_users, []}]}]

用户仅能对其所能访问的virtual hosts中的资源进行操作。这里的资源指的是virtual hosts中的exchanges、queues等，操作包括对资源进行配置、写、读。配置权限可创建、删除、资源并修改资源的行为，写权限可向资源发送消息，读权限从资源获取消息。比如：
exchange和queue的declare与delete分别需要exchange和queue上的配置权限
exchange的bind与unbind需要exchange的读写权限
queue的bind与unbind需要queue写权限exchange的读权限
发消息(publish)需exchange的写权限
获取或清除(get、consume、purge)消息需queue的读权限
对何种资源具有配置、写、读的权限通过正则表达式来匹配，具体命令如下：
```bash
set_permissions [-p <vhostpath>] <user> <conf> <write> <read>
```

其中,`<conf>`,`<read>`,`<write>`的位置分别用正则表达式来匹配特定的资源，如'^(amq\.gen.*|amq\.default)$'可以匹配server生成的和默认的exchange，'^$'不匹配任何资源

需要注意的是RabbitMQ会缓存每个connection或channel的权限验证结果、因此权限发生变化后需要重连才能生效。

#### 为用户赋权
```bash
sudo rabbitmqctl  set_permissions -p /vhost1  user_admin '.*' '.*' '.*'  
```
该命令使用户user_admin具有/vhost1这个virtual host中所有资源的配置、写、读权限以便管理其中的资源

*查看权限*

```bash
sudo rabbitmqctl list_user_permissions user_admin  
Listing permissions for user "user_admin" ...  
/vhost1<span style="white-space:pre"> </span>.*<span style="white-space:pre"> </span>.*<span style="white-space:pre"> </span>.*  
# 
sudo rabbitmqctl list_permissions -p /vhost1  
Listing permissions in vhost "/vhost1" ...  
user_admin<span style="white-space:pre">  </span>.*<span style="whitet-space:pre"> </span>.*<span style="white-space:pre"> </span>.*
```

### rabbitmqadmin 使用
#### rabbitmqadmin 安装

```bash
# 下载
wget https://raw.githubusercontent.com/rabbitmq/rabbitmq-management/v3.8.9/bin/rabbitmqadmin -P /usr/local/src
chmod +x /usr/local/src/rabbitmqadmin && cp /usr/local/src/rabbitmqadmin /usr/bin
```
#### rabbitmqadmin 使用

```bash
rabbitmqadmin list users                #查看用户列表
rabbitmqadmin list vhosts               #查看vhosts
rabbitmqadmin list connections          ###查看 connections
rabbitmqadmin list exchanges            ##查看 exchanges
rabbitmqadmin list bindings             ##查看 bindings
rabbitmqadmin list permissions          ##查看 permissions
rabbitmqadmin list channels             ##查看 channels
rabbitmqadmin list parameters           ##查看 parameters
rabbitmqadmin list consumers            ##查看consumers
rabbitmqadmin list queues               ##查看queues
rabbitmqadmin list policies             ##查看policies
rabbitmqadmin list nodes                ##查看nodes
rabbitmqadmin show overview             ##查看overview
使用 -f 可以指定格式
有如下几种格式 raw_json, long, pretty_json, kvp, tsv, table, bash 默认为 table
修改 rabbitmqadmin文件 default_options 中的 hostname 为 任意 RabbitMQ 节点 或者 Haproxy 节点 ip 或者 Keepalived vip，若修改了guest 用户，还需要修改 default_options 中用户名和密码配置
```

### rabbitmq 安装插件

插件地址如下：https://www.rabbitmq.com/community-plugins.html 

![](https://img-blog.csdnimg.cn/20191127171340814.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxXzM2ODUwODEz,size_16,color_FFFFFF,t_70)
```bash
# 下载插件
wget https://github.com/rabbitmq/rabbitmq-delayed-message-exchange/releases/download/v3.8.0/rabbitmq_delayed_message_exchange-3.8.0.ez -P /usr/local/src
# 放到指定目录下
mv /usr/local/src/rabbitmq_delayed_message_exchange-3.8.0.ez /usr/lib/rabbitmq/lib/rabbitmq_server-3.8.5/plugins
# 启用插件
rabbitmq-plugins enable rabbitmq_delayed_message_exchange
# 重启服务
systemctl restart rabitmq-server
```

### rabbitmq 集群搭建

rabbitmq 架构图如下：
![](https://upload-images.jianshu.io/upload_images/4325076-5f863f419723664c.png?imageMogr2/auto-orient/strip|imageView2/2/w/966/format/webp)

对于消息的生产和消费者可以通过HAProxy的软负载将请求分发至RabbitMQ集群中的Node1～Node7节点，其中Node8～Node10的三个节点作为磁盘节点保存集群元数据和配置信息。鉴于篇幅原因这里就不在对监控部分进行详细的描述的，会在后续篇幅中对如何使用RabbitMQ的HTTP API接口进行监控数据统计进行详细阐述。

#### RabbitMQ集群方案的原理

RabbitMQ这款消息队列中间件产品本身是基于Erlang编写，Erlang语言天生具备分布式特性（通过同步Erlang集群各节点的magic cookie来实现）。因此，RabbitMQ天然支持Clustering。这使得RabbitMQ本身不需要像ActiveMQ、Kafka那样通过ZooKeeper分别来实现HA方案和保存集群的元数据。集群是保证可靠性的一种方式，同时可以通过水平扩展以达到增加消息吞吐量能力的目的。 下面先来看下RabbitMQ集群的整体方案：

Exchange （交换器）的元数据信息在所有节点上是一致的，而Queue（存放消息的队列）的完整数据则只会存在于它所创建的那个节点上。，其他节点只知道这个queue的metadata信息和一个指向queue的owner node的指针。

#### RabbitMQ集群元数据的同步

RabbitMQ集群会始终同步四种类型的内部元数据（类似索引）：
a.队列元数据：队列名称和它的属性；
b.交换器元数据：交换器名称、类型和属性；
c.绑定元数据：一张简单的表格展示了如何将消息路由到队列；
d.vhost元数据：为vhost内的队列、交换器和绑定提供命名空间和安全属性；
因此，当用户访问其中任何一个RabbitMQ节点时，通过rabbitmqctl查询到的queue／user／exchange/vhost等信息都是相同的。

#### 为何RabbitMQ集群仅采用元数据同步的方式

我想肯定有不少同学会问，想要实现HA方案，那将RabbitMQ集群中的所有Queue的完整数据在所有节点上都保存一份不就可以了么？（可以类似MySQL的主主模式嘛）这样子，任何一个节点出现故障或者宕机不可用时，那么使用者的客户端只要能连接至其他节点能够照常完成消息的发布和订阅嘛。
我想RabbitMQ的作者这么设计主要还是基于集群本身的性能和存储空间上来考虑。第一，存储空间，如果每个集群节点都拥有所有Queue的完全数据拷贝，那么每个节点的存储空间会非常大，集群的消息积压能力会非常弱（无法通过集群节点的扩容提高消息积压能力）；第二，性能，消息的发布者需要将消息复制到每一个集群节点，对于持久化消息，网络和磁盘同步复制的开销都会明显增加。

#### RabbitMQ集群的搭建

##### 节点准备

|序号|主机名|节点类型|备注|
|----|----|----|----|
|1|node1|磁盘||
|2|node2|磁盘||
|3|node3|内存||
|4|node4|内存||
|5|node5|内存||
|6|node6|内存||

##### 配置免密，hosts
```bash
# 五台节点上都操作
ssh-keygen -t rsa 2096
# 配置hostname
hostnamectl set-hostname node1,node2,node3,node4,node5
#配置hosts解析
cat >> /etc/hosts <<- 'EOF'
192.168.1.1 node1
192.168.1.2 node2
192.168.1.3 node3
192.168.1.4 node4
192.168.1.5 node5
192.168.1.6 node6
EOF
```
##### 初始化集群
```bash
# 拷贝cookie
scp /var/lib/rabbitmq/.erlang.cookie root@node2,3,4,5://var/lib/rabbitmq/.erlang.cookie
# 添加权限
chown -R rabbitmq:rabbitmq /var/lib/rabbitmq
# 其他节点重启
systemctl restart rabbitmq-server

# 其他节点上操作
## 节点2上操作
rabbitmqctl stop_app 
rabbitmqctl reset 
rabbitmqctl join_cluster rabbit@node1
rabbitmqctl start_app
## 节点3-5上执行
rabbitmqctl stop_app 
rabbitmqctl reset 
rabbitmqctl join_cluster --ram rabbit@node1
rabbitmqctl start_app
# 配置镜像队列
rabbitmqctl set_policy ha-all "^" '{"ha-mode":"all"}'
```
#### haproxy 安装 (node3-4）
```bash
# 安装haproxy
yum install gcc -y
yum install haproxy -y
# 修改配置
cat > ./haproxy.cfg <<- 'EOF'

#logging options
global
    log 127.0.0.1 local0 info
    maxconn 5120
    chroot /usr/local/haproxy
    uid 99
    gid 99
    daemon
    quiet
    nbproc 20
    pidfile /var/run/haproxy.pid
    
defaults
    log global
    # 使用四层代理模式,"mode http" 为7层代理模式
    mode tcp
    # if you set mode to tcp,then you must change tcplog into httplog
    option tcplog
    option dontlognull
    retries 3
    option redispatch
    maxconn 2000
    contimeout 5s
    # 客户端空闲超时时间为60秒，过了该时间，HA发起重连机制
    clitimeout 60s
    # 服务端连接超时时间为15秒，过了该时间，HA发起重连机制
    srvtimeout 15s

listen rabbitmq_cluster
    # 定义监听地址和端口，本机的5672端口
    bind 0.0.0.0:5672
    # 配置 tcp 模式
    mode tcp
    # balance url_param userid
    # balance url_param session_id check_post 64
    # 简单的轮询
    balance roundrobin
    #rabbitmq集群节点配置 #inter 每隔五秒对mq集群做健康检查，2次正确证明服务器可用，
    #2次失败证明服务器不可用，并且配置主备机制
    server node1 192.168.174.10:5672 check inter 5000 rise 2 fall 2
    server node2 192.168.174.11:5672 check inter 5000 rise 2 fall 2
    server node3 192.168.174.12:5672 check inter 5000 rise 2 fall 2
        
# 配置 haproxy web 监控，查看统计信息
listen stats
    bind *:8100
    mode http
    option httplog
    stats enable
    # 设置 haproxy 监控地址为：http://localhost:8100/rabbitmq-stats
    stats uri /rabbitmq-stats
    stats refresh 5s
EOF
```
#### 源码安装

```bash
# 源代码安装
yum install -y openssl openssl-devel
yum install -y gcc
# 创建组
group add haproxy
useradd -g haproxy haproxy -s /bin/false
tar zxvf haproxy-1.6.9.tar.gz
cd haproxy-1.6.9
make TARGET=linux3100 CPU=x86_64 PREFIX=/usr/local/haprpxy #编译 uname -r #查看系统内核版本号
make install PREFIX=/usr/local/haproxy #安装
 
#数说明：
#TARGET=linux3100
#使用uname -r查看内核，如：2.6.18-371.el5，此时该参数就为linux26
#kernel 大于2.6.28的用：TARGET=linux2628
#CPU=x86_64 #使用uname -r查看系统信息，如x86_64 x86_64 x86_64 GNU/Linux，此时该参数就为x86_64
# 安装路径 PREFIX=/usr/local/haprpxy #/usr/local/haprpxy为haprpxy安装路径、

# 启动haproxy
service haproxy start #启动
service haproxy stop #关闭
service haproxy restart #重启
```

#### 配置haproxy
```bash

```

#### 配置日志轮转(syslog)
```bash
vi /etc/syslog.conf #编辑，在最下边增加
# haproxy.log
local0.*   /var/log/haproxy.log
local3.*   /var/log/haproxy.log
:wq! #保存退出
 
vi /etc/sysconfig/syslog #编辑修改
SYSLOGD_OPTIONS="-r -m 0" #接收远程服务器日志
:wq! #保存退出
# 重启syslog
service syslog restart #重启syslog
```

#### 安装keeplived
##### 配置文件
*node5配置如下*
```bash
! Configuration File for keepalived

global defs {
    router_id node5 ##标识节点的字符串，通常为hostname
}

vrrp_script chk_haproxy{
    script "/etc/keepalived/haproxy_check.sh"   ## 执行脚本位置
    interval 2  ##检查时间间隔
    weight -20 ##如果条件成立则权重减20
}

vrrp_instance VI_1 {
    state MASTER##主节点为MASTER,备份节点为BACKUP
    interface ens33 ##绑定虚拟ip的网络接口(网卡)
    virtual_router_id 13    ##虚拟路由id号，主备节点相同
    mcast_src_ip 192.168.174.13 ##本机ip地址
    priority 100    ##优先级(0-254)
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
        192.168.174.70 ##虚拟ip,可以指定多个
    }
}
```
*node6配置如下*

```bash
! Configuration File for keepalived

global defs {
    router_id node6 ##标识节点的字符串，通常为hostname
}

vrrp_script chk_haproxy{
    script "/etc/keepalived/haproxy_check.sh"   ## 执行脚本位置
    interval 2  ##检查时间间隔
    weight -20 ##如果条件成立则权重减20
}

vrrp_instance VI_1 {
    state BACKUP ##主节点为MASTER,备份节点为BACKUP
    interface ens33 ##绑定虚拟ip的网络接口(网卡)
    virtual_router_id 13    ##虚拟路由id号，主备节点相同
    mcast_src_ip 192.168.174.14 ##本机ip地址
    priority 90 ##优先级(0-254)
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
        192.168.174.70 ##虚拟ip,可以指定多个
    }
}
```
*haproxy_check 执行脚本如下*
```bash
#!/bin/bash
COUNT = `ps -C haproxy --no-header | wc -l`
if [$COUNT -eq 0];then
    /usr/local/haproxy/sbin/haproxy -f /etc/haproxy/haproxy.cfg
    sleep 2
    if[`ps -C haproxy --no-header | wc -l` -eq 0];then
        killall keepalived
    fi
fi
```
*添加脚本执行权限*

```bash
chmod +x haproxy_check.sh
```
*启动keeplived*

```bash
service keepalived start
```

#### 集群管理

集群管理常用命令

```bash
# 查看集群状态
rabbitmqctl cluster_status
# 启动节点
rabbitmq-server -detached  
# 启动应用
rabbitmqctl start_app 启动RabbitMQ应用，而不是节点
# 停止应用
rabbitmqctl stop_app  停止
# 移除节点
## 停止应用
rabbitmqctl stop_app
## 主节点上执行
rabbitmqctl  -n rabbit@node1 forget_cluster_node rabbit@node2
# 重置
rabbitmqctl reset application重置
```



