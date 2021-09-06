#### Prometheus 黑盒监控
前面主要是进行白盒监控，我们监控主机的资源用量、容器的运行状态、数据库中间件的运行数据、自动发现 Kubernetes 集群中的资源等等，这些都是支持业务和服务的基础设施，通过白盒能够了解其内部的实际运行状态，通过对监控指标的观察能够预判可能出现的问题，从而对潜在的不确定因素进行优化。而从完整的监控逻辑的角度，除了大量的应用白盒监控以外，还应该添加适当的 Blackbox（黑盒）监控，黑盒监控即以用户的身份测试服务的外部可见性，常见的黑盒监控包括HTTP 探针、TCP 探针 等用于检测站点或者服务的可访问性，以及访问效率等。

黑盒监控相较于白盒监控最大的不同在于黑盒监控是以故障为导向当故障发生时，黑盒监控能快速发现故障，而白盒监控则侧重于主动发现或者预测潜在的问题。一个完善的监控目标是要能够从白盒的角度发现潜在问题，能够在黑盒的角度快速发现已经发生的问题。

Blackbox Exporter 是 Prometheus 社区提供的官方黑盒监控解决方案，其允许用户通过：HTTP、HTTPS、DNS、TCP 以及 ICMP 的方式对网络进行探测。

同样首先需要在 Kubernetes 集群中运行 blackbox-exporter 服务，同样通过一个 ConfigMap 资源对象来为 Blackbox 提供配置，如下所示：（prome-blackbox.yaml）

```yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  labels:
    app: prometheus-blackbox-exporter
  name: prometheus-blackbox-exporter
  namespace: monitoring
data:
  blackbox.yml: |-
    modules:
      http_2xx:
        prober: http
        timeout: 10s
        http:
          valid_http_versions: ["HTTP/1.1", "HTTP/2"]
          valid_status_codes: [200]
          method: GET
          preferred_ip_protocol: "ip4"
      http_post_2xx: # http post 监测模块
        prober: http
        timeout: 10s
        http:
          valid_http_versions: ["HTTP/1.1", "HTTP/2"]
          method: POST
          preferred_ip_protocol: "ip4"
      tcp_connect:
        prober: tcp
        timeout: 10s
      icmp:
        prober: icmp
        timeout: 10s
        icmp:
          preferred_ip_protocol: "ip4"
      dns:  # DNS 检测模块
        prober: dns
        dns:
          transport_protocol: "tcp"  # 默认是 udp
          preferred_ip_protocol: "ip4"  # 默认是 ip6
          query_name: "kubernetes.default.svc.cluster.local"
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: prometheus-blackbox-exporter
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app: prometheus-blackbox-exporter
  replicas: 1
  template:
    metadata:
      labels:
        app: prometheus-blackbox-exporter
    spec:
      restartPolicy: Always
      containers:
      - name: prometheus-blackbox-exporter
        image: prom/blackbox-exporter:v0.16.0
        imagePullPolicy: IfNotPresent
        ports:
        - name: blackbox-port
          containerPort: 9115
        readinessProbe:
          tcpSocket:
            port: 9115
          initialDelaySeconds: 5
          timeoutSeconds: 5
        resources:
          requests:
            memory: 50Mi
            cpu: 100m
          limits:
            memory: 60Mi
            cpu: 200m
        volumeMounts:
        - name: config
          mountPath: /etc/blackbox_exporter
        args:
        - --config.file=/etc/blackbox_exporter/blackbox.yml
        - --log.level=debug
        - --web.listen-address=:9115
      volumes:
      - name: config
        configMap:
          name: prometheus-blackbox-exporter
      #nodeSelector:
      #      #  node-role.kubernetes.io/master: "true"
    #   tolerations:
    #   - key: "node-role.kubernetes.io/master"
    #     effect: "NoSchedule"
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: prometheus-blackbox-exporter
  name: prometheus-blackbox-exporter
  namespace: monitoring
  annotations:
    prometheus.io/scrape: 'true'
spec:
  #type: NodePort
  selector:
    app: prometheus-blackbox-exporter
  ports:
  - name: blackbox-port
    port: 9115
    targetPort: 9115
    protocol: TCP

```

