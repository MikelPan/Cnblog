### EFK 架构说明
日志收集方案是采用 Elasticsearch、Fluentd、Filebeat 和 Kibana（EFK）技术栈。
Fluented主要用来收集k8s组件和docker容器日志，Filebeat主要用来收集应用日志，主要因为目前项目中应用日志并未全部通过stdout方式输出到docker日志驱动中，导致flunted收集日志并不全面，需要通过Filebeat来将应用日志收集到es中，再由kibana来展示。

Elasticsearch 是一个实时的、分布式的可扩展的搜索引擎，允许进行全文、结构化搜索，它通常用于索引和搜索大量日志数据，也可用于搜索许多不同类型的文档。

Elasticsearch 通常与 Kibana 一起部署，Kibana 是 Elasticsearch 的一个功能强大的数据可视化 Dashboard，Kibana 允许你通过 web 界面来浏览 Elasticsearch 日志数据。

Fluentd是一个流行的开源数据收集器，我们将在 Kubernetes 集群节点上安装 Fluentd，通过获取容器日志文件、过滤和转换日志数据，然后将数据传递到 Elasticsearch 集群，在该集群中对其进行索引和存储。

Filebeat 内置有多种模块（auditd、Apache、NGINX、System、MySQL 等等），可针对常见格式的日志大大简化收集、解析和可视化过程，只需一条命令即可。之所以能实现这一点，是因为它将自动默认路径（因操作系统而异）与 Elasticsearch 采集节点管道的定义和 Kibana 仪表板组合在一起。不仅如此，数个 Filebeat 模块还包括预配置的 Machine Learning 任务。

将官方提供的yaml下载到本地，如EFK目录下
https://github.com/kubernetes/kubernetes/tree/master/cluster/addons/fluentd-elasticsearch
```bash
wget  \
https://raw.githubusercontent.com/kubernetes/kubernetes/master/cluster/addons/fluentd-elasticsearch/es-statefulset.yaml
wget  \
https://raw.githubusercontent.com/kubernetes/kubernetes/master/cluster/addons/fluentd-elasticsearch/es-service.yaml
wget  \
https://raw.githubusercontent.com/kubernetes/kubernetes/master/cluster/addons/fluentd-elasticsearch/fluentd-es-configmap.yaml
wget  \
https://raw.githubusercontent.com/kubernetes/kubernetes/master/cluster/addons/fluentd-elasticsearch/fluentd-es-ds.yaml
wget  \
https://raw.githubusercontent.com/kubernetes/kubernetes/master/cluster/addons/fluentd-elasticsearch/kibana-service.yaml
wget  \
https://raw.githubusercontent.com/kubernetes/kubernetes/master/cluster/addons/fluentd-elasticsearch/kibana-deployment.yaml
```

下载filebeat官方提供的yaml文件到本地目录下如EFK
https://github.com/elastic/beats/blob/master/deploy/kubernetes/filebeat-kubernetes.yaml


#### 创建 Elasticsearch 集群
在创建 Elasticsearch 集群之前，先创建一个命名空间，我们将在其中安装所有日志相关的资源对象。
新建一个 kube-logging_ns.yaml 文件：
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: logging
```
然后通过 kubectl 创建该资源清单，创建一个名为 logging 的 namespace：
```bash
# kubectl get ns
NAME                       STATUS   AGE
default                    Active   115d
kube-node-lease            Active   115d
kube-public                Active   115d
kube-system                Active   115d
logging                    Active   62d
```
修改定义 Pod 模板部分内容,添加java_opts环境变量
```bash
        env:
        - name: "NAMESPACE"
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        - name: ES_JAVA_OPTS
          value: "-Xms512m -Xmx512m"
```
该部分是定义 StatefulSet 中的 Pod，我们这里使用一个-oss后缀的镜像，该镜像是 Elasticsearch 的开源版本，如果你想使用包含X-Pack之类的版本，可以去掉该后缀。然后暴露了9200和9300两个端口，注意名称要和上面定义的 Service 保持一致。然后通过 volumeMount 声明了数据持久化目录，下面我们再来定义 VolumeClaims。最后就是我们在容器中设置的一些环境变量了：
- ES_JAVA_OPTS：这里我们设置为-Xms512m -Xmx512m，告诉JVM使用512 MB的最小和最大堆。

接下来添加关于 initContainer 的内容
```bash
      initContainers:
      - name: fix-permissions
        image: busybox
        command: ["sh", "-c", "chown -R 1000:1000 /usr/share/elasticsearch/data"]
        securityContext:
          privileged: true
        volumeMounts:
        - name: data
          mountPath: /usr/share/elasticsearch/data
      - name: elasticsearch-logging-init
        image: alpine:3.6
        command: ["/sbin/sysctl", "-w", "vm.max_map_count=262144"]
        securityContext:
          privileged: true
      - name: increase-fd-ulimit
        image: busybox
        command: ["sh", "-c", "ulimit -n 65536"]
        securityContext:
          privileged: true
                           
