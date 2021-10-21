### 架构图
一个 Kubernetes 集群由一组被称作节点的机器组成。这些节点上运行 Kubernetes 所管理的容器化应用。集群具有至少一个工作节点。

工作节点托管作为应用负载的组件的 Pod 。控制平面管理集群中的工作节点和 Pod 。 为集群提供故障转移和高可用性，这些控制平面一般跨多主机运行，集群跨多个节点运行

![](https://d33wubrfki0l68.cloudfront.net/2475489eaf20163ec0f54ddc1d92aa8d4c87c96b/e7c81/images/docs/components-of-kubernetes.svg)

### 控制平面组件

#### kube-apiserver
API 服务器是 Kubernetes 控制面的组件， 该组件公开了 Kubernetes API。 API 服务器是 Kubernetes 控制面的前端。

Kubernetes API 服务器的主要实现是 kube-apiserver。 kube-apiserver 设计上考虑了水平伸缩，也就是说，它可通过部署多个实例进行伸缩。 你可以运行 kube-apiserver 的多个实例，并在这些实例之间平衡流量。

#### etcd
etcd 是兼具一致性和高可用性的键值数据库，可以作为保存 Kubernetes 所有集群数据的后台数据库。

您的 Kubernetes 集群的 etcd 数据库通常需要有个备份计划。

要了解 etcd 更深层次的信息，请参考 etcd 文档。

#### kube-scheduler
控制平面组件，负责监视新创建的、未指定运行节点（node）的 Pods，选择节点让 Pod 在上面运行。

调度决策考虑的因素包括单个 Pod 和 Pod 集合的资源需求、硬件/软件/策略约束、亲和性和反亲和性规范、数据位置、工作负载间的干扰和最后时限。

#### kube-controller-manager
运行控制器进程的控制平面组件。

从逻辑上讲，每个控制器都是一个单独的进程， 但是为了降低复杂性，它们都被编译到同一个可执行文件，并在一个进程中运行。

这些控制器包括:

- 节点控制器（Node Controller）: 负责在节点出现故障时进行通知和响应
- 任务控制器（Job controller）: 监测代表一次性任务的 Job 对象，然后创建 Pods 来运行这些任务直至完成
- 端点控制器（Endpoints Controller）: 填充端点(Endpoints)对象(即加入 Service 与 Pod)
- 服务帐户和令牌控制器（Service Account & Token Controllers）: 为新的命名空间创建默认帐户和 API 访问令牌

#### cloud-controller-manager
云控制器管理器是指嵌入特定云的控制逻辑的 控制平面组件。 云控制器管理器使得你可以将你的集群连接到云提供商的 API 之上， 并将与该云平台交互的组件同与你的集群交互的组件分离开来。
cloud-controller-manager 仅运行特定于云平台的控制回路。 如果你在自己的环境中运行 Kubernetes，或者在本地计算机中运行学习环境， 所部署的环境中不需要云控制器管理器。

与 kube-controller-manager 类似，cloud-controller-manager 将若干逻辑上独立的 控制回路组合到同一个可执行文件中，供你以同一进程的方式运行。 你可以对其执行水平扩容（运行不止一个副本）以提升性能或者增强容错能力。

下面的控制器都包含对云平台驱动的依赖：

- 节点控制器（Node Controller）: 用于在节点终止响应后检查云提供商以确定节点是否已被删除
- 路由控制器（Route Controller）: 用于在底层云基础架构中设置路由
- 服务控制器（Service Controller）: 用于创建、更新和删除云提供商负载均衡器

### Node 组件

节点组件在每个节点上运行，维护运行的 Pod 并提供 Kubernetes 运行环境。

#### kubelet

一个在集群中每个节点（node）上运行的代理。 它保证容器（containers）都 运行在 Pod 中。

kubelet 接收一组通过各类机制提供给它的 PodSpecs，确保这些 PodSpecs 中描述的容器处于运行状态且健康。 kubelet 不会管理不是由 Kubernetes 创建的容器

#### kube-proxy
kube-proxy 是集群中每个节点上运行的网络代理， 实现 Kubernetes 服务（Service） 概念的一部分。

kube-proxy 维护节点上的网络规则。这些网络规则允许从集群内部或外部的网络会话与 Pod 进行网络通信。

如果操作系统提供了数据包过滤层并可用的话，kube-proxy 会通过它来实现网络规则。否则， kube-proxy 仅转发流量本身。

#### 容器运行时（Container Runtime） 

容器运行环境是负责运行容器的软件。

Kubernetes 支持多个容器运行环境: Docker、 containerd、CRI-O 以及任何实现 Kubernetes CRI (容器运行环境接口)。

#### DNS 
尽管其他插件都并非严格意义上的必需组件，但几乎所有 Kubernetes 集群都应该 有集群 DNS， 因为很多示例都需要 DNS 服务。

集群 DNS 是一个 DNS 服务器，和环境中的其他 DNS 服务器一起工作，它为 Kubernetes 服务提供 DNS 记录。

Kubernetes 启动的容器自动将此 DNS 服务器包含在其 DNS 搜索列表中。

### 节点

Kubernetes 通过将容器放入在节点（Node）上运行的 Pod 中来执行你的工作负载。 节点可以是一个虚拟机或者物理机器，取决于所在的集群配置。 每个节点包含运行 Pods 所需的服务； 这些节点由 控制面 负责管理。

通常集群中会有若干个节点；而在一个学习用或者资源受限的环境中，你的集群中也可能 只有一个节点。

节点上的组件包括 kubelet、 容器运行时以及 kube-proxy

#### 节点状态

一个节点的状态包含以下信息：
- 地址
- 状况
- 容量与分配
- 信息

查看节点信息
```bash
kubectl describe node <节点名称>
```

##### 地址
这些字段的用法取决于你的云服务商或物理机配置
- HostName： 由节点的内核设置。可以通过kubelet的--hostname-override参数覆盖
- ExternalIP： 通常是节点的可外部路由（从集群外部可访问）的IP地址
- InternalIP： 通常是节点的仅可在集群内部路由的IP地址

##### 状况

conditions 字段描述了所有 Running 节点的状态。状况的示例包括：

| 节点状况           | 描述                                                         |
| ------------------ | ------------------------------------------------------------ |
| Ready              | 如节点是健康的并已经准备好接收 Pod 则为 True；False 表示节点不健康而且不能接收 Pod；Unknown 表示节点控制器在最近 node-monitor-grace-period 期间（默认 40 秒）没有收到节点的消息 |
| DiskPressure       | True `表示节点的空闲空间不足以用于添加新 Pod`, 否则为 False  |
| MemoryPressure     | True `表示节点存在内存压力，即节点内存可用量低`，否则为 False |
| PIDPressure        | True` 表示节点存在进程压力，即节点上进程过多；否则为 `False  |
| NetworkUnavailable | True `表示节点网络配置不正确`；否则为 False                  |

##### 容量与可分配
描述节点上的可用资源：CPU、内存和可以调度到节点上的 Pod 的个数上限。

capacity 块中的字段标示节点拥有的资源总量。 allocatable 块指示节点上可供普通 Pod 消耗的资源量。

可以在学习如何在节点上预留计算资源 的时候了解有关容量和可分配资源的更多信息。

##### 节点控制器
节点控制器是 Kubernetes 控制面组件，管理节点的方方面面。

节点控制器在节点的生命周期中扮演多个角色。 第一个是当节点注册时为它分配一个 CIDR 区段（如果启用了 CIDR 分配）。

第二个是保持节点控制器内的节点列表与云服务商所提供的可用机器列表同步。 如果在云环境下运行，只要某节点不健康，节点控制器就会询问云服务是否节点的虚拟机仍可用。 如果不可用，节点控制器会将该节点从它的节点列表删除。

第三个是监控节点的健康情况。节点控制器负责在节点不可达 （即，节点控制器因为某些原因没有收到心跳，例如节点宕机）时， 将节点状态的 NodeReady 状况更新为 "Unknown"。 如果节点接下来持续处于不可达状态，节点控制器将逐出节点上的所有 Pod（使用体面终止）。 默认情况下 40 秒后开始报告 "Unknown"，在那之后 5 分钟开始逐出 Pod。

节点控制器每隔 --node-monitor-period 秒检查每个节点的状态。


### 控制面到节点通信

#### 节点到控制面

Kubernetes 采用的是中心辐射型（Hub-and-Spoke）API 模式。 所有从集群（或所运行的 Pods）发出的 API 调用都终止于 apiserver。 其它控制面组件都没有被设计为可暴露远程服务。 apiserver 被配置为在一个安全的 HTTPS 端口（通常为 443）上监听远程连接请求， 并启用一种或多种形式的客户端身份认证机制。 一种或多种客户端鉴权机制应该被启用， 特别是在允许使用匿名请求 或服务账号令牌的时候。

应该使用集群的公共根证书开通节点，这样它们就能够基于有效的客户端凭据安全地连接 apiserver。 一种好的方法是以客户端证书的形式将客户端凭据提供给 kubelet。 请查看 kubelet TLS 启动引导 以了解如何自动提供 kubelet 客户端证书。

想要连接到 apiserver 的 Pod 可以使用服务账号安全地进行连接。 当 Pod 被实例化时，Kubernetes 自动把公共根证书和一个有效的持有者令牌注入到 Pod 里。 kubernetes 服务（位于 default 名字空间中）配置了一个虚拟 IP 地址，用于（通过 kube-proxy）转发 请求到 apiserver 的 HTTPS 末端。

控制面组件也通过安全端口与集群的 apiserver 通信。

这样，从集群节点和节点上运行的 Pod 到控制面的连接的缺省操作模式即是安全的， 能够在不可信的网络或公网上运行。

#### 控制面到节点

从控制面（apiserver）到节点有两种主要的通信路径。 第一种是从 apiserver 到集群中每个节点上运行的 kubelet 进程。 第二种是从 apiserver 通过它的代理功能连接到任何节点、Pod 或者服务。


##### API 服务器到kubelet

从 apiserver 到 kubelet 的连接用于：

- 获取 Pod 日志
- 挂接（通过 kubectl）到运行中的 Pod
- 提供 kubelet 的端口转发功能。

这些连接终止于 kubelet 的 HTTPS 末端。 默认情况下，apiserver 不检查 kubelet 的服务证书。这使得此类连接容易受到中间人攻击， 在非受信网络或公开网络上运行也是 不安全的。

为了对这个连接进行认证，使用 --kubelet-certificate-authority 标志给 apiserver 提供一个根证书包，用于 kubelet 的服务证书。

如果无法实现这点，又要求避免在非受信网络或公共网络上进行连接，可在 apiserver 和 kubelet 之间使用 SSH 隧道。

最后，应该启用 kubelet 用户认证和/或鉴权 来保护 kubelet API。

##### apiserver到节点、Pod和服务

从 apiserver 到节点、Pod 或服务的连接默认为纯 HTTP 方式，因此既没有认证，也没有加密。 这些连接可通过给 API URL 中的节点、Pod 或服务名称添加前缀 https: 来运行在安全的 HTTPS 连接上。 不过这些连接既不会验证 HTTPS 末端提供的证书，也不会提供客户端证书。 因此，虽然连接是加密的，仍无法提供任何完整性保证。 这些连接 目前还不能安全地 在非受信网络或公共网络上运行。


### 组件工具
#### kube-apiserver

Kubernetes API 服务器验证并配置 API 对象的数据， 这些对象包括 pods、services、replicationcontrollers 等。 API 服务器为 REST 操作提供服务，并为集群的共享状态提供前端， 所有其他组件都通过该前端进行交互。

#### kubelet

kubelet 是在每个 Node 节点上运行的主要 “节点代理”。它可以使用以下之一向 apiserver 注册： 主机名（hostname）；覆盖主机名的参数；某云驱动的特定逻辑。

kubelet 是基于 PodSpec 来工作的。每个 PodSpec 是一个描述 Pod 的 YAML 或 JSON 对象。 kubelet 接受通过各种机制（主要是通过 apiserver）提供的一组 PodSpec，并确保这些 PodSpec 中描述的容器处于运行状态且运行状况良好。 kubelet 不管理不是由 Kubernetes 创建的容器。

除了来自 apiserver 的 PodSpec 之外，还可以通过以下三种方式将容器清单（manifest）提供给 kubelet。

文件（File）：利用命令行参数传递路径。kubelet 周期性地监视此路径下的文件是否有更新。 监视周期默认为 20s，且可通过参数进行配置。

HTTP 端点（HTTP endpoint）：利用命令行参数指定 HTTP 端点。 此端点的监视周期默认为 20 秒，也可以使用参数进行配置。

HTTP 服务器（HTTP server）：kubelet 还可以侦听 HTTP 并响应简单的 API （目前没有完整规范）来提交新的清单。

#### kube-controller-manager

Kubernetes 控制器管理器是一个守护进程，内嵌随 Kubernetes 一起发布的核心控制回路。 在机器人和自动化的应用中，控制回路是一个永不休止的循环，用于调节系统状态。 在 Kubernetes 中，每个控制器是一个控制回路，通过 API 服务器监视集群的共享状态， 并尝试进行更改以将当前状态转为期望状态。 目前，Kubernetes 自带的控制器例子包括副本控制器、节点控制器、命名空间控制器和服务账号控制器等

#### kube-scheduler

调度器通过 kubernetes 的监测（Watch）机制来发现集群中新创建且尚未被调度到 Node 上的 Pod。 调度器会将发现的每一个未调度的 Pod 调度到一个合适的 Node 上来运行。 调度器会依据下文的调度原则来做出调度选择。

kube-scheduler 是 Kubernetes 集群的默认调度器，并且是集群 控制面 的一部分。 如果你真的希望或者有这方面的需求，kube-scheduler 在设计上是允许 你自己写一个调度组件并替换原有的 kube-scheduler。

对每一个新创建的 Pod 或者是未被调度的 Pod，kube-scheduler 会选择一个最优的 Node 去运行这个 Pod。然而，Pod 内的每一个容器对资源都有不同的需求，而且 Pod 本身也有不同的资源需求。因此，Pod 在被调度到 Node 上之前， 根据这些特定的资源调度需求，需要对集群中的 Node 进行一次过滤。

在一个集群中，满足一个 Pod 调度请求的所有 Node 称之为 可调度节点。 如果没有任何一个 Node 能满足 Pod 的资源请求，那么这个 Pod 将一直停留在 未调度状态直到调度器能够找到合适的 Node。

调度器先在集群中找到一个 Pod 的所有可调度节点，然后根据一系列函数对这些可调度节点打分， 选出其中得分最高的 Node 来运行 Pod。之后，调度器将这个调度决定通知给 kube-apiserver，这个过程叫做 绑定。

在做调度决定时需要考虑的因素包括：单独和整体的资源请求、硬件/软件/策略限制、 亲和以及反亲和要求、数据局域性、负载间的干扰等等。

##### kube-scheduler调度流程

kube-scheduler 给一个 pod 做调度选择包含两个步骤：
- 过滤
- 打分
过滤阶段会将所有满足 Pod 调度需求的 Node 选出来。 例如，PodFitsResources 过滤函数会检查候选 Node 的可用资源能否满足 Pod 的资源请求。 在过滤之后，得出一个 Node 列表，里面包含了所有可调度节点；通常情况下， 这个 Node 列表包含不止一个 Node。如果这个列表是空的，代表这个 Pod 不可调度。

在打分阶段，调度器会为 Pod 从所有可调度节点中选取一个最合适的 Node。 根据当前启用的打分规则，调度器会给每一个可调度节点进行打分。

最后，kube-scheduler 会将 Pod 调度到得分最高的 Node 上。 如果存在多个得分最高的 Node，kube-scheduler 会从中随机选取一个。

支持以下两种方式配置调度器的过滤和打分行为：

- 调度策略 允许你配置过滤的 断言(Predicates) 和打分的 优先级(Priorities) 。
- 调度配置 允许你配置实现不同调度阶段的插件， 包括：QueueSort, Filter, Score, Bind, Reserve, Permit 等等。 你也可以配置 kube-scheduler 运行不同的配置文件

#### etcd

