## gitlab简介

## gitlab安装

### docker 版安装gitlab

1、使用docker命令安装

```bash
docker run --name gitlab_server \
    -p 10443:443 -p 10180:80 \
    --volume /var/lib/gitlab/config:/etc/gitlab \
    --volume /var/lib/gitlab/logs:/var/log/gitlab \
    --volume /var/lib/gitlab/data:/var/opt/gitlab \
    -d gitlab/gitlab-ce
```

2、使用docker-compose安装

```yaml
version: "3.8"
services:
  gitlab:
    image: gitlab/gitlab-ce:latest
    ports:
      - "2224:22"
      - "8929:80"
      - "8930:443"
    volumes:
      - /tencent-cfs/gitlab/data:/var/opt/gitlab
      - /tencent-cfs/gitlab/logs:/var/log/gitlab
      - /tencent-cfs/gitlab/config:/etc/gitlab
    networks:
      - "ddyw_net"
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        external_url 'https://gitlab.ctq6.cn'
        gitlab_rails['time_zone'] = 'Asia/Shanghai'
        gitlab_rails['gitlab_ssh_host'] = 'gitlab.ctq6.cn'
        gitlab_rails['gitlab_shell_ssh_port'] = 2224
        nginx['enable'] = true
        nginx['listen_https'] = false
        nginx['listen_port'] = 80
        nginx['listen_https'] = false
        nginx['http2_enabled'] = false
        nginx['client_max_body_size'] = '250m'
        nginx['redirect_http_to_https'] = true
        puma['per_worker_max_memory_mb'] = 2046
        postgresql['shared_buffers'] = "256MB"
        postgresql['max_worker_processes'] = 4
        gitlab_rails['initial_root_password'] = File.read('/run/secrets/gitlab_root_password')
        gitlab_rails['smtp_enable'] = true
        gitlab_rails['smtp_address'] = "smtp.126.com"
        gitlab_rails['smtp_port'] = 465
        gitlab_rails['smtp_user_name'] = "plyx_46204@126.com"
        gitlab_rails['smtp_password'] = "xxxxxx"
        gitlab_rails['smtp_domain'] = "smtp.126.com"
        gitlab_rails['smtp_authentication'] = "login"
        gitlab_rails['smtp_enable_starttls_auto'] = true
        gitlab_rails['smtp_tls'] = true
        gitlab_rails['gitlab_email_enabled'] = true
        gitlab_rails['gitlab_email_from'] = 'plyx_46204@126.com'
        gitlab_rails['gitlab_email_display_name'] = 'DDYW-会员中台Gitlab维护团队'
      #GITLAB_OMNIBUS_CONFIG: "from_file('/omnibus_config.rb')"
    #configs:
    #  - source: gitlab
    #    target: /omnibus_config.rb
    secrets:
      - gitlab_root_password
    deploy:
      mode: replicated
      labels:
        - "traefik.enable=true"
        - "traefik.docker.network=ddyw_net"
        - "traefik.http.routers.gitlab.rule=Host(`gitlab.ctq6.cn`)"
        - "traefik.http.services.gitlab_gitlab.loadbalancer.server.port=80"
        - "traefik.http.routers.gitlab.tls=true"
        - "traefik.http.routers.gitlab.tls.certresolver=foo"
        - "traefik.http.routers.gitlab.tls.domains[0].main=ctq6.cn"
        - "traefik.http.routers.gitlab.tls.domains[0].sans=*.ctq6.cn"
        - "traefik.http.routers.gitlab.middlewares=redirect-https"
        - "traefik.http.routers.gitlab.entrypoints=websecure"
      replicas: 1
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
        window: 120s
#configs:
#  gitlab:
#    file: /tencent-cfs/gitlab/gitlab.rb
secrets:
  gitlab_root_password:
    file: /root/.secret/gitlab_root_password.txt
networks:
  ddyw_net:
    external: true
    name: fygj_net
```

3、安装gitlab-runner

```bash

```

