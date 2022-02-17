## docker swarm 介绍

### docker swarm 搭建

#### 安装docker
```bash
curl -s https://gitee.com/YunFeiGuoJi/Cnblog/raw/master/shell/Scripts/docker_install.sh | sh
```
#### 安装docker swarm

```bash
# 初始化主节点
docker swarm init --advertise-addr xxxx
# 加入node结点
docker swarm join --token SWMTKN-1-6a8e0gwfplo0oj5d2ogsixa4daxbydn43bkhpj1nngbr9kx18i-51vg8oazna6j5g9weghwvg4tn xxxx:2377 node1上执行
docker swarm join --token SWMTKN-1-6a8e0gwfplo0oj5d2ogsixa4daxbydn43bkhpj1nngbr9kx18i-51vg8oazna6j5g9weghwvg4tn 120.79.77.84:2377 node2上执行
```
#### 配置docker swarm
```bash
# 配置网络
docker network create -d overlay swarm_net && docker network ls
# 启动服务
curl -s https://gitee.com/YunFeiGuoJi/Cnblog/raw/master/docker/swarm/docker-compose-nginx.yml |cat |docker stack deploy -c - nginx
# 删除服务
docker stack rm nginx
```
#### 管理docker swarm
##### 节点管理
查看命令帮助
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
管理节点
```bash
# 查看节点
docker node ls
ID                            HOSTNAME            STATUS              AVAILABILITY        MANAGER STATUS      ENGINE VERSION
8x5iogo0c2d7cl9edjvbacxio *   master              Ready               Active              Leader              19.03.12
shihkplhlozcttq3m8va4129c     node01              Ready               Active                                  19.03.12
# 删除节点
docker node rm shihkplhlozcttq3m8va4129c

```

服务管理

```bash
# 删除服务
docker service rm service_name
# 增加副本

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

#### traefik安装

```bash
# docker-compose yaml 文件
cat > docker-compose.yaml <<- 'EOF'
version: '3.8'

#secrets:
  #aliyun_access_key:
    #file: "./secrets/aliyun_access_key.secret"
  #aliyun_secret_key:
    #file: "./secrets/aliyun_secret_key.secret"
    
services:
  traefik:
    # If use docker-compose 
    container_name: "traefik"
    # If use docker swarm
    # The official v2 Traefik docker image
    image: traefik:v2.3
    # Enables the web UI and tells Traefik to listen to docker
    command:
      - "--log.level=DEBUG"
      #- "--log.level=INFO"
      - "--api=true"
      - "--api.insecure=true"
      - "--providers.docker=true"
      - "--api.dashboard=true"
      - "--api.debug=true"
      - "--accesslog"
      - "--log=true"
      - "--log.filepath=/tmp/traefik.err.log"
      - "--accesslog.filepath=/tmp/traefik.access.log"
      # If use docker swarm
      - "--providers.docker.swarmMode=true"
      - "--providers.docker.exposedbydefault=false"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
      - "--certificatesresolvers.foo.acme.dnschallenge=true"
      - "--certificatesresolvers.foo.acme.dnschallenge.provider=alidns"
      - "--certificatesresolvers.foo.acme.keytype=EC256"
      #- "--certificatesresolvers.foo.acme.caserver=https://acme-staging-v02.api.letsencrypt.org/directory"
      - "--certificatesresolvers.foo.acme.email=plyx_46204@126.com"
      - "--certificatesresolvers.foo.acme.storage=/letsencrypt/acme.json"
      - "--metrics.prometheus=true"
      - "--metrics.prometheus.buckets=0.100000, 0.300000, 1.200000, 5.000000"
      - "--metrics.prometheus.addEntryPointsLabels=true"
      - "--metrics.prometheus.addServicesLabels=true"
      - "--entryPoints.metrics.address=:8082"
      - "--metrics.prometheus.entryPoint=metrics"
    ports:
      # The HTTP port
      - "8080:80"
      # The Web UI (enabled by --api.insecure=true)
      - "8443:443"
    #secrets:
     # - "aliyun_access_key"
     # - "aliyun_secret_key"
    networks:
      - "tarfik-public"
    environment:
      - "ALICLOUD_REGION_ID=ch-shenzhen"
      - "ALICLOUD_ACCESS_KEY=xxx"
      - "ALICLOUD_SECRET_KEY=xxx"
      #- "ALICLOUD_ACCESS_KEY_FILE=/run/secrets/aliyun_access_key"
      #- "ALICLOUD_SECRET_KEY_FILE=/run/secrets/aliyun_secret_key"
    volumes:
      # So that Traefik can listen to the Docker events
      - "/var/run/docker.sock:/var/run/docker.sock"
      #- ./traefik.yaml:/traefik.yaml
      - "./letsencrypt:/letsencrypt"
    deploy:
      labels:
        - "traefik.enable=true"
        - "traefik.docker.network=traefik-public"
        - "traefik.http.routers.traefik.rule=Host(`traefik.local.cluster`)"
        - "traefik.http.routers.traefik.entrypoints=websecure"
        - "traefik.http.routers.traefik.tls=true"
        - "traefik.http.routers.traefik.tls.certresolver=foo"
        - "traefik.http.routers.traefik.tls.domains[0].main=local.cluster"
        - "traefik.http.routers.traefik.tls.domains[0].sans=*.local.cluster" 
        - "traefik.http.services.traefik.loadbalancer.server.port=8080"
      replicas: 1
      placement:
        constraints: [node.role == manager]
networks:
  traefik-public:
    external: true
EOF
docker stack deploy -c docker-compose.yaml  traefik
```

#### 制作镜像

```bash
# 配置pip 镜像源
mkdir $HOME/.pip
tee $HOME/.pip/pip.conf <<-'EOF'
[golbal]
index-url = http://mirrors.aliyun.com/pypi/simple
[install]
trusted-host = mirrors.aliyun.com
EOF
# 配置apk 镜像源
sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories
apk update && apk upgrade
# python 导出项目库
## 导出当前目录依赖库
pip3 install pipreqs
pipreqs ./ --force
## 导出项目库
pip3 freeze > requirements.txt
```

#### 文件系统

```bash
# docker-compose yml文件
cat > docker-compose.yaml <<- 'EOF'
version: "3.8"

services:
  filebrowser:
    image: filebrowser/filebrowser
    ports:
      - "9001:80"
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock"
      - "/data/filebrower:/srv"
    networks:
      - "tarefik-public"
    deploy:
      labels:
        - "traefik.enable=true"
        - "traefik.docker.network=traefik-public"
        - "traefik.http.routers.filebrowser.rule=Host(`file.local.cluster`)"
        - "traefik.http.routers.filebrowser.entrypoints=websecure"
        - "traefik.http.routers.filebrowser.tls=true"
        - "traefik.http.routers.filebrowser.tls.certresolver=foo"
        - "traefik.http.routers.filebrowser.tls.domains[0].main=local.cluster"
        - "traefik.http.routers.filebrowser.tls.domains[0].sans=*.local.cluster" 
        - "traefik.http.services.filebrowser.loadbalancer.server.port=9001"
      replicas: 1
      #placement:
        #constraints: [node.role == manager]
networks:
  traefik-public:
    external: true
EOF
# 执行命令
docker stack deploy -c docker-compose.yaml filebrower
# 访问
## 本地访问
https://file.local.cluster:8443
```

