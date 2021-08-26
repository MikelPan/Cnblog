## consul 简介
Consul是一个**服务网格**解决方案，提供了一个功能齐全的控制平面，具有服务发现、配置和分段功能。这些功能中的每一项都可以根据需要单独使用，也可以一起使用来构建一个完整的**服务网格**。Consul需要一个数据平面，并支持代理和原生集成模型。Consul提供了一个简单的内置代理，因此一切都可以开箱即用，但也支持第三方代理集成，如**Envoy**。 回顾下面的视频，向HashiCorp的联合创始人Armon了解更多关于Consul的信息

## consul实现功能
- 服务发现（Service Discovery）： `Consul` 提供了通过DNS或者HTTP接口的方式来注册服务和发现服务。一些外部的服务通过Consul很容易的找到它所依赖的服务。
- 健康检查（Health Checking）：Consul的Client可以提供任意数量的健康检查，既可以与给定的服务相关联(“webserver是否返回200 OK”)，也可以与本地节点相关联(“内存利用率是否低于90%”)。操作员可以使用这些信息来监视集群的健康状况，服务发现组件可以使用这些信息将流量从不健康的主机路由出去。
- Key/Value存储：应用程序可以根据自己的需要使用Consul提供的Key/Value存储。 Consul提供了简单易用的HTTP接口，结合其他工具可以实现动态配置、功能标记、领袖选举等等功能。
- 安全服务通信：Consul可以为服务生成和分发TLS证书，以建立相互的TLS连接。意图可用于定义允许哪些服务通信。服务分割可以很容易地进行管理，其目的是可以实时更改的，而不是使用复杂的网络拓扑和静态防火墙规则。
- 多数据中心：Consul支持开箱即用的多数据中心. 这意味着用户不需要担心需要建立额外的抽象层让业务扩展到多个区域

## consul 使用场景
Consul的应用场景包括服务发现、服务隔离、服务配置：

- 服务发现场景中consul作为注册中心，服务地址被注册到consul中以后，可以使用consul提供的dns、http接口查询，consul支持health check。
- 服务隔离场景中consul支持以服务为单位设置访问策略，能同时支持经典的平台和新兴的平台，支持tls证书分发，service-to-service加密。
- 服务配置场景中consul提供key-value数据存储功能，并且能将变动迅速地通知出去，借助Consul可以实现配置共享，需要读取配置的服务可以从Consul中读取到准确的配置信息。
- Consul可以帮助系统管理者更清晰的了解复杂系统内部的系统架构，运维人员可以将Consul看成一种监控软件，也可以看成一种资产（资源）管理系统。

### cousul 引入目前环境中


#### consul 搭建
```bash
# 使用helm安装
helm upgrade --install consul stable/consul --set service.replicas=1 -n kube-system --debug 
```

#### consul使用

1、服务注册
> 通过配置文件静态注册
创建文件夹/etc/consul.d
```bash
mkdir -pv /etc/consul.d
```
创建服务写入文件中
```bash
cat > /etc/consul.d <<- 'EOF'
{
    "service: {
        "name": "",
        "tags": "",
        "port": 80,
    }
}
EOF
```
注册服务
```bash
consul agent -dev -config-dir /etc/consul.d/
```
> 通过HTTP API接口注册
```bash
cat > register.json <<- 'EOF'
{
    "ID": "falsk-1",
    "Name": "flask",
    "Address": "172.31.49.221",
    "Port": 5000,
    "Tags": [
        "v1",
        "web"
    ],
    "EnableTagOverride": false,
    "Check": {
        "DeregisterCriticalServiceAfter": "12h",
        "HTTP": "http://172.31.49.221:5000/health",
        "Interval": "10s"
    }
}
EOF
# 注册
curl -XPUT -d @register.json https://consul.01member.com/v1/agent/service/register
```
2、服务查询
> HTTP APi 方式

查询单个服务
```bash
curl -v https://consul.01member.com/v1/catalog/service/flask
```
列出服务
```bash
curl -v https://consul.01member.com/v1/agent/members
```
查询健康状态为passing的节点
```bash
curl -v https://consul.01member.com/v1/health/service/flask?passing
```

查询异常的服务
```bash
curl -v https://consul.01member.com/v1/health/state/critical
```

> DNS API 查询

服务的 DNS 名是 NAME.service.consul。默认情况下，所有 DNS 名都在 consul 命名空间，也可以配置。service 子域告诉 Consul 我们要查询的是服务，NAME 则是服务的名字

```bash
dig @127.0.0.1 -p 8600 flask.service.consul
```

用标签来筛选服务，格式是 TAG.NAME.service.consul。例子如下，我们查询“v1”标签，就会得到以该标签注册的服务

```bash
dig @127.0.0.1 -p 8600 v1.flask.service.consul 
```

### consul与监控结合使用

### k8s服务自动注册到consul集群中
修改无状态服务，添加env
```bash
          env:
          - name: POD_IP
            valueFrom:
              filedRef:
                filedPath: status.podIP
          - name: POD_NAME
            valueFrom:
              filedRef:
                filedPath: metadata.name
          - name: POD_NAME
            valueFrom:
              filedRef:
                filedPath: metadata.namespace
          - name: CONSUL_ADDR
            value: "consul-consul-server.kube-system.svc.cluster.local"
          - name: CONSUL_PORT
            value: "8500"
``` 