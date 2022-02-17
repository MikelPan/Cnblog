### Elasticsearch 简介



### Elasticsearch 安装

```bash
# 使用rpm安装
## 导入key
rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
## 安装repo yum 源
cat > /etc/yum.repos.d/elasticsearch.repo <<- 'EOF'
[elasticsearch]
name=Elasticsearch repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=0
autorefresh=1
type=rpm-md
EOF
# 安装elasticsearch
yum install -y --enablerepo=elasticsearch elasticsearch
# 下载对应版本
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.10.2-x86_64.rpm -P /usr/local/src
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.10.2-x86_64.rpm.sha512 -P /usr/local/src
shasum -a 512 -c elasticsearch-7.10.2-x86_64.rpm.sha512 
rpm --install /usr/local/src/elasticsearch-7.10.2-x86_64.rpm
# 二进制安装
curl -L -O https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.10.2-linux-x86_64.tar.gz
curl -L -O https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.10.2-darwin-x86_64.tar.gz
tar -xvf elasticsearch-7.10.2-linux-x86_64.tar.gz
cd elasticsearch-7.10.2/bin && ./elasticsearch
./elasticsearch -Epath.data=data2 -Epath.logs=log2
```

### Elasticsearch 配置

```bash
# 开启自动创建索引
PUT _cluster / settings { ” persistent” ：{ “ action.auto_create_index” ：“ my-index-000001，index10，-index1 *，+ ind *” }}
PUT _cluster / settings { “ persistent” ：{ “ action.auto_create_index” ：“ false” }}
# 修改默认
PUT /_cluster/settings
{
  "transient": {
    "cluster": {
      "max_shards_per_node": 10000
    }
  }
}
```

### Elasticsearch 索引
#### 创建索引
```bash
PUT /es_wechat_fans_f04de36a-387f-4b39-9a7d-4633b22c5a04
{
	"settings": {
		"number_of_shards": 3,
		"number_of_replicas": 2
	}
}
```

#### 索引模板
curl -XPUT "http://$IP:9200/_template/94e8c881-26d3-46cd-bd8d-34ea9c39e98f_template" \
    -H 'Content-Type: application/json' \
    -u elastic:changeme \
    -d '{
        "index_patterns": [".monitoring-es-*"], 
        "settings": {
            "number_of_shards": 1,
            "number_of_replicas": 1,
            "index.lifecycle.name": "slm-history-ilm-policy", 
            "index.lifecycle.rollover_alias": "slm-history-ilm-policy_delete_index",
            "index.routing.allocation.include.box_type": "delete"
        }
    }'

#### 删除索引
```bash
DELETE /test-index
```

### Elasticseaech 分片原理
- shard(主分片)：我们上边所说的分片其实就指的是主分片，主分片是数据的容器，文档保存在主分片内，主分片又被分配到集群内的各个节点里。每个shard都是一个lucene index。
- replica（副本分片）：副本就是对分片的 Copy ，同步存储主分片的数据内容。为了达到高可用，Master 节点会避免将主分片和副本分片放在同一个节点上，所以副本分片数的最大值是 N-1（其中 N 为节点数）


ES 通过分片的功能使得索引在规模上和性能上都得到提升，有了 shard 就可以横向扩展，存储更多数据，让搜索和分析等操作分布到多台服务器上去执行，提升吞吐量和性能。

### Elasticsearch 写索引原理

**写索引是只能写在主分片上，然后同步到副本分片。写操作：对文档的新建、索引和删除请求，必须在主分片上面完成之后才能被复制到相关的副本分片**




curl -XPUT "http://$IP:9200/_template/my_test_template" \
    -H 'Content-Type: application/json' \
    -u elastic:changeme \
    -d '{
        "index_patterns": ["my-test-*"], 
        "settings": {
            "number_of_shards": 1,
            "number_of_replicas": 0,
            "index.lifecycle.name": "my_ilm_policy", 
            "index.lifecycle.rollover_alias": "my-test",
            "index.routing.allocation.include.box_type": "hot"
        }
    }'

