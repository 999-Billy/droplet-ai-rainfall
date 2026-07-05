import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../widgets/rain_gauge_hero.dart';
import '../config.dart';

const Map<int, String> monthNames = {
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

class PredictScreen extends StatefulWidget {
  const PredictScreen({super.key});

  @override
  State<PredictScreen> createState() => _PredictScreenState();
}

class _PredictScreenState extends State<PredictScreen> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  static const int _minYear = 2015;
  static const int _maxYear = 2036;

  Map<String, dynamic>? _result;
  bool _isLoading = false;
  bool _showSlowLoadMessage = false;
  String? _errorMessage;
  Timer? _slowLoadTimer;

  @override
  void dispose() {
    _slowLoadTimer?.cancel();
    super.dispose();
  }

  void _changeYear(int delta) {
    setState(() {
      final newYear = _selectedYear + delta;
      if (newYear >= _minYear && newYear <= _maxYear) {
        _selectedYear = newYear;
      }
    });
  }

  Future<void> _getForecast() async {
    setState(() {
      _isLoading = true;
      _showSlowLoadMessage = false;
      _errorMessage = null;
      _result = null;
    });

    _slowLoadTimer?.cancel();
    _slowLoadTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _isLoading) {
        setState(() => _showSlowLoadMessage = true);
      }
    });

    try {
      final response = await http.post(
        Uri.parse("$apiBaseUrl/predict"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"year": _selectedYear, "month": _selectedMonth}),
      );

      _slowLoadTimer?.cancel();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.containsKey("error")) {
          setState(() {
            _errorMessage = data["error"];
            _isLoading = false;
          });
        } else {
          setState(() {
            _result = data;
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = "Server returned status ${response.statusCode}";
          _isLoading = false;
        });
      }
    } catch (e) {
      _slowLoadTimer?.cancel();
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
            "Predict Rainfall",
            style: GoogleFonts.manrope(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Choose a month and year to get a SARIMA forecast for Tarkwa",
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
              onPressed: _isLoading ? null : _getForecast,
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
                      "Get Forecast",
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
          if (_isLoading && _showSlowLoadMessage) ...[
            const SizedBox(height: 10),
            Text(
              "Waking up the server — this can take up to a minute\nif it hasn't been used recently.",
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
              ),
            ),
          ],
          const SizedBox(height: 24),
          if (_errorMessage != null) _buildErrorCard(theme),
          if (_result != null)
            RainGaugeHero(
              monthName: _result!["month_name"],
              year: _result!["year"],
              mm: (_result!["predicted_rainfall_mm"] as num).toDouble(),
              category: _result!["category"],
            ),
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
                  items: monthNames.entries.map((entry) {
                    return DropdownMenuItem<int>(
                      value: entry.key,
                      child: Text(
                        entry.value,
                        style: GoogleFonts.manrope(fontSize: 14),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedMonth = value);
                    }
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
}
