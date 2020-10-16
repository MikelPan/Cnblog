### AlertManager 简介
Prometheus将数据采集和报警分成了两个模块。报警规则配置在Prometheus Servers上，然后发送报警信息到AlertManger，然后我们的AlertManager就来管理这些报警信息，包括silencing、inhibition，聚合报警信息过后通过email、PagerDuty、HipChat、Slack 等方式发送消息提示.

让AlertManager提供服务总的来说就下面3步： 
- 安装和配置AlertManger 
- 配置Prometheus来和AlertManager通信
- 在Prometheus中创建报警规则.

### 安装和配置AlertManager
在Prometheus-operator中已经集成了,安装AlterManager的监控部署文件,部署文件如下：
```bash
ls -al | grep alertmanager
-rw-r--r-- 1 root root 282989 Oct 13 22:34 0prometheus-operator-0alertmanagerCustomResourceDefinition.yaml
-rw-r--r-- 1 root root    384 Dec 19 11:10 alertmanager-alertmanager.yaml
-rw-r--r-- 1 root root   1022 Nov  6 23:54 alertmanager-secret.yaml
-rw-r--r-- 1 root root     96 Oct 13 20:11 alertmanager-serviceAccount.yaml
-rw-r--r-- 1 root root    254 Oct 13 20:16 alertmanager-serviceMonitor.yaml
-rw-r--r-- 1 root root    308 Oct 13 20:16 alertmanager-service.yaml
-rw-r--r-- 1 root root    769 Dec 19 11:01 alertmanager.yaml
-rw-r--r-- 1 root root    244 Dec 19 10:07 reset_alertmanager_config.sh
```
官方提供的altermanager-secret需要自定义更改，这里手动写了一个alertmanager.yaml文件来编写自定义告警配置:
```yaml
global:
  resolve_timeout: 5m
  smtp_smarthost: 'smtp-n.global-mail.cn:465'
  smtp_from: 'qinglongpan@dadi01.com'
  smtp_auth_username: 'qinglongpan@dadi01.com'
  smtp_auth_password: '591674Password1'
  smtp_hello: 'smtp-n.global-mail.cn'
  smtp_require_tls: false
route:
  group_by: ['alertname','severity']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 1s
  receiver: default
  routes:
  - receiver: default
    match:
      alertname: CPUThrottlingHigh
  - receiver: webhook
    group_wait: 1s
    match_re:
      altername: CPUThrottlingHigh|Watchdog   
receivers:
- name: 'default'
  email_configs:
  - to: 'qinglongpan@dadi01.com'
    send_resolved: true
- name: 'webhook'
  webhook_configs:
  - url: 'http://webhook-dingtalk'
    send_resolved: true
```
执行配置更新命令:
```bash
cat > reset_alertmanager_config.sh <<EOF
kubectl delete secret alertmanager-main -n monitoring
kubectl create secret generic alertmanager-main --from-file=alertmanager.yaml -n monitoring
kubectl delete -f alertmanager-alertmanager.yaml;kubectl create -f alertmanager-alertmanager.yaml
EOF
sh reset_alertmanager_config.sh
```
### 自定义Alｅrtmanager 通知规则

Alertmanager处理由类似Prometheus服务器等客户端发来的警报，之后需要删除重复、分组，并将它们通过路由发送到正确的接收器，比如电子邮件、Slack等。Alertmanager还支持沉默和警报抑制的机制。

#### 分组

  分组是指当出现问题时，Alertmanager会收到一个单一的通知，而当系统宕机时，很有可能成百上千的警报会同时生成，这种机制在较大的中断中特别有用。

  例如，当数十或数百个服务的实例在运行，网络发生故障时，有可能服务实例的一半不可达数据库。在告警规则中配置为每一个服务实例都发送警报的话，那么结果是数百警报被发送至Alertmanager。

  但是作为用户只想看到单一的报警页面，同时仍然能够清楚的看到哪些实例受到影响，因此，人们通过配置Alertmanager将警报分组打包，并发送一个相对看起来紧凑的通知。

  分组警报、警报时间，以及接收警报的receiver是在配置文件中通过路由树配置的。

#### 抑制

  抑制是指当警报发出后，停止重复发送由此警报引发其他错误的警报的机制。

  例如，当警报被触发，通知整个集群不可达，可以配置Alertmanager忽略由该警报触发而产生的所有其他警报，这可以防止通知数百或数千与此问题不相关的其他警报。

  抑制机制可以通过Alertmanager的配置文件来配置

#### 沉默

  沉默是一种简单的特定时间静音提醒的机制。一种沉默是通过匹配器来配置，就像路由树一样。传入的警报会匹配RE，如果匹配，将不会为此警报发送通知。

  沉默机制可以通过Alertmanager的Web页面进行配置。

#### alertmanager路由

  路由块定义了路由树及其子节点。如果没有设置的话，子节点的可选配置参数从其父节点继承。

  每个警报进入配置的路由树的顶级路径，顶级路径必须匹配所有警报（即没有任何形式的匹配）。然后匹配子节点。如果continue的值设置为false，它在匹配第一个孩子后就停止；如果在子节点匹配，continue的值为true，警报将继续进行后续兄弟姐妹的匹配。如果警报不匹配任何节点的任何子节点（没有匹配的子节点，或不存在），该警报基于当前节点的配置处理。

  接收器 receiver
  顾名思义，警报接收的配置。比如邮件配置和企业微信配置等

#### 发送警报通知

  Prometheus可以周期性的发送关于警报状态的信息到Alertmanager实例，然后Alertmanager调度来发送正确的通知。该Alertmanager可以通过-alertmanager.url命令行flag来配置.

