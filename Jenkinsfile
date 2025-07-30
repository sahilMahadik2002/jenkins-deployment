pipeline {
    agent any

    parameters {
        string(name: 'BRANCH_NAME', defaultValue: 'main', description: 'Enter the branch to build')
        string(name: 'TARGET_ENVIRONMENT', defaultValue: 'prod', description: 'Target environment (e.g., dev, staging, prod)')
        string(name: 'VERSION', defaultValue: 'v1.0.0', description: 'Deployment version label')
    }

    environment {
        PEM_KEY_PATH = '/c/Program Files/Jenkins/keys/jenkinsdeployment.pem'
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
                ${env.GIT_BASH} -c "chmod 400 '${env.PEM_KEY_PATH}' && echo '📦 Backup current deployment...' && ssh -o StrictHostKeyChecking=no -i '${env.PEM_KEY_PATH}' ${env.EC2_USER}@${env.EC2_HOST} 'sudo mkdir -p /tmp/rollback-${params.TARGET_ENVIRONMENT} && sudo rm -rf /tmp/rollback-${params.TARGET_ENVIRONMENT}/* && sudo cp -r ${env.NGINX_ROOT_DIR}/* /tmp/rollback-${params.TARGET_ENVIRONMENT}/' && echo '📤 Uploading build...' && scp -o StrictHostKeyChecking=no -i '${env.PEM_KEY_PATH}' -r dist/* ${env.EC2_USER}@${env.EC2_HOST}:${env.REMOTE_DEPLOY_DIR}/ && echo '⚙️ Deploying new build...' && ssh -o StrictHostKeyChecking=no -i '${env.PEM_KEY_PATH}' ${env.EC2_USER}@${env.EC2_HOST} 'sudo rm -rf ${env.NGINX_ROOT_DIR}/* && sudo cp -r ${env.REMOTE_DEPLOY_DIR}/* ${env.NGINX_ROOT_DIR}/ && echo Deployed ${params.VERSION} to ${params.TARGET_ENVIRONMENT} on \$(date) | sudo tee ${env.NGINX_ROOT_DIR}/VERSION.txt && sudo systemctl restart nginx'"
                """

            }
        }
    }

    post {
        success {
            echo "✅ Deployment to EC2 successful from branch: ${params.BRANCH_NAME}"
        }

        failure {
            echo "❌ Deployment failed, attempting rollback..."
            bat """
            ${env.GIT_BASH} -c "chmod 400 '${env.PEM_KEY_PATH}' && ssh -o StrictHostKeyChecking=no -i '${env.PEM_KEY_PATH}' ${env.EC2_USER}@${env.EC2_HOST} 'sudo rm -rf ${env.NGINX_ROOT_DIR}/* && sudo cp -r /tmp/rollback-${params.TARGET_ENVIRONMENT}/* ${env.NGINX_ROOT_DIR}/ && echo Rolled back on \$(date) | sudo tee ${env.NGINX_ROOT_DIR}/VERSION.txt && sudo systemctl restart nginx'"
            """

        }
    }
}
