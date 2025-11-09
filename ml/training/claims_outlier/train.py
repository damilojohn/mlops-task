import argparse
import logging
import os
import sys

import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import classification_report, roc_auc_score
import joblib

from google.cloud import storage

# Configure basic logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


DATA_PATH = "data/leakage_data.csv"
MODEL_FILENAME = "model.pkl"
RANDOM_STATE = 42

# For reproducibility
np.random.seed(RANDOM_STATE)


def load_data(data_path: str) -> pd.DataFrame:
    """Loads the training data from the specified path."""
    logger.info(f"Attempting to load data from {data_path}")
    try:
        # NOTE: In a real MLOps pipeline, this data might be downloaded
        # from a GCS or BigQuery location instead of a local path.
        df = pd.read_csv(data_path)
        logger.info(f"Data loaded successfully. Shape: {df.shape}")
        return df
    except FileNotFoundError:
        logger.error(f"Error: Data file not found at {data_path}. Exiting.")
        sys.exit(1)
    except Exception as e:
        logger.error(f"An error occurred during data loading: {e}. Exiting.")
        sys.exit(1)


def preprocess_data(df: pd.DataFrame) -> tuple[pd.DataFrame, pd.Series]:
    """Encodes categorical features and separates features (X) and target (y)."""
    logger.info("Starting data preprocessing (One-Hot Encoding).")

    # Encoding for pet_species and breed
    df_encoded = pd.get_dummies(df, columns=["pet_species", "pet_breed"], drop_first=True)

    # Define features and target
    X = df_encoded.drop(columns=["leakage_label", "id_loss"])
    y = df_encoded["leakage_label"]

    logger.info(f"Features shape: {X.shape}, Target shape: {y.shape}")
    return X, y


def train_model(X_train: pd.DataFrame, y_train: pd.Series) -> RandomForestClassifier:
    """Initializes and trains the Random Forest Classifier."""
    logger.info("Starting model training...")

    model = RandomForestClassifier(
        n_estimators=200,
        max_depth=8,
        min_samples_split=10,
        class_weight="balanced",
        random_state=RANDOM_STATE,
        n_jobs=-1
    )

    model.fit(X_train, y_train)
    logger.info("Model training complete.")
    return model


def evaluate_model(model: RandomForestClassifier, X_test: pd.DataFrame, y_test: pd.Series):
    """Evaluates the model and logs key metrics."""
    logger.info("Starting model evaluation...")

    y_pred = model.predict(X_test)
    y_prob = model.predict_proba(X_test)[:, 1]

    # Calculate metrics
    report = classification_report(y_test, y_pred, output_dict=True)
    roc_auc = roc_auc_score(y_test, y_prob)

    # Log metrics
    logger.info("--- Classification Report ---")
    logger.info(pd.DataFrame(report).transpose().to_markdown())
    logger.info(f"ROC AUC Score: {roc_auc:.3f}")



def upload_to_gcs(local_path: str, gcs_path: str):
    """Uploads a file to a specified Google Cloud Storage location."""
    logger.info(f"Attempting to upload model from {local_path} to GCS path: {gcs_path}")
    
    if not gcs_path.startswith("gs://"):
        logger.error("GCS path must start with 'gs://'. Aborting upload.")
        return

    path_parts = gcs_path[5:].split('/', 1)
    bucket_name = path_parts[0]
    blob_path = path_parts[1]

    try:
        storage_client = storage.Client()
        bucket = storage_client.bucket(bucket_name)
        blob = bucket.blob(blob_path)
        
        blob.upload_from_filename(local_path)
        
        logger.info(f"Successfully uploaded model to {gcs_path}")
    except Exception as e:
        logger.error(f"Failed to upload model to GCS: {e}")

        sys.exit(1)


def main(gcs_output_path: str):
    """Main execution function for the MLOps training job."""
    logger.info("--- MLOps Training Job Started ---")

    df = load_data(DATA_PATH)
    X, y = preprocess_data(df)

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, stratify=y, random_state=RANDOM_STATE
    )
    logger.info(f"Training samples: {len(X_train)}, Test samples: {len(X_test)}")

    model = train_model(X_train, y_train)

    evaluate_model(model, X_test, y_test)

    try:
        joblib.dump(model, MODEL_FILENAME)
        logger.info(f"Model serialized locally as {MODEL_FILENAME}")
    except Exception as e:
        logger.error(f"Error serializing model locally: {e}. Exiting.")
        sys.exit(1)

    upload_to_gcs(MODEL_FILENAME, gcs_output_path)

    os.remove(MODEL_FILENAME)
    logger.info(f"Cleaned up local file {MODEL_FILENAME}.")

    logger.info("--- MLOps Training Job Finished Successfully ---")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="ManyPets Leakage Model Training Job.")
    parser.add_argument(
        "--gcs-output-path",
        type=str,
        required=True,
        help="The Google Cloud Storage path to save the model (e.g., gs://bucket-name/models/model.pkl)."
    )
    args = parser.parse_args()

    main(args.gcs_output_path)
