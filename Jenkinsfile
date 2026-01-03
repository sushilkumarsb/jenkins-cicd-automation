pipeline {
    agent any

    triggers {
        githubPush()  // Auto-trigger on GitHub push
    }

    parameters {
        booleanParam(name: 'ROLLBACK', defaultValue: false, description: 'Rollback to previous deployment?')
        string(name: 'ROLLBACK_TAG', defaultValue: '', description: 'Specific tag to rollback to (leave empty for previous)')
    }

    environment {
        APP_NAME = 'jenkins-cicd-app'
        PYTHON_VERSION = '3.11'
        DOCKER_IMAGE = 'sushilkumarsb/jenkins-cicd-app'
        DOCKER_TAG = "${BUILD_NUMBER}"
        EC2_HOST = '44.210.20.212'
        DEPLOYMENT_STATE_FILE = '.deployment_state'
        
        // Performance metrics
        PIPELINE_START_TIME = "${System.currentTimeMillis()}"
    }
    
    stages {
        stage('Rollback Check') {
            when {
                expression { return params.ROLLBACK == true }
            }
            steps {
                script {
                    echo '🔄 ROLLBACK MODE ACTIVATED'
                    echo "Rolling back to previous deployment..."
                    
                    sh '''
                        chmod +x scripts/rollback.sh
                        ./scripts/rollback.sh
                    '''
                    
                    echo '✅ Rollback completed successfully'
                    currentBuild.result = 'SUCCESS'
                    error('Rollback complete - stopping pipeline')
                }
            }
        }
        
        stage('Build') {
            when {
                expression { return params.ROLLBACK == false }
            }
            steps {
                script {
                    env.STAGE_START_TIME = "${System.currentTimeMillis()}"
                }
                echo 'Setting up Python virtual environment...'
                sh '''
                    # Create virtual environment
                    python3 -m venv venv
                    
                    # Activate and install dependencies
                    . venv/bin/activate
                    pip install --upgrade pip
                    pip install -r src/requirements.txt
                '''
                script {
                    def stageDuration = (System.currentTimeMillis() - env.STAGE_START_TIME.toLong()) / 1000
                    echo "⏱️  Build stage completed in ${stageDuration} seconds"
                }
            }
        }
        
        stage('Test') {
            when {
                expression { return params.ROLLBACK == false }
            }
            steps {
                script {
                    env.STAGE_START_TIME = "${System.currentTimeMillis()}"
                }
                echo 'Running tests with coverage...'
                sh '''
                    # Activate virtual environment
                    . venv/bin/activate
                    python -m pytest tests/ -v --cov=src --cov-report=html --cov-report=xml --junitxml=test-results/results.xml
                '''
                script {
                    def stageDuration = (System.currentTimeMillis() - env.STAGE_START_TIME.toLong()) / 1000
                    echo "⏱️  Test stage completed in ${stageDuration} seconds"
                }
            }
            post {
                always {
                    junit 'test-results/results.xml'
                }
            }
        }
        
        stage('Code Quality') {
            when {
                expression { return params.ROLLBACK == false }
            }
            steps {
                script {
                    env.STAGE_START_TIME = "${System.currentTimeMillis()}"
                }
                echo 'Running code quality checks...'
                sh '''
                    # Activate virtual environment
                    . venv/bin/activate
                    echo "Syntax check..."
                    python -m py_compile src/app.py
                '''
                script {
                    def stageDuration = (System.currentTimeMillis() - env.STAGE_START_TIME.toLong()) / 1000
                    echo "⏱️  Code Quality stage completed in ${stageDuration} seconds"
                }
            }
        }
        
        stage('Docker Build') {
            when {
                expression { return params.ROLLBACK == false }
            }
            steps {
                script {
                    env.STAGE_START_TIME = "${System.currentTimeMillis()}"
                }
                echo 'Building Docker image...'
                sh """
                    docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                    docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest
                """
                script {
                    def stageDuration = (System.currentTimeMillis() - env.STAGE_START_TIME.toLong()) / 1000
                    echo "⏱️  Docker Build stage completed in ${stageDuration} seconds"
                }
            }
        }
        
        stage('Docker Push') {
            when {
                expression { return params.ROLLBACK == false }
            }
            steps {
                script {
                    env.STAGE_START_TIME = "${System.currentTimeMillis()}"
                }
                echo 'Pushing Docker image to Docker Hub...'
                withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', 
                                                 usernameVariable: 'DOCKER_USER', 
                                                 passwordVariable: 'DOCKER_PASS')]) {
                    sh '''
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                        docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                        docker logout
                    '''
                }
                script {
                    def stageDuration = (System.currentTimeMillis() - env.STAGE_START_TIME.toLong()) / 1000
                    echo "⏱️  Docker Push stage completed in ${stageDuration} seconds"
                }
            }
        }
        
        stage('Deploy to AWS') {
            when {
                expression { return params.ROLLBACK == false }
            }
            steps {
                script {
                    env.STAGE_START_TIME = "${System.currentTimeMillis()}"
                    
                    // Read current deployment state before deployment
                    def previousTag = 'latest'
                    if (fileExists(DEPLOYMENT_STATE_FILE)) {
                        def stateContent = readFile(DEPLOYMENT_STATE_FILE)
                        def matcher = (stateContent =~ /CURRENT_TAG=(.+)/)
                        if (matcher.find()) {
                            previousTag = matcher.group(1)
                        }
                    }
                    
                    echo "Previous deployment tag: ${previousTag}"
                    echo 'Deploying containerized app to AWS EC2...'
                    echo 'Pulling latest Docker image and running container...'
                    
                    sh """
                        # Deploy directly on localhost (Jenkins is on EC2)
                        docker pull ${DOCKER_IMAGE}:latest
                        
                        # Stop and remove old container if exists
                        docker stop flask-app || true
                        docker rm flask-app || true
                        
                        # Run new container
                        docker run -d \\
                            --name flask-app \\
                            --restart unless-stopped \\
                            -p 127.0.0.1:5000:5000 \\
                            ${DOCKER_IMAGE}:latest
                        
                        # Wait for container to start
                        sleep 5
                        
                        # Verify container is running
                        docker ps | grep flask-app
                    """
                    
                    // Health check with auto-rollback on failure
                    echo '🏥 Performing health check...'
                    def healthCheckPassed = false
                    def maxAttempts = 10
                    def attempt = 0
                    
                    while (attempt < maxAttempts && !healthCheckPassed) {
                        attempt++
                        echo "Health check attempt ${attempt}/${maxAttempts}"
                        
                        def healthStatus = sh(
                            script: 'curl -sf http://localhost:5000/health',
                            returnStatus: true
                        )
                        
                        if (healthStatus == 0) {
                            healthCheckPassed = true
                            echo '✅ Health check passed!'
                        } else if (attempt < maxAttempts) {
                            echo '⏳ Waiting 3 seconds before retry...'
                            sleep 3
                        }
                    }
                    
                    if (!healthCheckPassed) {
                        echo '❌ Health check failed! Initiating automatic rollback...'
                        
                        // Rollback to previous version
                        sh """
                            docker stop flask-app || true
                            docker rm flask-app || true
                            docker pull ${DOCKER_IMAGE}:${previousTag}
                            docker run -d \\
                                --name flask-app \\
                                --restart unless-stopped \\
                                -p 127.0.0.1:5000:5000 \\
                                ${DOCKER_IMAGE}:${previousTag}
                            sleep 5
                        """
                        
                        echo "🔄 Rolled back to ${DOCKER_IMAGE}:${previousTag}"
                        error('Deployment failed health check - automatic rollback completed')
                    }
                    
                    // Save deployment state
                    writeFile file: DEPLOYMENT_STATE_FILE, text: """CURRENT_TAG=${DOCKER_TAG}
PREVIOUS_TAG=${previousTag}
DEPLOYMENT_TIME=${new Date().format('yyyy-MM-dd HH:mm:ss')}
BUILD_NUMBER=${BUILD_NUMBER}
"""
                    
                    echo "💾 Deployment state saved"
                    
                    def stageDuration = (System.currentTimeMillis() - env.STAGE_START_TIME.toLong()) / 1000
                    echo "⏱️  Deploy stage completed in ${stageDuration} seconds"
                }
            }
        }
    }
    
    post {
        success {
            script {
                def pipelineDuration = (System.currentTimeMillis() - env.PIPELINE_START_TIME.toLong()) / 1000
                
                echo '✅ Pipeline completed successfully!'
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo "📊 PERFORMANCE METRICS - Build #${BUILD_NUMBER}"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo "⏱️  Total Pipeline Duration: ${pipelineDuration} seconds"
                echo "🐳 Docker Image: ${DOCKER_IMAGE}:${DOCKER_TAG}"
                echo "✅ Deployment Status: SUCCESS"
                echo "🌐 Application URL: https://sushilkumarsb.xyz/app/"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                
                // Archive deployment state
                archiveArtifacts artifacts: DEPLOYMENT_STATE_FILE, allowEmptyArchive: true
            }
        }
        failure {
            script {
                def pipelineDuration = (System.currentTimeMillis() - env.PIPELINE_START_TIME.toLong()) / 1000
                
                echo '❌ Pipeline failed!'
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo "📊 FAILURE REPORT - Build #${BUILD_NUMBER}"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo "⏱️  Pipeline ran for: ${pipelineDuration} seconds before failure"
                echo "❌ Deployment Status: FAILED"
                echo "🔄 Rollback may have been triggered"
                echo "📝 Check logs above for details"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            }
        }
        always {
            script {
                // Clean up old Docker images to save space
                echo '🧹 Cleaning up old Docker images...'
                sh '''
                    # Remove dangling images
                    docker image prune -f
                    
                    # Keep only last 5 builds
                    docker images ${DOCKER_IMAGE} --format "{{.Tag}}" | \
                        grep -v latest | \
                        sort -rn | \
                        tail -n +6 | \
                        xargs -r -I {} docker rmi ${DOCKER_IMAGE}:{} || true
                '''
                echo '✅ Cleanup completed'
            }
        }
    }
}
