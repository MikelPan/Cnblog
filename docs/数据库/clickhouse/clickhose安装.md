### clickhouse 安装

物理机安装
```bash
yum install yum-utils
rpm --import https://repo.clickhouse.tech/CLICKHOUSE-KEY.GPG
yum-config-manager --add-repo https://repo.clickhouse.tech/rpm/stable/x86_64
```

容器安装
```bash

```

### clickhouse 配置账号
```bash
# 创建用户
PASSWORD=$(base64 < /dev/urandom | head -c8); echo "$PASSWORD"; echo -n "$PASSWORD" | sha256sum | tr -d '-'
```

### clickhouse 备份
备份程序地址：https://github.com/AlexAkulov/clickhouse-backup
```bash

```

### clickhouse 查询
clickhouse-client --host=10.249.0.3 --port=9000 --user=guest01 --password=guest01
