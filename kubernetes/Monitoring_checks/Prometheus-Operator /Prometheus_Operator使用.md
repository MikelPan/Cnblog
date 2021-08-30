## Prometheus Operator 使用
#### 安装
最新的版本官方将资源https://github.com/coreos/prometheus-operator/tree/master/contrib/kube-prometheus迁移到了独立的 git 仓库中：https://github.com/coreos/kube-prometheus.git
克隆最新的代码：
```bash
git clone https://github.com/coreos/kube-prometheus.git
```
进入到 manifests 目录下面，这个目录下面包含所有的资源清单文件，需要对其中的文件 prometheus-serviceMonitorKubelet.yaml 进行简单的修改：
将https-metrics改为http-metrics

创建对应的资源
```bash
kubectl apply -f maifests/* 
```
#### 告警配置
删除掉官方的告警secreet,配置对应的告警secret,yaml文件如下：
```yaml
cat > alertmanager.yaml <<EOF
global:
  resolve_timeout: 5m
  smtp_smarthost: 'xxxxxx'
  smtp_from: 'xxxxxxxx'
  smtp_auth_username: 'xxxxxxx'
  smtp_auth_password: 'xxxxxxx'
  smtp_hello: 'xxxxx'
  smtp_require_tls: false
route:
  group_by: ['job','alertname','severity']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 5h
  receiver: default
  routes:
  - match:
      alertname: CPUThrottlingHigh
      receiver: default
    match_re:
      alertname: ^(severity|warring)$
      receiver: webhook
receivers:
- name: 'default'
  email_configs:
  - to: 'xxxxxxx'
    send_resolved: true
- name: 'webhook'
  webhook_configs:
  - url: 'https://oapi.dingtalk.com/robot/send?access_token=8512095dcbf2777d5521f556668a1f0c3df62737f6e244c868197f5bexxxxx'
    send_resolved: true
EOF 
```
生成新的告警文件

```bash
cat > reset_alertmanager_config.sh <<EOF
kubectl delete secret alertmanager-main -n monitoring
kubectl create secret generic alertmanager-main --from-file=alertmanager.yaml -n monitoring
kubectl delete -f alertmanager-alertmanager.yaml;kubectl create -f alertmanager-alertmanager.yaml
EOF
```

由于默认没有生成对应的kube-controller-manager和kube-scheduler的service,所以需要手动添加service

#### 监控kube-controller-manager
添加kube-controller-manager的监控service文件：
```yaml
cat > prometheus-kubeControllerManagerService.yaml <<EOF
apiVersion: v1
kind: Service
metadata:
  namespace: kube-system
  name: kube-controller-manager
  labels:
    k8s-app: kube-controller-manager
spec:
  selector:
    component: kube-controller-manager
  ports:
  - name: http-metrics
    port: 10251
    targetPort: 10251
    protocol: TCP
EOF
```
#### 监控 kube-scheduler
添加监控kube-scheduler的监控yaml文件
```yaml
cat > prometheus-kubeSchedulerService.yaml <<EOF
apiVersion: v1
kind: Service
metadata:
  namespace: kube-system
  name: kube-scheduler
  labels:
    k8s-app: kube-scheduler
spec:
  selector:
    component: kube-scheduler
  ports:
  - name: http-metrics
    port: 10251
    targetPort: 10251
    protocol: TCP
EOF
```
#### 监控etcd
由于etcd 使用的证书都对应在节点的 /etc/kubernetes/pki/etcd 这个路径下面，所以首先我们将需要使用到的证书通过 secret 对象保存到集群中去：(在 etcd 运行的节点)

创建etcd secret
```bash
kubectl -n monitoring create secret generic etcd-certs --from-file=/etc/kubernetes/pki/etcd/healthcheck-client.crt --from-file=/etc/kubernetes/pki/etcd/healthcheck-client.key --from-file=/etc/kubernetes/pki/etcd/ca.crt
```
然后将上面创建的 etcd-certs 对象配置到 prometheus 资源对象中，直接更新 prometheus 资源对象即可
```yaml
nodeSelector:
    kubernetes.io/os: linux
  podMonitorSelector: {}
  replicas: 2
  secrets:
  - etcd-certs
```
*创建 ServiceMonitor*
现在 Prometheus 访问 etcd 集群的证书已经准备好了，接下来创建 ServiceMonitor 对象即可（prometheus-serviceMonitorEtcd.yaml）
```yaml
cat > prometheus-serviceMonitorEtcd.yaml <<EOF
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: etcd-k8s
  namespace: monitoring
  labels:
    k8s-app: etcd
spec:
  jobLabel: etcd
  endpoints:
  - port: port
    interval: 30s
    scheme: https
    tlsConfig:
      caFile: /etc/prometheus/secrets/etcd-certs/ca.crt
      certFile: /etc/prometheus/secrets/etcd-certs/healthcheck-client.crt
      keyFile: /etc/prometheus/secrets/etcd-certs/healthcheck-client.key
      insecureSkipVerify: true
  selector:
    matchLabels:
      k8s-app: etcd
  namespaceSelector:
    matchNames:
    - kube-system
EOF
```
*创建Service*

