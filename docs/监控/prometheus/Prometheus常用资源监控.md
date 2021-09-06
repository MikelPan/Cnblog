#### 容器监控
cAdvisor已经内置在了 kubelet 组件之中，所以不需要单独去安装，cAdvisor的数据路径为/api/v1/nodes/<node>/proxy/metrics，同样这里使用 node 的服务发现模式，因为每一个节点下面都有 kubelet，自然都有cAdvisor采集到的数据指标，配置如下：
```yaml
cat > prometheus-cm.yaml<<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
  namespace: monitoring
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
      scrape_timeout: 15s
    scrape_configs:
    - job_name: 'prometheus'
      static_configs:
      - targets: ['localhost:9090']
    - job_name: 'kubernetes-nodes'
      kubernetes_sd_configs:
      - role: node
      relabel_configs:
      - source_labels: [__address__]
        regex: '(.*):10250'
        replacement: '${1}:9100'
        target_label: __address__
        action: replace
      - action: labelmap
        regex: __meta_kubernetes_node_label_(.+)

    - job_name: 'kubelet'
      kubernetes_sd_configs:
      - role: node
      scheme: https
      tls_config:
        ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        insecure_skip_verify: true
      bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
      relabel_configs:
      - action: labelmap
        regex: __meta_kubernetes_node_label_(.+)

    - job_name: 'kubernetes-cadvisor'
      kubernetes_sd_configs:
      - role: node
      scheme: https
      tls_config:
        ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
      bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
      relabel_configs:
      - action: labelmap
        regex: __meta_kubernetes_node_label_(.+)
      - target_label: __address__
        replacement: kubernetes.default.svc:443
      - source_labels: [__meta_kubernetes_node_name]
        regex: (.+)
        target_label: __metrics_path__
        replacement: /api/v1/nodes/${1}/proxy/metrics/cadvisor
EOF
```
上面的配置和之前配置 node-exporter 的时候几乎是一样的，区别是这里使用了 https 的协议，另外需要注意的是配置了 ca.cart 和 token 这两个文件，这两个文件是 Pod 启动后自动注入进来的，通过这两个文件可以在 Pod 中访问 apiserver，比如这里的__address__不在是 nodeip 了，而是 kubernetes 在集群中的服务地址，然后加上__metrics_path__的访问路径：/api/v1/nodes/${1}/proxy/metrics/cadvisor，现在同样更新下配置，然后查看 Targets 路径： 
![20191128114505.png](https://i.loli.net/2019/11/28/Zm8IgBpaJhebX42.png)

#### apiserver监控
apiserver 作为 Kubernetes 最核心的组件，当然他的监控也是非常有必要的，对于 apiserver 的监控我们可以直接通过 kubernetes 的 Service 来获取：
```bash
# kubectl get svc -n default
NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   92d
```
上面这个 Service 就是集群的 apiserver 在集群内部的 Service 地址，要自动发现 Service 类型的服务，就需要用到 role 为 Endpoints 的 kubernetes_sd_configs，可以在 ConfigMap 对象中添加上一个 Endpoints 类型的服务的监控任务,需要过滤的服务是 default 这个 namespace 下面，服务名为 kubernetes 的元数据，所以这里我们就可以根据对应的__meta_kubernetes_namespace和__meta_kubernetes_service_name这两个元数据来 relabel,另外由于 kubernetes 这个服务对应的端口是443，需要使用 https 协议，所以这里我们需要使用 https 的协议，对应的就需要将对应的 ca 证书配置上，如下：

查看配置的job:
```yaml
    - job_name: 'kubernetes-apiservers'
      kubernetes_sd_configs:
      - role: endpoints
      scheme: https
      tls_config:
        ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
      bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
      relabel_configs:
      - source_labels: [__meta_kubernetes_namespace, __meta_kubernetes_service_name, __meta_kubernetes_endpoint_port_name]
        action: keep
        regex: default;kubernetes;https
```
现在重新更新配置文件、重新加载 Prometheus，切换到 Prometheus 的 Targets 路径下查看：
![20191128114536.png](https://i.loli.net/2019/11/28/notY4p82ISKQDkB.png)

#### kube-contraller监控 
```yaml
    - job_name: 'kubernetes-schedule'          #任务名
      scrape_interval: 5s                   #本任务的抓取间隔，覆盖全局配置
      static_configs:
        - targets: ['xxxxx:10251']
```

#### kube-schedule监控
```yaml
    
    - job_name: 'kubernetes-control-manager'
      scrape_interval: 5s
      static_configs:
        - targets: ['xxxxx:10252']
```

#### endpoints监控

查看配置文件
```yaml
cat > prometheus-cm.yaml<<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
  namespace: monitoring
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
      scrape_timeout: 15s
    scrape_configs:
    - job_name: 'prometheus'
      static_configs:
      - targets: ['localhost:9090']
    - job_name: 'kubernetes-nodes'
      kubernetes_sd_configs:
      - role: node
      relabel_configs:
      - source_labels: [__address__]
        regex: '(.*):10250'
        replacement: '${1}:9100'
        target_label: __address__
        action: replace
      - action: labelmap
        regex: __meta_kubernetes_node_label_(.+)

    - job_name: 'kubernetes-kubelet'
      kubernetes_sd_configs:
      - role: node
      scheme: https
      tls_config:
        ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        insecure_skip_verify: true
      bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
      relabel_configs:
      - action: labelmap
        regex: __meta_kubernetes_node_label_(.+)

    - job_name: 'kubernetes-cadvisor'
      kubernetes_sd_configs:
      - role: node
      scheme: https
      tls_config:
        ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
      bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
      relabel_configs:
      - action: labelmap
        regex: __meta_kubernetes_node_label_(.+)
      - target_label: __address__
        replacement: kubernetes.default.svc:443
      - source_labels: [__meta_kubernetes_node_name]
        regex: (.+)
        target_label: __metrics_path__
        replacement: /api/v1/nodes/${1}/proxy/metrics/cadvisor

    - job_name: 'kubernetes-apiservers'
      kubernetes_sd_configs:
      - role: endpoints
      scheme: https
      tls_config:
        ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
      bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
      relabel_configs:
      - source_labels: [__meta_kubernetes_namespace, __meta_kubernetes_service_name, __meta_kubernetes_endpoint_port_name]
        action: keep
        regex: default;kubernetes;https

    - job_name: 'kubernetes-service-endpoints'
      kubernetes_sd_configs:
      - role: endpoints
      relabel_configs:
      - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scrape]
        action: keep
        regex: true
      - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scheme]
        action: replace
        target_label: __scheme__
        regex: (https?)
      - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_path]
        action: replace
        target_label: __metrics_path__
        regex: (.+)
      - source_labels: [__address__, __meta_kubernetes_service_annotation_prometheus_io_port]
        action: replace
        target_label: __address__
        regex: ([^:]+)(?::\d+)?;(\d+)
        replacement: $1:$2
      - action: labelmap
        regex: __meta_kubernetes_service_label_(.+)
      - source_labels: [__meta_kubernetes_namespace]
        action: replace
        target_label: kubernetes_namespace
      - source_labels: [__meta_kubernetes_service_name]
        action: replace
        target_label: kubernetes_name
EOF
```
注意这里在relabel_configs区域做了大量的配置，特别是第一个保留__meta_kubernetes_service_annotation_prometheus_io_scrape为true的才保留下来，这就是说要想自动发现集群中的 Service，就需要在 Service 的annotation区域添加prometheus.io/scrape=true的声明，现在先将上面的配置更新，查看下效果：

![20191128115619.png](https://i.loli.net/2019/11/28/6egrNzv4GlptnsZ.png)

#### k8s集群中的资源类型监控

上面配置了自动发现 Service（Pod也是一样的）的监控，但是这些监控数据都是应用内部的监控，需要应用本身提供一个/metrics接口，或者对应的 exporter 来暴露对应的指标数据，但是在 Kubernetes 集群上 Pod、DaemonSet、Deployment、Job、CronJob 等各种资源对象的状态也需要监控，这也反映了使用这些资源部署的应用的状态。但通过查看前面从集群中拉取的指标(这些指标主要来自 apiserver 和 kubelet 中集成的 cAdvisor)，并没有具体的各种资源对象的状态指标。对于 Prometheus 来说，当然是需要引入新的 exporter 来暴露这些指标，Kubernetes 提供了一个kube-state-metrics就是我们需要的。

kube-state-metrics 已经给出了在 Kubernetes 部署的 manifest 定义文件，我们直接将代码 Clone 到集群中(能用 kubectl 工具操作就行):
```bash
git clone https://github.com/kubernetes/kube-state-metrics.git
kubectl create -f kube-state-metrics/examples/standard/
```

创建监控配置文件如下:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
  namespace: monitoring
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
      scrape_timeout: 15s
    scrape_configs:
    - job_name: 'prometheus'
      static_configs:
      - targets: ['localhost:9090']
    - job_name: 'kubernetes-nodes'
      kubernetes_sd_configs:
      - role: node
      relabel_configs:
      - source_labels: [__address__]
        regex: '(.*):10250'
        replacement: '${1}:9100'
        target_label: __address__
        action: replace
      - action: labelmap
        regex: __meta_kubernetes_node_label_(.+)

    - job_name: 'kube-state-metrics'
      kubernetes_sd_configs:
      - role: endpoints
      relabel_configs:
      - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scrape]
        action: keep
        regex: true
      - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scheme]
        action: replace
        target_label: __scheme__
        regex: (https?)
      - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_path]
        action: replace
        target_label: __metrics_path__
        regex: (.+)
      - source_labels: [__address__, __meta_kubernetes_service_annotation_prometheus_io_port]
        action: replace
        target_label: __address__
        regex: ([^:]+)(?::\d+)?;(\d+)
        replacement: $1:$2
      - action: labelmap
        regex: __meta_kubernetes_service_label_(.+)
      - source_labels: [__meta_kubernetes_namespace]
        action: replace
        target_label: kubernetes_namespace
      - source_labels: [__meta_kubernetes_service_name]
        action: replace
        target_label: kubernetes_name
