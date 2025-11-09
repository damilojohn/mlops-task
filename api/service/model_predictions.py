from api.utils import Model
from api.schemas.prediction_schemas import PredictRequest

claims_model = Model(model_type="claims")


def predict_outlier_prob(request: PredictRequest):

    return claims_model.predict(request.claims)