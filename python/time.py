#!/usr/bin/env pythn3


from datetime import datetime, timedelta

def time():
  now_time = datetime.now()
  utc_time = now_time - timedelta(hours=8)              # UTC只是比北京时间提前了8个小时
  utc_time = utc_time.strftime("%Y-%m-%dT%H:%M:%SZ")    # 转换成Aliyun要求的传参格式...
  print(utc_time)

if __name__ == "__main__":
  time()