ServiceMonitor 创建完成了，但是现在还没有关联的对应的 Service 对象，所以需要我们去手动创建一个 Service 对象（prometheus-etcdService.yaml）
etcd 部署到k8s 集群中
```yaml
cat > prometheus-etcdService.yaml <<EOF
apiVersion: v1
kind: Service
metadata:
  name: etcd-k8s
  namespace: kube-system
  labels:
    k8s-app: etcd
spec:
  selector:
    component: etcd
  type: ClusterIP
  clusterIP: None
  ports:
  - name: port
    port: 2379
    protocol: TCP
EOF

```
etcd 部署到外部集群

```yaml
cat > prometheus-etcdService.yaml <<EOF
apiVersion: v1
kind: Service
metadata:
  name: etcd-k8s
  namespace: kube-system
  labels:
    component: etcd
spec:
  type: ClusterIP
  clusterIP: None
  ports:
  - name: port
    port: 2379
    protocol: TCP
---
apiVersion: v1
kind: Endpoints
metadata:
  name: etcd-k8s
  namespace: kube-system
  labels:
    k8s-app: etcd
subsets:
- addresses:
  - ip: 172.18.12.14
    nodeName: pre-etcd-master
  ports:
  - name: port
    port: 2379
    protocol: TCP
EOF
```
数据采集到后，可以在 grafana 中导入编号为3070的 dashboard，获取到 etcd 的监控图表

#### 黑盒监控
#### blackbox-eporter 监控k8s 网络性能
创建blackbox-exporter cm
```yaml
cat > prometheus-blackbox-exporter-cm.yaml <<EOF
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
        prober: https
        timeout: 10s
        http:
          valid_http_versions: ["HTTP/1.1", "HTTP/2"]
　　　　　　# 这里最好作一个返回状态码，在grafana作图时，有明示---陈刚注释。
          valid_status_codes: [200]
          method: GET
          preferred_ip_protocol: "ip4"
      http_post_2xx: # http post 监测模块
        prober: https
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
EOF
```
创建blackbox_exporter 启动文件
```yaml
cat > prometheus-blackbox-exporter-deploy.yaml <<EOF
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
      nodeSelector:
        node-role.kubernetes.io/master: "true"
      tolerations:
      - key: "node-role.kubernetes.io/master"
        effect: "NoSchedule"
EOF
```
创建blackbox_exporter service 文件
```yaml
cat > prometheus-blackbox-exporter-svc.yaml <<EOF
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
    #nodePort: 30009
    protocol: TCP
EOF
```

创建对应的资源
```bash
kubectl apply -f prometheus-blackbox-exporter-cm.yaml
kubectl apply -f prometheus-blackbox-exporter-deploy.yaml
kubectl apply -f prometheus-blackbox-exporter-svc.yaml
```
创建监控网络插件的serverMonitorer
```yaml
cat > prometheus-serviceMonitorBlackboxExporter.yaml <<EOF
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  labels:
    app: prometheus-blackbox-exporter
  name: prometheus-blackbox-exporter
  namespace: monitoring
spec:
  endpoints:
  - interval: 30s
    port: blackbox-port
  jobLabel: app
  namespaceSelector:
    matchNames:
    - monitoring
  selector:
    matchLabels:
      app: prometheus-blackbox-exporter
EOF

cat > prometheus-serviceMonitorBlackboxExporter.yaml <<EOF
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  labels:
    app: prometheus-blackbox-exporter
  name: prometheus-blackbox-exporter
  namespace: monitoring
spec:
  endpoints:
  - interval: 30s
    path: /probe
    params:
      moudle: [http_2xx]
    scheme: http
    kubernetes_sd_config:
    - role: service
    tlsConfig:
      caFile: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
    bearerTokenFile: /var/run/secrets/kubernetes.io/serviceaccount/token
    kubernetes_sd_configs:
    - role: service
    relabelings:
    # - action: keep
    #   sourceLabels:
    #   - __meta_kubernetes_service_annotation_prometheus_io_scrape
    #   - __meta_kubernetes_service_annotation_prometheus_io_http_probe
    #   regex: true;
    - sourceLabels: 
      - __address__
      targetLabel: __param_target
    - targetLabel: __address__
      replacement: prometheus-blackbox-exporter:9115
    - sourceLabels: 
      - __param_target
      targetLabel: instance
    - action: labelmap
      regex: __meta_kubernetes_service_label_(.+)
    - sourceLabels: 
      - __meta_kubernetes_namespace
      targetLabel: kubernetes_namespace
    - sourceLabels: 
      - __meta_kubernetes_service_name
      targetLabel: kubernetes_name
    port: blackbox-port
  jobLabel: app
  namespaceSelector:
    #any: true
    matchNames:
    - monitoring
    - kube-system
  selector:
    matchLabels:
      app: prometheus-blackbox-exporter
EOF
```

