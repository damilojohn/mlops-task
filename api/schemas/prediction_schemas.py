from pydantic import BaseModel
from typing import List
from enum import Enum


class PetSpecie(str, Enum):
    dog = "dog"
    cat = "cat"


class ClaimsRequest(BaseModel):
    id_loss: int = 1001
    claim_amount: float = 450.75
    pet_breed: str = "labrador"
    pet_species: PetSpecie = "dog"
    owner_age: str = 42
    number_of_previous_claims: int = 2
    days_to_claim: int = 5
    policy_tenure: int = 12


class Prediction(BaseModel):
    id_loss: int = 1001
    leakage_probability: float = 0.37


class PredictResponse(BaseModel):
    predictions: List[Prediction]


class PredictRequest(BaseModel):
    claims: List[ClaimsRequest]