pipeline {
    agent any

    stage('Build Docker Image') {
            echo 'docker'
            sh "docker compose up"          
        }

    stage('Push Docker Image') {

        withCredentials([string(credentialsId: 'docker_hun_credential', variable: 'DOCKER_HUB_CREDENTIALS')]) {
              sh "docker login -u bkt92 -p ${DOCKER_HUB_CREDENTIALS}"
          }
       sh "docker push bkt92/hello-nginx"
    }
}
