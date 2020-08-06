### docker swarm 介绍
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
docker swarm join --token SWMTKN-1-6a8e0gwfplo0oj5d2ogsixa4daxbydn43bkhpj1nngbr9kx18i-51vg8oazna6j5g9weghwvg4tn xxxx:2377 node2上执行
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

