### ansible galaxy 使用
[社区网站](https://galaxy.ansible.com)
```bash
ansible-galaxy collection install -p . ordidaad.jenkins
```

### ansible tower
```bash
# 安装
wget https://releases.ansible.com/ansible-tower/setup-bundle/ansible-tower-setup-bundle-3.7.0-4.tar.gz -F /apps/software
tar -zvxf ansible-tower-setup-bundle-3.2.6-1.el7.tar.gz -C /usr/local/src
mv /usr/local/src/ansible-tower-setup-bundle-3.2.6-1.el7 /usr/local/ansible-tower
cd /usr/local/ansible-tower
cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 24 |tee /root/pg_pwd.log
sed -i "s#password=''#password=$(cat /root/pg_pwd.log)#g" inventory 
sed -i "s#host=''#host='127.0.0.1'#g" inventory
sed -i "s#port=''#port='5432'#g" inventory
mkdir -p /var/log/tower
# nginx 修改监听端口
sed -i 's/80/7777/g' /usr/local/ansible-tower/roles/nginx/defaults/main.yml
# nginx 关闭https
./setup.sh -e nginx_disable_https=true
# 破解
pip3 install uncompyle6
cd /var/lib/awx/venv/awx/lib/python3.6/site-packages/tower_license
uncompyle6 __init__.pyc >__init__.py
## _check_cloudforms_subscription方法修改如下内容,特别需要注意格式。
    def _check_cloudforms_subscription(self):
## 只需要添加下面一行直接返回 True即可。注意格式要跟if对对齐。
        return True
        if os.path.exists('/var/lib/awx/i18n.db'):
            return True
        else:
            if os.path.isdir('/opt/rh/cfme-appliance'):
                if os.path.isdir('/opt/rh/cfme-gemset'):
                    pass
            try:

## 修改"license_date=253370764800L" 为 "license_date=253370764800"
    def _generate_cloudforms_subscription(self):
        self._attrs.update(dict(company_name='Red Hat CloudForms License', instance_count=9999999,
          license_date=253370764800,            # 只需要修改这一行
          license_key='xxxx',
          license_type='enterprise',
          subscription_name='Red Hat CloudForms License'))
# 重新编译
python3 -m py_compile __init__.py
python3 -O -m py_compile __init__.py
ansible-tower-service restart
```

### ansible tower cli 使用
#### 配置
```bash
pip install ansible-tower-cli
# 配置
tower-cli config host tower.example.com
tower-cli config username tower.example.com
tower-cli config password password
#取消ssl
tower-cli config verify_ssl false
#导入主机信息
awx-manage inventory_import --source=inventory --inventory-name=member-data-inventory --overwrite --overwrite-vars
#创建inventory
tower-cli inventory create -n uat-member-scrm-inventory --organization xxx
# 配置job
tower-cli job_template modify 9 --job-tags build,deploy,rollback  -e ENV=test -e PORT=8186 -e job_name=xxxxx -e code_name=xxxxx -e PKG_NAME=xxxxx
-- 9 job_template id 号
-- job-tags 执行的tags
-- -e 额外的传递的参数
```
#### 执行job
```bash
# 执行
tower-cli job_template list
tower-cli job lanch job_template_id
# 删除job
for i in `seq 1 200`;do tower-cli delete $i;done
```
#### psql使用
```bash
# 登陆
su - awx;psql
# 控制台命令
\h：查看SQL命令的解释，比如\h select。
\?：查看psql命令列表。
\l：列出所有数据库。
\c [database_name]：连接其他数据库。
\d：列出当前数据库的所有表格。
\d [table_name]：列出某一张表格的结构。
\du：列出所有用户。
\e：打开文本编辑器。
\conninfo：列出当前数据库和连接的信息。
# 数据库操作
## 创建新表
CREATE TABLE user_tbl(name VARCHAR(20), signup_date DATE);

## 插入数据
INSERT INTO user_tbl(name, signup_date) VALUES('张三', '2013-12-22');

## 选择记录
SELECT * FROM user_tbl;

## 更新数据
UPDATE user_tbl set name = '李四' WHERE name = '张三';

## 删除记录
DELETE FROM user_tbl WHERE name = '李四' ;

## 添加栏位
ALTER TABLE user_tbl ADD email VARCHAR(40);

## 更新结构
ALTER TABLE user_tbl ALTER COLUMN signup_date SET NOT NULL;

## 更名栏位
ALTER TABLE user_tbl RENAME COLUMN signup_date TO signup;

## 删除栏位
ALTER TABLE user_tbl DROP COLUMN email;

## 表格更名
ALTER TABLE user_tbl RENAME TO backup_tbl;

## 删除表格
DROP TABLE IF EXISTS backup_tbl;
```

