"""
Pytest configuration and fixtures
"""
import pytest
import sys
from pathlib import Path

# Add the project root to the Python path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

@pytest.fixture(scope='session')
def app():
    """Create application instance for testing"""
    from src.app import app
    app.config['TESTING'] = True
    return app

@pytest.fixture(scope='function')
def test_config():
    """Provide test configuration"""
    return {
        'ENVIRONMENT': 'test',
        'DEBUG': False,
        'TESTING': True
    }