```
这里定义了几个在主应用程序之前运行的 Init 容器，这些初始容器按照定义的顺序依次执行，执行完成后才会启动主应用容器。

第一个名为 fix-permissions 的容器用来运行 chown 命令，将 Elasticsearch 数据目录的用户和组更改为1000:1000（Elasticsearch 用户的 UID）。因为默认情况下，Kubernetes 用 root 用户挂载数据目录，这会使得 Elasticsearch 无法方法该数据目录，可以参考 Elasticsearch 生产中的一些默认注意事项相关文档说明：https://www.elastic.co/guide/en/elasticsearch/reference/current/docker.html#_notes_for_production_use_and_defaults。

第二个名为 elasticsearch-logging-init 的容器用来增加操作系统对mmap计数的限制，默认情况下该值可能太低，导致内存不足的错误，要了解更多关于该设置的信息，可以查看 Elasticsearch 官方文档说明：https://www.elastic.co/guide/en/elasticsearch/reference/current/vm-max-map-count.html。

最后一个初始化容器是用来执行ulimit命令增加打开文件描述符的最大数量的。

修改数据目录持久化
```bash
        volumeMounts:
        - name: elasticsearch-logging
          mountPath: /usr/share/elasticsearch/data
      volumes:
      - name: elasticsearch-logging
        hostPath:
          path: /data/elasticsearch-logs/data
```
通过hostPath模式将es数据持久化到宿主机上。

完整的配置文件如下：
```yaml
# RBAC authn and authz
apiVersion: v1
kind: ServiceAccount
metadata:
  name: elasticsearch-logging
  namespace: logging
  labels:
    k8s-app: elasticsearch-logging
    addonmanager.kubernetes.io/mode: Reconcile
---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: elasticsearch-logging
  labels:
    k8s-app: elasticsearch-logging
    addonmanager.kubernetes.io/mode: Reconcile
rules:
- apiGroups:
  - ""
  resources:
  - "services"
  - "namespaces"
  - "endpoints"
  verbs:
  - "get"
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  namespace: logging
  name: elasticsearch-logging
  labels:
    k8s-app: elasticsearch-logging
    addonmanager.kubernetes.io/mode: Reconcile
subjects:
- kind: ServiceAccount
  name: elasticsearch-logging
  namespace: logging
  apiGroup: ""
roleRef:
  kind: ClusterRole
  name: elasticsearch-logging
  apiGroup: ""
---
# Elasticsearch deployment itself
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: elasticsearch-logging
  namespace: logging
  labels:
    k8s-app: elasticsearch-logging
    version: v7.2.0
    addonmanager.kubernetes.io/mode: Reconcile
spec:
  serviceName: elasticsearch-logging
  replicas: 1
  selector:
    matchLabels:
      k8s-app: elasticsearch-logging
      version: v7.2.0
  template:
    metadata:
      labels:
        k8s-app: elasticsearch-logging
        version: v7.2.0
    spec:
      serviceAccountName: elasticsearch-logging
      containers:
      - image: quay.io/fluentd_elasticsearch/elasticsearch:v7.2.0
        name: elasticsearch-logging
        imagePullPolicy: IfNotPresent
        resources:
          # need more cpu upon initialization, therefore burstable class
          limits:
            cpu: 1000m
          requests:
            cpu: 100m
        ports:
        - containerPort: 9200
          name: db
          protocol: TCP
        - containerPort: 9300
          name: transport
          protocol: TCP
        volumeMounts:
        - name: data
          mountPath: /usr/share/elasticsearch/data
        env:
        - name: ES_JAVA_OPTS
          value: "-Xms512m -Xmx512m"
        - name: TZ
          value: Asia/Shanghai
        - name: "NAMESPACE"
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
      volumes:
      - name: data
        hostPath:
          path: /data/elasticsearch-logs/data
      # Elasticsearch requires vm.max_map_count to be at least 262144.
      # If your OS already sets up this number to a higher value, feel free
      # to remove this init container.
      initContainers:
      - name: fix-permissions
        image: busybox
        command: ["sh", "-c", "chown -R 1000:1000 /usr/share/elasticsearch/data"]
        securityContext:
          privileged: true
        volumeMounts:
        - name: data
          mountPath: /usr/share/elasticsearch/data
      - image: alpine:3.6
        command: ["/sbin/sysctl", "-w", "vm.max_map_count=262144"]
        name: elasticsearch-logging-init
        securityContext:
          privileged: true
      - name: increase-fd-ulimit
        image: busybox
        command: ["sh", "-c", "ulimit -n 65536"]
        securityContext:
          privileged: true
