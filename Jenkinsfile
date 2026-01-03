pipeline {
    agent any

     triggers {
        githubPush()  // Auto-trigger on GitHub push
    }

    environment {
        APP_NAME = 'jenkins-cicd-app'
        PYTHON_VERSION = '3.11'
        DOCKER_IMAGE = 'sushilkumarsb/jenkins-cicd-app'
        DOCKER_TAG = "${BUILD_NUMBER}"
        EC2_HOST = '44.210.20.212'
    }
    
    stages {
        stage('Build') {
            steps {
                echo 'Setting up Python virtual environment...'
                sh '''
                    # Create virtual environment
                    python3 -m venv venv
                    
                    # Activate and install dependencies
                    . venv/bin/activate
                    pip install --upgrade pip
                    pip install -r src/requirements.txt
                '''
            }
        }
        
        stage('Test') {
            steps {
                echo 'Running tests with coverage...'
                sh '''
                    # Activate virtual environment
                    . venv/bin/activate
                    python -m pytest tests/ -v --cov=src --cov-report=html --cov-report=xml --junitxml=test-results/results.xml
                '''
            }
            post {
                always {
                    junit 'test-results/results.xml'
                }
            }
        }
        
        stage('Code Quality') {
            steps {
                echo 'Running code quality checks...'
                sh '''
                    # Activate virtual environment
                    . venv/bin/activate
                    echo "Syntax check..."
                    python -m py_compile src/app.py
                '''
            }
        }
        
        stage('Docker Build') {
            steps {
                echo 'Building Docker image...'
                sh """
                    docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                    docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest
                """
            }
        }
        
        stage('Docker Push') {
            steps {
                echo 'Pushing Docker image to Docker Hub...'
                withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', 
                                                 usernameVariable: 'DOCKER_USER', 
                                                 passwordVariable: 'DOCKER_PASS')]) {
                    sh '''
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                        docker push ${DOCKER_IMAGE}:latest
                        docker logout
                    '''
                }
            }
        }
        
        stage('Deploy to AWS') {
            steps {
                echo 'Deploying containerized app to AWS EC2...'
                sshagent(['aws-ec2-ssh-key']) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ubuntu@${EC2_HOST} '
                            # Pull latest image
                            docker pull ${DOCKER_IMAGE}:latest
                            
                            # Stop and remove old container if exists
                            docker stop flask-app || true
                            docker rm flask-app || true
                            
                            # Run new container
                            docker run -d \\
                                --name flask-app \\
                                --restart unless-stopped \\
                                -p 5000:5000 \\
                                ${DOCKER_IMAGE}:latest
                            
                            # Verify container is running
                            docker ps | grep flask-app
                        '
                    """
                }
            }
        }
    }
    
    post {
        success {
            echo '✅ Pipeline completed successfully!'
            echo "Build #${BUILD_NUMBER} - All tests passed"
        }
        failure {
            echo '❌ Pipeline failed!'
            echo "Build #${BUILD_NUMBER} - Check logs for details"
        }
    }
}
