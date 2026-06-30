from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from datetime import datetime
import joblib
import numpy as np
import pandas as pd
import os

app = FastAPI(title="Droplet AI", description="Rainfall Prediction API for Tarkwa, Ghana")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

MODELS_DIR = os.path.join(os.path.dirname(__file__), "..", "models")
DATA_DIR = os.path.join(os.path.dirname(__file__), "..", "data")

print("Loading models...")

try:
    sarima_model = joblib.load(os.path.join(MODELS_DIR, "sarima_model.pkl"))
    print("✓ SARIMA loaded")
except Exception as e:
    print(f"✗ SARIMA failed to load: {e}")
    sarima_model = None

try:
    gam_model = joblib.load(os.path.join(MODELS_DIR, "gam_model.pkl"))
    print("✓ GAM loaded")
except Exception as e:
    print(f"✗ GAM failed to load: {e}")
    gam_model = None

try:
    xgb_model = joblib.load(os.path.join(MODELS_DIR, "xgboost_model.pkl"))
    print("✓ XGBoost loaded")
except Exception as e:
    print(f"✗ XGBoost failed to load: {e}")
    xgb_model = None

# LSTM is intentionally NOT loaded in the deployed API. It remains fully
# trained and evaluated in notebooks/06_lstm.ipynb and models/lstm_model.keras,
# but is excluded here due to memory constraints on free-tier hosting —
# TensorFlow alone typically uses 200-400MB+ RAM, which combined with the
# other three model libraries risks exceeding Render's 512MB free-tier limit.

try:
    historical_df = pd.read_csv(
        os.path.join(DATA_DIR, "tarkwa_monthly_clean.csv"),
        parse_dates=["Date"]
    ).sort_values("Date").reset_index(drop=True)
    print("✓ Historical data loaded")
except Exception as e:
    print(f"✗ Historical data failed to load: {e}")
    historical_df = None

print("Model loading complete.")


SARIMA_TRAINING_END = datetime(2014, 12, 1)

MONTH_NAMES = {
    1: "January", 2: "February", 3: "March", 4: "April",
    5: "May", 6: "June", 7: "July", 8: "August",
    9: "September", 10: "October", 11: "November", 12: "December"
}


def categorize_rainfall(mm: float) -> str:
    """Maps a rainfall value to the plain-language scale from the project brief."""
    if mm <= 50:
        return "Very Low"
    elif mm <= 100:
        return "Low"
    elif mm <= 150:
        return "Moderate"
    elif mm <= 250:
        return "High"
    elif mm <= 350:
        return "Very High"
    else:
        return "Extreme"


def predict_sarima(target_date: datetime) -> float:
    """SARIMA forecasts purely from its own internal structure — no real
    historical lag values are needed, so this is a direct forward forecast,
    whether the date is in the past or the future relative to today."""
    months_ahead = (target_date.year - SARIMA_TRAINING_END.year) * 12 + \
                    (target_date.month - SARIMA_TRAINING_END.month)
    if months_ahead < 1:
        raise ValueError("Date must be after December 2014")
    forecast = sarima_model.predict(n_periods=months_ahead)
    return float(forecast.iloc[-1])


def predict_gam(target_date: datetime) -> float:
    """GAM only needs Month_Num and Year — no historical lag data required,
    works identically for past or future dates."""
    X = np.array([[target_date.month, target_date.year]])
    return float(gam_model.predict(X)[0])


def get_historical_row_index(target_date: datetime):
    """Finds the row index in historical_df matching the target date, or None."""
    match = historical_df[historical_df["Date"] == pd.Timestamp(target_date)]
    if len(match) == 0:
        return None
    return match.index[0]


