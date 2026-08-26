from fastapi.testclient import TestClient

from main import HsmSigningService, app, create_signing_service, get_key_vault_secret_status_service, get_signing_service


class FakeSigningService:
    def sign(self, payload: str) -> tuple[str, str]:
        assert payload == "business-transaction-123"
        return "c2lnbmF0dXJl", "https://example.managedhsm.azure.net/keys/release-signing/version"

    def verify(self, payload: str, signature: str) -> bool:
        return payload == "business-transaction-123" and signature == "c2lnbmF0dXJl"


class FakeKeyVaultSecretStatusService:
    def check(self) -> None:
        return None


def test_health_returns_ok() -> None:
    response = TestClient(app).get("/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_metrics_exposes_application_counter() -> None:
    response = TestClient(app).get("/metrics")

    assert response.status_code == 200
    assert "demo_api_health_checks_total" in response.text


def test_sign_returns_hsm_signature() -> None:
    app.dependency_overrides[get_signing_service] = lambda: FakeSigningService()

    response = TestClient(app).post("/sign", json={"payload": "business-transaction-123"})

    app.dependency_overrides.clear()
    assert response.status_code == 200
    assert response.json()["algorithm"] == "RS256"
    assert response.json()["signature"] == "c2lnbmF0dXJl"


def test_verify_returns_valid_for_hsm_signature() -> None:
    app.dependency_overrides[get_signing_service] = lambda: FakeSigningService()

    response = TestClient(app).post(
        "/verify",
        json={"payload": "business-transaction-123", "signature": "c2lnbmF0dXJl"},
    )

    app.dependency_overrides.clear()
    assert response.status_code == 200
    assert response.json() == {"valid": True}


def test_key_vault_secret_status_does_not_return_secret_value() -> None:
    app.dependency_overrides[get_key_vault_secret_status_service] = lambda: FakeKeyVaultSecretStatusService()

    response = TestClient(app).get("/key-vault/secret-status")

    app.dependency_overrides.clear()
    assert response.status_code == 200
    assert response.json() == {"configured": True, "accessible": True}


def test_sign_returns_generic_error_when_hsm_initialization_fails(monkeypatch) -> None:
    def unavailable_hsm_service(hsm_uri: str, key_name: str) -> HsmSigningService:
        del hsm_uri, key_name
        raise RuntimeError("https://internal-hsm.example.net is unavailable")

    monkeypatch.setenv("AZURE_MANAGED_HSM_URI", "https://example.managedhsm.azure.net")
    monkeypatch.setenv("AZURE_MANAGED_HSM_KEY_NAME", "transaction-signing")
    create_signing_service.cache_clear()
    monkeypatch.setattr("main.HsmSigningService", unavailable_hsm_service)

    response = TestClient(app, raise_server_exceptions=False).post("/sign", json={"payload": "business-transaction-123"})

    create_signing_service.cache_clear()
    assert response.status_code == 503
    assert response.json() == {"detail": "Cryptographic service temporarily unavailable"}
