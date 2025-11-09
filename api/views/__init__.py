from fastapi import APIRouter, status
from fastapi.responses import JSONResponse
from api.schemas import HealthCheckResponse

base_router = APIRouter(prefix="/api/v1")


@base_router.get("/healthz",
                 summary="Health check endpoint",
                 description="Returns the operational status of the model service.",
                 response_model=HealthCheckResponse
)
def healthcheck():
    resp = HealthCheckResponse(
        status="ok",
        model_version="v1"
    )
    return JSONResponse(
        status_code=status.HTTP_200_OK,
        media_type="application/json",
        description="Service is healthy",
        content=resp
    )

from . import prediction_views, auth_views
