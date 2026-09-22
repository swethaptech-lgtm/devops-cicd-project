
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
                input message: 'Apply Terraform infrastructure changes?',
                      ok: 'Apply'
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

        stage('Trivy Security Scan') {
            steps {
                sh '''
                    trivy image \
                      --severity CRITICAL \
                      --exit-code 1 \
                      devops-demo:${BUILD_NUMBER}
                '''
            }
        }

        stage('Create Build Artifact') {
            steps {
                sh '''
                    tar -czf devops-demo-${BUILD_NUMBER}.tar.gz \
                        app Dockerfile

                    ls -lh devops-demo-${BUILD_NUMBER}.tar.gz
                '''
            }
        }

        stage('Upload Artifact to Nexus') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'nexus-credentials',
                        usernameVariable: 'NEXUS_USER',
                        passwordVariable: 'NEXUS_PASSWORD'
                    )
                ]) {
                    sh '''
                        set +x

                        curl --fail --show-error --silent \
                          --retry 3 \
                          --user "$NEXUS_USER:$NEXUS_PASSWORD" \
                          --upload-file "devops-demo-${BUILD_NUMBER}.tar.gz" \
                          "http://localhost:8081/repository/devops-artifacts/builds/${BUILD_NUMBER}/devops-demo-${BUILD_NUMBER}.tar.gz"

                        echo "Artifact uploaded to Nexus successfully."
                    '''
                }
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

        stage('Deploy Helm Application') {
            steps {
                sh '''
                    helm upgrade --install devops-demo-helm \
                      ./helm/devops-demo \
                      --namespace devops-demo-helm \
                      --create-namespace \
                      --set image.tag=${BUILD_NUMBER}
                '''
            }
        }

        stage('Verify Helm Deployment') {
            steps {
                sh '''
                    kubectl rollout status deployment/devops-demo \
                      -n devops-demo-helm \
                      --timeout=120s
                '''

                sh '''
                    kubectl get pods \
                      -n devops-demo-helm \
                      -o wide
                '''

                sh '''
                    helm status devops-demo-helm \
                      -n devops-demo-helm
                '''
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
        success {
            emailext(
                to: 'swethahp12345@gmail.com',
                subject: "SUCCESS: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: """
Jenkins CI/CD Pipeline Completed Successfully!

Job Name: ${env.JOB_NAME}
Build Number: ${env.BUILD_NUMBER}
Status: SUCCESS

Docker Image:
${env.IMAGE_NAME}:${env.BUILD_NUMBER}

Build Details:
${env.BUILD_URL}
"""
            )
        }

        failure {
            emailext(
                to: 'swethahp12345@gmail.com',
                subject: "FAILED: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: """
Jenkins CI/CD Pipeline Failed!

Job Name: ${env.JOB_NAME}
Build Number: ${env.BUILD_NUMBER}
Status: FAILURE

Check the Jenkins console output:
${env.BUILD_URL}
"""
            )
        }

        always {
            sh 'docker logout ghcr.io || true'
        }
    }
}
