from fastapi import FastAPI
from prometheus_client import Counter, make_asgi_app

app = FastAPI(title="demo-api", version="0.1.0")
health_checks = Counter("demo_api_health_checks_total", "Completed health checks.")

app.mount("/metrics", make_asgi_app())


@app.get("/health")
def health() -> dict[str, str]:
    health_checks.inc()
    return {"status": "ok"}
