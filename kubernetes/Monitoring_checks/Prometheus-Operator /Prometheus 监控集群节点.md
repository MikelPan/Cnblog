### 监控k8s 集群节点
对于集群的监控一般我们需要考虑以下几个方面：

Kubernetes 节点的监控：比如节点的 cpu、load、disk、memory 等指标
内部系统组件的状态：比如 kube-scheduler、kube-controller-manager、kubedns/coredns 等组件的详细运行状态
编排级的 metrics：比如 Deployment 的状态、资源请求、调度和 API 延迟等数据指标

Kubernetes 集群的监控方案目前主要有以下几种方案：
- cAdvisor：cAdvisor是Google开源的容器资源监控和性能分析工具，它是专门为容器而生，本身也支持 Docker 容器，在 Kubernetes 中，我们不需要单独去安装，cAdvisor 作为 kubelet 内置的一部分程序可以直接使用。

- Kube-state-metrics：kube-state-metrics通过监听 API Server 生成有关资源对象的状态指标，比如 Deployment、Node、Pod，需要注意的是 kube-state-metrics 只是简单提供一个 metrics 数据，并不会存储这些指标数据，所以我们可以使用 Prometheus 来抓取这些数据然后存储。
- metrics-server：metrics-server 也是一个集群范围内的资源数据聚合工具，是 Heapster 的替代品，同样的，metrics-server 也只是显示数据，并不提供数据存储服务。

不过 kube-state-metrics 和 metrics-server 之间还是有很大不同的，二者的主要区别如下：
- kube-state-metrics 主要关注的是业务相关的一些元数据，比如 Deployment、Pod、副本状态等
- metrics-server 主要关注的是资源度量 API 的实现，比如 CPU、文件描述符、内存、请求延时等指标。

#### 集群节点监控
这里通过 Prometheus 来采集节点的监控指标数据，可以通过node_exporter来获取，顾名思义，node_exporter 就是抓取用于采集服务器节点的各种运行指标，目前 node_exporter 支持几乎所有常见的监控点，比如 conntrack，cpu，diskstats，filesystem，loadavg，meminfo，netstat等，详细的监控点列表可以参考其Github repo

可以通过 DaemonSet 控制器来部署该服务，这样每一个节点都会自动运行一个这样的 Pod，如果从集群中删除或者添加节点后，也会进行自动扩展.

在部署 node-exporter 的时候有一些细节需要注意，如下资源清单文件：(prome-node-exporter.yaml)
```yaml
cat > prome-node-exporter.yaml <<EOF
apiVersion: extensions/v1beta1
kind: DaemonSet
metadata:
  name: node-exporter
  namespace: monitoring
  labels:
    name: node-exporter
spec:
  template:
    metadata:
      labels:
        name: node-exporter
    spec:
      hostPID: true
      hostIPC: true
      hostNetwork: true
      containers:
      - name: node-exporter
        image: prom/node-exporter:v0.18.1
        ports:
        - containerPort: 9100
        resources:
          requests:
            cpu: 0.15
        securityContext:
          privileged: true
        args:
        - --path.procfs
        - /host/proc
        - --path.sysfs
        - /host/sys
        - --collector.filesystem.ignored-mount-points
        - '"^/(sys|proc|dev|host|etc)($|/)"'
        volumeMounts:
        - name: dev
          mountPath: /host/dev
        - name: proc
          mountPath: /host/proc
        - name: sys
          mountPath: /host/sys
        - name: rootfs
          mountPath: /rootfs
      tolerations:
      - key: "node-role.kubernetes.io/master"
        operator: "Exists"
        effect: "NoSchedule"
      volumes:
        - name: proc
          hostPath:
            path: /proc
        - name: dev
          hostPath:
            path: /dev
        - name: sys
          hostPath:
            path: /sys
        - name: rootfs
          hostPath:
            path: /
EOF
```
由于要获取到的数据是主机的监控指标数据，而node-exporter 是运行在容器中的，所以在 Pod 中需要配置一些 Pod 的安全策略，这里就添加了hostPID: true、hostIPC: true、hostNetwork: true3个策略，用来使用主机的 PID namespace、IPC namespace 以及主机网络，这些 namespace 就是用于容器隔离的关键技术，要注意这里的 namespace 和集群中的 namespace 是两个完全不相同的概念。

另外还将主机的/dev、/proc、/sys这些目录挂载到容器中，这些因为采集的很多节点数据都是通过这些文件夹下面的文件来获取到的，比如在使用top命令可以查看当前cpu使用情况，数据就来源于文件/proc/stat，使用free命令可以查看当前内存使用情况，其数据来源是来自/proc/meminfo文件.

