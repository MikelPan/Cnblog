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
#### 删除索引
```bash
DELETE /test-index
```
