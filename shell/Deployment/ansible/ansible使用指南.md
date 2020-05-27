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
pwd=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 24`
sed -i "s#password=''#password='I30Jy41qVYX7TFh5TWMCFWB8'#g" inventory 
sed -i "s#host=''#host='127.0.0.1'#g" inventory
sed -i "s#port=''#port='5432'#g" inventory
mkdir -p /var/log/tower
./setup.sh
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


