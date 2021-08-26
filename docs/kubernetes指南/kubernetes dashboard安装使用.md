### helm 安装kubernetes-dashboard
#### 拉取 kubernetes-dashboard chart
```bash
# 拉取chart
helm pull kubernetes-dashboard/kubernetes-dashboard
# 修改values
# 添加ingressroute.yaml 文件
{{- if .Values.ingressRoute.enabled -}}
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: {{ .Release.Name }}
  annotations:
    helm.sh/hook: "post-install,post-upgrade"
    {{- with .Values.ingressRoute.annotations }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  labels:
    app.kubernetes.io/name: {{ template "kubernetes-dashboard.name" . }}
    helm.sh/chart: {{ template "kubernetes-dashboard.chart" . }}
    app.kubernetes.io/managed-by: {{ .Release.Service }}
    app.kubernetes.io/instance: {{ .Release.Name }}
    {{- with .Values.ingressRoute.labels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
spec:
  entryPoints:
    - websecure
  tls:
    - secretName: {{ template "kubernetes-dashboard.fullname" . }}-certs
  routes:
  #- match: Host(`cent-pre.kpmember.cn`) && PathPrefix(`/`)
  - match: Host(`kubernetes-dashboard.com`) && PathPrefix(`/`)
    # middlewares:
    # - name: replace-path-regex-mid
    kind: Rule
    services:
    - name: {{ .Release.Name }}
    {{- with .Values.ingressRoute.ports }}
    {{- toYaml . | nindent 6 }}
    {{- end }}
{{- end -}}

```
#### 创建自定义证书
```bash
## 生成tls证书
# 生成证书
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout /tmp/tls.key -out /tmp/tls.crt -subj "/CN=192.168.0.1"
# 生成secret
kubelet delete secret kubernetes-dashboard-certs -n kube-system
kubectl -n kube-system  create secret tls kubernetes-dashboard-secret --key tls.key --cert tls.crt
## 生成generic证书
#生成证书
openssl genrsa -out kubernetes-dashboard-test.01member.com.key 2048 
openssl req -new -out kubernetes-dashboard-test.01member.com.csr -key kubernetes-dashboard-test.01member.com.key -subj '/CN=kubernetes-dashboard-test.01member.com'
openssl x509 -req -in kubernetes-dashboard-test.01member.com.csr -signkey kubernetes-dashboard-test.01member.com.key -out kubernetes-dashboard-test.01member.com.crt
# 生成secret
kubectl delete secret kubernetes-dashboard-certs -n kube-system
kubectl create secret generic kubernetes-dashboard-certs --from-file=/root/.ssl/certs/kubernetes-dashboard-test.01member.com.key --from-file=/root/.ssl/certs/kubernetes-dashboard-test.01member.com.crt -n kube-system
```
#### 创建授权对象
```bash
# 创建serviceaccount.yaml
# 创建role.yaml
# 创建rolebinding.yaml
# 创建clusterrole.yaml
# 创建clusterbinding.yaml
```