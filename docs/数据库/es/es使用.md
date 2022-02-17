### es 查询使用

```bash
# 查询集群状态
curl -XGET http://localhost:9200/_cluster/health?pretty=true
# 查看副本
curl -XGET http://localhost:9200/_cat/shards
# 查询索引
curl -XGET --user user:pwd http://localhost:9200/_cat/indices?pretty
# 删除索引
curl -XDELETE --user user:pwd http://localhost:9200/market_behavior_94e8c881-26d3-46cd-bd8d-34ea9c39e98f
```

#### es 监控api
```bash
curl -XGET --user user:pwd http://localhost:9200/_cat
/_cat/allocation
/_cat/shards
/_cat/shards/{index}
/_cat/master?v=true
/_cat/master?v=help
/_cat/nodes
/_cat/nodes?h=ip,port,heapPercent,name
/_cat/tasks
/_cat/indices
/_cat/indices?bytes=b&s=store.size:desc&v=true
/_cat/indices/{index}
_cat/indices?format=json&pretty
/_cat/segments
/_cat/segments/{index}
/_cat/count
/_cat/count/{index}
/_cat/recovery
/_cat/recovery/{index}
/_cat/health
/_cat/health?v=true
/_cat/pending_tasks
/_cat/aliases
/_cat/aliases/{alias}
/_cat/thread_pool
/_cat/thread_pool/{thread_pools}
/_cat/plugins
/_cat/fielddata
/_cat/fielddata/{fields}
/_cat/nodeattrs
/_cat/repositories
/_cat/snapshots/{repository}
/_cat/templates
_cat/templates?v=true&s=order:desc,index_patterns
# 查看集群
curl -XGET --user user:pwd http://localhost:9200/_cat/master
# 查看节点
curl -XGET --user user:pwd http://localhost:9200/_cat/node
# 查看模板
curl -XGET --user user:pwd http://localhost:9200/_cat/templates
# 查看副本
curl -XGET --user user:pwd http://localhost:9200/_cat/shards
# 需改默认分片
curl -X PUT --user user:pwd http://localhost:9200/_template/scrm  -H 'Content-Type: application/json' -d '{
  "template": "*",
  "settings": {
    "number_of_shards": 1,
    "number_of_replicas": "0"
  }
}'
```

### Elasticsearch 查询

```bash
# 搜索
GET /bank/_search
{
  "query": { "match_all": {} },
  "sort": [
    { "account_number": "asc" }
  ]
}

POST /es_user_member_94e8c881-26d3-46cd-bd8d-34ea9c39e98f/_search 
{
  "query": {
    "term": {
      "member_id": {
        "value": "02yyp41en764eqlt"
      }
    }
  }
}


POST /es_user_member_94e8c881-26d3-46cd-bd8d-34ea9c39e98f/_search 
{
  "query": {
    "match": {
      "member_id": "02yyp41en764eqlt"
    }
  }
}

# 查询数据量
GET /_cat/count/index?v
# 分页查询
GET /index/_search
{
  "from": 0, 
  "size": 20
}

```

### Elasticsearch 插入数据
```bash
# 创建索引
PUT my_index
{
   "settings" : {
      "number_of_shards" : 5,
      "number_of_replicas" : 1
   }
  "mappings": {
    "_doc": {
      "properties": {
        "title":    { "type": "text"  },
        "name":     { "type": "text"  },
        "age":      { "type": "integer" }, 
        "created":  {
          "type":   "date",
          "format": "strict_date_optional_time||epoch_millis"
        }
      }
    }
  }
}

# 插入
POST -H 'Content-Type: application/json' locahost:9200/index/_doc -d '
{
  "member_id": "02yyp41en764eqlt"
}
'

# 动态增加分片
POST -H 'Content-Type: application/json' locahost:9200/index/_settings -d '
{
  "index": {
    "number_of_shards": 5,
    "number_of_replicas": 1
  }
}
'

# es创建空表


```

