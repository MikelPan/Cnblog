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
    "ID": "falsk",
    "Name": "flask",
    "Address": "172.31.49.221",
    "Port": 5001,
    "Tags": [
      "flask"
    ],
    "EnableTagOverride": false,
    "Check": {
      "name": "telnet tcp on port 5001",
      "tcp": "172.31.49.221:5001",
      "interval": "10s",
      "timeout": "1s"
    }
}
EOF
# 注册
curl -XPUT -d @register.json https://consul.01member.com/v1/agent/service/register
# 注册node-export到consul中
cat > node-export.register.json <<- 'EOF'
{
    "ID": "prometheus-node-export",
    "Name": "prometheus-node-export",
    "Address": "prometheus-operator-prometheus-node-exporter.kube-system.svc.cluster.local",
    "Port": 9100,
    "Tags": [
        "node-export"
    ],
    "Meta": {
        "project": "bigdata"
    }, 
    "EnableTagOverride": false,
    "Check": {
        "DeregisterCriticalServiceAfter": "12h",
        "HTTP": "http://prometheus-operator-prometheus-node-exporter.kube-system.svc.cluster.local:9100/metrics",
        "Interval": "10s"
    }
}
EOF
curl -XPUT -d @node-export.register.json https://consul.01member.com/v1/agent/service/register
# 注册web服务到consul中
cat > flask-1.register.json <<- 'EOF'
{
    "ID": "prometheus-flask-1",
    "Name": "prometheus-falsk",
    "Address": "172.31.49.221",
    "Port": 5000,
    "Tags": [
        "flask"
    ],
    "Meta": {
        "project": "web"
    }, 
    "EnableTagOverride": false,
    "Check": {
        "DeregisterCriticalServiceAfter": "12h",
        "HTTP": "http://172.31.49.221:5000/metrics",
        "Interval": "10s"
    }
}
EOF
cat > flask-2.register.json <<- 'EOF'
{
    "ID": "prometheus-flask-2",
    "Name": "prometheus-falsk",
    "Address": "172.31.49.221",
    "Port": 5001,
    "Tags": [
        "flask"
    ],
    "Meta": {
        "project": "web"
    }, 
    "EnableTagOverride": false,
    "Check": {
        "DeregisterCriticalServiceAfter": "12h",
        "HTTP": "http://172.31.49.221:5001/metrics",
        "Interval": "10s"
    }
}
EOF
curl -XPUT -d @flask-1.register.json https://consul.01member.com/v1/agent/service/register
curl -XPUT -d @flask-2.register.json https://consul.01member.com/v1/agent/service/register
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
          - name: POD_NAMESPACE
            valueFrom:
              filedRef:
                filedPath: metadata.namespace
          - name: CONSUL_ADDR
            value: "consul-consul-server.kube-system.svc.cluster.local"
          - name: CONSUL_PORT
            value: "8500"
``` 
添加postStart和preStop处理函数
```bash
      volumes:
        - name: scripts
          configMap:
            name: consul-register-sh 
            items:
            - key: consul-register.sh
              path: consul-register.sh
      containers:
        - name: {{ .Release.Name }}
        volumeMounts:
            - mountPath: /tmp/consul-register.sh
              name: scripts
              subPath: consul-register.sh
        lifecycle:
          postStart:
            exec:
              command: |
                - bash
                - c
                - /tmp/consul-register.sh
          preStop:
            exec:
              command: |
                - bash
                - c
                - curl -XPUST http://$CONSUL_ADDR:$CONSUL_PORT/v1/agent/service/deregister/$POD_NAME
              
```
挂载注册脚本容器中
```bash
apiVersion: v1
Kind: ConfigMap
metadata:
  name: consul-register-sh
data:
  consul-register.sh: |
    #!/bin/bash
    cat > /tmp/pod-info.json <<- 'EOF'
    {
        "ID": "$POD_NAME",
        "Name": "",
        "Tags": [
            "-$POD_NAME"
        ],
        "Address": "$POD_IP",
        "Port": ,
        "Meta": {
          "app": "",
          "project": "bus"
        },
        "EnableTagOverride": false,
        "Check": {
            "HTTP": "http://$POD_IP:/metrics",
            "Interval": "10s"
        }
    }
    EOF
    curl -XPUT -d @/tmp/pod-info.json http://$CONSUL_ADDR:$CONSUL_PORT/v1/agent/service/register
```

### consul与监控结合使用

#### 部署prometheus
```bash
helm upgrade --install prometheus-operator stable/prometheus-operator -n kube-system --debug
```
配置监控对外访问
```
# 添加ingressroute配置在values.yaml中
ingressRoute:
    enabled: true
    domain: prometheus-hk.01member.com
    middlewares:
      regex:
        enabled: false
    path: /
    annotations: {}
    ports:
      port: 9090
  # NOTE: Can't use 'false' due to https://github.com/jetstack/kube-lego/issues/173.
  # kubernetes.io/ingress.allow-http: true
  # kubernetes.io/ingress.class: gce
  # kubernetes.io/ingress.global-static-ip-name: ""
  # kubernetes.io/tls-acme: true
    labels: {}
    tls:
      certResolver: foo
      domains:
      - main: 01member.com
        sans:
        - '*.01member.com'
      options:
        name: ddyw-tlsoption
      passthrough: false
