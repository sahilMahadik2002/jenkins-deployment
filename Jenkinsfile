pipeline {
    agent any

    parameters {
        string(name: 'GIT_BRANCH', defaultValue: 'main', description: 'Git branch to deploy')
    }

    environment {
        SSH_USER = 'ubuntu'
        SSH_HOST = credentials('EC2_HOST_PROD')
        SSH_KEY = credentials('EC2_SSH_KEY_PROD')
        GIT_BASH = '"C:\\Program Files\\Git\\bin\\bash.exe"'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: "${params.GIT_BRANCH}", url: 'https://github.com/sahilMahadik2002/jenkins-deployment.git'
            }
        }

        stage('Build') {
            steps {
                bat '"C:\\Program Files\\Git\\bin\\bash.exe" build/build.sh'
            }
        }

        stage('Deploy') {
            environment {
                SSH_HOST = credentials('EC2_HOST_PROD') // Injects your EC2 host string
            }
            steps {
                sshagent(credentials: ['EC2_SSH_KEY_PROD']) {
                    sh '''
                        echo "Uploading build to remote server..."
                        scp -o StrictHostKeyChecking=no -r build/ ubuntu@$SSH_HOST:/tmp/build

                        echo "Running deploy script on remote server..."
                        ssh -o StrictHostKeyChecking=no ubuntu@$SSH_HOST 'bash -s' < deploy/deploy.sh /var/www/myapp
                    '''
                }
            }
            post {
                failure {
                    echo 'Deployment failed! Rolling back...'
                    sshagent(credentials: ['EC2_SSH_KEY_PROD']) {
                        sh '''
                            ssh -o StrictHostKeyChecking=no ubuntu@$SSH_HOST 'bash -s' < deploy/rollback.sh /var/www/myapp
                        '''
                    }
                }
            }
        }
        
    post {
        success {
            echo "Deployment successful on branch: ${params.GIT_BRANCH}"
        }
        failure {
            echo "Deployment failed on branch: ${params.GIT_BRANCH}"
        }
    }
}
