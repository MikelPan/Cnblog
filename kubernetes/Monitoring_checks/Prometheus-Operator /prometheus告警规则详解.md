## prometheus　告警规则详解

### 告警指标定义
- node
- k8s集群组件
- traefik
- k8s组件资源
- 网络探测
- 请求svc 

### Prometheus PromQL查询
Prometheus除了存储数据外，还提供了一种强大的功能表达式语言 PromQL，允许用户实时选择和汇聚时间序列数据。

表达式的结果可以在浏览器中显示为图形，也可以显示为表格数据，或者由外部系统通过 HTTP API 调用。通过PromQL用户可以非常方便地查询监控数据，或者利用表达式进行告警配置.

#### Metric类型
Prometheus会将所有采集到的样本数据以时间序列（time-series）的方式保存在内存数据库TSDB中，并且定时保存到硬盘上。time-series是按照时间戳和值的序列顺序存放的，我们称之为向量(vector)。每条time-series通过指标名称(metrics name)和一组标签集(labelset)命名。

在time-series中的每一个点称为一个样本（sample），样本由以下三部分组成：

指标(metric)：metric name和描述当前样本特征的labelsets;
时间戳(timestamp)：一个精确到毫秒的时间戳;
样本值(value)： 一个folat64的浮点型数据表示当前样本的值。

Prometheus定义了4中不同的指标类型(metric type):
- Counter 计数器
```bash
计数器，只增不减，如http_requests_total请求总数

例如，通过rate()函数获取HTTP请求量的增长率：
rate(http_requests_total[5m])
```
- Gauge 仪表盘
```bash
当前状态，可增可减。如kube_pod_status_ready当前pod可用数
可以获取样本在一段时间返回内的变化情况,如：
delta(kube_pod_status_ready[2h])
```
- Histogram 直方图
```bash
Histogram 由 <basename>_bucket{le="<upper inclusive bound>"}，<basename>_bucket{le="+Inf"}, <basename>_sum，<basename>_count 组成，主要用于表示一段时间范围内对数据进行采样（通常是请求持续时间或响应大小），并能够对其指定区间以及总数进行统计，通常它采集的数据展示为直方图。

例如 Prometheus server 中 prometheus_local_storage_series_chunks_persisted, 表示 Prometheus 中每个时序需要存储的 chunks 数量，我们可以用它计算待持久化的数据的分位数。
```
- Summary 摘要
```bash
Summary 和 Histogram 类似，由 <basename>{quantile="<φ>"}，<basename>_sum，<basename>_count 组成，主要用于表示一段时间内数据采样结果（通常是请求持续时间或响应大小），它直接存储了 quantile 数据，而不是根据统计区间计算出来的。

例如 Prometheus server 中 prometheus_target_interval_length_seconds。

Histogram 需要通过 <basename>_bucket 计算 quantile, 而 Summary 直接存储了 quantile 的值。
```

#### 基础查询
PromQL是Prometheus内置的数据查询语言，其提供对时间序列数据丰富的查询，聚合以及逻辑运算能力的支持.

你可以通过附加一组标签，并用{}括起来，来进一步筛选这些时间序列。下面这个例子只选择有http_requests_total名称的、有prometheus工作标签的、有canary组标签的时间序列：
```bash
http_requests_total{job="prometheus",group="canary"}
```
如果条件为空，可以写为：http_requests_total{}
```bash
  =：选择正好相等的字符串标签
  !=：选择不相等的字符串标签
  =~：选择匹配正则表达式的标签（或子标签）
  !=：选择不匹配正则表达式的标签（或子标签）
```
#### 范围查询
类似http_requests_total{job="prometheus",group="canary"}的方式，得到的是瞬时值，如果想得到一定范围内的值，可以使用范围查询

时间范围通过时间范围选择器[]进行定义。例如，通过以下表达式可以选择最近5分钟内的所有样本数据，如：http_request_total{}[5m]

除了分钟，支持的单位有：
- s-秒
- ｍ-分钟
- h-小时
- d-天
- w-周
- y-年

