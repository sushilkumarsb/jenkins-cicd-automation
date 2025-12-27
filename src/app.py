"""
Sample Python Flask Application
"""
from flask import Flask, jsonify, request
import os
import logging

app = Flask(__name__)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

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
        'status': 'ok'
    }), 200

@app.route('/version')
def version():
    """Version endpoint"""
    return jsonify({
        'version': '1.0.0'
    })

@app.route('/deploy', methods=['POST'])
def deploy():
    """Deploy endpoint"""
    logger.info("Deployment triggered")
    return jsonify({
        'status': 'success'
    })


def add_numbers(a, b):
    """Simple function to demonstrate testing"""
    return a + b

if __name__ == '__main__':
    port = int(os.getenv('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=True)
