pipeline {
    agent any

     triggers {
        githubPush()  // Auto-trigger on GitHub push
    }

    environment {
        APP_NAME = 'jenkins-cicd-app'
        PYTHON_VERSION = '3.11'
    }
    
    stages {
        stage('Build') {
            steps {
                echo 'Installing dependencies...'
                sh '''
                    python3 -m pip install --upgrade pip --user
                    python3 -m pip install -r src/requirements.txt --user
                '''
            }
        }
        
        stage('Test') {
            steps {
                echo 'Running tests with coverage...'
                sh '''
                    python3 -m pytest tests/ -v --cov=src --cov-report=html --cov-report=xml --junitxml=test-results/results.xml
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
                    echo "Syntax check..."
                    python3 -m py_compile src/app.py
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
