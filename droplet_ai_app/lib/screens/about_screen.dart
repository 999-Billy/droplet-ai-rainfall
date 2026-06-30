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
          _buildModelsCard(theme),
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
              "statistical and machine learning models to support agriculture, mining "
              "operations, environmental management, and disaster preparedness in the "
              "Western Region.",
            ),
            const SizedBox(height: 12),
            _bodyText(
              theme,
              "Forecasts are based on historical monthly rainfall records from the "
              "Tarkwa-U.M.A.T. station (1996–2019), provided by the Ghana Meteorological "
              "Agency.",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelsCard(ThemeData theme) {
    final models = [
      {
        "name": "SARIMA",
        "full": "Seasonal Autoregressive Integrated Moving Average",
        "desc":
            "A statistical time-series model that captures Tarkwa's seasonal rainfall cycle directly from its own historical pattern. Used as the default forecasting model.",
        "isDefault": true,
      },
      {
        "name": "GAM",
        "full": "Generalised Additive Model",
        "desc":
            "A statistical model that captures smooth, non-linear relationships between rainfall and calendar month.",
        "isDefault": false,
      },
      {
        "name": "XGBoost",
        "full": "Extreme Gradient Boosting",
        "desc":
            "A machine learning model that learns from recent rainfall patterns (previous months) alongside seasonality.",
        "isDefault": false,
      },
      {
        "name": "LSTM",
        "full": "Long Short-Term Memory",
        "desc":
            "A deep learning model designed to learn long-term dependencies across sequences of past rainfall. Trained and evaluated as part of this project, but not served by the live app (see Limitations below).",
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
                model["name"],
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  model["full"],
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
          _bodyText(theme, model["desc"]),
        ],
      ),
    );
  }

  Widget _buildScaleCard(ThemeData theme) {
    final scale = [
      {"range": "0–50 mm", "label": "Very Low"},
      {"range": "51–100 mm", "label": "Low"},
      {"range": "101–150 mm", "label": "Moderate"},
      {"range": "151–250 mm", "label": "High"},
      {"range": "251–350 mm", "label": "Very High"},
      {"range": "350+ mm", "label": "Extreme"},
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
                        row["range"]!,
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        row["label"]!,
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
              "• Historical data covers 1996–2019. Forecasts for dates beyond this range "
              "rely on the models' learned seasonal patterns, not live observations.\n\n"
              "• XGBoost forecasts for future dates use recursive forecasting, chaining "
              "the model's own predictions forward month by month. Uncertainty compounds "
              "the further ahead the forecast extends.\n\n"
              "• SARIMA's forecast confidence naturally narrows for near-term predictions "
              "and widens for dates further from the training period.\n\n"
              "• LSTM was trained and evaluated alongside the other three models, but is "
              "not served by this live application due to memory constraints on free-tier "
              "hosting infrastructure. Its full implementation and results remain available "
              "in the project's source notebooks.",
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
              "Department of Mathematical Sciences",
            ),
          ],
        ),
      ),
    );
  }
}
