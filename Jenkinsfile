pipeline {
    agent any

    parameters {
        string(name: 'DEPLOY_VERSION', defaultValue: 'v1.0.0', description: 'Deployment version')
        string(name: 'GIT_BRANCH', defaultValue: 'main', description: 'Git branch to deploy')
        choice(name: 'ENVIRONMENT', choices: ['prod'], description: 'Target environment')
    }

    environment {
        SSH_USER = 'ubuntu'
        SSH_HOST = credentials("EC2_HOST_PROD")
        SSH_KEY = credentials("EC2_SSH_KEY_PROD")
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: "${params.GIT_BRANCH}", url: 'https://github.com/your-user/your-react-app.git'
            }
        }

        stage('Build') {
            steps {
                sh 'bash build/build.sh'
            }
        }

        stage('Deploy') {
            steps {
                script {
                    try {
                        // Upload built files to EC2
                        sh """
                            scp -i ${SSH_KEY} -r build/ ${SSH_USER}@${SSH_HOST}:/tmp/build
                            ssh -i ${SSH_KEY} ${SSH_USER}@${SSH_HOST} 'bash -s' < deploy/deploy.sh /var/www/myapp
                        """
                    } catch (err) {
                        echo "Deployment failed! Rolling back..."
                        sh """
                            ssh -i ${SSH_KEY} ${SSH_USER}@${SSH_HOST} 'bash -s' < deploy/rollback.sh /var/www/myapp
                        """
                        error("Deployment failed and rollback executed.")
                    }
                }
            }
        }
    }
}
