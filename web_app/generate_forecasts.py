import joblib
import numpy as np
import pandas as pd
import json
import os
from tensorflow.keras.models import load_model

MODELS_DIR = os.path.join(os.path.dirname(__file__), "..", "models")
DATA_DIR = os.path.join(os.path.dirname(__file__), "..", "data")

FEATURE_COLS = [
    "temp_mean_C", "temp_max_C", "temp_min_C",
    "humidity_pct", "pressure_kPa", "wind_speed_ms",
    "month_sin", "month_cos",
    "rainfall_lag1", "rainfall_lag2", "rainfall_roll3"
]

print("Loading NASA POWER monthly data...")
nasa_df = pd.read_csv(
    os.path.join(DATA_DIR, "tarkwa_nasa_monthly.csv"),
    parse_dates=["date"]
).sort_values("date").reset_index(drop=True)

print("Loading 4 multivariate models...")
xgb_bundle = joblib.load(os.path.join(MODELS_DIR, "xgb_multi_model.pkl"))
xgb_model = xgb_bundle["model_fit"]
print("✓ XGBoost loaded")

gam_bundle = joblib.load(os.path.join(MODELS_DIR, "gam_multi_model.pkl"))
gam_model = gam_bundle["model_fit"]
print("✓ GAM loaded")

sarimax_bundle = joblib.load(os.path.join(MODELS_DIR, "sarimax_multi_model.pkl"))
sarimax_model = sarimax_bundle["model_fit"]
print("✓ SARIMAX loaded")

lstm_model = load_model(os.path.join(MODELS_DIR, "lstm_multi_model.keras"))
lstm_scaler = joblib.load(os.path.join(MODELS_DIR, "lstm_multi_scaler.pkl"))
print("✓ LSTM + scaler loaded")


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


def build_future_row(month: int, lag1: float, lag2: float, roll3: float) -> dict:
    row = get_monthly_climate_averages(month)
    row["month_sin"] = float(np.sin(2 * np.pi * month / 12))
    row["month_cos"] = float(np.cos(2 * np.pi * month / 12))
    row["rainfall_lag1"] = lag1
    row["rainfall_lag2"] = lag2
    row["rainfall_roll3"] = roll3
    return row


# Seed recursive lags from the last 3 known actual months in the dataset
seed_history = list(nasa_df["rainfall_mm"].iloc[-3:].values)
future_dates = pd.date_range("2026-01-01", "2030-12-01", freq="MS")

# ================= XGBoost =================
history = seed_history.copy()
xgb_forecasts = []
for d in future_dates:
    lag1, lag2, roll3 = history[-1], history[-2], np.mean(history[-3:])
    row = build_future_row(d.month, lag1, lag2, roll3)
    X = np.array([[row[c] for c in FEATURE_COLS]])
    pred = max(0.0, float(xgb_model.predict(X)[0]))
    xgb_forecasts.append(pred)
    history.append(pred)

# ================= GAM =================
history = seed_history.copy()
gam_forecasts = []
for d in future_dates:
    lag1, lag2, roll3 = history[-1], history[-2], np.mean(history[-3:])
    row = build_future_row(d.month, lag1, lag2, roll3)
    X = np.array([[row[c] for c in FEATURE_COLS]])
    pred = max(0.0, float(gam_model.predict(X)[0]))
    gam_forecasts.append(pred)
    history.append(pred)

# ================= SARIMAX =================
history = seed_history.copy()
sarimax_forecasts = []
current_model = sarimax_model
for d in future_dates:
    lag1, lag2, roll3 = history[-1], history[-2], np.mean(history[-3:])
    row = build_future_row(d.month, lag1, lag2, roll3)
    exog_row = np.array([[row[c] for c in FEATURE_COLS]])
    step = current_model.get_forecast(steps=1, exog=exog_row)
    pred = max(0.0, float(np.asarray(step.predicted_mean).flatten()[0]))
    sarimax_forecasts.append(pred)
    history.append(pred)
    current_model = current_model.append(endog=[pred], exog=exog_row, refit=False)

# ================= LSTM =================
LOOKBACK = 12
ALL_COLS = ["rainfall_mm"] + FEATURE_COLS

# Recreate the 11 engineered features on the historical data to build the seed window
hist_feat = nasa_df.copy()
hist_feat["month_sin"] = np.sin(2 * np.pi * hist_feat["month"] / 12)
hist_feat["month_cos"] = np.cos(2 * np.pi * hist_feat["month"] / 12)
hist_feat["rainfall_lag1"] = hist_feat["rainfall_mm"].shift(1)
hist_feat["rainfall_lag2"] = hist_feat["rainfall_mm"].shift(2)
hist_feat["rainfall_roll3"] = hist_feat["rainfall_mm"].shift(1).rolling(3).mean()
hist_feat = hist_feat.dropna().reset_index(drop=True)

window_df = hist_feat[ALL_COLS].iloc[-LOOKBACK:].values
window_scaled = lstm_scaler.transform(window_df)

history = seed_history.copy()
lstm_forecasts = []
for d in future_dates:
    pred_scaled = lstm_model.predict(window_scaled.reshape(1, LOOKBACK, len(ALL_COLS)), verbose=0)
    dummy = np.zeros((1, len(ALL_COLS)))
    dummy[0, 0] = pred_scaled.flatten()[0]
    pred = max(0.0, float(lstm_scaler.inverse_transform(dummy)[0, 0]))
    lstm_forecasts.append(pred)
    history.append(pred)

    lag1, lag2, roll3 = history[-1], history[-2], np.mean(history[-3:])
    row = build_future_row(d.month, lag1, lag2, roll3)
    new_row = [pred] + [row[c] for c in FEATURE_COLS]
    new_row_scaled = lstm_scaler.transform([new_row])
    window_scaled = np.vstack([window_scaled[1:], new_row_scaled])

# ================= Combine and save =================
output = {
    "generated_from": str(nasa_df["date"].max().date()),
    "forecast_start": "2026-01-01",
    "forecast_end": "2030-12-01",
    "forecasts": []
}

for i, d in enumerate(future_dates):
    output["forecasts"].append({
        "date": str(d.date()),
        "year": int(d.year),
        "month": int(d.month),
        "xgboost": round(xgb_forecasts[i], 1),
        "gam": round(gam_forecasts[i], 1),
        "sarimax": round(sarimax_forecasts[i], 1),
        "lstm": round(lstm_forecasts[i], 1),
    })

out_path = os.path.join(os.path.dirname(__file__), "forecasts_2026_2030.json")
with open(out_path, "w") as f:
    json.dump(output, f, indent=2)

print(f"Saved {len(future_dates)} months of forecasts to {out_path}")
print(f"Sample (Jan 2026): {output['forecasts'][0]}")