```

#### 创建 Kibana 服务
修改kibana-deployment.yaml文件将服务认证注释掉
```yaml
         # - name: SERVER_BASEPATH
            value: /api/v1/namespaces/kube-system/services/kibana-logging/proxy
```
修改server为Noport模式暴露出来
```yaml
spec:
  type: NodePort
  ports:
  - port: 5601
    protocol: TCP
    targetPort: ui
    nodePort: 32617

```
启动服务
```bash
kubectl apply -f kibana-deployment.yaml kibana-service.yaml
```
安装完成后直接通过IP+端口方式访问kibana面板

#### 安装fluented服务
##### 工作原理

Fluentd 通过一组给定的数据源抓取日志数据，处理后（转换成结构化的数据格式）将它们转发给其他服务，比如 Elasticsearch、对象存储等等。Fluentd 支持超过300个日志存储和分析服务，所以在这方面是非常灵活的。主要运行步骤如下：

- 首先 Fluentd 从多个日志源获取数据
- 结构化并且标记这些数据
- 然后根据匹配的标签将数据发送到多个目标服务去

*日志源配置*
收集 Kubernetes 节点上的所有容器日志，就需要做如下的日志源配置
```yaml
<source>

@id fluentd-containers.log

@type tail

path /var/log/containers/*.log

pos_file /var/log/fluentd-containers.log.pos

time_format %Y-%m-%dT%H:%M:%S.%NZ

tag raw.kubernetes.*

format json

read_from_head true

</source>
```
上面配置部分参数说明如下：

- id：表示引用该日志源的唯一标识符，该标识可用于进一步过滤和路由结构化日志数据
- type：Fluentd 内置的指令，tail表示 Fluentd 从上次读取的位置通过 tail 不断获取数据，另外一个是http表示通过一个 GET 请求来收集数据。
- path：tail类型下的特定参数，告诉 Fluentd 采集/var/log/containers目录下的所有日志，这是 docker 在 Kubernetes 节点上用来存储运行容器 stdout 输出日志数据的目录。
- pos_file：检查点，如果 Fluentd 程序重新启动了，它将使用此文件中的位置来恢复日志数据收集。
- tag：用来将日志源与目标或者过滤器匹配的自定义字符串，Fluentd 匹配源/目标标签来路由日志数据。

*路由配置*
上面是日志源的配置，接下来看看如何将日志数据发送到 Elasticsearch：

```yaml
    <match **>
      @id elasticsearch
      @type elasticsearch
      @log_level info
      type_name _doc
      include_tag_key true
      host elasticsearch-logging
      port 9200
      logstash_format true
      <buffer>
        @type file
        path /var/log/fluentd-buffers/kubernetes.system.buffer
        flush_mode interval
        retry_type exponential_backoff
        flush_thread_count 2
        flush_interval 5s
        retry_forever
        retry_max_interval 30
        chunk_limit_size 2M
        queue_limit_length 8
        overflow_action block
      </buffer>
    </match>
```
- match：标识一个目标标签，后面是一个匹配日志源的正则表达式，这里想要捕获所有的日志并将它们发送给 Elasticsearch，所以需要配置成**。
- id：目标的一个唯一标识符。
- type：支持的输出插件标识符，这里要输出到 Elasticsearch，所以配置成 elasticsearch，这是 Fluentd 的一个内置插件。
- log_level：指定要捕获的日志级别，这里配置成info，表示任何该级别或者该级别以上（INFO、WARNING、ERROR）的日志都将被路由到 Elsasticsearch。
- host/port：定义 Elasticsearch 的地址，也可以配置认证信息，我们的 Elasticsearch 不需要认证，所以这里直接指定 host 和 port 即可。
- logstash_format：Elasticsearch 服务对日志数据构建反向索引进行搜索，将 logstash_format 设置为true，Fluentd 将会以 logstash 格式来转发结构化的日志数据。
- Buffer： Fluentd 允许在目标不可用时进行缓存，比如，如果网络出现故障或者 Elasticsearch 不可用的时候。缓冲区配置也有助于降低磁盘的 IO。

##### 安装fluented

要收集 Kubernetes 集群的日志，直接用 DasemonSet 控制器来部署 Fluentd 应用，这样，它就可以从 Kubernetes 节点上采集日志，确保在集群中的每个节点上始终运行一个 Fluentd 容器。

首先，通过 ConfigMap 对象来指定 Fluentd 配置文件，新建 fluentd-configmap.yaml 文件，文件内容如下：
```yaml
kind: ConfigMap
apiVersion: v1
metadata:
  name: fluentd-es-config-v0.2.0
  namespace: kube-system
  labels:
    addonmanager.kubernetes.io/mode: Reconcile
data:
  system.conf: |-
    <system>
      root_dir /tmp/fluentd-buffers/
    </system>
  containers.input.conf: |-
    <source>
      @id fluentd-containers.log
      @type tail
      path /var/log/containers/*.log
      pos_file /var/log/es-containers.log.pos
      time_format %Y-%m-%dT%H:%M:%S.%NZ
      localtime
      tag raw.kubernetes.*
      format json
      read_from_head true
    </source>
    # Detect exceptions in the log output and forward them as one log entry.
    <match raw.kubernetes.**>
      @id raw.kubernetes
      @type detect_exceptions
      remove_tag_prefix raw
      message log
      stream stream
      multiline_flush_interval 5
      max_bytes 500000
      max_lines 1000
    </match>
    system.input.conf: |-
    # Logs from systemd-journal for interesting services.
    <source>
      @id journald-docker
      @type systemd
      filters [{ "_SYSTEMD_UNIT": "docker.service" }]
      <storage>
        @type local
        persistent true
      </storage>
      read_from_head true
      tag docker
    </source>
    <source>
      @id journald-kubelet
      @type systemd
      filters [{ "_SYSTEMD_UNIT": "kubelet.service" }]
      <storage>
        @type local
        persistent true
      </storage>
      read_from_head true
      tag kubelet
    </source>
  forward.input.conf: |-
    # Takes the messages sent over TCP
    <source>
      @type forward
    </source>
  output.conf: |-
    # Enriches records with Kubernetes metadata
    <filter kubernetes.**>
      @type kubernetes_metadata
    </filter>
    <match **>
      @id elasticsearch
      @type elasticsearch
      @log_level info
      include_tag_key true
      host elasticsearch
      port 9200
      logstash_format true
      request_timeout    30s
      <buffer>
        @type file
        path /var/log/fluentd-buffers/kubernetes.system.buffer
        flush_mode interval
        retry_type exponential_backoff
        flush_thread_count 2
        flush_interval 5s
        retry_forever
        retry_max_interval 30
        chunk_limit_size 2M
        queue_limit_length 8
        overflow_action block
      </buffer>
    </match>
```
上面配置文件中配置了 docker 容器日志目录以及 docker、kubelet 应用的日志的收集，收集到数据经过处理后发送到 elasticsearch:9200 服务

新建一个 fluentd-daemonset.yaml 的文件，文件内容如下：
```yaml
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: fluentd-es
  namespace: logging
  labels:
    k8s-app: fluentd-es
    addonmanager.kubernetes.io/mode: Reconcile
---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: fluentd-es
  labels:
    k8s-app: fluentd-es
    addonmanager.kubernetes.io/mode: Reconcile
rules:
- apiGroups:
  - ""
  resources:
  - "namespaces"
  - "pods"
  - "service"
  verbs:
  - "get"
  - "watch"
  - "list"
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: fluentd-es
  labels:
    k8s-app: fluentd-es
    addonmanager.kubernetes.io/mode: Reconcile
subjects:
- kind: ServiceAccount
  name: fluentd-es
  namespace: logging
  apiGroup: ""
roleRef:
  kind: ClusterRole
  name: fluentd-es
  apiGroup: ""
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd-es-v2.7.0
  namespace: logging
  labels:
    k8s-app: fluentd-es
    version: v2.7.0
    addonmanager.kubernetes.io/mode: Reconcile
spec:
  selector:
    matchLabels:
      k8s-app: fluentd-es
      version: v2.7.0
  template:
    metadata:
      labels:
        k8s-app: fluentd-es
        version: v2.7.0
      # This annotation ensures that fluentd does not get evicted if the node
      # supports critical pod annotation based priority scheme.
      # Note that this does not guarantee admission on the nodes (#40573).
      annotations:
        seccomp.security.alpha.kubernetes.io/pod: 'docker/default'
    spec:
      priorityClassName: system-node-critical
      serviceAccountName: fluentd-es
      containers:
      - name: fluentd-es
        image: quay.io/fluentd_elasticsearch/fluentd:v2.7.0
        env:
        - name: FLUENTD_ARGS
          value: --no-supervisor -q
        resources:
          limits:
            memory: 500Mi
          requests:
            cpu: 100m
            memory: 200Mi
        volumeMounts:
        - name: varlog
          mountPath: /var/log
        - name: varlibdockercontainers
          mountPath: /var/lib/docker/containers
          readOnly: true
        - name: config-volume
          mountPath: /etc/fluent/config.d
      terminationGracePeriodSeconds: 30
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
      - name: varlibdockercontainers
        hostPath:
          path: /var/lib/docker/containers
      - name: config-volume
        configMap:
          name: fluentd-es-config-v0.2.0
```

分别创建上面的 ConfigMap 对象和 DaemonSet
```bash
kubectl apply -f fluentd-es-configmap.yaml   fluentd-es-ds.yaml
```

Fluentd 启动成功后，可以前往 Kibana 的 Dashboard 页面中，点击左侧的Discover，配置index后即可查看日志。

#### 安装 filebeat
这里，将基于Elastic官方提供的Filebeat部署脚本进行部署：
官方配置文件无法直接使用，需要我们定制。首先，修改DaemonSet中的环境变量env：
```yaml
   env:
        - name: ELASTICSEARCH_HOST
          value: "47.106.212.22"
        - name: ELASTICSEARCH_PORT
          value: "32700"
        - name: ELASTICSEARCH_USERNAME
          value:
        - name: ELASTICSEARCH_PASSWORD
          value:
        - name: ELASTIC_CLOUD_ID
          value:
        - name: ELASTIC_CLOUD_AUTH
```
如上，ELASTICSEARCH_HOST指定为Elasticsearch集群的入口地址，端口ELASTICSEARCH_PORT为默认的9200；由于集群没有加密，因此ELASTICSEARCH_USERNAME和ELASTICSEARCH_PASSWORD全部留空；其他保持默认。

同时，还需要注释掉第一个ConfigMap中output.elasticsearch的用户名和密码：
```yaml
      #username: ${ELASTICSEARCH_USERNAME}
      #password: ${ELASTICSEARCH_PASSWORD}
```
其次，还需要修改第二个ConfigMap的data部分为，修改为自身符合的配置，这里根据项目名称添加不同的索引值
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: filebeat-config
  namespace: kube-system
  labels:
    k8s-app: filebeat
data:
  filebeat.yml: |-
    filebeat.inputs:
    - type: log
      paths:
        - "/data/log/app/*/*/*.log"
        - "/data/log/app/*/*"
        - "/data/log/app/*"
    output.elasticsearch:
      hosts: ['${ELASTICSEARCH_HOST:47.106.212.24}:${ELASTICSEARCH_PORT:32700}']
      indices:
        - index: "nginx-log-%{+yyyy.MM.dd}"
          when.contains:
            message: "nginx-log"
        - index: "notification-log-%{+yyyy.MM.dd}"
          when.contains:
            message: "notification-log"
        - index: "offer-policy-log-%{+yyyy.MM.dd}"
          when.contains:
            message: "offer-policy-log"
        - index: "core-%{+yyyy.MM.dd}"
          when.contains:
            message: "core-log"
```
修改完配置后，可以启动filebeat服务
```bash
kubectl apply -f filebeat-kubernetes.yaml
```
启动成功后即可在kibana面板中配置添加索引模式，方便阅览。