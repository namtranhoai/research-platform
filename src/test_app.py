"""Tests for Research Platform API."""
import pytest

from app import app


@pytest.fixture
def client():
    """Test client."""
    app.config["TESTING"] = True
    with app.test_client() as c:
        yield c


def test_health(client):
    """Health endpoint returns ok."""
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json["status"] == "ok"


def test_index(client):
    """Root returns service info."""
    r = client.get("/")
    assert r.status_code == 200
    assert r.json["service"] == "research-platform"