```
查看完整的监控配置文件：

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
  namespace: monitoring
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
      scrape_timeout: 15s
    scrape_configs:
    - job_name: 'prometheus'
      static_configs:
      - targets: ['localhost:9090']
    - job_name: 'kubernetes-nodes'
      kubernetes_sd_configs:
      - role: node
      relabel_configs:
      - source_labels: [__address__]
        regex: '(.*):10250'
        replacement: '${1}:9100'
        target_label: __address__
        action: replace
      - action: labelmap
        regex: __meta_kubernetes_node_label_(.+)

    - job_name: 'kubelet'
      kubernetes_sd_configs:
      - role: node
      scheme: https
      tls_config:
        ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        insecure_skip_verify: true
      bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
      relabel_configs:
      - action: labelmap
        regex: __meta_kubernetes_node_label_(.+)

    - job_name: 'kubernetes-cadvisor'
      kubernetes_sd_configs:
      - role: node
      scheme: https
      tls_config:
        ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
      bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
      relabel_configs:
      - action: labelmap
        regex: __meta_kubernetes_node_label_(.+)
      - target_label: __address__
        replacement: kubernetes.default.svc:443
      - source_labels: [__meta_kubernetes_node_name]
        regex: (.+)
        target_label: __metrics_path__
        replacement: /api/v1/nodes/${1}/proxy/metrics/cadvisor

    - job_name: 'kubernetes-apiservers'
      kubernetes_sd_configs:
      - role: endpoints
      scheme: https
      tls_config:
        ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
      bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
      relabel_configs:
      - source_labels: [__meta_kubernetes_namespace, __meta_kubernetes_service_name, __meta_kubernetes_endpoint_port_name]
        action: keep
        regex: default;kubernetes;https

    - job_name: 'kube-state-metrics'
      kubernetes_sd_configs:
      - role: endpoints
      relabel_configs:
      - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scrape]
        action: keep
        regex: true
      - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scheme]
        action: replace
        target_label: __scheme__
        regex: (https?)
      - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_path]
        action: replace
        target_label: __metrics_path__
        regex: (.+)
      - source_labels: [__address__, __meta_kubernetes_service_annotation_prometheus_io_port]
        action: replace
        target_label: __address__
        regex: ([^:]+)(?::\d+)?;(\d+)
        replacement: $1:$2
      - action: labelmap
        regex: __meta_kubernetes_service_label_(.+)
      - source_labels: [__meta_kubernetes_namespace]
        action: replace
        target_label: kubernetes_namespace
      - source_labels: [__meta_kubernetes_service_name]
        action: replace
        target_label: kubernetes_name
```
####  metrics-server安装使用
kubernetes 集群资源监控之前可以通过 heapster 来获取数据，在 1.11 开始开始逐渐废弃 heapster 了，采用 metrics-server 来代替，metrics-server 是集群的核心监控数据的聚合器，它从 kubelet 公开的 Summary API 中采集指标信息，metrics-server 是扩展的 APIServer，依赖于kube-aggregator，因为我们需要在 APIServer 中开启相关参数。

