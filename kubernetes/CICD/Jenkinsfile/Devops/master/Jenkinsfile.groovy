pipeline {
   agent any

   parameters {
       choice(
         description: '发布指定的分支\n说明:\n默认值master',
         name: 'BRANCH', 
         choices: ['master','uat']
       )
   }

   stages {
    //   options { retry(2) }
       stage('Test') {
         steps {
             echo 'Hello,world!'

         }
      }
    }
}


