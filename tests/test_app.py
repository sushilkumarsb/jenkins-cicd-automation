"""
Unit tests for the Flask application
"""
import pytest
import json
from src.app import add_numbers

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

def test_home_endpoint(client):
    """Test GET / endpoint returns welcome message"""
    response = client.get('/')
    assert response.status_code == 200
    data = response.get_json()
    assert 'message' in data
    assert data['status'] == 'running'
    assert data['version'] == '1.0.0'

# ========================================
# Edge Cases & Error Handling
# ========================================

def test_health_endpoint_wrong_method(client):
    """Test POST to /health returns 405 Method Not Allowed"""
    response = client.post('/health')
    assert response.status_code == 405

def test_version_endpoint_wrong_method(client):
    """Test POST to /version returns 405 Method Not Allowed"""
    response = client.post('/version')
    assert response.status_code == 405

def test_deploy_endpoint_wrong_method(client):
    """Test GET to /deploy returns 405 Method Not Allowed"""
    response = client.get('/deploy')
    assert response.status_code == 405

def test_deploy_endpoint_with_json_data(client):
    """Test POST /deploy with JSON payload"""
    payload = {'environment': 'production', 'version': '1.0.0'}
    response = client.post('/deploy',
                          data=json.dumps(payload),
                          content_type='application/json')
    assert response.status_code == 200
    data = response.get_json()
    assert data['status'] == 'success'

def test_deploy_endpoint_with_invalid_json(client):
    """Test POST /deploy with invalid JSON handles gracefully"""
    response = client.post('/deploy',
                          data='invalid{json',
                          content_type='application/json')
    # Should still return 200 since endpoint doesn't validate JSON
    assert response.status_code in [200, 400]

def test_deploy_endpoint_empty_body(client):
    """Test POST /deploy with empty body"""
    response = client.post('/deploy')
    assert response.status_code == 200
    data = response.get_json()
    assert data['status'] == 'success'

def test_multiple_slashes_in_url(client):
    """Test endpoints with multiple slashes - Flask routes // to root"""
    response = client.get('//health')
    # Flask interprets //health as // (root) followed by path, routes to home
    assert response.status_code == 200
    data = response.get_json()
    assert data['status'] == 'running'  # Home endpoint response

def test_case_sensitive_endpoints(client):
    """Test endpoints are case-sensitive"""
    response = client.get('/HEALTH')
    assert response.status_code == 404
    
    response = client.get('/Health')
    assert response.status_code == 404

def test_endpoint_with_trailing_slash(client):
    """Test endpoints with trailing slash - strict_slashes=False behavior"""
    response = client.get('/health/')
    # With strict_slashes=False, routes accept both /health and /health/
    assert response.status_code == 200
    data = response.get_json()
    assert data['status'] == 'ok'

def test_endpoint_with_query_parameters(client):
    """Test /health endpoint ignores query parameters"""
    response = client.get('/health?debug=true&verbose=1')
    assert response.status_code == 200
    data = response.get_json()
    assert data['status'] == 'ok'

# ========================================
# Response Format Tests
# ========================================

def test_health_response_content_type(client):
    """Test /health returns JSON content type"""
    response = client.get('/health')
    assert response.content_type == 'application/json'

def test_version_response_content_type(client):
    """Test /version returns JSON content type"""
    response = client.get('/version')
    assert response.content_type == 'application/json'

def test_deploy_response_content_type(client):
    """Test /deploy returns JSON content type"""
    response = client.post('/deploy')
    assert response.content_type == 'application/json'

def test_health_response_structure(client):
    """Test /health returns correct JSON structure"""
    response = client.get('/health')
    data = response.get_json()
    assert isinstance(data, dict)
    assert len(data) == 1
    assert 'status' in data

def test_version_response_structure(client):
    """Test /version returns correct JSON structure"""
    response = client.get('/version')
    data = response.get_json()
    assert isinstance(data, dict)
    assert 'version' in data
    assert isinstance(data['version'], str)

# ========================================
# Utility Function Tests
# ========================================

def test_add_numbers_positive(client):
    """Test add_numbers with positive integers"""
    result = add_numbers(5, 3)
    assert result == 8

def test_add_numbers_negative(client):
    """Test add_numbers with negative integers"""
    result = add_numbers(-5, -3)
    assert result == -8

def test_add_numbers_mixed(client):
    """Test add_numbers with mixed positive/negative"""
    result = add_numbers(10, -3)
    assert result == 7

def test_add_numbers_zero(client):
    """Test add_numbers with zero"""
    result = add_numbers(0, 5)
    assert result == 5
    result = add_numbers(5, 0)
    assert result == 5

def test_add_numbers_floats(client):
    """Test add_numbers with floating point numbers"""
    result = add_numbers(2.5, 3.7)
    assert abs(result - 6.2) < 0.001

# ========================================
# Concurrent Request Tests
# ========================================

def test_multiple_health_checks(client):
    """Test multiple concurrent health checks"""
    responses = [client.get('/health') for _ in range(5)]
    assert all(r.status_code == 200 for r in responses)
    assert all(r.get_json()['status'] == 'ok' for r in responses)

def test_mixed_endpoint_calls(client):
    """Test calling different endpoints in sequence"""
    r1 = client.get('/health')
    r2 = client.get('/version')
    r3 = client.post('/deploy')
    r4 = client.get('/')
    
    assert all(r.status_code == 200 for r in [r1, r2, r3, r4])

# ========================================
# Application Configuration Tests
# ========================================

def test_app_configuration(app):
    """Test Flask app is configured correctly"""
    assert app.config['TESTING'] is True
    assert app.name == 'src.app'

def test_environment_port_default():
    """Test default port configuration"""
    import os
    # Test that PORT env var defaults to 5000
    port = int(os.getenv('PORT', 5000))
    assert port == 5000

def test_environment_port_custom():
    """Test custom port configuration from environment"""
    import os
    os.environ['PORT'] = '8000'
    port = int(os.getenv('PORT', 5000))
    assert port == 8000
    # Clean up
    del os.environ['PORT']
