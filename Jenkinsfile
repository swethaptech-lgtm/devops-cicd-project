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

        stage('Terraform Init') {
            steps {
                dir('terraform') {
                    sh 'terraform init -reconfigure'
                }
            }
        }

        stage('Terraform Validate') {
            steps {
                dir('terraform') {
                    sh '''
                        terraform fmt -check
                        terraform validate
                    '''
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                dir('terraform') {
                    script {
                        def planStatus = sh(
                            script: 'terraform plan -detailed-exitcode -out=tfplan',
                            returnStatus: true
                        )

                        if (planStatus == 0) {
                            echo 'Terraform: No infrastructure changes detected.'
                            env.TF_CHANGES = 'false'
                        } else if (planStatus == 2) {
                            echo 'Terraform: Infrastructure changes detected.'
                            env.TF_CHANGES = 'true'

                            sh 'terraform show -no-color tfplan'
                        } else {
                            error 'Terraform plan failed.'
                        }
                    }
                }
            }
        }

        stage('Approve Terraform Apply') {
            when {
                expression {
                    env.TF_CHANGES == 'true'
                }
            }

            steps {
                input message: 'Apply Terraform infrastructure changes?', ok: 'Apply'
            }
        }

        stage('Terraform Apply') {
            when {
                expression {
                    env.TF_CHANGES == 'true'
                }
            }

            steps {
                dir('terraform') {
                    sh 'terraform apply -auto-approve tfplan'
                }
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

        stage('Deploy to Kubernetes') {
            steps {
                sh '''
                    kubectl set image deployment/devops-demo \
                      devops-demo=${IMAGE_NAME}:${BUILD_NUMBER} \
                      -n devops-demo
                '''
            }
        }

        stage('Verify Deployment') {
            steps {
                sh '''
                    kubectl rollout status deployment/devops-demo \
                      -n devops-demo \
                      --timeout=120s
                '''

                sh '''
                    kubectl get pods \
                      -n devops-demo \
                      -o wide
                '''
            }
        }
    }

    post {
        always {
            sh 'docker logout ghcr.io || true'
        }
    }
}


