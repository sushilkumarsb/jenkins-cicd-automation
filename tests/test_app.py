"""
Unit tests for the Flask application
"""
import pytest

def test_health_endpoint(client):
    """Test GET /health endpoint returns 200 and status='ok'"""
    response = client.get('/health')
    assert response.status_code == 200
    data = response.get_json()
    assert data['status'] == 'ok'

def test_version_endpoint(client):
    """Test GET /version endpoint returns version '1.0.0'"""
    response = client.get('/version')
    assert response.status_code == 200
    data = response.get_json()
    assert data['version'] == '1.0.0'

def test_deploy_endpoint(client):
    """Test POST /deploy endpoint logs and returns success"""
    response = client.post('/deploy')
    assert response.status_code == 200
    data = response.get_json()
    assert data['status'] == 'success'

def test_invalid_endpoint(client):
    """Test invalid endpoints return 404"""
    response = client.get('/invalid')
    assert response.status_code == 404
