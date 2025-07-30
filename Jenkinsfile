pipeline {
    agent any
    
    parameters {
        string(
            name: 'DEPLOYMENT_VERSION',
            defaultValue: 'v1.0.0',
            description: 'Version tag for this deployment (e.g., v1.0.0, v2.1.3)'
        )
        string(
            name: 'GIT_BRANCH',
            defaultValue: 'main',
            description: 'Git branch to deploy from'
        )
        choice(
            name: 'TARGET_ENVIRONMENT',
            choices: ['dev', 'staging', 'prod'],
            description: 'Target deployment environment'
        )
        booleanParam(
            name: 'SKIP_TESTS',
            defaultValue: false,
            description: 'Skip tests during build process'
        )
        booleanParam(
            name: 'FORCE_DEPLOY',
            defaultValue: false,
            description: 'Force deployment even if version already exists'
        )
    }
    
    environment {
        // Common settings
        REPO_URL = 'https://github.com/sahilMahadik2002/jenkins-deployment.git'
        PEM_KEY_PATH = 'C:\\Program Files\\Jenkins\\keys\\jenkinsdeployment.pem'
        TIMESTAMP = "${new Date().format('yyyy-MM-dd-HH-mm-ss')}"
        BUILD_ID = "${params.DEPLOYMENT_VERSION}-${env.BUILD_NUMBER}-${TIMESTAMP}"
        
        // Environment-specific configurations
        DEV_HOST = 'ec2-13-51-48-112.eu-north-1.compute.amazonaws.com'
        STAGING_HOST = 'ec2-13-51-48-112.eu-north-1.compute.amazonaws.com'
        PROD_HOST = 'ec2-13-51-48-112.eu-north-1.compute.amazonaws.com'
        
        DEV_USER = 'ubuntu'
        STAGING_USER = 'ubuntu'
        PROD_USER = 'ubuntu'
        
        // Paths on target servers
        REMOTE_APP_DIR = '/opt/react-app'
        REMOTE_BACKUP_DIR = '/opt/backups'
        NGINX_ROOT_DIR = '/var/www/html'
        
        // Deployment settings
        MAX_BACKUPS = '5'
        HEALTH_CHECK_TIMEOUT = '60'
    }
    
    stages {
        stage('Initialize Deployment') {
            steps {
                script {
                    // Set environment-specific variables
                    switch(params.TARGET_ENVIRONMENT) {
                        case 'dev':
                            env.TARGET_HOST = env.DEV_HOST
                            env.TARGET_USER = env.DEV_USER
                            env.ENV_COLOR = '🟡'
                            break
                        case 'staging':
                            env.TARGET_HOST = env.STAGING_HOST
                            env.TARGET_USER = env.STAGING_USER
                            env.ENV_COLOR = '🟠'
                            break
                        case 'prod':
                            env.TARGET_HOST = env.PROD_HOST
                            env.TARGET_USER = env.PROD_USER
                            env.ENV_COLOR = '🔴'
                            break
                    }
                    
                    echo """
                    🚀 DEPLOYMENT INITIALIZATION
                    ================================
                    ${env.ENV_COLOR} Environment: ${params.TARGET_ENVIRONMENT.toUpperCase()}
                    📦 Version: ${params.DEPLOYMENT_VERSION}
                    🌿 Branch: ${params.GIT_BRANCH}
                    🎯 Target: ${env.TARGET_HOST}
                    🆔 Build ID: ${env.BUILD_ID}
                    ================================
                    """
                }
            }
        }

        stage('Pre-deployment Checks') {
            steps {
                script {
                    echo "🔍 Running pre-deployment checks..."
                    
                    // Check if version already exists (unless forced)
                    if (!params.FORCE_DEPLOY) {
                        bat """
                        echo "Checking if version ${params.DEPLOYMENT_VERSION} already exists..."
                        "C:\\Program Files\\Git\\bin\\bash.exe" -c "chmod 400 '${env.PEM_KEY_PATH}'"
                        """
                        
                        def versionExists = bat(
                            script: "\"C:\\Program Files\\Git\\bin\\bash.exe\" -c \"ssh -o StrictHostKeyChecking=no -i '${env.PEM_KEY_PATH}' ${env.TARGET_USER}@${env.TARGET_HOST} 'test -d ${env.REMOTE_BACKUP_DIR}/${params.DEPLOYMENT_VERSION} && echo EXISTS || echo NOT_EXISTS'\"",
                            returnStdout: true
                        ).trim()
                        
                        if (versionExists.contains('EXISTS')) {
                            error("❌ Version ${params.DEPLOYMENT_VERSION} already exists in ${params.TARGET_ENVIRONMENT}. Use FORCE_DEPLOY to override.")
                        }
                    }
                    
                    echo "✅ Pre-deployment checks passed"
                }
            }
        }
        
        stage('Backup Current Version') {
            steps {
                script {
                    echo "📦 Creating backup of current deployment..."
                    
                    bat """
                    "C:\\Program Files\\Git\\bin\\bash.exe" -c "ssh -o StrictHostKeyChecking=no -i '${env.PEM_KEY_PATH}' ${env.TARGET_USER}@${env.TARGET_HOST} 'sudo mkdir -p ${env.REMOTE_BACKUP_DIR}/versions && sudo mkdir -p ${env.REMOTE_BACKUP_DIR}/snapshots && CURRENT_VERSION=\\\$(sudo cat ${env.NGINX_ROOT_DIR}/.version 2>/dev/null || echo no-version) && echo Current version: \\\$CURRENT_VERSION && if [ -f ${env.NGINX_ROOT_DIR}/index.html ]; then echo Creating snapshot backup... && sudo cp -r ${env.NGINX_ROOT_DIR} ${env.REMOTE_BACKUP_DIR}/snapshots/pre-${env.BUILD_ID} && echo \\\$CURRENT_VERSION | sudo tee ${env.REMOTE_BACKUP_DIR}/snapshots/pre-${env.BUILD_ID}/.previous_version && echo Backup created: pre-${env.BUILD_ID}; else echo No existing deployment to backup; fi'"
                    """
                }
            }
        }
        
        stage('Checkout Code') {
            steps {
                echo "📥 Checking out code from branch: ${params.GIT_BRANCH}"
                git branch: "${params.GIT_BRANCH}", url: "${env.REPO_URL}"
                
                // Tag the commit with deployment version
                bat """
                git tag -a "${params.DEPLOYMENT_VERSION}-deployed" -m "Deployed version ${params.DEPLOYMENT_VERSION} to ${params.TARGET_ENVIRONMENT}"
                """
            }
        }
        
        stage('Install Dependencies') {
            steps {
                echo "📦 Installing dependencies..."
                bat 'npm install'
            }
        }
        
        stage('Build Application') {
            steps {
                echo "🏗️ Building application..."
                bat """
                npm run build
                echo "${params.DEPLOYMENT_VERSION}" > dist/.version
                echo "${env.BUILD_ID}" > dist/.build_id
                echo "${params.TARGET_ENVIRONMENT}" > dist/.environment
                """
            }
        }
        
        stage('Deploy to Server') {
            steps {
                script {
                    echo "🚀 Deploying to ${params.TARGET_ENVIRONMENT} environment..."
                    
                    try {
                        bat """
                        echo "Uploading files to server..."
                        "C:\\Program Files\\Git\\bin\\bash.exe" -c "scp -o StrictHostKeyChecking=no -i '${env.PEM_KEY_PATH}' -r dist/* ${env.TARGET_USER}@${env.TARGET_HOST}:${env.REMOTE_APP_DIR}/"
                        """
                        
                        bat """
                        echo "Deploying to nginx directory..."
                        "C:\\Program Files\\Git\\bin\\bash.exe" -c "ssh -o StrictHostKeyChecking=no -i '${env.PEM_KEY_PATH}' ${env.TARGET_USER}@${env.TARGET_HOST} 'sudo mkdir -p ${env.REMOTE_BACKUP_DIR}/versions/${params.DEPLOYMENT_VERSION} && sudo cp -r ${env.REMOTE_APP_DIR}/* ${env.REMOTE_BACKUP_DIR}/versions/${params.DEPLOYMENT_VERSION}/ && sudo rm -rf ${env.NGINX_ROOT_DIR}/* && sudo cp -r ${env.REMOTE_APP_DIR}/* ${env.NGINX_ROOT_DIR}/ && sudo chown -R www-data:www-data ${env.NGINX_ROOT_DIR}/ && sudo chmod -R 644 ${env.NGINX_ROOT_DIR}/* && sudo chmod 755 ${env.NGINX_ROOT_DIR}/ && sudo systemctl restart nginx && echo Deployment completed: ${params.DEPLOYMENT_VERSION}'"
                        """
                        
                        env.DEPLOYMENT_SUCCESS = 'true'
                        
                    } catch (Exception e) {
                        env.DEPLOYMENT_SUCCESS = 'false'
                        env.DEPLOYMENT_ERROR = e.getMessage()
                        echo "❌ Deployment failed: ${e.getMessage()}"
                        throw e
                    }
                }
            }
        }
        
        stage('Cleanup Old Backups') {
            steps {
                echo "🧹 Cleaning up old backups..."
                bat """
                "C:\\Program Files\\Git\\bin\\bash.exe" -c "ssh -o StrictHostKeyChecking=no -i '${env.PEM_KEY_PATH}' ${env.TARGET_USER}@${env.TARGET_HOST} 'cd ${env.REMOTE_BACKUP_DIR}/versions && ls -t | tail -n +\\$((${env.MAX_BACKUPS} + 1)) | xargs -r sudo rm -rf && cd ${env.REMOTE_BACKUP_DIR}/snapshots && ls -t | tail -n +\\$((${env.MAX_BACKUPS} + 1)) | xargs -r sudo rm -rf && echo Cleanup completed. Current backups: && ls -la ${env.REMOTE_BACKUP_DIR}/versions/ 2>/dev/null || echo No version backups && ls -la ${env.REMOTE_BACKUP_DIR}/snapshots/ 2>/dev/null || echo No snapshot backups'"
                """
            }
        }
    }
    
    post {
        success {
            echo """
            ✅ DEPLOYMENT SUCCESSFUL!
            ================================
            ${env.ENV_COLOR} Environment: ${params.TARGET_ENVIRONMENT.toUpperCase()}
            📦 Version: ${params.DEPLOYMENT_VERSION}
            🌿 Branch: ${params.GIT_BRANCH}
            🎯 Target: ${env.TARGET_HOST}
            🆔 Build ID: ${env.BUILD_ID}
            🌐 URL: http://${env.TARGET_HOST}
            ================================
            """
        }
        
        failure {
            script {
                echo """
                ❌ DEPLOYMENT FAILED!
                ================================
                ${env.ENV_COLOR} Environment: ${params.TARGET_ENVIRONMENT.toUpperCase()}
                📦 Version: ${params.DEPLOYMENT_VERSION}
                🌿 Branch: ${params.GIT_BRANCH}
                ================================
                """
                
                // Automatic rollback on failure
                if (env.DEPLOYMENT_SUCCESS == 'false' || env.HEALTH_CHECK_SUCCESS == 'false') {
                    echo "🔄 Initiating automatic rollback..."
                    
                    try {
                        bat """
                        "C:\\Program Files\\Git\\bin\\bash.exe" -c "ssh -o StrictHostKeyChecking=no -i '${env.PEM_KEY_PATH}' ${env.TARGET_USER}@${env.TARGET_HOST} 'echo Starting automatic rollback... && LATEST_BACKUP=\\$(ls -t ${env.REMOTE_BACKUP_DIR}/snapshots/ | grep pre- | head -1) && if [ -n \\$LATEST_BACKUP ]; then echo Rolling back to: \\$LATEST_BACKUP && sudo rm -rf ${env.NGINX_ROOT_DIR}/* && sudo cp -r ${env.REMOTE_BACKUP_DIR}/snapshots/\\$LATEST_BACKUP/* ${env.NGINX_ROOT_DIR}/ && sudo chown -R www-data:www-data ${env.NGINX_ROOT_DIR}/ && sudo chmod -R 644 ${env.NGINX_ROOT_DIR}/* && sudo chmod 755 ${env.NGINX_ROOT_DIR}/ && sudo systemctl restart nginx && sleep 5 && ROLLBACK_STATUS=\\$(curl -s -o /dev/null -w %{http_code} http://localhost --max-time 10) && if [ \\$ROLLBACK_STATUS = 200 ]; then echo Rollback successful! Service restored.; else echo Rollback completed but health check returned: \\$ROLLBACK_STATUS; fi; else echo No backup found for rollback!; fi'"
                        """
                        
                        echo "🔄 Automatic rollback completed"
                        
                    } catch (Exception rollbackError) {
                        echo "❌ Automatic rollback failed: ${rollbackError.getMessage()}"
                        echo "📞 Manual intervention required!"
                    }
                }
            }
        }
        
        always {
            echo "📊 Deployment Summary:"
            bat """
            "C:\\Program Files\\Git\\bin\\bash.exe" -c "ssh -o StrictHostKeyChecking=no -i '${env.PEM_KEY_PATH}' ${env.TARGET_USER}@${env.TARGET_HOST} 'echo Current version: \\$(sudo cat ${env.NGINX_ROOT_DIR}/.version 2>/dev/null || echo unknown) && echo Service status: \\$(sudo systemctl is-active nginx) && echo Available backups: \\$(ls ${env.REMOTE_BACKUP_DIR}/versions/ 2>/dev/null | wc -l) versions, \\$(ls ${env.REMOTE_BACKUP_DIR}/snapshots/ 2>/dev/null | wc -l) snapshots'"
            """
        }
    }
}