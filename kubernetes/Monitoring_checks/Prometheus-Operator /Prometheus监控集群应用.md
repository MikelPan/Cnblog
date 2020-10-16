##### Traefik Service 设置标签
Prometheus Operator 是通过 Label 匹配的，需要提前设置 Service 贴上"k8s-app: traefik-ingress"标签
```yaml
apiVersion: v1
kind: Service
metadata:
  namespace: kube-system
  name: traefik
  labels:
    k8s-app: traefik-ingress
spec:
  ports:
    - protocol: TCP
      name: web
      port: 80
    - protocol: TCP
      name: admin
      port: 8080
    - protocol: TCP
      name: websecure
      port: 443
  selector:
    app: traefik
```
##### 添加监控traefik
创建 ServiceMonitor 对象（prometheus-serviceMonitorTraefik.yaml）
```yaml
cat > prometheus-serviceMonitorTraefik.yaml <<EOF
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: traefik-ingress
  namespace: monitoring
  labels:
    k8s-app: traefik-ingress
spec:
  jobLabel: k8s-app
  endpoints:
  - port: admin              #---设置为traefik 8080端口名称 admin
    interval: 30s
  selector:
    matchLabels:
      k8s-app: traefik-ingress
  namespaceSelector:
    matchNames:
    - kube-system
EOF
```