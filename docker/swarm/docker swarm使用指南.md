### 初始化swarm 集群
安装docker环境
```bash
curl -sL https://gitee.com/YunFeiGuoJi/Cnblog/raw/master/shell/Scripts/docker_install.sh|sh -x -
```

修改damean.json
```bash
"live-restore": false
systemctl restart docker
```

在docker swarm manager上执行以下命令初始化集群
```bash
docker swarm init --advertise-addr 192.168.56.101
--advertise-addr 指定与其他 node 通信的地址 
```
docker swarm init 输出告诉我们：

① swarm 创建成功，swarm-manager 成为 manager node。
② 添加 worker node 需要执行的命令。
③ 添加 manager node 需要执行的命令。

如果当时没有记录下 docker swarm init 提示的添加 worker 的完整命令，可以通过 docker swarm join-token worker 查看

### 创建服务
创建一个web服务
```bash
docker service create --name web1 nginx
docker service ls
```
扩容副本
```bash
docker service scale web1=2
```
### 服务发现
实现功能：
- 让 service 通过简单的方法访问到其他 service。
- 当 service 副本的 IP 发生变化时，不会影响访问该 service 的其他 service。
- 当 service 的副本数发生变化时，不会影响访问该 service 的其他 service。

#### 创建覆盖网络

```bash
docker network create \
  --driver overlay \
  --gateway 10.1.5.1 \
  --subnet 10.1.0.0/16 \
  --ip-range 10.1.5.0/24 \
  --attachable yfgj_net
```
#### 创建服务
```bash
# 创建服务
docker service create --name app1  --network yfgj --replicas 2 --entrypoint "sleep 1d" busybox
docker service create --name app2  --network yfgj --replicas 2 nginx
# 查看生成的vip
docker service inspect --format='{{json .Endpoint.VirtualIPs}}' app1
[{"NetworkID":"9ttgtpwyvnssbfnw33wchbgwi","Addr":"10.0.15.5/24"}]
docker service inspect --format='{{json .Endpoint.VirtualIPs}}' app2
```

### 暴露服务外部访问
#### 安装traefik 代理服务
```bash
# 配置域名
阿里云或者腾讯云上配置域名指向安装traefik所在节点，并将443，80，8443防火强配置为允许公网访问，配置需要访问的服务域名
# 部署traefik 服务
docker stack deploy -c docker-compose-traefik.yml traefik
# 测试traefik 域名是否生成
curl -v  localhost:8080/api/http/routers|jq .
# 测试是否能访问对应的服务
curl -v -H "Host:traefik.ctq6.cn" localhost
curl -v -H "Host:traefik-443.ctq6.cn" localhost:443
curl -v -H "Host:traefik-8443.ctq6.cn" localhost:8443
# 浏览器访问
http://traefik.ctq6.cn
https://traefik-443.ctq6.cn
http://traefik-8443.ctq6.cn:8443
```
#### 安装nginx服务
```bash
docker stack deploy -c docker-compose-traefik.yml traefik
```

