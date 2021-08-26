## 一、Msql数据类型

### 1、整型

tinyint,  占 1字节 ,有符号： -128~127,无符号位 :0~255

smallint, 占 2字节 ,有符号： -32768~32767无符号位 :0~65535

mediumint 占 3字节 ,有符号： -8388608~8388607,无符号位:0~16777215:

int, 占 4字节 ,有符号： -2147483648~2147483647,无符号位 无符号位 :0~4 284967295

bigint, bigint,bigint, 占 8字节

bool  等价于 tinyint

### 2、浮点型

float([m[,d]])  占 4字节 ,1.17E-38~3.4E+3838~3.4E

double([m[,d]])  占 8字节

decimal([m[,d]])  以字符串形式表示的浮点数 

### 3、字符型

char([m]): :定长的字符 ,占用 m字节

varchar[(m)]: :变长的字符 ,占用 m+1m+1 字节，大于 255 个字符：占用 m+2m+2

tinytext,255 个字符 (2 的 8次方 )

text,65535 个字符 (2 的 16 次方 )

mediumtext,16777215字符 (2 的 24 次方 )

longtext (2的 32 次方 )

enum(value,value,...)占 1/2个字节 最多可以有 65535 个成员 个成员

set(value,value,...) 占 1/2/3/4/8个字节，最多可以 有 64个成员

## 二、Mysql数据运算

### 1、逻辑运算 and or not

for example：

选择出 书籍价格 为（30,60,40，50）的记录

> sql> select bName,publishing,price from books where price=30 or price=40 or price=50 or price=60; 

### 2、in 运算符

in 运算符用于 WHERE 表达式，以列表的形式支持多个选择，语法如下

where colunmm in （value1，value2，.......）

where colunmm not in (value1,value2,..........)

当in前面加上not时，表示与in相反，既不在结果中

> sql> select bName,publishing,price from books where  price in （30，40，50，60）order by price asc；

### 3、算术运算符  >= | <=| <> |=

for example

找出价格小于70的记录

> mysql> select bName,price from books where price <= 70;

### 4、模糊查询  like '%...%'

字段名 [not] like  '%......%'   通配符  任意多个字符

查询书中包含程序字样的记录

> mysql> select bName,price from books where bName like '%程序%'

### 5、范围运算 [not] between .......and

查找价格不在30和60之间的书名和价格

mysql> select bName,price from books where price not between 30 and 60  order by price desc;

### 6、Mysql 子查询

select where条件中又出现select

查询类型为网络技术的图书

> mysql> select bName,bTypeId from books where bTypeId=(select bTypeId from category where bTypeName='网络技术');

### 7、limit 限定显示的条目

LIMIT子句可以被用于强制 SELECT语句返回指定的记录数。 LIMIT 接受一个或两数字参。必 须是一个整数常量。如果给定两 个数，第一指定返 回记录行的偏移量，第二个参数返回记录行的最大数目。初始偏移量是 0( 而不是 1)。

语法 ： select * from limit m，n

其中 m是指记录开始的 index indexindex，从 0开始，表示第一条记录，n是指从第 m+1 条开始，取 n。

查询books表中第2条到六行的记录

mysql>select * from books limit 1,6;

### 8、连接查询

以一个共同的字段，求两张表当中符合条件并集。 通过 共同字段把这两张表的共同字段把这两张表连 接起来。

常用的连接：

内连接：根据表中的共同字段进行匹配

外连接：现实某数据表的 全部记录和另外数据表中符合连接条件的记录。

外连接：左连接、右连接

**内连接：for exmaple**

