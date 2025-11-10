from fastapi import status, HTTPException
from fastapi.responses import JSONResponse
from api.views import base_router
from api.schemas.prediction_schemas import PredictRequest, PredictResponse
from api.service.model_predictions import predict_outlier_prob


@base_router.post(
    path="/predict",
    response_model=PredictResponse,
    description="Predicted leakage probabilities"
)
def predict(
    request: PredictRequest
):
    try:
        preds = predict_outlier_prob(request)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"model prediction failed with error {e}"
        )

    resp = PredictResponse(
        predictions=preds
    )

    return JSONResponse(
        status_code=status.HTTP_200_OK,
        content=resp.model_dump(),
        media_type="application/json"
    )