## kubernetes operator使用
### Operator 简介
Kubernetes 作为领先的容器编排项目之所以如此成功，其中一个原因就在于其可扩展性。借助自定义资源，开发者可以扩展 Kubernetes API 以管理超出原生对象范围外的资源（例如，pod 和服务）。此外，Kubernetes Go Client 提供了强大的资源库，用于为自定义资源编写控制器。控制器实施闭环控制逻辑，通过持续运行对资源的期望状态与所观测到的状态进行协调。

Operator 将特定于应用程序的控制器与相关自定义资源组合在一起，编撰特定领域的知识，用于管理资源生命周期。第一组 Operator 起初聚焦于 Kubernetes 中运行的有状态服务，但近年来，Operator 的范围越来越广泛，如今社区为各种广泛用例构建的 Operator 数量正与日俱增。例如，OperatorHub.io 提供了一个社区 Operator 目录，用于处理各种不同种类的软件和服务。

Operator 的吸引力如此之大，原因有多种。如果您已在使用 Kubernetes 来部署和管理应用程序或更大的解决方案，Operator 可提供一致的资源模型来定义和管理应用程序中的所有不同组件。例如，如果应用程序需要 etcd 数据库，那么只需安装 etcd Operator 并创建 EtcdCluster 自定义资源即可。etcd Operator 随后就会负责为应用程序部署和管理 etcd 集群，包括次日操作，如备份和复原。由于 Operator 依赖于自定义资源，即 Kubernetes API 扩展，因此默认情况下，Kubernetes 的所有现有工具都适用。无需学习新工具或新方法。您可以使用同样的 Kubernetes CLI (kubectl) 来创建、更新或删除 Pod 和自定义资源。对于自定义资源来说，基于角色的访问控制 (RBAC) 和准入控制的工作方式是相同的。

那么集群外部的应用程序组件情况又如何呢？Operator 在这方面同样可以提供帮助。例如，假设您正在编写需要语言翻译的应用程序。您可以使用基于云的服务，例如，Watson Language Translator。要使用此服务，您就需要使用 IBM Cloud 目录或命令行界面并从中配置此服务，然后创建服务凭证，并将凭证复制到可供 pod 轻松访问的 Kubernetes 密钥中。通常，此过程中涉及若干手动步骤，但 Operator 可以自动执行这些步骤。

借助 Operator，您可以像在 Kubernetes 中创建任何其他资源一样来创建翻译程序服务的实例。无需采用超出范围的步骤或脚本来创建外部资源。只需通过一组 Kubernetes 模板来描述自己的应用程序（包括外部依赖项），并直接通过 kubectl apply 部署整个应用程序和依赖项即可。

此外，由于 Operator 可持续将期望状态与当前状态进行比较并加以协调，因此 Operator 可提供自我修复功能，并确保重新启动服务（如果服务不正常或遭意外删除，则可重新创建）

### OLM 安装

#### 在集群中安装 OLM 的最新发行版
```shell
# 安装OLM
kubectl apply -f https://github.com/operator-framework/operator-lifecycle-manager/releases/download/0.15.1/crds.yaml
kubectl apply -f https://github.com/operator-framework/operator-lifecycle-manager/releases/download/0.15.1/olm.yaml
# 安装OLM ui
./scripts/run_console_local.sh
```
#### 安装 Marketplace Operator
```shell
# 克隆项目
git clone https://github.com/operator-framework/operator-marketplace.git
# 安装
kubectl apply -f operator-marketplace/deploy/upstream/
```
#### 配置 Marketplace Operator 名称空间
```shell
kubectl apply -f - <<EOF
apiVersion: operators.coreos.com/v1alpha2
kind: OperatorGroup
metadata:
  name: marketplace-operators
  namespace: marketplace
EOF
```

