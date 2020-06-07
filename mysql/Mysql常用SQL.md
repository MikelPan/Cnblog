### 一、加密查询
```shell
# md5加密
select MD5('123456') as a
# 掩藏身份证号
select CONCAT(LEFT(`id_number`,9),'*********',RIGHT(`id_number`,1))
# 查询身份证号
select * from test where left('id_number',6)=123456 and right('id_number',3)=456
# 生成随机数
select round(rand()*(999999-111111)+111111)
# 生成id流水号
set id = CONCAT(LEFT(id_number,6),'181206',LPAD(id, 7,'0'))  #从左到右截取
set id = CONCAT(LEFT(id_number,6),'181206',RPAD(id, 7,'0'))  #从右到左截取
# 添加性别
IF (MOD(SUBSTRING(id_number,17,1),2),'男','女') as "user_sex"
# 正则匹配
select * from table where clounme REGEXP '[A-Z]'
# 识别大小写
select * from test where id_number like 'x%'
# 查看字段
select COLUMN_NAME,DATA_TYPE,COLUMN_COMMENT from information_schema.columns  where table_name='export' and table_schema='data_import'
# 查询字段是否存在
select * from information_schema.columns where table_name = 'export' and column_name = '创业市'
```
### 二、去重查询
```shell
# 去重查询
select username from auth_user GROUP BY username HAVING COUNT(*) >4
select * from user where username in(select username from auth_user GROUP BY username HAVING COUNT(*) >1
# 去重删除
select id from user  where id_number in(select id_number from user group BY id_number HAVING COUNT(id_number) >1) and id not in (select min(id) from use_exit group by id_number having count(id_number)>1)
# 字段去重查询
select distinct census_county from user
# 字符串截取
select left('abcd',3)
select right('abcd',3)
select substring('abcd',2,2)
select substring('abcd',-2,2)
select substring('abcd',-2)
# 字符串转换日期格式
select FROM_UNXITIME(date_bitrh,'%Y%m%d') from a
```
### 三、连接查询
```shell
# 内连接查询
select * from table1 inner join table2 on table1.user=table2.user
# 左连接查询
select * from table1 left join table2 on table1.user=table2.user
# 右连接查询
select * from table1 right join table2 on table1.user=table2.user
# update 更新
update user a inner join user_regiter b on 
a.id_number=b.id_number set b.id=a.id,a.user_sex=b.user_sex,a.user_name=b.user_name
# 子查询更新
update user a,(select IF (MOD(SUBSTRING(id_number,17,1),2),'男','女')  as user_sex from user_1) b set a.user_sex=b.user_sex where a.id_number is not null
update user a,(select date_birth,id_number_enc from user_register_1) b set a.date_birth=b.date_birth where a.id_number=b.id_number
```
### 四、增加字段
```shell
# 增加字段
alter table user add is tinyint(1) comment '是否人员';
# 修改字段名
ALTER TABLE testalter_tbl CHANGE i j BIGINT;
ALTER TABLE testalter_tbl MODIFY c CHAR(10);
# 修改表名
ALTER TABLE testalter_tbl RENAME TO alter_tbl;
# 创建索引
CREATE INDEX indexName ON mytable(username(length));
# 添加普通索引
ALTER table tableName ADD INDEX indexName(columnName)
# 删除索引
DROP INDEX [indexName] ON mytable;
# 删除字段
ALTER table tableName drop cloumes
# 查看索引
show index from table;
# 创建唯一索引
CREATE UNIQUE INDEX indexName ON mytable(username(length))
# 添加索引
ALTER TABLE tbl_name ADD PRIMARY KEY (column_list)
ALTER TABLE tbl_name ADD UNIQUE index_name (column_list)
ALTER TABLE tbl_name ADD INDEX index_name (column_list)  # 普通索引，索引值可以出现多次
ALTER TABLE tbl_name ADD FULLTEXT index_name (column_list)
# 删除主键
ALTER TABLE testalter_tbl DROP PRIMARY KEY
# 增加字段类型长度
alter table 表名 modify column 字段名 char(19)
```
### 五、查询数据库
```shell
# 查询数据库
show status like 'Table%';select * from information_schema.PROCESSLIST ORDER BY  time desc;show status like '%connect%'
# 查询语句
EXPLAIN select operationl0_.id as id1_23_0_, operationl0_.action as action2_23_0_, operationl0_.create_time as create_t3_23_0_, operationl0_.module as module4_23_0_, operationl0_.new_value as new_valu5_23_0_, operationl0_.old_value as old_valu6_23_0_, operationl0_.relevance_id as relevanc7_23_0_, operationl0_.remark as remark8_23_0_, operationl0_.url as url9_23_0_, operationl0_.user_id as user_id10_23_0_, operationl0_.user_name as user_na11_23_0_ from operation_log operationl0_ where operationl0_.id=1141181855320596481
```
### 六、权限添加
```shell
# 存储过程权限添加
grant select on mysql.proc to developer@'xxxx'
grant create routine on testdb.* to developer@’192.168.0.%’; -- now, can show procedure status
grant alter routine on testdb.* to developer@’192.168.0.%’; -- now, you can drop a procedure
grant execute on testdb.* to developer@’192.168.0.%’;
# mysql 修改密码（5.7）
update user set authentication_string=PASSWORD("Runsdata@2017#user") where user="society_user";
ALTER USER 'society_user'@'%' IDENTIFIED WITH mysql_native_password BY 'Runsdata@2017#user';
```
### 七、创建临时表恢复数据
```shell
create table new_table like old_table
insert into new_table select * from old_table
rename oldname to newname
rename table old_name to newname
### 锁表
# 加读锁
SET AUTOCOMMIT=0;
lock tables user_auth_image read
COMMIT;
UNLOCK TABLES;
```