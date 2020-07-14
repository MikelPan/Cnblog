#!/bin/bash
mouth=`date +"%y%m"`
day=`date +"%d"`
time=`date +"%F_%H:%M"`
Htime=`date +"%F_%H"`
daytime=`date +"%Y%m%d"`
mysqlrootpwd='password'
mysql_dir=/data/mysql_back
backlog=/work/Monitoring/checksqlback
hostIP=192.168.123.30
# 全量备份
automysqldump="mysqldump  --default-character-set=utf8 --routines --opt -uroot -p$mysqlrootpwd -h$hostIP -P3306"
mkdir -p $mysql_dir/$mouth
mkdir -p $backlog
cd $backlog && touch $daytime.log
get_datename_info()
{
cat << 'EOF' > /work/Monitoring/proc_name-to-dbname
society_operation_foundation society_operation_foundation
society_operation_user society_operation_user
EOF
}
dump_mysql()
{
for i in `awk '{print $1}' /work/Monitoring/proc_name-to-dbname`
	do
        dataname=`awk -v I="$i" '{if(I==$1)print $2}' /work/Monitoring/proc_name-to-dbname`
 	$automysqldump $dataname > $mysql_dir/$mouth/$dataname.$daytime.sql
		if [ $? -eq 0 ];then
        		echo "mysql $time backup ok " >> $backlog/$daytime.log
        	else
        		echo "mysql $time backup failed" >> $backlog/$daytime.log
        	fi
        cd $mysql_dir/$mouth
        tar zcf $dataname-$daytime.sql.tgz $dataname.$daytime.sql --remove-files
        done
cd $mysql_dir/$mouth
find -name "*.tgz" -mtime +3 -exec rm {} \;
}
get_datename_info
dump_mysql
# 创建定时任务
0 1 * * * sh /work/sh/mysql_back.sh > /dev/null 2>&1