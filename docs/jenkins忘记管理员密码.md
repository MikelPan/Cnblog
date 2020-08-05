### 忘记Jenkins管理员密码的解决办法
#### admin密码未更改情况

1.进入\Jenkins\secrets目录，打开initialAdminPassword文件，复制密码；

2.访问Jenkins页面，输入管理员admin，及刚才的密码；

3.进入后可更改其他管理员密码；

#### admin密码更改忘记情况

删除Jenkins目录下config.xml文件中下面代码，并保存文件.
```xml
 <useSecurity>true</useSecurity>
  <authorizationStrategy class="hudson.security.FullControlOnceLoggedInAuthorizationStrategy">
    <denyAnonymousReadAccess>true</denyAnonymousReadAccess>
  </authorizationStrategy>
  <securityRealm class="hudson.security.HudsonPrivateSecurityRealm">
    <disableSignup>true</disableSignup>
    <enableCaptcha>false</enableCaptcha>
  </securityRealm>
```
重启Jenkins服务

进入首页>“系统管理”>“Configure Global Security”

勾选“启用安全”

点选“Jenkins专有用户数据库”，并点击“保存”

重新点击首页>“系统管理”,发现此时出现“管理用户”

点击进入展示“用户列表”

点击右侧进入修改密码页面，修改后即可重新登录