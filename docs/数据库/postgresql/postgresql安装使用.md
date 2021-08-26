### postgresql安装

### 数据库登录
```bash
psql -U dbuser -d exampledb -h 127.0.0.1 -p 5432
```
### 数据导入导出
```bash
# 数据导出
pg_dump -h SERVICE_NAME -U postgres DATABASE_NAME > /tmp/backup.sql
# 数据导入
psql -U postgres DATABASE_NAME < /tmp/backup.sql
```
### 控制台命令
```bash
\h：查看SQL命令的解释，比如\h select。
\?：查看psql命令列表。
\l：列出所有数据库。
\c [database_name]：连接其他数据库。
\d：列出当前数据库的所有表格。
\d [table_name]：列出某一张表格的结构。
\du：列出所有用户。
\e：打开文本编辑器。
\conninfo：列出当前数据库和连接的信息。
```
### 基本数据库操作
```bash
# 创建新表
CREATE TABLE user_tbl(name VARCHAR(20), signup_date DATE);
# 插入数据
INSERT INTO user_tbl(name, signup_date) VALUES('张三', '2013-12-22');
# 选择记录
SELECT * FROM user_tbl;
# 更新数据
UPDATE user_tbl set name = '李四' WHERE name = '张三';
# 删除记录
DELETE FROM user_tbl WHERE name = '李四' ;
# 添加字段
ALTER TABLE user_tbl ADD email VARCHAR(40);
# 更新表结构
ALTER TABLE user_tbl ALTER COLUMN signup_date SET NOT NULL;
# 更名字段
ALTER TABLE user_tbl RENAME COLUMN signup_date TO signup;
# 删除字段
ALTER TABLE user_tbl DROP COLUMN email;
# 更新表名
ALTER TABLE user_tbl RENAME TO backup_tbl;
# 删除表
DROP TABLE IF EXISTS backup_tbl;
```
### 数据库操作
```bash
# 创建账号
$ psql -U postgres
postgres=# drop database DATABASE_NAME;
postgres=# create database DATABASE_NAME;
postgres=# create user USER_NAME;
postgres=# alter role USER_NAME with password 'BITNAMI_USER_PASSWORD';
postgres=# grant all privileges on database DATABASE_NAME to USER_NAME;
postgres=# alter database DATABASE_NAME owner to USER_NAME;
```