## Prometheus 简介
Prometheus 最初是 SoundCloud 构建的开源系统监控和报警工具，是一个独立的开源项目，于2016年加入了 CNCF 基金会，作为继 Kubernetes 之后的第二个托管项目。
### 特征
Prometheus 相比于其他传统监控工具主要有以下几个特点：

具有由 metric 名称和键/值对标识的时间序列数据的多维数据模型
有一个灵活的查询语言
不依赖分布式存储，只和本地磁盘有关
通过 HTTP 的服务拉取时间序列数据
也支持推送的方式来添加时间序列数据
还支持通过服务发现或静态配置发现目标
多种图形和仪表板支持
### 组件
Prometheus 由多个组件组成，但是其中许多组件是可选的：

Prometheus Server：用于抓取指标、存储时间序列数据
exporter：暴露指标让任务来抓
pushgateway：push 的方式将指标数据推送到该网关
alertmanager：处理报警的报警组件
adhoc：用于数据查询
大多数 Prometheus 组件都是用 Go 编写的，因此很容易构建和部署为静态的二进制文件。
### 架构
下图是 Prometheus 官方提供的架构及其一些相关的生态系统组件：
![20191125153314.png](https://i.loli.net/2019/11/25/FRnrWzNPwm4eyZJ.png)
### prometheus 联邦使用
通过Remote Storage可以分离监控样本采集和数据存储，解决Prometheus的持久化问题。这一部分会重点讨论如何利用联邦集群特性对Promthues进行扩展，以适应不同监控规模的变化

对于大部分监控规模而言，我们只需要在每一个数据中心(例如：EC2可用区，Kubernetes集群)安装一个Prometheus Server实例，就可以在各个数据中心处理上千规模的集群。同时将Prometheus Server部署到不同的数据中心可以避免网络配置的复杂性
![20191125154355.png](https://i.loli.net/2019/11/25/BhjaxmdLnIWOqef.png)

如上图所示，在每个数据中心部署单独的Prometheus Server，用于采集当前数据中心监控数据。并由一个中心的Prometheus Server负责聚合多个数据中心的监控数据。这一特性在Promthues中称为联邦集群。

联邦集群的核心在于每一个Prometheus Server都包含额一个用于获取当前实例中监控样本的接口/federate。对于中心Prometheus Server而言，无论是从其他的Prometheus实例还是Exporter实例中获取数据实际上并没有任何差异

```bash
scrape_configs:
  - job_name: 'federate'
    scrape_interval: 15s
    honor_labels: true
    metrics_path: '/federate'
    params:
      'match[]':
        - '{job="prometheus"}'
        - '{__name__=~"job:.*"}'
        - '{__name__=~"node.*"}'
    static_configs:
      - targets:
        - 'xxxxxxx:9090'
        - 'xxxxxxx:9090'

为了有效的减少不必要的时间序列，通过params参数可以用于指定只获取某些时间序列的样本数据，例如
```bash
"http://192.168.77.11:9090/federate?match[]={job%3D"prometheus"}&match[]={__name__%3D~"job%3A.*"}&match[]={__name__%3D~"node.*"}"
```
通过URL中的match[]参数指定我们可以指定需要获取的时间序列。match[]参数必须是一个瞬时向量选择器，例如up或者{job="api-server"}。配置多个match[]参数，用于获取多组时间序列的监控数据。

horbor_labels配置true可以确保当采集到的监控指标冲突时，能够自动忽略冲突的监控数据。如果为false时，prometheus会自动将冲突的标签替换为”exported_“的形式