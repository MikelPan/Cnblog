## 工具Explain
在详细总结MySQL的索引优化策略之前，先给大家介绍一个工具，方便在查慢查询的过程，排查大部分的问题：Explain。有关Explain的详细介绍，可以查看官网地址：
dev.mysql.com/doc/refman/… 。这里再给大家推荐一个学习方法，就是一定要去官网学习第一手资料，如果觉得英语阅读有挑战的朋友，建议还是平时都积累看看英文文章，英语对于程序员来说很重要，先进的技术和理论很多资料都是英文版，而官网也是非常全的，要想成为技术大牛，这是必须需要修炼的。
扯淡就到这里，下面我简单描述一下Explain怎么使用。
举例：

```sql
mysql> explain select * from user where name="xiao" and age=9099 and birthday="1980-08-02";
```