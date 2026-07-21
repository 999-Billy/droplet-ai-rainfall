from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import json
import pandas as pd
import os

app = FastAPI(
    title="Droplet AI",
    description="Rainfall Forecast API for Tarkwa, Ghana — 2026-2030 Monthly Forecasts (NASA POWER Multi-Variable Dataset)"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

DATA_DIR = os.path.join(os.path.dirname(__file__), "..", "data")
FORECAST_PATH = os.path.join(os.path.dirname(__file__), "forecasts_2026_2030.json")

print("Loading precomputed 2026-2030 forecasts...")
try:
    with open(FORECAST_PATH) as f:
        FORECAST_DATA = json.load(f)
    FORECASTS_BY_KEY = {
        (entry["year"], entry["month"]): entry for entry in FORECAST_DATA["forecasts"]
    }
    print(f"✓ Forecasts loaded ({len(FORECASTS_BY_KEY)} months, {FORECAST_DATA['forecast_start']} to {FORECAST_DATA['forecast_end']})")
except Exception as e:
    print(f"✗ Forecasts failed to load: {e}")
    FORECAST_DATA = None
    FORECASTS_BY_KEY = {}

print("Loading NASA POWER monthly data (for historical/seasonal endpoints)...")
try:
    nasa_df = pd.read_csv(
        os.path.join(DATA_DIR, "tarkwa_nasa_monthly.csv"),
        parse_dates=["date"]
    ).sort_values("date").reset_index(drop=True)
    print("✓ NASA POWER monthly data loaded")
except Exception as e:
    print(f"✗ NASA POWER data failed to load: {e}")
    nasa_df = None

print("Startup complete.")

MONTH_NAMES = {
    1: "January", 2: "February", 3: "March", 4: "April",
    5: "May", 6: "June", 7: "July", 8: "August",
    9: "September", 10: "October", 11: "November", 12: "December"
}

# The single highest monthly rainfall ever recorded in the Tarkwa
# NASA POWER dataset (October 2024: 573.9mm) — used as the denominator
# for the rainfall intensity percentage shown to users.
ALL_TIME_MAX_RAINFALL_MM = 573.9

PRIMARY_MODEL_KEY = "xgboost"
PRIMARY_MODEL_NAME = "XGBoost (multivariate)"


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
    Example: 69.9mm predicted -> (69.9 / 573.9) x 100 = 12.2%"""
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
        "version": "3.0",
        "dataset": "NASA POWER (1990-2026)",
        "status": "running",
        "forecast_range": f"{FORECAST_DATA['forecast_start']} to {FORECAST_DATA['forecast_end']}" if FORECAST_DATA else None,
        "models_available": ["xgboost", "gam", "sarimax", "lstm"],
        "default_model": PRIMARY_MODEL_NAME,
    }


@app.post("/predict")
def predict(request: PredictionRequest):
    if request.month < 1 or request.month > 12:
        return {"error": "Month must be between 1 and 12"}

    key = (request.year, request.month)
    if key not in FORECASTS_BY_KEY:
        return {"error": f"Date out of forecast range ({FORECAST_DATA['forecast_start']} to {FORECAST_DATA['forecast_end']})"}

    entry = FORECASTS_BY_KEY[key]
    predicted_mm = entry[PRIMARY_MODEL_KEY]
    category = categorize_rainfall(predicted_mm)
    advisory = get_advisory(category)
    probability = get_rainfall_probability(predicted_mm)
    hist = get_historical_stats(request.month)

    return {
        "model": PRIMARY_MODEL_NAME,
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
    }


@app.post("/compare")
def compare(request: PredictionRequest):
    if request.month < 1 or request.month > 12:
        return {"error": "Month must be between 1 and 12"}

    key = (request.year, request.month)
    if key not in FORECASTS_BY_KEY:
        return {"error": f"Date out of forecast range ({FORECAST_DATA['forecast_start']} to {FORECAST_DATA['forecast_end']})"}

    entry = FORECASTS_BY_KEY[key]
    hist = get_historical_stats(request.month)

    model_keys = ["xgboost", "gam", "sarimax", "lstm"]
    results = {}
    categories = []

    for key_name in model_keys:
        mm = entry[key_name]
        cat = categorize_rainfall(mm)
        prob = get_rainfall_probability(mm)
        results[key_name] = {
            "predicted_rainfall_mm": mm,
            "rainfall_probability_pct": prob,
            "category": cat,
            "advisory": get_advisory(cat),
        }
        categories.append(cat)

    most_common_cat = max(set(categories), key=categories.count) if categories else None
    agreement_count = categories.count(most_common_cat) if most_common_cat else 0
    agreement_pct = round(agreement_count / len(categories) * 100) if categories else 0

    primary_mm = results.get(PRIMARY_MODEL_KEY, {}).get("predicted_rainfall_mm", 0) or 0
    overall_probability = get_rainfall_probability(primary_mm)

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


@app.get("/forecast/all")
def forecast_all():
    """Full 60-month primary-model (XGBoost) forecast series, 2026-2030 -- for frontend charts."""
    if not FORECAST_DATA:
        return {"error": "Forecast data not loaded"}
    return [
        {"date": entry["date"], "year": entry["year"], "month": entry["month"],
         "rainfall_mm": entry[PRIMARY_MODEL_KEY]}
        for entry in FORECAST_DATA["forecasts"]
    ]