pipeline {
   agent any

   stages {
    //   options { retry(2) }
       stage('Test') {
         when {
           branch 'dev'
         }
         steps {
             echo 'Hello,world!'

         }
      }
    }
}