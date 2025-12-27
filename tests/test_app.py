"""
Unit tests for the Flask application
"""
import pytest
from src.app import app, add_numbers

@pytest.fixture
def client():
    """Create a test client"""
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_home_endpoint(client):
    """Test the home endpoint"""
    response = client.get('/')
    assert response.status_code == 200
    data = response.get_json()
    assert data['status'] == 'running'
    assert 'message' in data

def test_health_endpoint(client):
    """Test the health check endpoint"""
    response = client.get('/health')
    assert response.status_code == 200
    data = response.get_json()
    assert data['status'] == 'healthy'
    assert data['service'] == 'jenkins-cicd-app'

def test_info_endpoint(client):
    """Test the info endpoint"""
    response = client.get('/api/info')
    assert response.status_code == 200
    data = response.get_json()
    assert 'app_name' in data
    assert 'version' in data
    assert data['version'] == '1.0.0'

def test_add_numbers():
    """Test the add_numbers function"""
    assert add_numbers(2, 3) == 5
    assert add_numbers(0, 0) == 0
    assert add_numbers(-1, 1) == 0
    assert add_numbers(10, 20) == 30

def test_add_numbers_floats():
    """Test add_numbers with float values"""
    assert add_numbers(1.5, 2.5) == 4.0
    assert add_numbers(0.1, 0.2) == pytest.approx(0.3)
