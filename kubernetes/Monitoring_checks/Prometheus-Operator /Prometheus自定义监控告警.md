### Prometheus Operator 配置告警规则ator

在Prometheus Operator中,默认就添加了一部分规则,配置文件如下:
```bash
cat prometheus-rules.yaml | head -n 20
```
对应的yaml 配置文件
```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  labels:
    prometheus: k8s
    role: alert-rules
  name: prometheus-k8s-rules
  namespace: monitoring
spec:
  groups:
  - name: node-exporter.rules
    rules:
    - expr: |
        count without (cpu) (
          count without (mode) (
            node_cpu_seconds_total{job="node-exporter"}
          )
        )
      record: instance:node_num_cpu:sum
    - expr: |
```

默认需要添加两个labels,prometheus和role,kind类型为PrometheusRule,下面针对自定义的监控项配置自定义告警规则配置文件：
```yaml
cat > prometheus-Customrules.yaml <<EOF
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  labels:
    prometheus: k8s
    role: alert-rules
  name: prometheus-custom-rules
  namespace: monitoring
spec:
  groups:
  - name: physical-node
    rules:
    - alert: KubeMasterDown
      annotations:
        message: "{{ $labels.env }} 环境中的k8s集群 master节点　{{ $labels.instance}} 节点已经故障了,请联系管理员处理。"
      expr: |
        probe_success{group=~"pre.*cent.*master.*"} == 0
      for: 1m
      labels:
        severity: critical
    - alert: kubeNodeDown
      annotations:
        message: "{{ $labels.env }} 环境中的k8s集群 node节点　{{ $labels.instance}} 节点已经故障了,请联系管理员处理。"
      expr: |
        probe_success{group=~"pre.*cent.*master.*"} == 0
      for: 1m
    - alert: AliYunMongodbMasterDown
      annotations:
        message: "{{ $labels.env }} 环境中使用的阿里云Mongodb master节点　{{ $labels.instance}} 已经无法连接了,请联系管理员处理。"
      expr: |
        probe_success{group=~".*mongo.*",status="slave"} == 0
      for: 1m
      labels:
        severity: critical
    - alert: AliYunMongodbNodeDown
      annotations:
        message: "{{ $labels.env }} 环境中使用的阿里云Mongodb master节点　{{ $labels.instance}} 已经无法连接了,请联系管理员处理。"
      expr: |
        probe_success{group=~".*mongo.*",status="slave"} == 0
      for: 1m
      labels:
        severity: critical
    - alert: AliYunPsqlDown
      annotations:
        message: "{{ $labels.env }} 环境中使用的阿里云Psql数据库　{{ $labels.instance}} 已经无法连接了,请联系管理员处理。"
      expr: |
        probe_success{group=~".*psql.*"} == 0
      for: 1m
      labels:
        severity: critical
    - alert: QinYunAMQPDown
      annotations:
        message: "{{ $labels.env }} 环境中使用的青云的AMQP消息队列　{{ $labels.instance}} 已经无法连接了,请联系管理员处理。"
      expr: |
        probe_success{group=~".*amqp.*"} == 0
      for: 1m
      labels:
        severity: critical
  - name: kubernetes-Busness-service
    rules:
    - alert: ProjectPHPServiceDown
      annotations:
        message: "{{ $labels.env }} 环境中的 {{ $labels.instance }} 服务异常, 请联系管理员"
      expr: |
        probe_http_status_code{instance=~".*80",env="pre-cent",instance!~".*account.*|.*ingress.*|.*knowledge.*"} == 0
      for: 1m
      labels:
        severity: critical
    - alert: ProjectWebServiceDown
      anotations:
        message: "{{ $label.env }} 环境中的 {{ $labels.instance }} 服务异常, 请联系管理员"
      expr: |
        probe_http_status_code{env="pre-cent",instance!~".*80",instance=~".*console.*|.*knowledge.*|.*account-system-web.*"} == 0
      for: 1m
      labels:
        severity: critical
    - alert: ProjectGoServiceDown
      anotations:
        message: "{{ $label.env }} 环境中的 {{ $labels.instance }} 服务异常, 请联系管理员"
      expr: |
        probe_http_status_code{instance=~".*console.*|.*knowledge.*"} == 0
      for: 1m
      labels:
        severity: critical
  - name: Domain-Front
    rules:
    - alert: ProjectWebDomainDown
      anotations:
        message: "{{ $label.env }} 环境中的前端访问域名({{ $labels.instance }}) 访问异常,请联系管理员"
      expr: |
        probe_http_status_code{group=~".*前端页面.*"} != 200
      for: 5m
      labels:
        severity: critical
  - name: Domain-Ｂackend
    rules:
    - alert: ProjectBackendDomainDown
      anotations:
        message: "{{ $label.env }} 环境中的后端服务请求域名({{ $labels.instance }}) 访问异常,请联系管理员"
      expr: |
        probe_http_status_code{group=~".*后端.*"} !=200
      for: 1m
      labels:
        severity: critical
  - name: Domain-Backend-AuthService
    rules:
    - alert: ProjectBackendDistAuthServiceDomainDown
      anotations:
        message: "{{ $label.env }} 环境中的后端鉴权服务请求域名({{ $labels.instance }}) 访问异常,请联系管理员"
      expr: |
         probe_http_status_code{instance=~"https.*",instance=~".*ingress-auth-service.*"} == 0
      for: 5m
      labels:
        severity: critical
  - name: Service-Dist
    rules:
    - alert: ServiceDistMemberPHP
      anotations:
        message: "{{ $label.env }} 环境中的svc({{ $labels.instance }}) 访问异常,请联系管理员"
      expr: |
        probe_http_status_code{sname=~"member.*",instance!~".*gateway.*|.*points.*"} == 0
      for: 5m
      labels:
        severity: critical
    - alert: ServiceMemberGO
      anotations:
        message: "{{ $label.env }} 环境中的svc({{ $labels.instance }}) 访问异常,请联系管理员"
      expr: |
        probe_http_status_code{sname=~"member-api-gateway.*",instance=~".*8000"} == 0
      for: 5m
      labels:
        severity: critical
    - alert: ServiceDistPointsCore
      anotations:
        message: "{{ $label.env }} 环境中的svc({{ $labels.instance }}) 访问异常,请联系管理员"
      expr: |
        probe_http_status_code{sname=~"points.*",instance!~".*points-offer.*"} == 0
      for: 5m
      labels:
        severity: critical
    - alert: ServiceDistPointsOffer
      anotations:
        message: "{{ $label.env }} 环境中的svc({{ $labels.instance }}) 访问异常,请联系管理员"
      expr: |
        probe_success{sname=~".*points-offer.*",instance=~".*9501"} == 0
    - alert: ServiceCentPHP
      anotations:
        message: "{{ $label.env }} 环境中的svc({{ $labels.instance }}) 访问异常,请联系管理员"
      expr: |
        probe_http_status_code{instance=~".*80",kubernetes_namespace="dadi-saas-member-pre",name=~".*service.*|.*system.*",name!~".*ingress.*|.*center.*"}
      for: 5m
      labels:
        severity: critical
    - alert: ServiceDistGo
      anotations:
        message: "{{ $label.env }} 环境中的svc({{ $labels.instance }}) 访问异常,请联系管理员"
      expr: |
        probe_http_status_code{env!~".*cent.*",instance=~".*ingress.*|.*zone.*",instance!~".*https.*"} == 0
      for: 5m
      labels:
        severity: critical
  - name: Service-Cent
    rules:
    - alert: ServiceCentGo
      anotations:
        message: "{{ $label.env }} 环境中的svc({{ $labels.instance }}) 访问异常,请联系管理员"
      expr: |
        probe_http_status_code{env="pre-cent",instance=~".*80",kubernetes_namespace="dadi-saas-member-pre",name=~".*ingress.*|.*center.*"}
      for: 5m
      labels:
        severity: critical
  - name: TraefikService
    rules:
    - alert: TraefikService404
      anotations:
        message: "{{ $label.env }} 环境中５分钟之内的访问请求出现404的占比已经达到%{{ $value }}了,请联系管理员"
      expr: |
        (sum(traefik_entrypoint_requests_total{protocol=~"http|https",code="404"}- (traefik_entrypoint_requests_total{protocol=~"http|https",code="404"} offset 5m)) / sum(traefik_entrypoint_requests_total-(traefik_entrypoint_requests_total offset 5m)) ) * 100 > 30
      for: 5m
      labels:
        severity: critical
    - alert: TraefikService403
      anotations:
        message: "{{ $label.env }} 环境中５分钟之内的访问请求出现403的占已经达到%{{ $value }}了,请联系管理员"
      expr: |
        (sum(traefik_entrypoint_requests_total{protocol=~"http|https",code="403"}- (traefik_entrypoint_requests_total{protocol=~"http|https",code="403"} offset 5m)) / sum(traefik_entrypoint_requests_total-(traefik_entrypoint_requests_total offset 5m)) ) * 100 > 10
      for: 5m
      labels:
        severity: critical
    - alert: TraefikService5XX
      anotations:
        message: "{{ $label.env }} 环境中５分钟之内的访问请求出现5XX的占已经达到%{{ $value }}了,请联系管理员"
      expr: |
        (sum(traefik_entrypoint_requests_total{protocol=~"http|https",code=~"5.*"}- (traefik_entrypoint_requests_total{protocol=~"http|https",code=~"5.*"} offset 5m)) / sum(traefik_entrypoint_requests_total-(traefik_entrypoint_requests_total offset 5m)) ) * 100 > 5
      for: 5m
      labels:
        severity: critical
    - alert: TraefikService5XX
      anotations:
        message: "{{ $label.env }} 环境中后端服务{{ $label.service }}的访问请求中状态码为5XX,请联系管理员"
      expr: |
        traefik_service_requests_total{group="pre-cent",code=~"5.*"} 
      for: 5m
      labels:
        severity: critical
  - name: KubePodStatus
    rules:
    - alert: KUbePodRestartNumber
      anotations:
        message: "{{ $label.group }} 环境中的Pod{{ $label.pod }}五分钟之内已经重启{{ $value }}了,请联系管理员"
      expr: |
        kube_pod_container_status_restarts_total- (kube_pod_container_status_restarts_total offset 5m) > 10
      for: 5m
      labels:
        severity: critical
    - alert: KubePodRestartNumber
      anotations:
        message: "{{ $label.group }} 环境中的Pod{{ $label.pod }}运行至今已经重启{{ $value }}了,请联系管理员"
      expr: |
        kube_pod_container_status_restarts_total > 100
      for: 5m
      labels:
        severity: critical
EOF
``












