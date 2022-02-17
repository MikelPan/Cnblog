### loki简介

`Loki`是 Grafana Labs 团队最新的开源项目，是一个水平可扩展，高可用性，多租户的日志聚合系统。它的设计非常经济高效且易于操作，因为它不会为日志内容编制索引，而是为每个日志流编制一组标签。项目受 Prometheus 启发，官方的介绍就是：`Like Prometheus, but for logs.`，类似于 Prometheus 的日志系统。

与其他日志聚合系统相比，`Loki`具有下面的一些特性：

- 不对日志进行全文索引。通过存储压缩非结构化日志和仅索引元数据，Loki 操作起来会更简单，更省成本。
- 通过使用与 Prometheus 相同的标签记录流对日志进行索引和分组，这使得日志的扩展和操作效率更高。
- 特别适合储存 Kubernetes Pod 日志; 诸如 Pod 标签之类的元数据会被自动删除和编入索引。
- 受 Grafana 原生支持。

Loki 由以下3个部分组成：

- `loki`是主服务器，负责存储日志和处理查询。
- `promtail`是代理，负责收集日志并将其发送给 loki 。
- `Grafana`用于 UI 展示

### Loki 使用

切换到 grafana 左侧区域的`Explore`，即可进入到`Loki`的页面：

![image-20210901174447130](/Users/admin/Library/Application Support/typora-user-images/image-20210901174447130.png)

![image-20210901174515962](/Users/admin/Library/Application Support/typora-user-images/image-20210901174515962.png)

然后点击`Log labels`就可以把当前系统采集的日志标签给显示出来，可以根据这些标签进行日志的过滤查询

![image-20210901174649893](/Users/admin/Library/Application Support/typora-user-images/image-20210901174649893.png)

### Loki语法说明

#### 选择器

对于查询表达式的标签部分，将其包装在花括号中`{}`，然后使用键值对的语法来选择标签，多个标签表达式用逗号分隔，比如

- |=：日志行包含字符串。
- !=：日志行不包含字符串。
- |~：日志行匹配正则表达式。
- !~：日志行与正则表达式不匹配

精确匹配：|="2020-11-16 "

```bash
{app_kubernetes_io_instance="x'x'x'x"}|="2020-11-16 "
```

模糊匹配：|~"2020-11-16 "

```bash
{app_kubernetes_io_instance="x'x'x'x'x"}|~"2020-11-16 "
```

排除过滤：!=/!~ "数据中心"

```bash
{app_kubernetes_io_instance="x'x'x'x'x"}!="数据中心"
{app_kubernetes_io_instance="x'x'x'x'x'x'x'x'x"}!~"数据中心"
```

正则匹配： |~ "()"

```bash
{app_kubernetes_io_instance="x'x'x'x'x'x"}!~"(admin|web)"
{app_kubernetes_io_instance="x'x'x'x'x'x'x"}|~"ERROR|error"
```

### Loki错误信息查看

先通过表达式查询出有错误的日志

![image-20210901174826788](/Users/admin/Library/Application Support/typora-user-images/image-20210901174826788.png)



再根据上下文查看异常堆栈信息

![image-20210901174918169](/Users/admin/Library/Application Support/typora-user-images/image-20210901174918169.png)

异常信息如下

![image-20210901174857688](/Users/admin/Library/Application Support/typora-user-images/image-20210901174857688.png)

如果行数不够，可以点击Load 10 more，点击一次将会增加10行，左边将会显示Found 20 rows

历史查询使用，选择历史查询记录，查询，默认保留7天查询记录

![image-20210901174958074](/Users/admin/Library/Application Support/typora-user-images/image-20210901174958074.png)



分屏功能使用，根据不同标签选择器查询不同的日志

![image-20210901175019754](/Users/admin/Library/Application Support/typora-user-images/image-20210901175019754.png)



根据标签选择器，自动刷新日志

![image-20210901175046395](/Users/admin/Library/Application Support/typora-user-images/image-20210901175046395.png)



#### 范围查询

- rate：计算每秒的条目数
- count_over_time：计算给定范围内每个日志流的条目

```bash
# 三十分钟日志行记录
count_over_time({app_kubernetes_io_instance="UUUU"}[30m]) 
# 12h小时内出现错误的速率
rate({app_kubernetes_io_instance=~".*UUUUU.*"} |~ "ERROR|error" [12h])
```

#### 集合运算

与PromQL一样，LogQL支持内置聚合运算符的一个子集，可用于聚合单个向量的元素，从而产生具有更少元素但具有集合值的新向量：

- sum：计算标签上的总和
- min：选择最少的标签
- max：选择标签上方的最大值
- avg：计算标签上的平均值
- stddev：计算标签上的总体标准差
- stdvar：计算标签上的总体标准方差
- count：计算向量中元素的数量
- bottomk：通过样本值选择最小的k个元素
- topk：通过样本值选择最大的k个元素