#### 偏移查询
如：查询http_requests_total在当前时刻的一周的速率：
```bash
rate(http_requests_total{} offset 1w)
```
请注意，偏移量修饰符始终需要跟随选择器:
```bash
sum(http_requests_total{method="GET"} offset 5m)
```
#### 操作符
Prometheus 查询语句中，支持常见的各种表达式操作符，例如

*算术运算符:*
支持的算术运算符有 +，-，*，/，%，^, 例如 http_requests_total * 2 表示将 http_requests_total 所有数据 double 一倍

*比较运算符:*
支持的比较运算符有 ==，!=，>，<，>=，<=, 例如 http_requests_total > 100 表示 http_requests_total 结果中大于 100 的数据。

*逻辑运算符:*
支持的逻辑运算符有 and，or，unless, 例如 http_requests_total == 5 or http_requests_total == 2 表示 http_requests_total 结果中等于 5 或者 2 的数据

*聚合运算符:*
支持的聚合运算符有 sum，min，max，avg，stddev，stdvar，count，count_values，bottomk，topk，quantile，, 例如 max(http_requests_total) 表示 http_requests_total 结果中最大的数据。
sum (求和)
min (最小值)
max (最大值)
avg (平均值)
stddev (标准差)
stdvar (标准差异)
count (计数)
count_values (对 value 进行计数)
bottomk (样本值最小的 k 个元素)
topk (样本值最大的k个元素)
quantile (分布统计)

这些操作符被用于聚合所有标签维度，或者通过 without 或者 by 子语句来保留不同的维度
- without 用于从计算结果中移除列举的标签，而保留其它标签。
- by 则正好相反，结果向量中只保留列出的标签，其余标签则移除

注意，和四则运算类型，Prometheus 的运算符也有优先级，它们遵从（^）> (*, /, %) > (+, -) > (==, !=, <=, <, >=, >) > (and, unless) > (or) 的原则

*优先级*
四则运算有优先级，promql的复杂运算也有优先级
例如，查询主机的CPU使用率，可以使用表达式：
```bash
100 * (1 - avg (irate(node_cpu{mode='idle'}[5m])) by(job) )
```
其中irate是PromQL中的内置函数，用于计算区间向量中时间序列每秒的即时增长率
在PromQL操作符中优先级由高到低依次为：
```bash
^
*, /, %
+, -
==, !=, <=, <, >=, >
and, unless
or
```
#### 内置函数
Prometheus 提供了其它大量的内置函数，可以对时序数据进行丰富的处理
```bash
100 * (1 - avg (irate(node_cpu{mode='idle'}[5m])) by(job) )
```
两分钟内的平均CPU使用率：
rate(node_cpu[2m])
irate(node_cpu[2m])

