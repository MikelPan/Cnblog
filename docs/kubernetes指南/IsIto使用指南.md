
## 安装

### 下载并安装isito

#### 下载isito
```bash
# 下载isito
curl -L https://istio.io/downloadIstio | sh -
# 加入环境变量
export PATH=$PWD/bin:$PATH
```

#### 安装isito

1、为 Istio 组件，创建命名空间 istio-system :
```bash
kubectl create namespace istio-system
```

2、安装 Istio base chart，它包含了 Istio 控制平面用到的集群范围的资源：
```bash
helm upgrade --install istio-base manifests/charts/base -n istio-system --debug 
```

3、安装 Istio discovery chart，它用于部署 istiod 服务：
```bash
helm upgrade --install istiod manifests/charts/istio-control/istio-discovery \
    --set global.hub="docker.io/istio" \
    --set global.tag="1.10.1" \
    -n istio-system --debug
```

4、(可选项) 安装 Istio 的入站网关 chart，它包含入站网关组件：
```bash
helm upgrade --install istio-ingress manifests/charts/gateways/istio-ingress \
    --set global.hub="docker.io/istio" \
    --set global.tag="1.10.1" \
    -n istio-system --debug
```

5、(可选项) 安装 Istio 的出站网关 chart，它包含了出站网关组件：
```bash
helm upgrade --install istio-egress manifests/charts/gateways/istio-egress \
    --set global.hub="docker.io/istio" \
    --set global.tag="1.10.1" \
    -n istio-system --debug
```

6、 确认命名空间 istio-system 中所有 Kubernetes pods 均已部署，且返回值中 STATUS 的值为 Running：
```bash
kubectl get pods -n istio-system
```

#### 卸载

卸载前面安装的 chart，以便卸载 Istio 和它的各个组件

1、列出在命名空间 istio-system 中安装的所有 Istio chart：
```bash
 
```

2、(可选项) 删除 Istio 安装的 CRD
```bash
kubectl get crd | grep --color=never 'istio.io' | awk '{print $1}' \
    | xargs -n1 kubectl delete crd
```

## 功能

### 流量管理

#### 配置请求路由

## 维护

### 架构