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
              "A web-based rainfall prediction system for Tarkwa, Ghana, combining "
              "four machine learning models trained on NASA POWER satellite-derived "
              "meteorological data. Built to support agriculture, mining operations, "
              "environmental management, and disaster preparedness in the Western Region.",
            ),
            const SizedBox(height: 12),
            _bodyText(
              theme,
              "Forecasts are based on NASA POWER daily observations (1990–2026), aggregated "
              "to monthly totals and averages. Six meteorological variables are used as "
              "predictors: temperature, humidity, atmospheric pressure, and wind speed.",
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
              "The large percentage shown on each forecast (e.g. 12.2%) represents "
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
        "name": "GBR",
        "full": "Gradient Boosting Regressor",
        "desc":
            "sklearn's implementation of stage-wise additive gradient boosting. "
            "The best-performing model in this study (R² 0.7140). Used as the "
            "default model for all predictions.",
        "isDefault": true,
      },
      {
        "name": "LightGBM",
        "full": "Light Gradient Boosting Machine",
        "desc":
            "Microsoft's efficient gradient boosting implementation using "
            "leaf-wise tree growth. Second-best performer (R² 0.6891). "
            "Handles right-skewed rainfall distributions effectively.",
        "isDefault": false,
      },
      {
        "name": "XGBoost",
        "full": "Extreme Gradient Boosting",
        "desc":
            "Scalable gradient boosting with built-in regularization to prevent "
            "overfitting. Third-best performer (R² 0.6608). Provides interpretable "
            "feature importances showing which variables drove each prediction.",
        "isDefault": false,
      },
      {
        "name": "Random Forest",
        "full": "Random Forest Regressor",
        "desc":
            "An ensemble of independently built decision trees, averaged for "
            "robustness. Fourth performer (R² 0.6414). More resistant to outliers "
            "than gradient boosting methods.",
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
      (name: "GBR", rmse: "63.15", mae: "45.67", r2: "0.7140", isDefault: true),
      (
        name: "LightGBM",
        rmse: "65.85",
        mae: "47.18",
        r2: "0.6891",
        isDefault: false,
      ),
      (
        name: "XGBoost",
        rmse: "68.78",
        mae: "50.84",
        r2: "0.6608",
        isDefault: false,
      ),
      (
        name: "Random Forest",
        rmse: "70.72",
        mae: "51.72",
        r2: "0.6414",
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
              "Evaluated on test period Jan 2019 – Jun 2026 (90 months)",
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
              "RMSE and MAE in mm. R² closer to 1.0 = better fit.",
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
              "• Forecasts are based on NASA POWER satellite-derived data (1990–2026), "
              "not live meteorological station observations. Predictions use historical "
              "monthly averages as model inputs for future dates.\n\n"
              "• All four models use recursive lag features — their predictions for "
              "future dates are influenced by recent recorded rainfall, which may not "
              "fully capture abrupt climate shifts.\n\n"
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
