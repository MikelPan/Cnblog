### docker 安装jumpserver
```bash
# 创建env
cat > .env <<EOF
# 版本号可以自己根据项目的版本修改
Version=v2.5.3

# MySQL
DB_HOST=mysql
DB_PORT=3306
DB_USER=jumpserver
DB_PASSWORD=4A448YH7rQ2dw2sU0PjBqcQS
DB_NAME=jumpserver

# Redis
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=ObnL9EVofZE7y0HMJE8xQpdB

# Core
SECRET_KEY=B3f2w8P2PfxIAS7s4URrD9YmSbtqX4vXdPUL217kL9XPUOWrmf
BOOTSTRAP_TOKEN=7Q11Vz6R2J6BLAdd

LOG_LEVEL=ERROR

##
# SECRET_KEY 保护签名数据的密匙, 首次安装请一定要修改并牢记, 后续升级和迁移不可更改, 否则将导致加密的数据不可解密。
# BOOTSTRAP_TOKEN 为组件认证使用的密钥, 仅组件注册时使用。组件指 koko、guacamole
EOF
# 创建docker-compose
cat > docker-compose.yaml <<'EOF'
version: '3'
services:
  mysql:
    image: jumpserver/jms_mysql:${Version}
    container_name: jms_mysql
    restart: always
    tty: true
    environment:
      DB_PORT: $DB_PORT
      DB_USER: $DB_USER
      DB_PASSWORD: $DB_PASSWORD
      DB_NAME: $DB_NAME
    volumes:
      - mysql-data:/var/lib/mysql
    networks:
      - jumpserver

  redis:
    image: jumpserver/jms_redis:${Version}
    container_name: jms_redis
    restart: always
    tty: true
    environment:
      REDIS_PORT: $REDIS_PORT
      REDIS_PASSWORD: $REDIS_PASSWORD
    volumes:
      - redis-data:/var/lib/redis/
    ports:
      - 13306:3306
    networks:
      - jumpserver

  core:
    image: jumpserver/jms_core:${Version}
    container_name: jms_core
    restart: always
    tty: true
    environment:
      SECRET_KEY: $SECRET_KEY
      BOOTSTRAP_TOKEN: $BOOTSTRAP_TOKEN
      LOG_LEVEL: $LOG_LEVEL
      DB_HOST: $DB_HOST
      DB_PORT: $DB_PORT
      DB_USER: $DB_USER
      DB_PASSWORD: $DB_PASSWORD
      DB_NAME: $DB_NAME
      REDIS_HOST: $REDIS_HOST
      REDIS_PORT: $REDIS_PORT
      REDIS_PASSWORD: $REDIS_PASSWORD
    depends_on:
      - mysql
      - redis
    volumes:
      - core-data:/opt/jumpserver/data
    ports:
      - 16739:6379
    networks:
      - jumpserver

  koko:
    image: jumpserver/jms_koko:${Version}
    container_name: jms_koko
    restart: always
    privileged: true
    tty: true
    environment:
      CORE_HOST: http://core:8080
      BOOTSTRAP_TOKEN: $BOOTSTRAP_TOKEN
      LOG_LEVEL: $LOG_LEVEL
    depends_on:
      - core
      - mysql
      - redis
    volumes:
      - koko-data:/opt/koko/data
    ports:
      - 2222:2222
    networks:
      - jumpserver

  guacamole:
    image: jumpserver/jms_guacamole:${Version}
    container_name: jms_guacamole
    restart: always
    tty: true
    environment:
      JUMPSERVER_SERVER: http://core:8080
      BOOTSTRAP_TOKEN: $BOOTSTRAP_TOKEN
      GUACAMOLE_LOG_LEVEL: $LOG_LEVEL
    depends_on:
      - core
      - mysql
      - redis
    volumes:
      - guacamole-data:/config/guacamole/data
    networks:
      - jumpserver

  nginx:
    image: jumpserver/jms_nginx:${Version}
    container_name: jms_nginx
    restart: always
    tty: true
    depends_on:
      - core
      - koko
      - mysql
      - redis
    volumes:
      - core-data:/opt/jumpserver/data
    ports:
      - 8080:80
    networks:
      - jumpserver

volumes:
  mysql-data:
  redis-data:
  core-data:
  koko-data:
  guacamole-data:

networks:
  jumpserver:
EOF
```