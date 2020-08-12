## oracle服务器安装
```shell
# 使用docker安装oracle服务器
#!/bin/bash
docker stop oracle
docker rm -f oracle
docker run -d  \
    --name oracle \
    -v /data/oracle_data:/data/oracle_data \
    -p 49170:22 \
    -p 49171:1521 \
    -e ORACLE_ALLOW_REMOTE=true \
    --restart=always \
    bizybot/docker-oracle-xe-11g
```
## oracle数据导入
### 导入前工作
```shell
# 创建数据目录
ssh root@127.0.0.1 -p 49160 密码为 admin
mkdir /data/oracle_data/backup
# 登录数据库
sqlplus / as sysdba
select a.tablespace_name,a.bytes/1024/1024 "sum MB",  (a.bytes-b.bytes)/1024/1024 "used MB",b.bytes/1024/1024 "free MB",round (((a.bytes-b.bytes)/a.bytes)*100,2) "used%" from (select tablespace_name,sum(bytes) bytes from dba_data_files group by tablespace_name) a, (select tablespace_name,sum(bytes) bytes,max (bytes) largest from dba_free_space group by tablespace_name)b where a.tablespace_name=b.tablespace_name order by ((a.bytes-b.bytes)/a.bytes) desc;
# 创建临时表空间
create temporary tablespace 临时表空间名 tempfile ‘临时表空间位置’ size 临时表空间大小autoextend on next 100m maxsize 102400m extent management local;
create temporary tablespace TEST_temp tempfile'/opt/oracle/oradata/TEST_temp.dbf' size 1024m autoextend on next 100m  extent management local;
# 创建数据库表空间
create tablespace TEST logging datafile '/opt/oracle/oradata/TEST.dbf' size 1024m autoextend on next 100m  extent management local;
# 为表空间怎能更加数据文件
alter tablespace TEST add datafile '/data/oracle_data/test/TEST.dbf' size 1024m autoextend on next 100m maxsize unlimited;
# 设置表空间自动拓展
alter tablespace SPS_DATA add datafile '/home/oracle/app/oradata/snail/SPS_DATA02.dbf' size 2000m autoextend on next 200M maxsize 12000M;
# 创建用户指定表空间
create user  SI0001 identified by mikel_2019 default tablespace TEST temporary tablespace TEST_temp;
create user  test identified by mikel_2019 default tablespace TEST temporary tablespace TEST_temp;
# 给用户指定表空间
alter user test default tablespace TEST temporary tablespace TEST_temp;
alter user SI0001 default tablespace TEST temporary tablespace TEST_temp;
alter user test default tablespace TEST_temp;
# 给用户指定权限
grant create user,drop user,alter user ,create any view ,drop any view,exp_full_database,imp_full_database,dba,connect,resource,create session to test;
```
### 采用exp/imp命令
**导出命令**
```shell
# 完全漠视导出
exp system/manager buffer=32000 file=d:\iom.dmp full=y 
# 指定用户导出
exp iom/iom   buffer=32000 file=d:\iom.dmp owner=iom
# 表模式导出
exp iom/iom    buffer=32000 file=d:\iom.dmp owner=iom tables=(iom)
```
**导出/导入步骤**
```shell
# 导出步骤
su - oracle
exp iom/iom file=iom.dmp log=oradb.log full=y compress=y direct=y 
# 导入步骤
su - oracle
imp test/mikel_2019 file=/opt/oracle/oradata/backup/rsdata_0527.dmp log=/opt/oracle/oradata/backup/rsdata_0527.log full=y ignore=y;
imp test/mikel_2019 file=/opt/oracle/oradata/backup/taianjm_0605.dmp log=/opt/oracle/oradata/backup/taianjm_0605.dmp.log full=y ignore=y;
```
### 使用nacitiv导入

#### nacitiv 连接
```shell
# 连接方式
hostname: localhost
port: 49171
sid: xe
username: system
password: oracle
```
#### nacitiv导入

##### 在nacitiv中，创建目录并付给权限，将数据导入dump文件拷贝到数据目录中，在执行数据榜导入

### oracle 修改字符集
```shell
# 修改客户端字符集
select parameter,value from nls_database_parameters where parameter in('NLS_LANGUAGE','NLS_TERRITORY','NLS_CHARACTERSET');
select to_char(nls_charset_id('ZHS16GBK'), 'xxxx') from dual;
export NLS_LANG=AMERICAN_AMERICA.ZHS16GBK
# 修改服务端字符集
SQL> su oracle
SQL> sqlplus test/test
SQL> startup mount        
SQL> shutdown immediate; 
SQL> startup mount;    
SQL> alter session set sql_trace=true; 
SQL> alter system enable restricted session; 
SQL> alter system set job_queue_processes=0; 
SQL> alter system set aq_tm_processes=0; 
SQL> alter database open; 
SQL> ALTER DATABASE character set INTERNAL_USE ZHS16GBK;AL16UTF16 ZHS16GBK --修改字符集AL32UTF8->ZHS16GBK 
SQL> shutdown immediate;        --再次关闭数据库 
SQL> STARTUP;            --启动数据库 
SQL> select * from v$nls_parameters where parameter = 'NLS_CHARACTERSET'; 
```
### 表空间删除重建
```shell
SELECT distinct owner, segment_type, segment_name FROM dba_segments WHERE tablespace_name='TEST';
DROP TABLESPACE TEST INCLUDING CONTENTS AND DATAFILES;
DROP TABLESPACE TEST_TEMP INCLUDING CONTENTS AND DATAFILES;
ALTER TABLESPACE TEST SHRINK SPACE KEEP xxxxxM;
```