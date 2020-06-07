## 一.Mysql简介

MySQL是一个[**关系型数据库管理系统**](https://baike.baidu.com/item/%E5%85%B3%E7%B3%BB%E5%9E%8B%E6%95%B0%E6%8D%AE%E5%BA%93%E7%AE%A1%E7%90%86%E7%B3%BB%E7%BB%9F)，由瑞典MySQL AB 公司开发，目前属于 [Oracle](https://baike.baidu.com/item/Oracle) 旗下产品。MySQL 是最流行的[关系型数据库管理系统](https://baike.baidu.com/item/%E5%85%B3%E7%B3%BB%E5%9E%8B%E6%95%B0%E6%8D%AE%E5%BA%93%E7%AE%A1%E7%90%86%E7%B3%BB%E7%BB%9F)之一，在 WEB 应用方面，MySQL是最好的 RDBMS (Relational Database Management System，关系数据库管理系统) 应用软件。

## 二.Mysql基本命令

### I.库

### 1. 创建数据库

> 语法 ：create database 数据库名
>
> **创建数据库ab**
>
> create database ab；

### 2. 查看数据库

> **显示所有的数据库**
>
> show databases；
>
> **以行显示所有数据库**
>
> show databases \G

### 3.删除数据库

> 语法:drop database 数据库名
>
> 删除数据库ab
>
> drop database ab；

### II.表

### 1. 创建表

> 语法:create table 表名 （字段名，类型，字段名，类型，字段名，类型）;
>
> create table book（idint（10），namechar（40），age int）;

### 2.查看表结构

> desclist；
>
> explain food.list;
>
> show columns from food .list;
>
> show columns from food. list like'%id';
>
> **#查看表的创建过程，指定存储引擎，字符集**
>
> show create table list；

### 3.mysql存储引擎

mysql的存储引擎包括：MyISAM、InnoDB、BDB、MEMORY、MERGE、EXAMPLE、NDBCluster、ARCHIVE、CSV、BLACKHOLE、FEDERATED

### 4. 删除表

> 语法：drop table 表名
>
> drop table list；

### 5.修改表名

> 语法：alter table 表名 rename 新表名；
>
> alter table list rename lists；

### 6. 修改表中的字段类型

> 语法：alter table 表名 modify 要修改的字段名 字段名的新字段类型
>
> alter table lists modifyid char（40）；

### 7.修改表中字段名称和类型

> 语法：altertable 表名 change 原字段名 新字段名 新字段类型
>
> alter table lists change id ids int（40）；

### 8.表中添加字段

#### 1.表中添加字段

> 语法：alter table 表名 add 字段名 字段类型
>
> alter table lists add sum int（50）；

#### 2.表第一行添加字段

> 语法：alter table 表名 add 字段名 字段类型 first
>
> **第一行添加字段**
>
> alter table lists add sum int（50）first；

#### 3.在字段后添加字段

> 语法：alter table 表名 add 字段名 字段类型 after su
>
> **字段su后添加字段**
> alter table lists add so char（30）after su;

### 9.删除表中字段

> 语法：alter table 表名 drop 字段名
>
> alter table lists drop so；

### III.记录

#### 1.字段中插入记录

> 语法：insert into 表名 values（1,'zhangshan',2）;
>
> **后面记录指定为空**
>
> insert into lists values（1，2，‘shanshi’，null，null）；
>
> **插入多条记录中间用分号隔开**
>
> insert into lists valus （1，2，‘lisi’，null，null），（2，3，‘siji’，1，1）；
>
> **指定字段插入**
>
> insert into lists （su，ids）values（1，1）；

#### 2.查询表中记录

> 语法：select * from 表名
>
> **表示所有记录**
>
> select * from lists；
>
> **查询ids中记录**
>
> select ids from lists；
>
> **查询ids，su中记录**
>
> select ids，su from lists；
>
> **查看指定数据库中表内容**
>
> select * from food.lists;    `

#### 3.删除表中记录

> 语法：delete from表名 where 字段名=xx
>
> delete from lists where ids=2；
>
> **删除字段name记录为空的行**
>
> delete from lists where name is null；

#### 4.更新记录

> 语法：update 表名 set 字段名1=xx where 字段名2=xx
>
> update lists set ids=1 where name=null；
>
> **所有都变成2**
>
> update lists set ids=2
>
> **同时更新多个字段用分号隔开**
>
> update lists set ids=3，name=‘lisi’ where su=1；

## 三.SQL基本语句查询

### 1. 多字段查询

> 语法：select 字段1，字段2 from 表名
>
> select ids，name from lists；

### 2. 去重复查询

> 语法：select distinct 字段1，字段2 from 表名
>
> select distinct ids，name from lists；

### 3.使用and和or多条件查询

> 语法：select  字段1，字段2 from 表名 where 字段1>3 and 字段2<5
>
> select ids,name from lists where ids>3 and name <5;
>
> select ids,name from lists where ids>3 or name <5;
>
> **and与or同时存在时，先算and左右两边的，逻辑与先执行**
>
> select * from lists where ids=3 and(su=1 or name =5);

### 4.mysql区分大小写查询

> 语法：select * from 表名 where binary 字段1=‘xxx’
>
> **binary区分大小写**
>
> select *from lists where binary name=‘LK’

### 5.排序查询

> 语法：select distinct 字段1，字段2 from 表名 orderby 字段名
>
> **默认是升序排列**
>
> select distinct ids，su from lists orderby ids；
>
> **降序排列**
>
> select distinct ids，su from lists orderby ids desc；

### 6.查询引用别名

> 语法：select * from 旧表名 新表名
>
> select * from lists s；
>
> 语法：select 旧字段名 as 新字段名 from 表名
>
> **指定字段别名**
>
> select ids as s from lists；

### **7.like查询**

> 语法：select 字段名1 字段名2 ... from 表名 where 字段名1 like '%abc' or 字段名2 like '%ABC'
>
> select abc ABC from abc1 where abc like '%abc' or ABC like '%ABC'

## 四.常用select查询

> **打印当前的日期和时间**
>
> selectnow（）；
>
> **打印当前的日期**
>
> selectcurdate（）；
>
> **打印当前的时间**
>
> selectcurtime（）
>
> **打印当前数据库**
>
> selectdatabase（）；
>
> **打印数据库版本**
>
> selectversion（）；
>
> **打印当前用户**
>
> selectuser（）；

## 五.导入导出数据库

### 1.导入数据库

#### 方法一

> 创建数据库  ：mysql -e ‘create database book’ -uroot -p123456
>
> 导入数据库  ：mysql -uroot -p123456 book

#### 方法二

> 创建数据库  ：mysql  -e ‘create database book’ -uroot -p123456
>
> 导入数据库  ：source /root/book.sql  ** // 数据库所在路径**

### 2.导出数据库

> mysqldump -uroot -p123456 数据库名>数据库文件名
>
> mysqldump -uroot -p123456 book>book.sql
>
> **导出包含建库语句**
>
> mysqldump -uroot -p123456 -B book>book.sql
>
> **导出所有数据库**
>
> mysqldump -uroot -p123456 -A book>book.sql
>
> **导出数据库到文件**
>
> select * from lists outfile ‘/tmp/123.txt' ;  