# 配置ingressroute资源
{{- if .Values.prometheus.ingressRoute.enabled -}}
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: {{ template "prometheus-operator.name" . }}-prometheus
  annotations:
    helm.sh/hook: "post-install,post-upgrade"
  labels:
    app.kubernetes.io/name: {{ template "prometheus-operator.name" . }}-prometheus
    app.kubernetes.io/managed-by: {{ .Release.Service }}
    app.kubernetes.io/instance: {{ template "prometheus-operator.name" . }}-prometheus
    {{- with .Values.prometheus.ingressRoute.labels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
spec:
  entryPoints:
    - websecure
  tls:
  {{- with .Values.prometheus.ingressRoute.tls }}
  {{- toYaml . | nindent 4 }}
  {{- end }}
  routes:
  - match: "Host(`{{ .Values.prometheus.ingressRoute.domain }}`) && PathPrefix(`{{ .Values.prometheus.ingressRoute.path }}`)"
    {{- if .Values.prometheus.ingressRoute.middlewares.regex.enable }}
    middlewares:
    - name: replace-path-regex-mid
    {{- end }}
    kind: Rule
    services:
    - name: {{ template "prometheus-operator.fullname" . }}-prometheus
    {{- with .Values.prometheus.ingressRoute.ports }}
    {{- toYaml . | nindent 6 }}
    {{- end }}
{{- end -}}
# 重新更新一下监控
helm upgrade --install prometheus-operator stable/prometheus-operator -n kube-system --debug
```
#### 配置prometheus抓取consul服务
```bash
# 在prometheus-operator 配置文件中values.yaml中配置additionalScrapeConfigs
additionalScrapeConfigs:
    - job_name: 'prometheus-consul-bigdata'
      consul_sd_configs:
      - server: 'consul-consul-server.kube-system.svc.cluster.local:8500'
        services: []
      relabel_configs:
      - source_labels: [__meta_consul_tags]
        regex: .*node-export.*
        action: keep
      - action: labelmap
        regex: __meta_consul_service_metadata_(.+)
    - job_name: 'prometheus-consul-flask'
      consul_sd_configs:
      - server: 'consul-consul-server.kube-system.svc.cluster.local:8500'
        services: []
      relabel_configs:
      - source_labels: [__meta_consul_tags]
        regex: .*flask.*
        action: keep
      - action: labelmap
        regex: __meta_consul_service_metadata_(.+) 
# 更新配置
helm upgrade --install prometheus-operator prometheus-operator/ -n kube-system --debug
```

#### 安装prometheus-consul-export监控consul服务
```bash
# 安装consul配置中心
helm upgrade --install prometheus-consul-exporter stable/prometheus-consul-exporter -n kube-system --debug
```

#### Prometheus 中查询对应服务
```bash
https://prometheus-hk.01member.com/graph?g0.range_input=1h&g0.expr=consul_service_checks&g0.tab=1
```

#### consul 注册服务健康检查使用场景

1、脚本检查
```bash
{
  "check": {
    "id": "mem-util",
    "name": "Memory utilization",
    "args": ["/usr/local/bin/check_mem.py", "-limit", "256MB"],
    "interval": "10s",
    "timeout": "1s"
  }
}
```

2、HTTP检查
```bash
{
  "check": {
    "id": "api",
    "name": "HTTP API on port 5000",
    "http": "https://localhost:5000/health",
    "tls_server_name": "",
    "tls_skip_verify": false,
    "method": "POST",
    "header": {"Content-Type": ["application/json"]},
    "body": "{\"method\":\"health\"}",
    "interval": "10s",
    "timeout": "1s"
  }
}
```

3、TCP检查
```bash
{
  "check": {
    "id": "ssh",
    "name": "SSH TCP on port 22",
    "tcp": "localhost:22",
    "interval": "10s",
    "timeout": "1s"
  }
}
```

4、TTL检查
```bash
{
  "check": {
    "id": "web-app",
    "name": "Web App Status",
    "notes": "Web app does a curl internally every 10 seconds",
    "ttl": "30s"
  }
}
```

5、Docker检查
```bash
{
  "check": {
    "id": "mem-util",
    "name": "Memory utilization",
    "docker_container_id": "f972c95ebf0e",
    "shell": "/bin/bash",
    "args": ["/usr/local/bin/check_mem.py"],
    "interval": "10s"
  }
}
```

6、对整个程序grpc检查
```bash
{
  "check": {
    "id": "mem-util",
    "name": "Memory utilization",
    "docker_container_id": "f972c95ebf0e",
    "shell": "/bin/bash",
    "args": ["/usr/local/bin/check_mem.py"],
    "interval": "10s"
  }
}
```

7、h2ping检查
```bash
{
  "check": {
    "id": "h2ping-check",
    "name": "h2ping",
    "h2ping": "localhost:22222",
    "interval": "10s",
  }
}
```

检查脚本通常可以自由地做任何事情来确定检查的状态。唯一的限制是退出代码必须遵守这个约定：

退出代码 0 - 检查通过
退出代码 1 - 检查是警告
任何其他代码 - 检查失败


通过监控consul_service_checks监控指标查询在consul中是否有异常的服务


