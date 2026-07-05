from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import joblib
import numpy as np
import pandas as pd
import os

app = FastAPI(
    title="Droplet AI",
    description="Rainfall Prediction API for Tarkwa, Ghana — NASA POWER Multi-Variable Dataset"
)

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
    gbr_model = joblib.load(os.path.join(MODELS_DIR, "nasa_gbr_model.pkl"))
    print("✓ GBR loaded")
except Exception as e:
    print(f"✗ GBR failed to load: {e}")
    gbr_model = None

try:
    lgbm_model = joblib.load(os.path.join(MODELS_DIR, "nasa_lgbm_model.pkl"))
    print("✓ LightGBM loaded")
except Exception as e:
    print(f"✗ LightGBM failed to load: {e}")
    lgbm_model = None

try:
    xgb_model = joblib.load(os.path.join(MODELS_DIR, "nasa_xgboost_model.pkl"))
    print("✓ XGBoost loaded")
except Exception as e:
    print(f"✗ XGBoost failed to load: {e}")
    xgb_model = None

try:
    rf_model = joblib.load(os.path.join(MODELS_DIR, "nasa_rf_model.pkl"))
    print("✓ Random Forest loaded")
except Exception as e:
    print(f"✗ Random Forest failed to load: {e}")
    rf_model = None

try:
    nasa_df = pd.read_csv(
        os.path.join(DATA_DIR, "tarkwa_nasa_monthly.csv"),
        parse_dates=["date"]
    ).sort_values("date").reset_index(drop=True)
    print("✓ NASA POWER monthly data loaded")
except Exception as e:
    print(f"✗ NASA POWER data failed to load: {e}")
    nasa_df = None

print("Model loading complete.")

MONTH_NAMES = {
    1: "January", 2: "February", 3: "March", 4: "April",
    5: "May", 6: "June", 7: "July", 8: "August",
    9: "September", 10: "October", 11: "November", 12: "December"
}

FEATURE_COLS = [
    "temp_mean_C", "temp_max_C", "temp_min_C",
    "humidity_pct", "pressure_kPa", "wind_speed_ms",
    "month", "year", "lag_1", "lag_2", "lag_3"
]

# The single highest monthly rainfall ever recorded in the Tarkwa
# NASA POWER dataset (October 2024: 573.9mm) — used as the denominator
# for the rainfall intensity percentage shown to users.
ALL_TIME_MAX_RAINFALL_MM = 573.9


def get_monthly_climate_averages(month: int) -> dict:
    subset = nasa_df[nasa_df["month"] == month]
    return {
        "temp_mean_C": float(subset["temp_mean_C"].mean()),
        "temp_max_C": float(subset["temp_max_C"].mean()),
        "temp_min_C": float(subset["temp_min_C"].mean()),
        "humidity_pct": float(subset["humidity_pct"].mean()),
        "pressure_kPa": float(subset["pressure_kPa"].mean()),
        "wind_speed_ms": float(subset["wind_speed_ms"].mean()),
    }


def get_lag_values(year: int, month: int) -> tuple:
    def get_rainfall_for(y, m):
        if m < 1:
            m += 12
            y -= 1
        row = nasa_df[(nasa_df["year"] == y) & (nasa_df["month"] == m)]
        if len(row) > 0:
            return float(row["rainfall_mm"].iloc[0])
        return float(nasa_df[nasa_df["month"] == m]["rainfall_mm"].mean())
    return (
        get_rainfall_for(year, month - 1),
        get_rainfall_for(year, month - 2),
        get_rainfall_for(year, month - 3)
    )


def build_feature_vector(year: int, month: int) -> np.ndarray:
    climate = get_monthly_climate_averages(month)
    lag1, lag2, lag3 = get_lag_values(year, month)
    return np.array([[
        climate["temp_mean_C"], climate["temp_max_C"], climate["temp_min_C"],
        climate["humidity_pct"], climate["pressure_kPa"], climate["wind_speed_ms"],
        month, year, lag1, lag2, lag3
    ]])


def predict_with_model(model, X: np.ndarray) -> float:
    raw = model.predict(X)
    pred = float(np.array(raw).flatten()[0])
    return max(0.0, round(pred, 1))


def categorize_rainfall(mm: float) -> str:
    if mm <= 50: return "Very Low"
    elif mm <= 100: return "Low"
    elif mm <= 150: return "Moderate"
    elif mm <= 250: return "High"
    elif mm <= 350: return "Very High"
    else: return "Extreme"


def get_advisory(category: str) -> str:
    advisories = {
        "Very Low": "Minimal rainfall expected. Outdoor activities can proceed as planned.",
        "Low": "Light rainfall likely. Consider carrying an umbrella for outdoor activities.",
        "Moderate": "Moderate rainfall expected. Plan outdoor activities carefully and ensure drainage systems are clear.",
        "High": "Significant rainfall ahead. Prepare adequate waterproofing and monitor drainage in flood-prone areas.",
        "Very High": "Heavy rainfall expected. Exercise caution in low-lying and flood-prone areas. Mining operations should review pit drainage.",
        "Extreme": "Extreme rainfall conditions forecast. Follow local authority advisories closely and take precautionary measures immediately."
    }
    return advisories.get(category, "")


def get_rainfall_probability(predicted_mm: float) -> float:
    """Expresses predicted rainfall as a percentage of the all-time highest
    monthly rainfall ever recorded in the Tarkwa dataset (573.9mm, October 2024).
    Example: 69.9mm predicted → (69.9 / 573.9) × 100 = 12.2%"""
    percentage = (predicted_mm / ALL_TIME_MAX_RAINFALL_MM) * 100
    return round(min(percentage, 100.0), 1)


