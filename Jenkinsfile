pipeline {
    agent any

    environment {
        IMAGE_NAME = 'ghcr.io/swethaptech-lgtm/devops-demo'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Show Files') {
            steps {
                sh 'pwd'
                sh 'ls -la'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t devops-demo:${BUILD_NUMBER} .'
            }
        }

        stage('Tag Docker Image') {
            steps {
                sh 'docker tag devops-demo:${BUILD_NUMBER} ${IMAGE_NAME}:${BUILD_NUMBER}'
            }
        }

        stage('Login to GHCR') {
            steps {
                withCredentials([
                    string(
                        credentialsId: 'github-ghcr-token',
                        variable: 'GHCR_TOKEN'
                    )
                ]) {
                    sh '''
                        set +x
                        echo "$GHCR_TOKEN" | docker login ghcr.io \
                          -u swethaptech-lgtm \
                          --password-stdin
                    '''
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                sh 'docker push ${IMAGE_NAME}:${BUILD_NUMBER}'
            }
        }
    }

    post {
        always {
            sh 'docker logout ghcr.io || true'
        }
    }
}