> create table student（sit int(4) primary key auto_increment,name varchar(40)）;
>
> insert into student values(1,‘张三’），（2，‘李四’），（3，‘王五’），（4，‘mikel’）;
>
> create table teachers（sit int(4)，id int(4) primary key auto_increment,score varchar(40)）;
>
> insert into teachers values(1,1,‘1234’)，（1,2,‘2345’），（3,3,‘2467’），（4,4，‘2134’）；
>
> select s.* ,t.* from student as s,teachers as t where s.sid=t.sid;


**左连接**： select 语句 a表 left[outer] join b 表  on 连接条件 ，a表是主，都显示。

b表是从，主表内容全都有，主表多出来的字段，从表没有的就显示 null，从表多出主表的字段不显示。

**select \* from student as s left join teachers as t on  s.sit=t.sit;**

**右连接**：select 语句 a表 right[outer] join b 表  on 连接条件 ，b表是主，都显示。

a表是从，主表内容全都有，主表多出来的字段，从表没有的就显示 null，从表多出主表的字段不显示。

**select \* from student as sright join teachers as t on  s.sit=t.sit;**

## **三、聚合函数**

### 1、sam() 求和

**select sum (id+score) as g from teachers;**

### 2、avg() 求平均值

**select avg (id+score) as g from teachers;**

### 3、max() 最大值

**select max (id) as g from teachers;**

### 4、min() 最小值

**select min(id) as g from teachers;**

### 5、substr（string，start，len） 截取

**select substr(soucr,1,2) as g from teachers;**

从start开始，截取len长度，start从1开始

concat（str1,str2,str3......................）字符串拼接，将多个字符串拼接在一起

**select concat(id,score,sit) as g from teachers;**

### 6、count() 统计计数 记录字段数据条数

**select count(id) as g from teachers;**

### 7、upper() 大写

**select upper(name) as g from student;**  #将字段name中英文全部变为大写，但不改变原值

### 8、lower() 小写

**select lower(name) as g from student; ** #将字段name中英文全部变为小写，但不改变原值

## 四、索引

mysql中索引是以文件形式存放的，对表进行增删改，会同步到索引，索引和表保持一致，常用在where 后字段查询就加索引。

**优点：加快查询速度，减少查询时间**

**缺点：索引占据一定磁盘空间，会影响insert，delete，update执行时间**

### **1、索引类型**

**普通索引：最基本索引，不具备唯一性**

**唯一索引：索引列的值必须唯一，但允许有空值。如果是组合索引，则列值的组合必须唯一**

**主键索引：记录值唯一，主键字段很少被改动，不能为空，不能修改，可用于一个字段或者多个字段**

**全文索引：检索文本信息的, 针对较大的数据，生成全文索引查询速度快，但也很浪费时间和空间**

**组合索引：一个索引包含多个列**

### **2、创建索引**

**普通索引：**

**# 创建普通索引**

**create table demo(id int(4),uName varchar(20),uPwd varchar(20),index (uPwd));**

**# 查看建表过程**

**show create table demo；**

demo | CREATE TABLE `demo` (

  `id` int(4) DEFAULT NULL,

  `uName` varchar(20) DEFAULT NULL,

  `uPwd` varchar(20) DEFAULT NULL,

  KEY `uPwd` (`uPwd`)

) ENGINE=InnoDB DEFAULT CHARSET=utf8 |

**唯一索引：字段值只允许出现一次，可以有空值**

**# 创建唯一索引**

**create table demo1（id int(4),uName varchar(20),uPwd varchar(20),unique index (uName)）;**

**# 查看建表过程**

**show create table demo1;**

demo1 | CREATE TABLE `demo1` (

  `id` int(4) DEFAULT NULL,

  `uName` varchar(20) DEFAULT NULL,

  `uPwd` varchar(20) DEFAULT NULL,

  UNIQUE KEY `uName` (`uName`)

) ENGINE=InnoDB DEFAULT CHARSET=utf8 |

**主键索引：字段记录值唯一，字段很少被修改，一般主键约束为auto_increment或者not null unique，不能为空，不能重复。**

**# 创建主键索引**

**create table demo2(id int(4) auto_increment primary key,uName varchar(20),uPwd varchar(20));**

**# 查看建表语句**

demo2 | CREATE TABLE `demo2` (

  `id` int(4) NOT NULL AUTO_INCREMENT,

  `uName` varchar(20) DEFAULT NULL,

  `uPwd` varchar(20) DEFAULT NULL,

  PRIMARY KEY (`id`)

) ENGINE=InnoDB DEFAULT CHARSET=utf8 |

**全文索引：提高全文检索效率，解决模糊查询**

**# 创建全文索引**

**create table demo3(id int(4),uName varchar(20),uPwd varchar(20),fulltext(uName,uPwd));**

**# 查看建表语句**

| demo3 | CREATE TABLE `demo3` (

`id` int(4) DEFAULT NULL,

  `uName` varchar(20) DEFAULT NULL,

  `uPwd` varchar(20) DEFAULT NULL,

  FULLTEXT KEY `uName` (`uName`,`uPwd`)

) ENGINE=InnoDB DEFAULT CHARSET=utf8 |

## **五、外键约束**

**外键约束：foreign key 表与表之间的一种约定关系，由于这种关系存在，让表与表之间的数据更加具有完整性，更加具有关联性。**

#### **1、创建外键约束**

**创建user主表**

**create table user1(id int(11)auto_increment primary key,name varchar(50),sex int(1));**

**插入数据**

**insert into user1(name,sex)values("mikel",4),("plyx",6);**

**创建order外键表**

**create table `order`(order_id int(11)auto_increment primary key,u_id int(11),username varchar(50),monery int(11),foreign key(u_id) references user1(id)  on delete cascade on update cascade )engine=innodb);**

**插入数据**

**INSERT INTO `order` (order_id,u_id,username,monery)values(1,1,'mikel',2345),(2,2,'plyx',3456)**

**在order表中插入一条u_id为6的记录**

**insert into `orser` (u_id)values(6);**

**Cannot add or update a child row: a foreign key constraint fails (`school`.`order`, CONSTRAINT `order_ibfk_1` FOREIGN KEY (`u_id`) REFERENCES `user1` (`id`) ON DELETE CASCADE ON UPDATE CASCADE)**

**user1中不存在id为6的记录，现在添加一条id为6的记录**

**insert into user1(id)values(6);**

#### **2、视图**

**是一张虚拟表，由 select select select语句指定的数据结构和数据，不生成真实文件**