def get_historical_stats(month: int) -> dict:
    subset = nasa_df[nasa_df["month"] == month].copy()
    return {
        "mean_mm": round(float(subset["rainfall_mm"].mean()), 1),
        "min_mm": round(float(subset["rainfall_mm"].min()), 1),
        "max_mm": round(float(subset["rainfall_mm"].max()), 1),
        "yearly_values": [
            {"year": int(row["year"]), "rainfall_mm": round(float(row["rainfall_mm"]), 1)}
            for _, row in subset.sort_values("year").iterrows()
        ]
    }


def get_seasonal_profile() -> list:
    result = []
    for m in range(1, 13):
        subset = nasa_df[nasa_df["month"] == m]
        result.append({
            "month": m,
            "month_name": MONTH_NAMES[m],
            "avg_rainfall_mm": round(float(subset["rainfall_mm"].mean()), 1)
        })
    return result


class PredictionRequest(BaseModel):
    year: int
    month: int


@app.get("/")
def root():
    return {
        "app": "Droplet AI",
        "version": "2.0",
        "dataset": "NASA POWER (1990-2026)",
        "status": "running",
        "models_loaded": {
            "gbr": gbr_model is not None,
            "lgbm": lgbm_model is not None,
            "xgboost": xgb_model is not None,
            "random_forest": rf_model is not None,
        },
        "default_model": "GBR (Gradient Boosting Regressor)",
    }


@app.post("/predict")
def predict(request: PredictionRequest):
    if request.month < 1 or request.month > 12:
        return {"error": "Month must be between 1 and 12"}
    if gbr_model is None:
        return {"error": "GBR model is not available"}

    X = build_feature_vector(request.year, request.month)
    predicted_mm = predict_with_model(gbr_model, X)
    category = categorize_rainfall(predicted_mm)
    advisory = get_advisory(category)
    probability = get_rainfall_probability(predicted_mm)
    hist = get_historical_stats(request.month)
    climate = get_monthly_climate_averages(request.month)

    return {
        "model": "GBR",
        "year": request.year,
        "month": request.month,
        "month_name": MONTH_NAMES[request.month],
        "predicted_rainfall_mm": predicted_mm,
        "rainfall_probability_pct": probability,
        "category": category,
        "advisory": advisory,
        "historical_avg_mm": hist["mean_mm"],
        "historical_min_mm": hist["min_mm"],
        "historical_max_mm": hist["max_mm"],
        "climate_inputs": {
            "humidity_pct": round(climate["humidity_pct"], 1),
            "temp_mean_C": round(climate["temp_mean_C"], 1),
            "temp_max_C": round(climate["temp_max_C"], 1),
            "temp_min_C": round(climate["temp_min_C"], 1),
            "pressure_kPa": round(climate["pressure_kPa"], 1),
            "wind_speed_ms": round(climate["wind_speed_ms"], 2),
        }
    }


@app.post("/compare")
def compare(request: PredictionRequest):
    if request.month < 1 or request.month > 12:
        return {"error": "Month must be between 1 and 12"}

    X = build_feature_vector(request.year, request.month)
    hist = get_historical_stats(request.month)
    climate = get_monthly_climate_averages(request.month)

    models = {
        "gbr": gbr_model,
        "lgbm": lgbm_model,
        "xgboost": xgb_model,
        "random_forest": rf_model,
    }

    results = {}
    categories = []

    for key, model in models.items():
        if model is None:
            results[key] = {"error": "Model not available"}
            continue
        try:
            mm = predict_with_model(model, X)
            cat = categorize_rainfall(mm)
            prob = get_rainfall_probability(mm)
            results[key] = {
                "predicted_rainfall_mm": mm,
                "rainfall_probability_pct": prob,
                "category": cat,
                "advisory": get_advisory(cat),
            }
            categories.append(cat)
        except Exception as e:
            results[key] = {"error": str(e)}

    most_common_cat = max(set(categories), key=categories.count) if categories else None
    agreement_count = categories.count(most_common_cat) if most_common_cat else 0
    agreement_pct = round(agreement_count / len(categories) * 100) if categories else 0

    gbr_mm = results.get("gbr", {}).get("predicted_rainfall_mm", 0) or 0
    overall_probability = get_rainfall_probability(gbr_mm)

    return {
        "year": request.year,
        "month": request.month,
        "month_name": MONTH_NAMES[request.month],
        "rainfall_probability_pct": overall_probability,
        "models": results,
        "model_agreement": {
            "consensus_category": most_common_cat,
            "agreement_pct": agreement_pct,
            "models_in_agreement": agreement_count,
            "total_models": len(categories),
        },
        "historical": hist,
        "climate_inputs": {
            "humidity_pct": round(climate["humidity_pct"], 1),
            "temp_mean_C": round(climate["temp_mean_C"], 1),
            "temp_max_C": round(climate["temp_max_C"], 1),
            "temp_min_C": round(climate["temp_min_C"], 1),
            "pressure_kPa": round(climate["pressure_kPa"], 1),
            "wind_speed_ms": round(climate["wind_speed_ms"], 2),
        }
    }


@app.get("/seasonal")
def seasonal():
    return {"profile": get_seasonal_profile()}


@app.get("/historical/{month}")
def historical(month: int):
    if month < 1 or month > 12:
        return {"error": "Month must be between 1 and 12"}
    hist = get_historical_stats(month)
    return {"month": month, "month_name": MONTH_NAMES[month], **hist}