from fastapi.testclient import TestClient

from main import app


def test_health_returns_ok() -> None:
    response = TestClient(app).get("/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_metrics_exposes_application_counter() -> None:
    response = TestClient(app).get("/metrics")

    assert response.status_code == 200
    assert "demo_api_health_checks_total" in response.text
