from enum import Enum
from api.schemas.prediction_schemas import ClaimsRequest


class ModelTypes(str, Enum):
    claims_leakage = "claims"
    fraud_detection = "fraud_detection"


class Model:
    def __init__(self, model_type:ModelTypes):
        self.model_type = model_type
        self.model = self._load_model_registry()

    def _load_model_from_registry(self):
        #code to pull model from GCP Model Registry
        pass

    def predict(self, data: ClaimsRequest):
        #mock data
        return [{"id_loss":x, ""
        "leakage_probability": 0.1} for x in range(1000)]