将 kube-state-metrics 部署到 Kubernetes 上之后，就会发现 Kubernetes 集群中的 Prometheus 会在kubernetes-service-endpoints 这个 job 下自动服务发现 kube-state-metrics，并开始拉取 metrics，这是因为部署 kube-state-metrics 的 manifest 定义文件 kube-state-metrics-service.yaml 对 Service 的定义包含prometheus.io/scrape: 'true'这样的一个annotation，因此 kube-state-metrics 的 endpoint 可以被 Prometheus 自动服务发现。

查看 APIServer 参数配置，确保你的 APIServer 启动参数中包含下的一些参数配置。
```yaml
...
- --requestheader-client-ca-file=/etc/kubernetes/certs/proxy-ca.crt
- --proxy-client-cert-file=/etc/kubernetes/certs/proxy.crt
- --proxy-client-key-file=/etc/kubernetes/certs/proxy.key
- --requestheader-allowed-names=aggregator
- --requestheader-extra-headers-prefix=X-Remote-Extra-
- --requestheader-group-headers=X-Remote-Group
- --requestheader-username-headers=X-Remote-User
- --enable-aggregator-routing=true
...
```
如果未在 master 节点上运行 kube-proxy，则必须确保 kube-apiserver 启动参数中包含--enable-aggregator-routing=true

