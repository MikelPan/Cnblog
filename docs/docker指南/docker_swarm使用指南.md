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

### 管理docker swarm
#### 节点管理
**查看命令帮助**
```bash
[root@master ~]# docker node --help

Usage:	docker node COMMAND

Manage Swarm nodes

Commands:
  demote      Demote one or more nodes from manager in the swarm
  inspect     Display detailed information on one or more nodes
  ls          List nodes in the swarm
  promote     Promote one or more nodes to manager in the swarm
  ps          List tasks running on one or more nodes, defaults to current node
  rm          Remove one or more nodes from the swarm
  update      Update a node

Run 'docker node COMMAND --help' for more information on a command.
```
**管理节点**

```bash
# 查看节点
docker node ls
ID                            HOSTNAME            STATUS              AVAILABILITY        MANAGER STATUS      ENGINE VERSION
8x5iogo0c2d7cl9edjvbacxio *   master              Ready               Active              Leader              19.03.12
shihkplhlozcttq3m8va4129c     node01              Ready               Active                                  19.03.12
# 删除节点
docker node rm shihkplhlozcttq3m8va4129c

```

#### 服务管理

**创建服务**

```bash
docker service create --name app1  --network yfgj --replicas 2 --entrypoint "sleep 1d" busybox
docker service create --name app2  --network yfgj --replicas 2 nginx
# 查看生成的vip
docker service inspect --format='{{json .Endpoint.VirtualIPs}}' app1
[{"NetworkID":"9ttgtpwyvnssbfnw33wchbgwi","Addr":"10.0.15.5/24"}]
docker service inspect --format='{{json .Endpoint.VirtualIPs}}' app2
```

**扩容副本**

```bash
docker service scale web1=2
```

**删除服务**

```
docker service rm service_name
```

#### Gui管理界面安装

```bash
# docker-compose yml文件
cat > docker-compose.yaml <<- 'EOF'
version: "3.8"

services:
  portainer:
    image: portainer/portainer-ce:latest
    ports:
      - "9000:9000"
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock"
    networks:
      - "tarfik-public"
    deploy:
      labels:
        - "traefik.enable=true"
        - "traefik.docker.network=traefik-public"
        - "traefik.http.routers.portainer.rule=Host(`portainer.local.cluster`)"
        - "traefik.http.routers.portainer.entrypoints=websecure"
        - "traefik.http.routers.portainer.tls=true"
        - "traefik.http.routers.portainer.tls.certresolver=foo"
        - "traefik.http.routers.portainer.tls.domains[0].main=local.cluster"
        - "traefik.http.routers.portainer.tls.domains[0].sans=*.local.cluster" 
        - "traefik.http.services.portainer.loadbalancer.server.port=9000"
      replicas: 1
      placement:
        constraints: [node.role == manager]
networks:
  traefik-public:
    external: true
EOF
# 执行命令
docker stack deploy -c docker-compose.yaml docker-swarm-manager
# 访问
## 本地访问
http://localhost:9000
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
  --gateway 10.0.4.1 \
  --subnet 10.0.4.0/22 \
  --ip-range 10.0.4.0/24 \
  --attachable yfgj_net
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
#### 安装traefik服务
```bash
docker stack deploy -c docker-compose-traefik.yml traefik
```

