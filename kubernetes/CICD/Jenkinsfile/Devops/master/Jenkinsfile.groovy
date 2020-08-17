pipeline {
   agent any

    stages {
    //   options { retry(2) }
      stage('Test') {
         steps {
             echo 'Hello,world!'

         }
      }
    }
}