可以直接使用 metrics-server 官方提供的资源清单文件直接安装，地址：https://github.com/kubernetes-incubator/metrics-server/tree/master/deploy,修改镜像为阿里云镜像　registry.aliyuncs.com/google_containers/metrics-server-amd64:v0.3.6
```bash
kubectl create -f 1.8+/
```

在 metrics-server 的启动参数中修改kubelet-preferred-address-types参数，因为部署集群的时候，CA 证书并没有把各个节点的 IP 签上去，所以这里 metrics-server 通过 IP 去请求时，提示签的证书没有对应的 IP（错误：x509: cannot validate certificate for 192.168.33.11 because it doesn’t contain any IP SANs），可以添加一个--kubelet-insecure-tls参数跳过证书校验：
```yaml
args:
- --kubelet-insecure-tls
- --kubelet-preferred-address-types=InternalDNS,InternalIP,ExternalDNS,ExternalIP,Hostname
```
查看节点资源使用率：
```bash
NAME                              CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%   
dadi-saas-pre-master-dist-sz-01   260m         13%    2330Mi          63%       
dadi-saas-pre-node-dist-sz-01     536m         13%    5032Mi          65%       
dadi-saas-pre-node-dist-sz-02     548m         13%    4267Mi          55% 
```

#### etcd监控
创建etcd secret
```bash
kubectl -n monitoring create secret generic etcd-certs --from-file=/etc/kubernetes/pki/etcd/healthcheck-client.crt --from-file=/etc/kubernetes/pki/etcd/healthcheck-client.key --from-file=/etc/kubernetes/pki/etcd/ca.crt
```
重新配置prometheus-deploy.yaml添加etcd-cert
```yaml
        - name: etcd-secret
          mountPath: "/etc/prometheus/secrets/etcd-certs"
      volumes:
      - name: etcd-secret
        secret:
          secretName: etcd-certs

```
查看配置的job
```yaml
    - job_name: 'kubernetes-etcd'
      scheme: https
      tls_config:
        ca_file: /etc/prometheus/secrets/etcd-certs/ca.crt
        cert_file: /etc/prometheus/secrets/etcd-certs/healthcheck-client.crt
        key_file: /etc/prometheus/secrets/etcd-certs/healthcheck-client.key
        insecureSkipVerify: true
      scrape_interval: 5s
      static_configs:
        - targets: ['172.18.12.19:2379']
```

#### 监控Pod
创建配置文件,加入到prometheus即可：
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
  namespace: monitoring
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
      scrape_timeout: 15s
    scrape_configs:
    - job_name: 'prometheus'
      static_configs:
      - targets: ['localhost:9090']
      
    - job_name: 'kubernetes-pods'
      kubernetes_sd_configs:
      - role: pod
      relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
        action: replace
        target_label: __metrics_path__
        regex: (.+)
      - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
        action: replace
        regex: ([^:]+)(?::\d+)?;(\d+)
        replacement: $1:$2
        target_label: __address__
      - action: labelmap
        regex: __meta_kubernetes_pod_label_(.+)
      - source_labels: [__meta_kubernetes_namespace]
        action: replace
        target_label: kubernetes_namespace
      - source_labels: [__meta_kubernetes_pod_name]
        action: replace
        target_label: kubernetes_pod_name
```