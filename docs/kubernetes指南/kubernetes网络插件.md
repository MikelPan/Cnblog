### 阿里云网络插件
Terway网络插件是ACK自研的网络插件，将原生的弹性网卡分配给Pod实现Pod网络，支持基于Kubernetes标准的网络策略（Network Policy）来定义容器间的访问策略，并兼容Calico的网络策略。

在Terway网络插件中，每个Pod都拥有自己网络栈和IP地址。同一台ECS内的Pod之间通信，直接通过机器内部的转发，跨ECS的Pod通信、报文通过VPC的弹性网卡直接转发。由于不需要使用VxLAN等的隧道技术封装报文，因此Terway模式网络具有较高的通信性能。

![](https://help-static-aliyun-doc.aliyuncs.com/assets/img/zh-CN/4385659951/p32414.png)


