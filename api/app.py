from contextlib import asynccontextmanager

from fastapi import FastAPI, APIRouter
from fastapi.middleware.cors import CORSMiddleware
import structlog

from api.views import base_router
from api.utils.config import Settings

LOG = structlog.stdlib.get_logger()


def configure_cors(app: FastAPI, settings: Settings) -> None:
    app.add_middleware(
        CORSMiddleware,
        allow_credentials=True,
        allow_origins=[settings.cors_origins],
        allow_methods=["*"],
        allow_headers=["*"],
    )


@asynccontextmanager
async def lifespan(
    app: FastAPI):
    try:
        LOG.info("Prediction API Starting.....")

        # load trained models for serving

        yield
    
    finally:
        # close model class
        LOG.info("Prediction API shutting down.....")


def create_app() -> FastAPI:
    app = FastAPI(
        title="ManyPets Leakage Model API",
        description="""API for serving the ManyPets leakage classification model. 
                Provides endpoints for health checks and predicting leakage probability 
                for insurance claims.""",
        version="1.0.0",
        lifespan=lifespan
        )
    settings = Settings()

    configure_cors(app, settings)
    app.include_router(base_router)
    return app


app = create_app()
