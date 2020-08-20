pipeline {
   agent {
       docker {

           label 'mvn-1'
           image: 'registry.jt7t.cn/maven:3.6.3-jdk-8-slim'
           args: '-v /root/.m2:/root/.m2 -v /var/run/docker.sock:/var/run/docker.sock'
       }
       docker {
           label 'mvn-2'
           image: 'registry.jt7t.cn/maven:3.6.3-jdk-8-slim'
           args: '-v /root/.m2:/root/.m2 -v /var/run/docker.sock:/var/run/docker.sock'
       }
   }

   stages {
    //   options { retry(2) }
       stage('Test') {
         when {
           branch 'dev'
         }
         agent label {'mvn-1'}
         steps {
             sh 'mvn clean package -Dmaven.test.skip=true'
         }
      }
    }
}