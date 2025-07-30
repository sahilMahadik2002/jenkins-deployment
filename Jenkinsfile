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
                git branch: "${params.GIT_BRANCH}", url: 'https://github.com/Shital-Lanke/Devops_Learning.git'
            }
        }

        stage('Build') {
            steps {
                bat '"C:\\Program Files\\Git\\bin\\bash.exe" build/build.sh'
            }
        }

        stage('Deploy') {
            steps {
                script {
                    try {
                        bat """
                        ${GIT_BASH} -c "chmod 400 ${SSH_KEY} && \
                        scp -o StrictHostKeyChecking=no -i ${SSH_KEY} -r build/ ${SSH_USER}@${SSH_HOST}:/tmp/build && \
                        ssh -o StrictHostKeyChecking=no -i ${SSH_KEY} ${SSH_USER}@${SSH_HOST} 'bash -s' < deploy/deploy.sh /var/www/myapp"
                        """
                    } catch (err) {
                        echo "Deployment failed! Rolling back..."
                        bat """
                        ${GIT_BASH} -c "ssh -o StrictHostKeyChecking=no -i ${SSH_KEY} ${SSH_USER}@${SSH_HOST} 'bash -s' < deploy/rollback.sh /var/www/myapp"
                        """
                        error("Deployment failed and rollback executed.")
                    }
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