创建一个发送邮件通知的模板文件:
```yaml
cat > altermanager-template-cm.yaml <<EOF
apiVersion: v1  
kind: ConfigMap  
metadata:    
  name: alertmanager-templates  
  namespace: monitoring
data:  
  default.tmpl: |  
  {{ define "wechat.default.message" }}  
  {{ range .Alerts }}  
  ========start==========  
  告警程序：prometheus_alert  
  告警级别：{{ .Labels.severity }}  
  告警类型：{{ .Labels.alertname }}  
  故障主机: {{ .Labels.instance }}  
  告警主题: {{ .Annotations.summary }}  
  告警详情: {{ .Annotations.description }}  
  触发时间: {{ .StartsAt.Format "%Y-%m-%d %H:%M:%S" }}  
  ========end==========  
  {{ end }}  
  {{ end }} 
EOF
```
在Prometheus-operator中alertmanager的配置是在statefulset中配置：
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"monitoring.coreos.com/v1","kind":"Alertmanager","metadata":{"annotations":{},"labels":{"alertmanager":"main"},"name":"main","namespace":"monitoring"},"spec":{"baseImage":"quay.io/prometheus/alertmanager","nodeSelector":{"kubernetes.io/os":"linux"},"replicas":3,"securityContext":{"fsGroup":2000,"runAsNonRoot":true,"runAsUser":1000},"serviceAccountName":"alertmanager-main","version":"v0.18.0"}}
  creationTimestamp: "2019-12-19T02:45:35Z"
  generation: 1
  labels:
    alertmanager: main
  name: alertmanager-main
  namespace: monitoring
  ownerReferences:
  - apiVersion: monitoring.coreos.com/v1
    blockOwnerDeletion: true
    controller: true
    kind: Alertmanager
    name: main
    uid: 3facd495-83d7-4041-bfbd-cfe5becb9317
  resourceVersion: "17066440"
  selfLink: /apis/apps/v1/namespaces/monitoring/statefulsets/alertmanager-main
  uid: c30be63a-d678-454e-a7b2-e365e2852bd0
spec:
  podManagementPolicy: Parallel
  replicas: 3
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      alertmanager: main
      app: alertmanager
  serviceName: alertmanager-operated
  template:
    metadata:
      creationTimestamp: null
      labels:
        alertmanager: main
        app: alertmanager
    spec:
      containers:
      - args:
        - --config.file=/etc/alertmanager/config/alertmanager.yaml
        - --cluster.listen-address=[$(POD_IP)]:9094
        - --storage.path=/alertmanager
        - --data.retention=120h
        - --web.listen-address=:9093
        - --web.route-prefix=/
        - --cluster.peer=alertmanager-main-0.alertmanager-operated.monitoring.svc:9094
        - --cluster.peer=alertmanager-main-1.alertmanager-operated.monitoring.svc:9094
        - --cluster.peer=alertmanager-main-2.alertmanager-operated.monitoring.svc:9094
        env:
        - name: POD_IP
          valueFrom:
            fieldRef:
              apiVersion: v1
              fieldPath: status.podIP
        image: quay.io/prometheus/alertmanager:v0.18.0
        imagePullPolicy: IfNotPresent
        livenessProbe:
          failureThreshold: 10
          httpGet:
            path: /-/healthy
            port: web
            scheme: HTTP
          periodSeconds: 10
          successThreshold: 1
          timeoutSeconds: 3
        name: alertmanager
        ports:
        - containerPort: 9093
          name: web
          protocol: TCP
        - containerPort: 9094
          name: mesh-tcp
          protocol: TCP
        - containerPort: 9094
          name: mesh-udp
          protocol: UDP
        readinessProbe:
          failureThreshold: 10
          httpGet:
            path: /-/ready
            port: web
            scheme: HTTP
          initialDelaySeconds: 3
          periodSeconds: 5
          successThreshold: 1
          timeoutSeconds: 3
        resources:
          requests:
            memory: 200Mi
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: FallbackToLogsOnError
        volumeMounts:
        - mountPath: /etc/alertmanager/config
          name: config-volume
        - mountPath: /alertmanager
          name: alertmanager-main-db
        - mountPath: /usr/local/prometheus/alertmanager/template
          name: alertmanager-templates
      - args:
        - -webhook-url=http://localhost:9093/-/reload
        - -volume-dir=/etc/alertmanager/config
        image: quay.io/coreos/configmap-reload:v0.0.1
        imagePullPolicy: IfNotPresent
        name: config-reloader
        resources:
          limits:
            cpu: 100m
            memory: 25Mi
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: FallbackToLogsOnError
        volumeMounts:
        - mountPath: /etc/alertmanager/config
          name: config-volume
        - mountPath: /usr/local/prometheus/alertmanager/template
          name: alertmanager-templates
          readOnly: true
      dnsPolicy: ClusterFirst
      nodeSelector:
        kubernetes.io/os: linux
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext:
        fsGroup: 2000
        runAsNonRoot: true
        runAsUser: 1000
      serviceAccount: alertmanager-main
      serviceAccountName: alertmanager-main
      terminationGracePeriodSeconds: 120
      volumes:
      - name: config-volume
        secret:
          defaultMode: 420
          secretName: alertmanager-main
      - name: alertmanager-templates
        configMap: 
          name: alertmanager-templates
      - emptyDir: {}
        name: alertmanager-main-db
  updateStrategy:
    type: RollingUpdate
status:
  collisionCount: 0
  currentReplicas: 3
  currentRevision: alertmanager-main-8db7b8b5d
  observedGeneration: 1
  readyReplicas: 3
  replicas: 3
  updateRevision: alertmanager-main-8db7b8b5d
  updatedReplicas: 3
```
在重新更新下配置:
```bash
sh reset_alertmanager_config.sh
```