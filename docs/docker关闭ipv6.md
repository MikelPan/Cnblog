打开 /etc/default/grub，
找到 GRUB_CMDLINE_LINUX="..." 或者有的叫做 GRUB_CMDLINE_LINUX_DEFAULT="..."。

```bash
GRUB_CMDLINE_LINUX="ipv6.disable=1  ..."
GRUB_CMDLINE_LINUX_DEFAULT="ipv6.disable=1  ..."
```
将 ipv6.disable=1 加入到最前面，注意与后面的其他值空格隔开
执行如下命令
```bash
grub2-mkconfig -o /boot/grub2/grub.cfg
```
该命令会重新生成一个引导文件，覆盖掉现有的文件

reboot
重启系统