#### 配置集群联邦
将Prometheus Operator做为中心节点集群node节点的数据,组成联邦。配置yaml文件如下：
```yaml
cat > prometheus-additional.yaml <<EOF
- job_name: 'dist-sz-pre-monitoring/kube-state-metrics'
  scrape_interval: 15s

  honor_labels: true
  metrics_path: '/federate'

  params:
    'match[]':
    - '{job="kube-state-metrics"}'
    - '{job="kubelet"}'

  static_configs:
  - targets:
    - '39.108.192.100:32501'
    labels:
      group: 'sz-pre'
EOF
```
由于prometheus 提供自动发现服务机制,所以只需要将联邦的配置放到自动发现配置中即可, 配置自动发现集群中的 Service，就需要在 Service 的annotation区域添加prometheus.io/scrape=true的声明，将上面文件直接保存为 prometheus-additional.yaml，然后通过这个文件创建一个对应的 Secret 对象：
```bash
cat > reset_additional_secret.sh <<EOF
kubectl delete secret additional-configs -n monitoring
kubectl create secret generic additional-configs --from-file=prometheus-additional.yaml -n monitoring
EOF
```
修改prometheus-prometheus.yaml,添加自动发现配置：
```yaml
cat > prometheus-prometheus.yaml <<EOF
apiVersion: monitoring.coreos.com/v1
kind: Prometheus
metadata:
  labels:
    prometheus: k8s
  name: k8s
  namespace: monitoring
spec:
  alerting:
    alertmanagers:
    - name: alertmanager-main
      namespace: monitoring
      port: web
  baseImage: quay.io/prometheus/prometheus
  nodeSelector:
    kubernetes.io/os: linux
  podMonitorSelector: {}
  replicas: 2
  resources:
    requests:
      memory: 400Mi
  ruleSelector:
    matchLabels:
      prometheus: k8s
      role: alert-rules
  securityContext:
    fsGroup: 2000
    runAsNonRoot: true
    runAsUser: 1000
  serviceAccountName: prometheus-k8s
  serviceMonitorNamespaceSelector: {}
  serviceMonitorSelector: {}
  version: v2.11.0
  additionalScrapeConfigs:
    name: additional-configs
    key: prometheus-additional.yaml
EOF
```
重新应用启用配置文件,更新自动发现
```bash
sh reset_additional_secret.sh
kubectl delete -f prometheus-prometheus.yaml
kubectl apply -f prometheus-prometheus.yaml
```

也可以将prometheus配置文件加入到addtional文件中,使prometheus-operator像prometheus配置一致,例如配置黑盒监控,配置文件如下:
```yaml
- job_name: 'pre-monitoring/kube-state-metrics'
  scrape_interval: 15s

  honor_labels: true
  metrics_path: '/federate'

  params:
    'match[]':
    - '{job="kube-state-metrics"}'
    - '{job="kubelet"}'
    - '{job="apiserver"}'
    - '{job="node-exporter"}'
    - '{job="kube-scheduler"}'
    - '{job="kube-controller-manager"}'
    - '{job="etcd-k8s"}'
    - '{job="traefik-ingress"}'
    - '{job="kubernetes-services"}'
    - '{job="kubernetes-Business-redis"}'
    - '{job="kubernetes-Business-mongodb"}'
    - '{job="kubernetes-Business-psql"}'
    - '{job="kubernetes-Business-amqp"}'
    - '{job="kubernetes-Physical-node"}'

  static_configs:
  - targets:
    - '39.108.192.100:32501'
    labels:
      group: 'dist-sz-pre'

- job_name: 'kubernetes-Business-services'
  metrics_path: /probe
  params:
    module: [http_2xx]
  kubernetes_sd_configs:
  - role: service
  relabel_configs:
  #- source_labels: [__meta_kubernetes_service_annotation_prometheus_io_probe]
  #  action: keep
  #  regex: true
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
    target_label: kubernetes_service
  - source_labels: [instance]
    regex: ".*22.*"
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
  #只有service的annotation中配置了 prometheus.io/http_probe=true 的才进行发现
  #- source_labels: [__meta_kubernetes_service_annotation_prometheus_io_http_probe]
  #  action: keep
  #  regex: true
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

- job_name: 'kubernetes-ingresses'
  metrics_path: /probe
  params:
    module: [http_2xx]  # 使用定义的http模块
  kubernetes_sd_configs:
  - role: ingress  # ingress 类型的服务发现
  relabel_configs:
  # 只有ingress的annotation中配置了 prometheus.io/http_probe=true的才进行发现
  #- source_labels: [__meta_kubernetes_ingress_annotation_prometheus_io_http_probe]
  #  action: keep
  #  regex: true
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

