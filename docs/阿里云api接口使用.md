### 阿里云api官方介绍
### 阿里云云命令行使用
#### 安装
```bash
# 使用dockerfile
FROM alpine:latest

# 添加jq，以JSON的格式输出
RUN apk add --no-cache jq

# 获取并安装阿里云CLI工具
RUN wget https://aliyuncli.alicdn.com/aliyun-cli-linux-3.0.2-amd64.tgz
RUN tar -xvzf aliyun-cli-linux-3.0.2-amd64.tgz
RUN rm aliyun-cli-linux-3.0.2-amd64.tgz
RUN mv aliyun /usr/local/bin/

docker run -it -d -–name aliyuncli aliyuncli

docker exec -it aliyuncli /bin/sh
```
#### 使用
```bash
# 初始化
aliyun configure
aliyun Access Key ID [None]: xxxxx
aliyun Access Key Secret [None]: xxxxx
Default Region Id [None]: cn-hangzhou # 地域ID
Default Output Format [json]: json (Only supports JSON) # 目前仅支持JSON
Default Language [zh|en]: en # 在这里选择英语

# 创建实例
aliyun ecs CreateInstance \
    --InstanceName myvm1 \
    --ImageId centos_7_03_64_40G_alibase_20170625.vhd \
    --InstanceType ecs.n4.small \
    --SecurityGroupId sg-xxxxxx123 \ # 安全组ID
    --VSwitchId vsw-xxxxxx456 \ # 交换机ID
    --InternetChargeType PayByTraffic
    --Password xxx # 设置实例登录密码（也可以指定密钥）
```

#### 创建dnat条目
```bash
# 一、分析请求参数

```
#### 修改dnat条目
```bash
# 一、分析请求参数
请求ModifyForwardEntry方法，需要三个参数，ForwardTableId，ForwardEntryId，RegionId
aliyun vpc ModifyForwardEntry --help
阿里云CLI命令行工具 3.0.2

Product: Vpc (专有网络VPC)
Link:    https://help.aliyun.com/api/vpc/ModifyForwardEntry.html

Parameters:
  --ForwardTableId String  Required 
  --ForwardEntryId String  Required 
  --ExternalIp     String  Optional 
  --ExternalPort   String  Optional 
  --InternalIp     String  Optional 
  --InternalPort   String  Optional 
  --IpProtocol     String  Optional 
  --RegionId       String  Required 

# 二、获取RegionId
aliyun vpc DescribeRegions | jq '.Regions.Region[0:5][]'
{
  "RegionId": "cn-qingdao",
  "RegionEndpoint": "vpc.aliyuncs.com",
  "LocalName": "华北 1"
}
{
  "RegionId": "cn-beijing",
  "RegionEndpoint": "vpc.aliyuncs.com",
  "LocalName": "华北 2"
}
{
  "RegionId": "cn-zhangjiakou",
  "RegionEndpoint": "vpc.cn-zhangjiakou.aliyuncs.com",
  "LocalName": "华北 3"
}
{
  "RegionId": "cn-huhehaote",
  "RegionEndpoint": "vpc.cn-huhehaote.aliyuncs.com",
  "LocalName": "华北 5"
}
{
  "RegionId": "cn-wulanchabu",
  "RegionEndpoint": "vpc.cn-wulanchabu.aliyuncs.com",
  "LocalName": "华北6（乌兰察布）"
}

aliyun vpc DescribeRegions | jq '.Regions.Region[1].RegionId'
"cn-beijing"

# 三、获取ForwardTableId参数
请求DescribeNatGateways方法，根据返回值获取ForwardTableId
aliyun vpc DescribeNatGateways | jq '.NatGateways.NatGateway[0]|{ Name: .Name, ForwardTableIds: .ForwardTableIds.ForwardTableId[] }'
aliyun vpc DescribeNatGateways | jq '.NatGateways.NatGateway[0].ForwardTableIds.ForwardTableId[]'

# 四、获取ForwardEntryId参数
请求DescribeForwardTableEntries方法，根据返回值获取ForwardEntryId，此方法需要两个参数
aliyun vpc DescribeForwardTableEntries --help
阿里云CLI命令行工具 3.0.2

Product: Vpc (专有网络VPC)
Link:    https://help.aliyun.com/api/vpc/DescribeForwardTableEntries.html

Parameters:
  --RegionId       String  Required 
  --ForwardTableId String  Required 
  --ForwardEntryId String  Optional 
  --PageNumber     Integer Optional 
  --PageSize       Integer Optional

aliyun vpc DescribeForwardTableEntries --RegionId  `aliyun vpc DescribeRegions | jq '.Regions.Region[1].RegionId'` --ForwardTableId `aliyun vpc DescribeNatGateways | jq '.NatGateways.NatGateway[0].ForwardTableIds.ForwardTableId[]'` | jq '.ForwardTableEntries.ForwardTableEntry[-2].ForwardEntryId'

# 五、修改dnat
请求ModifyForwardEntry方法，需要三个必选参数，ForwardTableId，ForwardEntryId，RegionId，五个可选参数
[root@test-scrm-jumper .aliyun]# aliyun vpc ModifyForwardEntry --help
阿里云CLI命令行工具 3.0.2

Product: Vpc (专有网络VPC)
Link:    https://help.aliyun.com/api/vpc/ModifyForwardEntry.html

Parameters:
  --ForwardTableId String  Required 
  --ForwardEntryId String  Required 
  --ExternalIp     String  Optional 
  --ExternalPort   String  Optional 
  --InternalIp     String  Optional 
  --InternalPort   String  Optional 
  --IpProtocol     String  Optional 
  --RegionId       String  Required 

此次修改外网端口和内网端口地址
ForwardTableId=`aliyun vpc DescribeNatGateways | jq '.NatGateways.NatGateway[0].ForwardTableIds.ForwardTableId[]'`

RegionId=`aliyun vpc DescribeRegions | jq '.Regions.Region[1].RegionId'`

ForwardEntryId=`aliyun vpc DescribeForwardTableEntries --RegionId  `aliyun vpc DescribeRegions | jq '.Regions.Region[1].RegionId'` --ForwardTableId `aliyun vpc DescribeNatGateways | jq '.NatGateways.NatGateway[0].ForwardTableIds.ForwardTableId[]'` | jq '.ForwardTableEntries.ForwardTableEntry[-2].ForwardEntryId'`

aliyun vpc ModifyForwardEntry --ForwardTableId $ForwardTableId \
    --ForwardEntryId  $ForwardEntryId\
    --ForwardTableId $ForwardTableId \
    --ExternalPort 20147 \
    --InternalPort 9007 \
    --RegionId $RegionId
···
#### 