def predict_xgboost(target_date: datetime) -> float:
    """If the target date falls within our recorded history, use the REAL
    rainfall from the 3 preceding months as lag features. Only when the
    date is beyond our last recorded month do we fall back to recursive
    forecasting, chaining the model's own predictions forward."""
    last_known_date = historical_df["Date"].max()

    if target_date <= last_known_date:
        idx = get_historical_row_index(target_date)
        if idx is None or idx < 3:
            raise ValueError("Not enough historical data before this date")
        lag_1 = historical_df["Monthly_Rainfall_mm"].iloc[idx - 1]
        lag_2 = historical_df["Monthly_Rainfall_mm"].iloc[idx - 2]
        lag_3 = historical_df["Monthly_Rainfall_mm"].iloc[idx - 3]
        X = np.array([[lag_1, lag_2, lag_3, target_date.month]])
        return float(xgb_model.predict(X)[0])

    recent = historical_df["Monthly_Rainfall_mm"].iloc[-3:].tolist()
    current_date = last_known_date
    while current_date < target_date:
        current_date = current_date + pd.DateOffset(months=1)
        lag_1, lag_2, lag_3 = recent[-1], recent[-2], recent[-3]
        X = np.array([[lag_1, lag_2, lag_3, current_date.month]])
        pred = float(xgb_model.predict(X)[0])
        recent.append(pred)
    return recent[-1]


def get_historical_monthly_average(month: int) -> float:
    """Returns the historical average rainfall for a given calendar month
    across all years in the dataset — used for the Home screen's
    'vs historical average' comparison."""
    matches = historical_df[historical_df["Date"].dt.month == month]
    return float(matches["Monthly_Rainfall_mm"].mean())


class PredictionRequest(BaseModel):
    year: int
    month: int  # 1-12


@app.get("/")
def root():
    return {
        "app": "Droplet AI",
        "status": "running",
        "models_loaded": {
            "sarima": sarima_model is not None,
            "gam": gam_model is not None,
            "xgboost": xgb_model is not None,
        },
        "note": "LSTM was trained and evaluated for this project but is not served live; see project notebooks."
    }


@app.post("/predict")
def predict(request: PredictionRequest):
    if request.month < 1 or request.month > 12:
        return {"error": "Month must be between 1 and 12"}

    target_date = datetime(request.year, request.month, 1)

    if sarima_model is None:
        return {"error": "SARIMA model is not available"}

    try:
        predicted_mm = predict_sarima(target_date)
    except ValueError as e:
        return {"error": str(e)}

    historical_avg = get_historical_monthly_average(request.month)
    percent_vs_average = ((predicted_mm - historical_avg) / historical_avg) * 100 if historical_avg > 0 else 0

    return {
        "model": "SARIMA",
        "year": request.year,
        "month": request.month,
        "month_name": MONTH_NAMES[request.month],
        "predicted_rainfall_mm": round(predicted_mm, 1),
        "category": categorize_rainfall(predicted_mm),
        "historical_average_mm": round(historical_avg, 1),
        "percent_vs_average": round(percent_vs_average, 1)
    }


@app.post("/compare")
def compare(request: PredictionRequest):
    if request.month < 1 or request.month > 12:
        return {"error": "Month must be between 1 and 12"}

    target_date = datetime(request.year, request.month, 1)
    results = {}

    try:
        mm = predict_sarima(target_date)
        results["sarima"] = {"predicted_rainfall_mm": round(mm, 1), "category": categorize_rainfall(mm)}
    except Exception as e:
        results["sarima"] = {"error": str(e)}

    try:
        mm = predict_gam(target_date)
        results["gam"] = {"predicted_rainfall_mm": round(mm, 1), "category": categorize_rainfall(mm)}
    except Exception as e:
        results["gam"] = {"error": str(e)}

    try:
        mm = predict_xgboost(target_date)
        results["xgboost"] = {"predicted_rainfall_mm": round(mm, 1), "category": categorize_rainfall(mm)}
    except Exception as e:
        results["xgboost"] = {"error": str(e)}

    return {
        "year": request.year,
        "month": request.month,
        "month_name": MONTH_NAMES[request.month],
        "models": results
    }