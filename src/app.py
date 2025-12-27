"""
Sample Python Flask Application
"""
from flask import Flask, jsonify
import os

app = Flask(__name__)

@app.route('/')
def home():
    """Home endpoint"""
    return jsonify({
        'message': 'Welcome to Jenkins CI/CD Automation Demo',
        'status': 'running',
        'version': '1.0.0'
    })

@app.route('/health')
def health():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'service': 'jenkins-cicd-app'
    }), 200

@app.route('/api/info')
def info():
    """Application info endpoint"""
    return jsonify({
        'app_name': 'Jenkins CI/CD App',
        'environment': os.getenv('ENVIRONMENT', 'development'),
        'version': '1.0.0'
    })

def add_numbers(a, b):
    """Simple function to demonstrate testing"""
    return a + b

if __name__ == '__main__':
    port = int(os.getenv('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False)
