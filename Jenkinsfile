pipeline {
    agent any

    stages {
    stage('Build Docker Image') 
    {
    steps {
            sh "docker compose up"          
        }
    }

    stage('Push Docker Image') {
        steps{
            withCredentials([string(credentialsId: 'docker_hun_credential', variable: 'DOCKER_HUB_CREDENTIALS')]) {
              sh "docker login -u bkt92 -p ${DOCKER_HUB_CREDENTIALS}"
          }
       sh "docker push bkt92/hello-nginx"
        }
    }
    }
}