直接创建上面的资源清单：
```bash
kubectl apply -f prome-blackbox.yaml 
```

然后需要在 Prometheus 的配置文件中加入对 BlackBox 的抓取设置，如下所示：
```yaml
    - job_name: "kubernetes-service-dns"
      metrics_path: /probe # 不是 metrics，是 probe
      params:
        module: [dns] # 使用 DNS 模块
      static_configs:
      - targets:
        - kube-dns.kube-system:53  # 不要省略端口号
      relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: prometheus-blackbox-exporter:9115  # 服务地址，和上面的 Service 定义保持一致
```

首先获取 targets 实例的 __address__ 值写进 __param_target，__param_<name> 形式的标签里的 name 和它的值会被添加到发送到黑盒的 http 的 header 的 params 当作键值，例如 __param_module 对应 params 里的module。然后获取 __param_target 的值，并覆写到 instance 标签中，覆写 Target 实例的 __address__ 标签值为 BlockBox Exporter 实例的访问地址，向 blackbox:9115 发送请求获取实例的 metrics 信息。然后更新配置：
```bash
kubectl apply -f prometheus-cm.yaml
```

除了 DNS 的配置外，上面还配置了一个 http_2xx 的模块，也就是 HTTP 探针，HTTP 探针是进行黑盒监控时最常用的探针之一，通过 HTTP 探针能够对网站或者 HTTP 服务建立有效的监控，包括其本身的可用性，以及用户体验相关的如响应时间等等。除了能够在服务出现异常的时候及时报警，还能帮助系统管理员分析和优化网站体验。这里可以使用他来对 http 服务进行检测。

因为前面已经给 Blackbox 配置了 http_2xx 模块，所以这里只需要在 Prometheus 中加入抓取任务，这里我们可以结合前面的 Prometheus 的服务发现功能来做黑盒监控，对于 Service 和 Ingress 类型的服务发现，用来进行黑盒监控是非常合适的，配置如下所示：
```yaml
- job_name: 'kubernetes-Business-services'
  metrics_path: /probe
  params:
    module: [http_2xx]  # 使用定义的http模块
  kubernetes_sd_configs:
  - role: service  # service 类型的服务发现
  relabel_configs:
  # 只有service的annotation中配置了 prometheus.io/http_probe=true 的才进行发现
  - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_http_probe]
    action: keep
    regex: true
  - source_labels: [__address__]
    target_label: __param_target
  - target_label: __address__
    replacement: prometheus-blackbox-exporter:9115
  - source_labels: [__param_target]
    target_label: instance
  - action: labelmap
    regex: __meta_kubernetes_service_label_(.+)
  - source_labels: [__meta_kubernetes_namespace]
    target_label: kubernetes_namespace
  - source_labels: [__meta_kubernetes_service_name]
    target_label: kubernetes_name
  - source_labels: [__meta_kubernetes_service_port_name]
    target_label: kubernetes_port_name
  - source_labels: [__meta_kubernetes_service_name]
    regex: "redis.*"
    action: drop
  - source_labels: [instance]
    regex: ".*22.*"
    action: drop
  - source_labels: [instance]
    regex: "member-api-gateway.*8080.*"
    action: drop
  - source_labels: [__meta_kubernetes_namespace]
    regex: "dadi-saas-member-pre"
    action: keep

- job_name: 'kubernetes-services'
  metrics_path: /probe
  params:
    module: [http_2xx]  # 使用定义的http模块
  kubernetes_sd_configs:
  - role: service  # service 类型的服务发现
  relabel_configs:
  只有service的annotation中配置了 prometheus.io/http_probe=true 的才进行发现
  - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_http_probe]
    action: keep
    regex: true
  - source_labels: [__address__]
    target_label: __param_target
  - target_label: __address__
    replacement: prometheus-blackbox-exporter:9115
  - source_labels: [__param_target]
    target_label: instance
  - action: labelmap
    regex: __meta_kubernetes_service_label_(.+)
  - source_labels: [__meta_kubernetes_namespace]
    target_label: kubernetes_namespace
  - source_labels: [__meta_kubernetes_service_name]
    target_label: kubernetes_name
  - source_labels: [__meta_kubernetes_service_port_name]
    target_label: kubernetes_port_name
  - source_labels: [__meta_kubernetes_namespace]
    regex: "dadi-saas-member-pre"
    action: drop

- job_name: 'kubernetes-ingresses'
  metrics_path: /probe
  params:
    module: [http_2xx]  # 使用定义的http模块
  kubernetes_sd_configs:
  - role: ingress  # ingress 类型的服务发现
  relabel_configs:
  # 只有ingress的annotation中配置了 prometheus.io/http_probe=true的才进行发现
  - source_labels: [__meta_kubernetes_ingress_annotation_prometheus_io_http_probe]
    action: keep
    regex: true
  - source_labels: [__meta_kubernetes_ingress_scheme,__address__,__meta_kubernetes_ingress_path]
    regex: (.+);(.+);(.+)
    replacement: ${1}://${2}${3}
    target_label: __param_target
  - target_label: __address__
    replacement: prometheus-blackbox-exporter:9115
  - source_labels: [__param_target]
    target_label: instance
  - action: labelmap
    regex: __meta_kubernetes_ingress_label_(.+)
  - source_labels: [__meta_kubernetes_namespace]
    target_label: kubernetes_namespace
  - source_labels: [__meta_kubernetes_ingress_name]
    target_label: kubernetes_name
```
因为前面已经给 Blackbox 配置了 tcp模块，所以这里只需要在 Prometheus 中加入抓取任务，这里我们可以结合前面的 Prometheus 的，配置如下所示：
```yaml
- job_name: 'kubernetes-Business-redis'
  metrics_path: /probe
  params:
    module: [tcp_connect]  # 使用定义的http模块
  kubernetes_sd_configs:
  - role: service  # service 类型的服务发现
  relabel_configs:
  只有service的annotation中配置了 prometheus.io/http_probe=true 的才进行发现
  #- source_labels: [__meta_kubernetes_service_annotation_prometheus_io_http_probe]
  #  action: keep
  # regex: true
  - source_labels: [__address__]
    target_label: __param_target
  - target_label: __address__
    replacement: prometheus-blackbox-exporter:9115
  - source_labels: [__param_target]
    target_label: instance
  - action: labelmap
    regex: __meta_kubernetes_service_label_(.+)
  - source_labels: [__meta_kubernetes_namespace]
    target_label: kubernetes_namespace
  - source_labels: [__meta_kubernetes_service_name]
    target_label: kubernetes_name
  - source_labels: [instance]
    regex: ".*6379.*"
    action: keep
```
  