**create view mikel as select \* from school.books;**

**select  \* from mikel;**

## **六、存储过程**

**存储过程用来封装mysql代码，相当于函数，一次编译，生成二进制文件，永久有效，提高效率。**

### **1、定义存储过程**

**create procedure 过程名（参数1，参数2，.............）**

**begin**

​	sql语句	

**end**

### 2、调用存储过程

**call 过程名（参数1，参数2，...................）**

**example:定义一个存储过程查看books表中所有数据**

​    **1. 修改sql默认执行符号**

​    delimiter //

 create  procedure seebooks();

begin

​         **select \* from sctudent.books;**

​    **end //**

call seebooks() //

### **3、存储过程参数传递**

**in 传入参数 int 赋值**

IN输入参数：表示调用者向过程传入值（传入值可以是字面量或变量）

OUT输出参数：表示过程向调用者传出值(可以返回多个值)（传出值只能是变量）

INOUT输入输出参数：既表示调用者向过程传入值，又表示过程向调用者传出值（值只能是变量）

create procedure seebook(in b int)

begin

  select * from school.books where bId=b;

end //

call seebook(4)

16

**out --------------传出参数**

select into 在过程中赋值传给变量，并查看变量值

create procedure seebook2(out b varchar(100))

begin

  select bName into b  from school.books where bId=4;

end //

17

**过程内的变量使用方法**

**声明变量名称，类型，declare 过程内的变量没有@**

**赋值 set 变量名=（select 语句）**

create procedure seebook3()

begin 

​        declare str varchar(100);****

​        set str=(select bName from school.books where bId=20);

​        select str;

end//

call seebook3() //

18

## 七、触发器

**与数据表有关，当表出现（增，删，改，查）时，自动执行其特定的操作**

**语法：create trigger 触发器名称 触发器时机 触发器动作 on 表名 for each row**

**触发器名称：自定义**

**触发器时机：after/before   之后/之前**

**触发器动作：insert  update  delete**

**创建触发器：**

create trigger delstudent after delete on grade for each now

**delete from student where sid='4';**

delete from grade where sid=4;

mysql> select sid from student where sid=4;

Empty set

查看是否还有sid=4的值，可以发现已经被删除

## 八、事务

**单个逻辑单元执行的一系列操作，通过将一组操作组成一个，执行的时要么全部成功，要么全部失败，使程序更可靠，简化错误恢复。**

**MySQL 事务主要用于处理操作量大，复杂度高的数据。比如说，在人员管理系统中，你删除一个人员，你即需要删除人员的基本资料，也要删除和该人员相关的信息，如信箱，文章等等，这样，这些数据库操作语句就构成一个事务！**

在 MySQL 中只有使用了 Innodb 数据库引擎的数据库或表才支持事务。

事务处理可以用来维护数据库的完整性，保证成批的 SQL 语句要么全部执行，要么全部不执行。事务用来管理 insert,update,delete 语句。

MYSQL 事务处理主要有两种方法：

1、用 BEGIN, ROLLBACK, COMMIT来实现

**BEGIN** 开始一个事务

**ROLLBACK** 事务回滚

**COMMIT** 事务确认

2、直接用 SET 来改变 MySQL 的自动提交模式:

**SET AUTOCOMMIT=0** 禁止自动提交

**SET AUTOCOMMIT=1** 开启自动提交

创建事务

begin;

update books set bName="plyx" where bId=1；

update books set bName="plyx" where bId=2；

commit//

查看记录，已经修改了

select * from books;

## **九、mysql数据结构**

**主配置文件  my.cnf**

**数据目录：/var/lib/mysql**

**进程通信sock文件 ：/var/lib/mysql/mysql.sock**

**错误日志文件**

[**mysqld_safe]**

**log-error=/var/log/mysqld.log**

**进程PID文件：pid-file=/var/run/mysqld/mysqld.pid**

**二进制文件：log-bin=mysql-bin.log**

### **十.常见的存储引擎介绍**

**myisam :**

特性：
1、不支持事务，不支持外键，宕机时会破坏表

2、使用较小的内存和磁盘空间，访问速度快

3、基于表的锁，表级锁

4、mysql 只缓存index索引， 数据由OS缓存

**适用场景：日志系统，门户网站，低并发。**

**Innodb：**

特性：
1、具有提交，回滚，崩溃恢复能力的事务安全存储引擎

2、支持自动增长列，支持外键约束

3、占用更多的磁盘空间以保留数据和索引

4、不支持全文索引

**适用场景：需要事务应用，高并发，自动恢复，轻快基于主键操作**

**MEMORY：**

特性：
1、Memory存储引擎使用存在于内存中的内容来创建表。

2、每个memory表只实际对应一个磁盘文件，格式是.frm。memory类型的表访问非常的快，因为它的数据是放在内存中的，并且默认使用HASH索引，但是一旦服务关闭，表中的数据就会丢失掉。 

​3、MEMORY存储引擎的表可以选择使用BTREE索引或者HASH索引。