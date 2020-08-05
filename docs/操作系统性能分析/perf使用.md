### perf数据采集
```bash
yum install -y perf
```
### 用 perf 生成火焰图
#### 安装
```bash
git clone https://github.com/brendangregg/FlameGraph
```
#### perf采集数据
```bash
# 采集数据
perf record -F 99 -p 4480 -g -- sleep 30
perf record -e cpu-clock -p 4480 -g -- sleep 30
# 查看报告
perf report -i perf.data
# 折叠
perf script -i perf.data &> perf.unfold
# 生产火焰图
stackcollapse-perf.pl perf.unfold &> perf.folded
# 生成svg图
./flamegraph.pl perf.folded > perf.svg
```

