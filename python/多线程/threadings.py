import threading
from datetime import datetime
import time


def thread_func():  # 线程函数
    # time.sleep(1)
    i = 0
    while(1):
        print(datetime.now())
        i += 1


def many_thread():
    threads = []
    for _ in range(10):  # 循环创建500个线程
        t = threading.Thread(target=thread_func)
        threads.append(t)
        t.setDaemon(True)  # 给每个子线程添加守护线程
    for t in threads:  # 循环启动500个线程
        t.start()
    # for t in threads:
    #     t.join(2)  # 设置子线程超时2秒


if __name__ == '__main__':
    many_thread()
    print("thread end")
