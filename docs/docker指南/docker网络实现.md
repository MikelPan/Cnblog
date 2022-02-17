Docker支持4类网络模式，kubernetes通常只会使用bridge模式
- host模式 --net=host指定
- container模式 --net=container:NAME_or_ID指定
- none模式 --net=none指定
- bridge模式 --net=bridge指定，为默认设置