irate同样用于计算区间向量的计算率，但是其反应出的是瞬时增长率.
irate函数相比于rate函数提供了更高的灵敏度，不过当需要分析长期趋势或者在告警规则中，irate的这种灵敏度反而容易造成干扰.
因此在长期趋势分析或者告警中更推荐使用rate函数.
完整的函数列表为：
```bash
abs()
// abs(v instant-vector) 返回所有样本值均转换为绝对值的输入向量
absent()
// absent(v instant-vector) 如果传递给它的向量有任何元素，则返回一个空向量；如果传递给它的向量没有元素，则返回值为1的1元素向量
ceil()
// ceil(v instant-vector) 是一个向上舍入为最接近的整数
changes()
// 对于每个输入时间序列，changes(v range-vector)返回其值在提供的时间范围内变化的次数作为即时向量
clamp_max()
// clamp_max(v instant-vector, max scalar)将所有元素的样本值钳位为的v上限max
clamp_min()
// clamp_min(v instant-vector, min scalar)将所有元素的样本值钳位为v下限min
day_of_month()
// day_of_month(v=vector(time()) instant-vector)返回UTC中给定时间的每个月的一天。返回值是1到31
day_of_week()
// day_of_week(v=vector(time()) instant-vector)返回UTC中每个给定时间的星期几。返回的值是从0到6，其中0表示星期日等
days_in_month()
// days_in_month(v=vector(time()) instant-vector)返回UTC中每个给定时间的月份中的天数。返回值是28到31
delta()
// delta(v range-vector)计算范围向量中每个时间序列元素的第一个值与最后一个值之间的差v，并返回具有给定增量和等效标签的即时向量。根据范围向量选择器中的指定，可以将增量外推以覆盖整个时间范围，因此即使采样值都是整数，也可以获得非整数结果.
deriv()
// deriv(v range-vector)v使用简单的线性回归来计算范围向量中时间序列的每秒导数
exp()
// exp(v instant-vector)计算中的所有元素的指数函数v。特殊情况是
- Exp(+Inf) = +Inf
- Exp(NaN) = NaN
floor()
// floor(v instant-vector)将所有元素的样本值四舍五入v到最接近的整数
histogram_quantile()
// histogram_quantile(φ float, b instant-vector)计算φ -分位数（0≤φ≤1）从桶b一个的 直方图。（有关φ分位数的详细说明以及通常使用直方图度量类型的信息，请参见 直方图和摘要。）中的样本b是每个存储桶中观察值的计数。每个样本必须有一个标签le，其中标签值表示存储桶的包含上限。（不带标签的样本将被忽略。）直方图度量标准类型会 自动提供带有_bucket后缀和适当标签的时间序列
holt_winters()
// holt_winters(v range-vector, sf scalar, tf scalar)根据中的范围为时间序列生成平滑值v。平滑因子越低sf，对旧数据的重视程度越高。趋势因子越高tf，考虑的数据趋势就越多。二者sf并tf必须在0和1之间
hour()
// hour(v=vector(time()) instant-vector)返回UTC中每个给定时间的一天中的小时。返回值是从0到23
idelta()
// idelta(v range-vector)计算范围向量中最后两个样本之间的差v，并返回具有给定增量和等效标签的即时向量
increase()
// increase(v range-vector)计算范围向量中时间序列的增加。单调性中断（例如由于目标重启而导致的计数器重置）会自动调整。根据范围向量选择器中的指定，可以推断出增加的时间范围，以覆盖整个时间范围，因此即使计数器仅以整数增量增加，也可以获得非整数结果
irate()
// irate(v range-vector)计算范围向量中时间序列的每秒瞬时增加率。这基于最后两个数据点。单调性中断（例如由于目标重启而导致的计数器重置）会自动调整
label_join()
// 对于中的每个时间序列v，label_join(v instant-vector, dst_label string, separator string, src_label_1 string, src_label_2 string, ...)将所有src_labels using 的所有值结合separator在一起，并返回带有dst_label包含结合值的标签的时间序列。src_labels此功能可以有任意多个
label_replace()
// 对于其中的每个时间序列v，label_replace(v instant-vector, dst_label string, replacement string, src_label string, regex string)将正则表达式regex与标签匹配src_label。如果匹配，则返回时间序列，并dst_label用的扩展名替换 标签replacement。$1用第一个匹配的子组替换，$2再用第二个匹配的子组替换。如果正则表达式不匹配，则时间序列不变
ln()
// ln(v instant-vector)计算中所有元素的自然对数v。特殊情况是
- ln(+Inf) = +Inf
- ln(0) = -Inf
- ln(x < 0) = NaN
- ln(NaN) = NaN
log2()
log10()
minute()
month()
predict_linear()
rate()
resets()
round()
scalar()
sort()
sort_desc()
sqrt()
time()
timestamp()
vector()
year()
<aggregation>_over_time()
```


### 监控项说明
#### CPUThrottlingHigh
expr如下：
```bash
100
  * sum by(container_name, pod_name, namespace) (increase(container_cpu_cfs_throttled_periods_total{container_name!=""}[5m]))
  / sum by(container_name, pod_name, namespace) (increase(container_cpu_cfs_periods_total[5m]))
  > 25
```
这个表达式的作用是查出最近5分钟，超过25%的CPU执行周期受到限制的container，这里用到了来自kubelet的两个重要指标：
- container_cpu_cfs_periods_total：container生命周期中度过的cpu周期总数
- container_cpu_cfs_throttled_periods_total：container生命周期中度过的受限的cpu周期总数

 #### 

 
  