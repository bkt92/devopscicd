pipeline {
    agent any
    environment {
        DOCKER_AUTH = credentials('docker_hun_credential')
    }

    stages {
    stage('Build Docker Image') 
    {
    steps {
            sh "docker build -t bkt92/hello-nginx:master ./hello-nginx"        
        }
    }

    stage('Push Docker Image') {
        steps{
              sh 'docker login -u $DOCKER_AUTH_USR -p $DOCKER_AUTH_PSW'
       sh "docker push bkt92/hello-nginx:master"
        }
    }
    }
}
