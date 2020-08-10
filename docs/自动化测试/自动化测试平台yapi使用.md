### yapi　简介
#### yapi安装
#### yapi更新插件
```bash
# 克隆插件包
cd node_moudle && git clone https://github.com/shouldnotappearcalm/yapi-plugin-interface-oauth2-token.git
rm -rf node_module/yapi-plugin-interface-oauth2-token/.git
# 安装node-sass
su jenkins && cd /opt/yapi/scrm_yapi/vendor && npm install node-sass
# 安装插件
cd /opt/yapi/scrm_yapi && yapi plugin --name yapi-plugin-interface-oauth2-token
# 重启服务
pm2 restart /opt/yapi/scrm_yapi/vendors/server/app.js
```
