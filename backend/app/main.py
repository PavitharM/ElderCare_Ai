import logging

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from sqlalchemy import text

from .api.v1.router import api_router
from .core.config import settings
from .db.session import engine
from .web.routes import router as web_router

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s: %(message)s")


def create_app() -> FastAPI:
    app = FastAPI(
        title=settings.PROJECT_NAME,
        version=settings.VERSION,
        description="ElderGuard AI - REST API for elderly health monitoring, risk assessment and emergency assistance.",
    )

    allow_all = "*" in settings.CORS_ORIGINS
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"] if allow_all else settings.CORS_ORIGINS,
        allow_credentials=not allow_all,  # credentials are never allowed with a wildcard origin
        allow_methods=["*"],
        allow_headers=["*"],
    )

    app.include_router(api_router, prefix=settings.API_V1_STR)
    app.include_router(web_router)

    @app.get("/health", tags=["System"])
    def healthcheck():
        try:
            with engine.connect() as conn:
                conn.execute(text("SELECT 1"))
            db_status = "connected"
        except Exception:
            db_status = "unavailable"
        body = {"status": "healthy" if db_status == "connected" else "degraded", "service": settings.PROJECT_NAME,
                "version": settings.VERSION, "database": db_status}
        return JSONResponse(body, status_code=200 if db_status == "connected" else 503)

    @app.get("/", tags=["System"])
    def root():
        return {"message": "ElderGuard AI backend", "docs": "/docs", "version": settings.VERSION}

    return app


app = create_app()