监控阿里云数据库,配置如下所示：
```yaml
- job_name: 'kubernetes-Business-mysql'
  metrics_path: /probe
  params:
    module: [tcp_connect]  # 使用定义的http模块
  static_configs:
  - targets:
    - 'xxxxxxx:3306'
    labels:
      group: 'pre 环境数据库'
  relabel_configs:
  只有service的annotation中配置了 prometheus.io/http_probe=true 的才进行发现
  - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_http_probe]
    action: keep
    regex: true
  - source_labels: [__address__]
    target_label: __param_target
  - source_labels: [__param_target]
    target_label: instance
  - target_label: __address__
    replacement: prometheus-blackbox-exporter:9115
```
监控阿里云mongodb
```yaml
- job_name: 'kubernetes-Business-mongodb'
  metrics_path: /probe
  params:
    module: [tcp_connect]  # 使用定义的http模块
  static_configs:
  - targets:
    - 'xxxxxxx:3717'
    - 'xxxxxxx:3717'
    labels:
      group: 'pre 环境mongodb'
  relabel_configs:
  只有service的annotation中配置了 prometheus.io/http_probe=true 的才进行发现
  - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_http_probe]
    action: keep
    regex: true
  - source_labels: [__address__]
    target_label: __param_target
  - source_labels: [__param_target]
    target_label: instance
  - target_label: __address__
    replacement: prometheus-blackbox-exporter:9115
```
监控阿里云psql
```yaml
- job_name: 'kubernetes-Business-psql'
  metrics_path: /probe
  params:
    module: [tcp_connect]  # 使用定义的http模块
  static_configs:
  - targets:
    - 'xxxxxxx:3433'
    labels:
      group: 'pre 环境psql'
  relabel_configs:
  只有service的annotation中配置了 prometheus.io/http_probe=true 的才进行发现
  - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_http_probe]
    action: keep
    regex: true
  - source_labels: [__address__]
    target_label: __param_target
  - source_labels: [__param_target]
    target_label: instance
  - target_label: __address__
    replacement: prometheus-blackbox-exporter:9115
```
监控青云amqp
```yaml
- job_name: 'kubernetes-Business-amqp'
  metrics_path: /probe
  params:
    module: [tcp_connect]  # 使用定义的http模块
  static_configs:
  - targets:
    - 'xxxxxx:5672'
    labels:
      group: 'pre 环境psql'
  relabel_configs:
  只有service的annotation中配置了 prometheus.io/http_probe=true 的才进行发现
  - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_http_probe]
    action: keep
    regex: true
  - source_labels: [__address__]
    target_label: __param_target
  - source_labels: [__param_target]
    target_label: instance
  - target_label: __address__
    replacement: prometheus-blackbox-exporter:9115
```
监控物理节点联通性
```yaml
- job_name: 'kubernetes-Physical-node'
  metrics_path: /probe
  params:
    module: [tcp_connect]  # 使用定义的http模块
  static_configs:
  - targets:
    - 'xxxxxxxxx:22'
    - 'xxxxxxxxx:22'
    - 'xxxxxxxxx:22'
    labels:
      group: 'pre cent 物理节点'
  - targets:
    - 'xxxxxxxx:22'
    - 'xxxxxxxx:22'
    - 'xxxxxxxx:22'
    labels:
      group: 'pre dist sz 物理节点'
  relabel_configs:
  只有service的annotation中配置了 prometheus.io/http_probe=true 的才进行发现
  - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_http_probe]
    action: keep
    regex: true
  - source_labels: [__address__]
    target_label: __param_target
  - source_labels: [__param_target]
    target_label: instance
  - target_label: __address__
    replacement: prometheus-blackbox-exporter:9115
```
监控域名访问是否正常
```yaml
- job_name: 'kubernetes-domain-front'
  metrics_path: /probe
  params:
    module: [http_2xx]  # 使用定义的http模块
  static_configs:
  - targets:
    - 'https://xxxxxx'
    - 'https://xxxxxx'
    - 'https://xxxxxx'
    - 'https://xxxxxx/'
    labels:
      group: 'pre cent 前端页面'
  - targets:
    - 'https://xxxxxx'
    labels:
      group: 'pre cent 平台系统后端'
  - targets:
    - 'https://xxxxxx'
    labels:
      group: 'pre cent 账号中心系统后端'
  - targets:
    - 'https://xxxxxx'
    labels:
      group: 'pre cent 租户系统后端'
  - targets:
    - 'https://xxxxxx'
    lables:
      group: 'pre dist 鉴权系统后端'
  - targets:
    - 'https://xxxxxx'
    lables:
      group: 'pre dist 地域管理器后端'
  - targets:
    - 'https://xxxxxx'
    - 'https://xxxxxx'
    - 'https://xxxxxx'
    - 'https://xxxxxx'
    labels:
      group: 'prod cent 前端页面'
  - targets:
    - 'https://xxxxxx'
    labels:
      group: 'prod　平台系统后端'
  relabel_configs:
  只有service的annotation中配置了 prometheus.io/http_probe=true 的才进行发现
  - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_http_probe]
    action: keep
    regex: true
  - source_labels: [__address__]
    target_label: __param_target
  - source_labels: [__param_target]
    target_label: instance
  - target_label: __address__
    replacement: prometheus-blackbox-exporter:9115
```
监控租户系统是否正常
```yaml
- job_name: 'kubernetes-domain-tenant-system'
  metrics_path: /probe
  params:
    module: [http_2xx_member_tenant_system] # 使用定义的http模块
  static_configs:
  - targets:
    - 'https://xxxxxxx'
    labels:
      group: 'pre cent 前端页面'
  relabel_configs:
  只有service的annotation中配置了 prometheus.io/http_probe=true 的才进行发现
  - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_http_probe]
    action: keep
    regex: true
  - source_labels: [__address__]
    target_label: __param_target
  - source_labels: [__param_target]
    target_label: instance
  - target_label: __address__
    replacement: prometheus-blackbox-exporter:9115
```










   
