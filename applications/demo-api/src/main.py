import base64
import binascii
import hashlib
import logging
import os
from functools import lru_cache

from azure.core.exceptions import AzureError
from azure.identity import DefaultAzureCredential
from azure.keyvault.keys import KeyClient
from azure.keyvault.keys.crypto import CryptographyClient, SignatureAlgorithm
from azure.keyvault.secrets import SecretClient
from fastapi import Depends, FastAPI, HTTPException
from pydantic import BaseModel, Field
from prometheus_client import Counter, make_asgi_app

app = FastAPI(title="demo-api", version="0.1.0")
logger = logging.getLogger(__name__)
health_checks = Counter("demo_api_health_checks_total", "Completed health checks.")
crypto_operations = Counter("demo_api_crypto_operations_total", "Managed HSM cryptographic operations.", ["operation", "outcome"])

app.mount("/metrics", make_asgi_app())


@app.get("/health")
def health() -> dict[str, str]:
    health_checks.inc()
    return {"status": "ok"}


class SignRequest(BaseModel):
    payload: str = Field(min_length=1, max_length=65536)


class VerifyRequest(SignRequest):
    signature: str = Field(min_length=1)


class HsmSigningService:
    def __init__(self, hsm_uri: str, key_name: str) -> None:
        credential = DefaultAzureCredential()
        key = KeyClient(vault_url=hsm_uri, credential=credential).get_key(key_name)
        self._crypto_client = CryptographyClient(key, credential)

    @staticmethod
    def _digest(payload: str) -> bytes:
        return hashlib.sha256(payload.encode("utf-8")).digest()

    def sign(self, payload: str) -> tuple[str, str]:
        result = self._crypto_client.sign(SignatureAlgorithm.rs256, self._digest(payload))
        return base64.b64encode(result.signature).decode("ascii"), result.key_id

    def verify(self, payload: str, signature: str) -> bool:
        try:
            signature_bytes = base64.b64decode(signature, validate=True)
        except (ValueError, binascii.Error) as error:
            raise ValueError("signature must be valid base64") from error

        result = self._crypto_client.verify(
            SignatureAlgorithm.rs256,
            self._digest(payload),
            signature_bytes,
        )
        return result.is_valid


class KeyVaultSecretStatusService:
    def __init__(self, vault_uri: str, secret_name: str) -> None:
        self._secret_name = secret_name
        self._client = SecretClient(vault_url=vault_uri, credential=DefaultAzureCredential())

    def check(self) -> None:
        secret = self._client.get_secret(self._secret_name)
        del secret


@lru_cache
def create_signing_service(hsm_uri: str, key_name: str) -> HsmSigningService:
    return HsmSigningService(hsm_uri, key_name)


def get_signing_service() -> HsmSigningService:
    hsm_uri = os.getenv("AZURE_MANAGED_HSM_URI")
    key_name = os.getenv("AZURE_MANAGED_HSM_KEY_NAME")
    if not hsm_uri or not key_name:
        raise HTTPException(status_code=503, detail="Cryptographic service is not configured")

    try:
        return create_signing_service(hsm_uri, key_name)
    except Exception as error:
        raise unavailable(error) from error


@lru_cache
def get_key_vault_secret_status_service() -> KeyVaultSecretStatusService | None:
    vault_uri = os.getenv("AZURE_KEY_VAULT_URI")
    secret_name = os.getenv("CRYPTO_DEMO_SECRET_NAME")
    if not vault_uri or not secret_name:
        return None
    return KeyVaultSecretStatusService(vault_uri, secret_name)


def unavailable(error: Exception) -> HTTPException:
    logger.exception("Azure cryptographic service request failed", exc_info=error)
    return HTTPException(status_code=503, detail="Cryptographic service temporarily unavailable")


@app.post("/sign")
def sign(request: SignRequest, service: HsmSigningService = Depends(get_signing_service)) -> dict[str, str]:
    try:
        signature, key_id = service.sign(request.payload)
    except AzureError as error:
        crypto_operations.labels(operation="sign", outcome="failure").inc()
        raise unavailable(error) from error

    crypto_operations.labels(operation="sign", outcome="success").inc()
    return {"algorithm": "RS256", "key_id": key_id, "signature": signature}


@app.post("/verify")
def verify(request: VerifyRequest, service: HsmSigningService = Depends(get_signing_service)) -> dict[str, bool]:
    try:
        valid = service.verify(request.payload, request.signature)
    except ValueError as error:
        raise HTTPException(status_code=400, detail=str(error)) from error
    except AzureError as error:
        crypto_operations.labels(operation="verify", outcome="failure").inc()
        raise unavailable(error) from error

    crypto_operations.labels(operation="verify", outcome="success" if valid else "invalid").inc()
    return {"valid": valid}


@app.get("/key-vault/secret-status")
def key_vault_secret_status(
    service: KeyVaultSecretStatusService | None = Depends(get_key_vault_secret_status_service),
) -> dict[str, bool]:
    if service is None:
        return {"configured": False, "accessible": False}

    try:
        service.check()
    except AzureError as error:
        raise unavailable(error) from error

    return {"configured": True, "accessible": True}
