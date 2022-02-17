#!/usr/bin/env python3 

class XiaoMing:
    first_name = '明'
    last_name = '小'

    @property
    def full_name(self):
        return self.last_name + self.first_name

xiaoming = XiaoMing()
print(xiaoming.full_name)