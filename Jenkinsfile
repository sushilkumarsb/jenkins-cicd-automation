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
