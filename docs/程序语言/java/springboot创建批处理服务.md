##
### 初始化项目
- 初始化基础项目结构
```bash
# 使用spring boot cli初始化项目
spring init -d=batch --build=gradle --name devops --java-version 1.8 --groupId cn.jt7t.springboot --artifactId springboot-devops --language java --boot-version 2.3.2.RELEASE --type gradle-project --extract
```
- 编写业务类
```java
package com.example.batchprocessing;

public class Person {

  private String lastName;
  private String firstName;

  public Person() {
  }

  public Person(String firstName, String lastName) {
    this.firstName = firstName;
    this.lastName = lastName;
  }

  public void setFirstName(String firstName) {
    this.firstName = firstName;
  }

  public String getFirstName() {
    return firstName;
  }

  public String getLastName() {
    return lastName;
  }

  public void setLastName(String lastName) {
    this.lastName = lastName;
  }

  @Override
  public String toString() {
    return "firstName: " + firstName + ", lastName: " + lastName;
  }

}
```
