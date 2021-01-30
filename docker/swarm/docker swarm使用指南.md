### 初始化swarm 集群
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
  yfgj
```
#### 创建服务
```bash
# 创建服务
docker service create --name web1 --network yfgj_net
docker service create --name busybox  --entrypoint "sleep 1d" busybox
# 查看生成的vip
docker service inspect --format='{{json .Endpoint.VirtualIPs}}' web1
[{"NetworkID":"9ttgtpwyvnssbfnw33wchbgwi","Addr":"10.0.15.5/24"}]
```

#### 