然后直接创建上面的资源对象即可：
```bash
kubectl create -f prome-node-exporter.yaml
kubectl get pods -n monitoring -o wide
NAME                          READY   STATUS    RESTARTS   AGE   IP              NODE                              NOMINATED NODE   READINESS GATES
node-exporter-q7xnc           1/1     Running   0          40s   172.18.12.19    dadi-saas-pre-master-dist-sz-01   <none>           <none>
node-exporter-rbfrz           1/1     Running   0          40s   172.18.12.20    dadi-saas-pre-node-dist-sz-01     <none>           <none>
node-exporter-zvlmz           1/1     Running   0          40s   172.18.143.48   dadi-saas-pre-node-dist-sz-02     <none>           <none>
prometheus-7cb9f4dc8d-g9x75   1/1     Running   0          25m   10.0.2.134      dadi-saas-pre-node-dist-sz-02     <none>           <none>

```
部署完成后，可以看到在3个节点上都运行了一个 Pod，应该怎样去获取/metrics数据呢？上面是不是指定了hostNetwork=true，所以在每个节点上就会绑定一个端口 9100，可以通过这个端口去获取到监控指标数据：
```bash
# curl 127.0.0.1:9100/metrics | head -n 20
# TYPE go_gc_duration_seconds summary
go_gc_duration_seconds{quantile="0"} 1.1498e-05
go_gc_duration_seconds{quantile="0.25"} 1.475e-05
go_gc_duration_seconds{quantile="0.5"} 3.3738e-05
go_gc_duration_seconds{quantile="0.75"} 4.21e-05
go_gc_duration_seconds{quantile="1"} 0.000174304
go_gc_duration_seconds_sum 0.00027639
go_gc_duration_seconds_count 5
```
####　服务发现

在 Kubernetes 下，Promethues 通过与 Kubernetes API 集成，目前主要支持5中服务发现模式，分别是：Node、Service、Pod、Endpoints、Ingress。

通过 kubectl 命令可以很方便的获取到当前集群中的所有节点信息：
```bash
# kubectl get nodes
NAME                              STATUS   ROLES    AGE   VERSION
dadi-saas-pre-master-dist-sz-01   Ready    master   91d   v1.15.3
dadi-saas-pre-node-dist-sz-01     Ready    <none>   91d   v1.15.3
dadi-saas-pre-node-dist-sz-02     Ready    <none>   14d   v1.15.3
```
但是要让 Prometheus 也能够获取到当前集群中的所有节点信息的话，就需要利用 Node 的服务发现模式，同样的，在 prometheus.yml 文件中配置如下的 job 任务即可：
```yaml
cat > prome-cm.yaml<<EOF
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
    - job_name: 'kubernetes-node'
      kubernetes_sd_configs:
      - role: node
EOF
```
通过指定kubernetes_sd_configs的模式为node，Prometheus 就会自动从 Kubernetes 中发现所有的 node 节点并作为当前 job 监控的目标实例，发现的节点/metrics接口是默认的 kubelet 的 HTTP 接口。

prometheus 的 ConfigMap 更新完成后，同样的执行 reload 操作，让配置生效：
```bash
kubectl delete -f prometheus-cm.yaml;kubectl create -f prometheus-cm.yaml
# 执行下面的　reload
# kubectl get svc -A | grep prometheus
monitoring             prometheus                                                     NodePort    10.97.135.241    <none>        9090:32501/TCP                      37m
curl -X POST "http://10.97.135.241:9090/-/reload"
```
配置生效后，再去 prometheus 的 dashboard 中查看 Targets 是否能够正常抓取数据，访问任意节点IP:32501：
![20191126224048.png](https://i.loli.net/2019/11/26/3uEahrZ97stpPnS.png)

可以看到上面的kubernetes-nodes这个 job 任务已经自动发现了我们3个 node 节点，但是在获取数据的时候失败了.

这个是因为 prometheus 去发现 Node 模式的服务的时候，访问的端口默认是10250，而现在该端口下面已经没有了/metrics指标数据了，现在 kubelet 只读的数据接口统一通过10255端口进行暴露了，所以应该去替换掉这里的端口，但是是要替换成10255端口吗？不是的，因为我们是要去配置上面通过node-exporter抓取到的节点指标数据，而上面是不是指定了hostNetwork=true，所以在每个节点上就会绑定一个端口9100，所以我们应该将这里的10250替换成9100，但是应该怎样替换呢？

这里就需要使用到 Prometheus 提供的relabel_configs中的replace能力了，relabel 可以在 Prometheus 采集数据之前，通过Target 实例的 Metadata 信息，动态重新写入 Label 的值。除此之外，我们还能根据 Target 实例的 Metadata 信息选择是否采集或者忽略该 Target 实例。比如这里就可以去匹配__address__这个 Label 标签，然后替换掉其中的端口：
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
EOF
```
这里就是一个正则表达式，去匹配__address__，然后将 host 部分保留下来，port 替换成了9100，现在重新更新配置文件，执行 reload 操作，然后再去看 Prometheus 的 Dashboard 的 Targets 路径下面 kubernetes-nodes 这个 job 任务是否正常了：
![20191127232601.png](https://i.loli.net/2019/11/27/QTaYcbD7yeFS9Lf.png)

添加了一个 action 为labelmap，正则表达式是__meta_kubernetes_node_label_(.+)的配置，这里的意思就是表达式中匹配都的数据也添加到指标数据的 Label 标签中去。

对于 kubernetes_sd_configs 下面可用的标签如下： 可用元标签：

- __meta_kubernetes_node_name：节点对象的名称
- _meta_kubernetes_node_label：节点对象中的每个标签
- _meta_kubernetes_node_annotation：来自节点对象的每个注释
- _meta_kubernetes_node_address：每个节点地址类型的第一个地址（如果存在） *

另外由于 kubelet 也自带了一些监控指标数据，就上面提到的10255端口，所以这里也把 kubelet 的监控任务也一并配置上：
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
EOF
```
现在再去更新下配置文件，执行 reload 操作，让配置生效，然后访问 Prometheus 的 Dashboard 查看 Targets 路径：

![20191127234244.png](https://i.loli.net/2019/11/27/uUwdzcSTobFtnsP.png)

