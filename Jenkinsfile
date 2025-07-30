pipeline {
    agent any

    parameters {
        string(name: 'BRANCH_NAME', defaultValue: 'main', description: 'Enter the branch to build')
    }

    environment {
        PEM_KEY_PATH = '"/c/Program Files/Jenkins/keys/jenkinsdeployment.pem"'
        EC2_USER = 'ubuntu'
        EC2_HOST = 'ec2-13-51-48-112.eu-north-1.compute.amazonaws.com'
        REPO_URL = 'https://github.com/sahilMahadik2002/jenkins-deployment.git'
        REMOTE_DEPLOY_DIR = '/tmp/react-build'
        NGINX_ROOT_DIR = '/var/www/html'
        GIT_BASH = '"C:\\Program Files\\Git\\bin\\bash.exe"'
    }

    stages {
        stage('Clone Repository') {
            steps {
                git branch: "${params.BRANCH_NAME}", url: "${env.REPO_URL}"
            }
        }

        stage('Install Dependencies') {
            steps {
                bat 'npm install'
            }
        }

        stage('Build Vite Project') {
            steps {
                bat 'npm run build'
            }
        }

        stage('Deploy to EC2') {
            steps {
                bat """
                "${env.GIT_BASH}" --login -c '
                    chmod 400 /c/Program\\ Files/Jenkins/keys/jenkinsdeployment.pem && \
                    echo "Copying dist to EC2..." && \
                    scp -o StrictHostKeyChecking=no -i /c/Program\\ Files/Jenkins/keys/jenkinsdeployment.pem -r dist/* ${env.EC2_USER}@${env.EC2_HOST}:${env.REMOTE_DEPLOY_DIR}/ && \
                    echo "SSH into EC2 and deploy..." && \
                    ssh -o StrictHostKeyChecking=no -i /c/Program\\ Files/Jenkins/keys/jenkinsdeployment.pem ${env.EC2_USER}@${env.EC2_HOST} \\
                        "sudo rm -rf ${env.NGINX_ROOT_DIR}/* && \
                        sudo cp -r ${env.REMOTE_DEPLOY_DIR}/* ${env.NGINX_ROOT_DIR}/ && \
                        sudo systemctl restart nginx"
                '
                """
            }
        }
    }

    post {
        success {
            echo "✅ Deployment to EC2 successful from branch: ${params.BRANCH_NAME}"
        }
        failure {
            echo "❌ Deployment failed for branch: ${params.BRANCH_NAME}"
        }
    }
}
