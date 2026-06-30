import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

const Map<int, String> monthNamesCompare = {
  1: "January",
  2: "February",
  3: "March",
  4: "April",
  5: "May",
  6: "June",
  7: "July",
  8: "August",
  9: "September",
  10: "October",
  11: "November",
  12: "December",
};

const List<String> modelOrder = ["sarima", "gam", "xgboost"];
const Map<String, String> modelDisplayNames = {
  "sarima": "SARIMA",
  "gam": "GAM",
  "xgboost": "XGBoost",
};

class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  static const int _minYear = 2015;
  static const int _maxYear = 2036;

  Map<String, dynamic>? _result;
  bool _isLoading = false;
  String? _errorMessage;

  void _changeYear(int delta) {
    setState(() {
      final newYear = _selectedYear + delta;
      if (newYear >= _minYear && newYear <= _maxYear) {
        _selectedYear = newYear;
      }
    });
  }

  Future<void> _getComparison() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _result = null;
    });

    try {
      final response = await http.post(
        Uri.parse("$apiBaseUrl/compare"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"year": _selectedYear, "month": _selectedMonth}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _result = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "Server returned status ${response.statusCode}";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            "Could not reach the prediction server.\nMake sure the backend is running.";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Compare Models",
            style: GoogleFonts.manrope(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "See how SARIMA, GAM, and XGBoost forecast the same month",
            style: GoogleFonts.manrope(
              fontSize: 13,
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),
          _buildSelectorCard(theme),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isLoading ? null : _getComparison,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      "Compare Models",
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),
          if (_errorMessage != null) _buildErrorCard(theme),
          if (_result != null) _buildComparisonChart(theme),
        ],
      ),
    );
  }

  Widget _buildSelectorCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  "Month",
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                DropdownButton<int>(
                  value: _selectedMonth,
                  underline: const SizedBox.shrink(),
                  items: monthNamesCompare.entries.map((entry) {
                    return DropdownMenuItem<int>(
                      value: entry.key,
                      child: Text(
                        entry.value,
                        style: GoogleFonts.manrope(fontSize: 14),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedMonth = value);
                  },
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Icon(Icons.event, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  "Year",
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _selectedYear > _minYear
                      ? () => _changeYear(-1)
                      : null,
                ),
                SizedBox(
                  width: 56,
                  child: Text(
                    "$_selectedYear",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.fraunces(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _selectedYear < _maxYear
                      ? () => _changeYear(1)
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 40, color: theme.colorScheme.error),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? "Something went wrong",
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonChart(ThemeData theme) {
    final models = _result!["models"] as Map<String, dynamic>;

    double maxMm = 1;
    for (final key in modelOrder) {
      final entry = models[key];
      if (entry != null && entry["predicted_rainfall_mm"] != null) {
        final mm = (entry["predicted_rainfall_mm"] as num).toDouble();
        if (mm > maxMm) maxMm = mm;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${_result!["month_name"]} ${_result!["year"]}",
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 20),
            for (final key in modelOrder)
              _buildModelBar(theme, key, models[key], maxMm),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.star, size: 14, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  "SARIMA is the recommended default model",
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    color: theme.textTheme.bodySmall?.color?.withValues(
                      alpha: 0.6,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelBar(
    ThemeData theme,
    String key,
    dynamic entry,
    double maxMm,
  ) {
    final isDefault = key == "sarima";
    final barColor = isDefault
        ? theme.colorScheme.primary
        : theme.colorScheme.primary.withValues(alpha: 0.45);

    if (entry == null || entry["error"] != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 70,
              child: Text(
                modelDisplayNames[key]!,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: Text(
                "Unavailable",
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final mm = (entry["predicted_rainfall_mm"] as num).toDouble();
    final category = entry["category"] as String;
    final ratio = (mm / maxMm).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 70,
            child: Row(
              children: [
                if (isDefault)
                  Icon(Icons.star, size: 12, color: theme.colorScheme.primary),
                if (isDefault) const SizedBox(width: 4),
                Text(
                  modelDisplayNames[key]!,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    Container(
                      height: 22,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.08,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      height: 22,
                      width: constraints.maxWidth * ratio,
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 92,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${mm.toStringAsFixed(1)} mm",
                  textAlign: TextAlign.right,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  category,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    color: theme.textTheme.bodySmall?.color?.withValues(
                      alpha: 0.55,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