```bash
# 统计1个小时日志量最大的前10个服务 
topk(10,sum(rate({app_kubernetes_io_instance=~".*uuuu.*"}[60m])) by(container))
# 统计最近6小时内错误日志计数
sum(count_over_time({app_kubernetes_io_instance=~".*uuuuuu.*"}|~"ERROR"[6h])) by (container)
```

#### Loki Url 表达式编写

```bash
# url如下
https://localhost:3100/explore?orgId=1&left=%5B%22now-1h%22,%22now%22,%22Loki%22,%7B%22expr%22:%22%7Bapp_kubernetes_io_instance%3D~%5C%22user-service%5C%22%7D%7C~%5C%222020-11-05%5C%22%7C~%5C%22ERROR%5C%22%7C~%5C%22.aaa.%5C%22%22,%22maxLines%22:5000%7D%5D
--- 分析
1、%7C 表示|
2、%5C%22 表示"
3、时间：now-1h 可替换 now-1min或者 now-5min
4、项目名称：user-service 可替换为 .*service.* 或者 web-service
5、查询日志：2020-11-05 可替换为 2020-11-04
6、删除一个管道 %7C%5C%22ERROR%5C%22%7C%5C%22.aaa.%5C%22 这一段删除
最后生成的链接粘贴到浏览器访问
```
也可通过url加解密生成最终查询url链接

 *url加解密*

进入指定网站中，https://www.sojson.com/encodeurl.html

上例中解密如下：

```bash
https://localhsot/explore?orgId=1&left=["now-1m","now","Loki",{"expr":"{app_kubernetes_io_instance%3D\"user-service-\"}|\"2020-11-05\"|\"ERROR\"|\".aaaaa.\"","maxLines":5000}]
```

根据自定义查询语句

```bash
# 查询语句如下
## 根据日期查询
https://lcoalhsot/explore?orgId=1&left=["now-1h","now","Loki",{"expr":"{app_kubernetes_io_instance=~\"user-service\"}|~\"2020-11-18\"","maxLines":5000}]
## 加密
https://lcoalhsot/explore?orgId=1&left=%5B%22now-1h%22,%22now%22,%22Loki%22,%7B%22expr%22:%22%7Bapp_kubernetes_io_instance=~%5C%22user-service%5C%22%7D%7C~%5C%222020-11-18%5C%22%22,%22maxLines%22:5000%7D%5D
## 根据服务名称查询
https://localhost/explore?orgId=1&left=["now-1h","now","Loki",{"expr":"{app_kubernetes_io_instance=~\"data-service\"}|~\"2020-11-18\"","maxLines":5000}]
## 加密
https://localhost/explore?orgId=1&left=%5B%22now-1h%22,%22now%22,%22Loki%22,%7B%22expr%22:%22%7Bapp_kubernetes_io_instance=~%5C%22data-service%5C%22%7D%7C~%5C%222020-11-18%5C%22%22,%22maxLines%22:5000%7D%5D
## 根据对应的数据库查询
https://localhost/explore?orgId=1&left=["now-1h","now","Loki",{"expr":"{app_kubernetes_io_instance=~\"data-service\"}|~\"2020-11-18\"|~\"database\"","maxLines":5000}]
## 加密
https://localhost/explore?orgId=1&left=%5B%22now-1h%22,%22now%22,%22Loki%22,%7B%22expr%22:%22%7Bapp_kubernetes_io_instance=~%5C%22data-service%5C%22%7D%7C~%5C%222020-11-18%5C%22%7C~%5C%22database%5C%22%22,%22maxLines%22:5000%7D%5D
```

加密好的url直接粘贴到浏览器中即可查询

#### Loki api使用

查询标签

curl -G -s  "http://localhost:3100/loki/api/v1/labels" | jq

```bash
curl -G -s  "http://lcoalhpst:3100/loki/api/v1/labels" | jq .data[]
"__name__"
"app"
"app_kubernetes_io_component"
"app_kubernetes_io_instance"
"app_kubernetes_io_managed_by"
"app_kubernetes_io_name"
"app_kubernetes_io_version"
"chart"
"component"
"container"
"controller_revision_hash"
"filename"
"helm_sh_chart"
"heritage"
"job"
"k8s_app"
"name"
"namespace"
"pod"
"pod_template_generation"
"pod_template_hash"
"release"
"releaseRevision"
"statefulset_kubernetes_io_pod_name"
"stream"
"task"
```

根据标签查询对应标签值

curl -G -s http://localhost:3100/loki/api/v1/label/<name>/values |jq

```bash
curl -G -s  "http://lcoalhost:3100/loki/api/v1/label/app_kubernetes_io_instance/values" | jq .data[]
"web-service"
"user-service"
```

根据标签查询对应的日志

curl -G -s http://localhost:3100/loki/api/v1/query_range | jq

```bash
# 查询对应日志
curl -G -s  "http://lcoalhost:3100/loki/api/v1/query_range" --data-urlencode 'query={app_kubernetes_io_instance=~".*user-service.*"}|~"ERROR|error"' | jq .data.result | jq .[].values[0][1]
```



