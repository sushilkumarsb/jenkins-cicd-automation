pipeline {
    agent any
    
    environment {
        APP_NAME = 'jenkins-cicd-app'
        PYTHON_VERSION = '3.11'
    }
    
    stages {
        stage('Build') {
            steps {
                echo 'Installing dependencies...'
                bat '''
                    python -m pip install --upgrade pip
                    pip install -r src/requirements.txt
                '''
            }
        }
        
        stage('Test') {
            steps {
                echo 'Running tests with coverage...'
                bat '''
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
                bat '''
                    echo "Syntax check..."
                    python -m py_compile src/app.py
                '''
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
