import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderCard(theme),
          const SizedBox(height: 16),
          _buildPercentageExplainerCard(theme),
          const SizedBox(height: 16),
          _buildModelsCard(theme),
          const SizedBox(height: 16),
          _buildPerformanceCard(theme),
          const SizedBox(height: 16),
          _buildScaleCard(theme),
          const SizedBox(height: 16),
          _buildLimitationsCard(theme),
          const SizedBox(height: 16),
          _buildCreditsCard(theme),
        ],
      ),
    );
  }

  Widget _sectionTitle(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: GoogleFonts.manrope(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _bodyText(ThemeData theme, String text) {
    return Text(
      text,
      style: GoogleFonts.manrope(
        fontSize: 13,
        height: 1.5,
        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.85),
      ),
    );
  }

  Widget _buildHeaderCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.water_drop,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Text(
                  "Droplet AI",
                  style: GoogleFonts.fraunces(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _bodyText(
              theme,
              "A web-based rainfall forecasting system for Tarkwa, Ghana, combining "
              "four statistical and machine learning models trained on NASA POWER "
              "satellite-derived meteorological data. Built to support agriculture, "
              "mining operations, environmental management, and disaster preparedness "
              "in the Western Region.",
            ),
            const SizedBox(height: 12),
            _bodyText(
              theme,
              "The app forecasts monthly rainfall from January 2026 through December "
              "2030. Each model was trained in two forms: a univariate version using "
              "only rainfall history, and a multivariate version additionally using "
              "temperature, humidity, atmospheric pressure, wind speed, and seasonal "
              "and lagged rainfall features. The deployed app uses the multivariate "
              "models; the univariate versions are documented in the accompanying "
              "thesis for comparison.",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPercentageExplainerCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.percent, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                _sectionTitle(theme, "What the Percentage Means"),
              ],
            ),
            _bodyText(
              theme,
              "The large percentage shown on each forecast (e.g. 41.8%) represents "
              "the predicted rainfall as a proportion of the highest monthly rainfall "
              "ever recorded in the Tarkwa dataset — 573.9mm in October 2024.\n\n"
              "Formula: Predicted mm ÷ 573.9mm × 100\n\n"
              "This gives you immediate context: a prediction of 12% means this month "
              "is expected to bring about an eighth of the most extreme month ever "
              "recorded. A prediction of 80% or above signals an exceptionally heavy "
              "rainfall month by historical standards.",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelsCard(ThemeData theme) {
    final models = [
      {
        "name": "XGBoost",
        "full": "Extreme Gradient Boosting (multivariate)",
        "desc":
            "Scalable gradient-boosted trees with built-in regularization. "
            "The best-performing model in this study (R² 0.7369). Used as the "
            "default model for all predictions.",
        "isDefault": true,
      },
      {
        "name": "GAM",
        "full": "Generalized Additive Model (multivariate)",
        "desc":
            "Fits smooth, flexible functions to each predictor rather than a "
            "single linear relationship. Second-best performer (R² 0.6305), "
            "and the most interpretable of the four models.",
        "isDefault": false,
      },
      {
        "name": "SARIMAX",
        "full": "Seasonal ARIMA with Exogenous Variables (multivariate)",
        "desc":
            "A classical statistical time-series model that captures trend "
            "and seasonality directly, extended here with climate variables "
            "as exogenous regressors. Third performer (R² 0.6134).",
        "isDefault": false,
      },
      {
        "name": "LSTM",
        "full": "Long Short-Term Memory Network (multivariate)",
        "desc":
            "A recurrent neural network designed to learn patterns across "
            "sequences of past months. Fourth performer (R² 0.4169) — deep "
            "learning models typically need more training data than was "
            "available here (~348 months) to outperform simpler methods.",
        "isDefault": false,
      },
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(theme, "The Four Models"),
            for (final model in models) _buildModelRow(theme, model),
          ],
        ),
      ),
    );
  }

  Widget _buildModelRow(ThemeData theme, Map<String, dynamic> model) {
    final isDefault = model["isDefault"] as bool;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isDefault)
                Icon(Icons.star, size: 14, color: theme.colorScheme.primary),
              if (isDefault) const SizedBox(width: 6),
              Text(
                model["name"] as String,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  model["full"] as String,
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    color: theme.textTheme.bodySmall?.color?.withValues(
                      alpha: 0.5,
                    ),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _bodyText(theme, model["desc"] as String),
        ],
      ),
    );
  }

  Widget _buildPerformanceCard(ThemeData theme) {
    final models = [
      (
        name: "XGBoost",
        rmse: "60.58",
        mae: "45.45",
        r2: "0.7369",
        isDefault: true,
      ),
      (
        name: "GAM",
        rmse: "71.79",
        mae: "54.50",
        r2: "0.6305",
        isDefault: false,
      ),
      (
        name: "SARIMAX",
        rmse: "73.43",
        mae: "52.83",
        r2: "0.6134",
        isDefault: false,
      ),
      (
        name: "LSTM",
        rmse: "90.18",
        mae: "64.09",
        r2: "0.4169",
        isDefault: false,
      ),
    ];

    final dividerColor =
        theme.textTheme.bodySmall?.color?.withValues(alpha: 0.12) ??
        Colors.grey.withValues(alpha: 0.12);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(theme, "Model Performance"),
            Text(
              "Evaluated on chronological test period Jan 2019 – Jun 2026, multivariate models",
              style: GoogleFonts.manrope(
                fontSize: 11,
                color: theme.textTheme.bodySmall?.color?.withValues(
                  alpha: 0.55,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    "Model",
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: theme.textTheme.bodySmall?.color?.withValues(
                        alpha: 0.6,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "RMSE",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: theme.textTheme.bodySmall?.color?.withValues(
                        alpha: 0.6,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "MAE",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: theme.textTheme.bodySmall?.color?.withValues(
                        alpha: 0.6,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "R²",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: theme.textTheme.bodySmall?.color?.withValues(
                        alpha: 0.6,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Divider(color: dividerColor, height: 16),
            for (int i = 0; i < models.length; i++) ...[
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        if (models[i].isDefault) ...[
                          Icon(
                            Icons.star,
                            size: 11,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Flexible(
                          child: Text(
                            models[i].name,
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: models[i].isDefault
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      models[i].rmse,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(fontSize: 12),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      models[i].mae,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(fontSize: 12),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      models[i].r2,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: models[i].isDefault
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: models[i].isDefault
                            ? theme.colorScheme.primary
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
              if (i < models.length - 1)
                Divider(color: dividerColor, height: 12),
            ],
            const SizedBox(height: 8),
            Text(
              "RMSE and MAE in mm. R² closer to 1.0 = better fit. Univariate "
              "counterparts of all four models were also trained and are "
              "documented in the thesis for comparison, but are not used in the app.",
              style: GoogleFonts.manrope(
                fontSize: 10,
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScaleCard(ThemeData theme) {
    final scale = [
      ("0–50 mm", "Very Low"),
      ("51–100 mm", "Low"),
      ("101–150 mm", "Moderate"),
      ("151–250 mm", "High"),
      ("251–350 mm", "Very High"),
      ("350+ mm", "Extreme"),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(theme, "Rainfall Interpretation Scale"),
            for (final row in scale)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 90,
                      child: Text(
                        row.$1,
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        row.$2,
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          color: theme.textTheme.bodyMedium?.color?.withValues(
                            alpha: 0.75,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLimitationsCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                _sectionTitle(theme, "Limitations"),
              ],
            ),
            _bodyText(
              theme,
              "• Forecasts for 2026–2030 rely on historical monthly climatological "
              "averages for temperature, humidity, pressure, and wind speed, since "
              "actual future values for these variables cannot be observed. This is "
              "a standard approach in applied forecasting but means the models do "
              "not account for any future deviation from typical seasonal patterns.\n\n"
              "• All four models forecast recursively — each month's prediction feeds "
              "into the next month's lag features, so forecast uncertainty compounds "
              "the further out the forecast extends toward 2030.\n\n"
              "• Monthly aggregation smooths daily rainfall variability — the system "
              "predicts monthly totals, not daily or weekly events.\n\n"
              "• The system is calibrated on Tarkwa-specific data and is not intended "
              "for generalisation to other locations without retraining on local data.",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditsCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(theme, "Project Credits"),
            _bodyText(
              theme,
              "Development of a Web-Based Rainfall Prediction System Using Statistical "
              "and Machine Learning Models: A Case Study of Tarkwa, Ghana\n\n"
              "Tetteh Andy Bilson\n"
              "Benjamin Oppong\n"
              "Prince Kwadwo Korley\n"
              "Henry Nana Osei Asamoah\n\n"
              "Supervisor: Assoc. Prof. Lewis Brew\n\n"
              "University of Mines and Technology (UMaT), Tarkwa\n"
              "Faculty of Computing and Mathematical Sciences\n"
              "Department of Mathematical Sciences\n\n"
              "Dataset: NASA POWER Meteorological Data (1990–2026)\n"
              "nasa.gov/power",
            ),
          ],
        ),
      ),
    );
  }
}
