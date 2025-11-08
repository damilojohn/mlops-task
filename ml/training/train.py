import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import classification_report, roc_auc_score
import joblib

# For reproducibility
np.random.seed(42)



df = pd.read_csv("data/leakage_data.csv")

df.leakage_label.value_counts().plot(kind="bar")


# encoding for pet_species and breed
df_encoded = pd.get_dummies(df, columns=["pet_species", "pet_breed"], drop_first=True)

X = df_encoded.drop(columns=["leakage_label", "id_loss"])
y = df_encoded["leakage_label"]

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, stratify=y, random_state=42)

print("Training samples:", len(X_train))
print("Test samples:", len(X_test))

model = RandomForestClassifier(
    n_estimators=200,
    max_depth=8,
    min_samples_split=10,
    class_weight="balanced",
    random_state=42
)

model.fit(X_train, y_train)

y_pred = model.predict(X_test)
y_prob = model.predict_proba(X_test)[:, 1]

print(classification_report(y_test, y_pred))
print("ROC AUC:", roc_auc_score(y_test, y_prob).round(3))
