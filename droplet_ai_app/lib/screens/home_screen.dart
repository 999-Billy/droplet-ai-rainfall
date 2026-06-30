import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../widgets/rain_gauge_hero.dart';
import '../config.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _prediction;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchNextMonthPrediction();
  }

  Future<void> _fetchNextMonthPrediction() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final now = DateTime.now();
    int targetYear = now.year;
    int targetMonth = now.month + 1;
    if (targetMonth > 12) {
      targetMonth = 1;
      targetYear += 1;
    }

    try {
      final response = await http.post(
        Uri.parse("$apiBaseUrl/predict"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"year": targetYear, "month": targetMonth}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.containsKey("error")) {
          setState(() {
            _errorMessage = data["error"];
            _isLoading = false;
          });
        } else {
          setState(() {
            _prediction = data;
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
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12
        ? "Good morning"
        : hour < 18
        ? "Good afternoon"
        : "Good evening";

    return RefreshIndicator(
      onRefresh: _fetchNextMonthPrediction,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: GoogleFonts.manrope(
                fontSize: 15,
                color: theme.textTheme.bodyMedium?.color?.withValues(
                  alpha: 0.6,
                ),
              ),
            ),
            Row(
              children: [
                Text(
                  "Tarkwa",
                  style: GoogleFonts.manrope(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_isLoading) _buildLoadingCard(theme),
            if (!_isLoading && _errorMessage != null) _buildErrorCard(theme),
            if (!_isLoading && _prediction != null)
              RainGaugeHero(
                monthName: _prediction!["month_name"],
                year: _prediction!["year"],
                mm: (_prediction!["predicted_rainfall_mm"] as num).toDouble(),
                category: _prediction!["category"],
              ),
            const SizedBox(height: 16),
            if (!_isLoading && _prediction != null) _buildStatStrip(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: CircularProgressIndicator(color: theme.colorScheme.primary),
        ),
      ),
    );
  }

  Widget _buildErrorCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.cloud_off, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? "Something went wrong",
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchNextMonthPrediction,
              child: const Text("Try Again"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatStrip(ThemeData theme) {
    final historicalAvg = _prediction!["historical_average_mm"];
    final percentVsAvg = _prediction!["percent_vs_average"];
    final isAboveAverage = percentVsAvg >= 0;
    final dividerColor =
        theme.textTheme.bodySmall?.color?.withValues(alpha: 0.12) ??
        Colors.grey.withValues(alpha: 0.12);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        child: Row(
          children: [
            Expanded(
              child: _statColumn(
                theme,
                "${_prediction!["predicted_rainfall_mm"]}",
                "mm",
                "Predicted",
              ),
            ),
            Container(width: 1, height: 40, color: dividerColor),
            Expanded(
              child: _statColumn(
                theme,
                "$historicalAvg",
                "mm",
                "Historical Avg",
              ),
            ),
            Container(width: 1, height: 40, color: dividerColor),
            Expanded(
              child: _statColumn(
                theme,
                "${isAboveAverage ? '+' : ''}$percentVsAvg",
                "%",
                "vs Average",
                valueColor: isAboveAverage
                    ? theme.colorScheme.primary
                    : theme.colorScheme.error,
              ),
            ),
            Container(width: 1, height: 40, color: dividerColor),
            Expanded(
              child: _statColumn(theme, _prediction!["category"], "", "Level"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statColumn(
    ThemeData theme,
    String value,
    String unit,
    String label, {
    Color? valueColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          unit.isEmpty ? value : "$value$unit",
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: valueColor ?? theme.textTheme.titleMedium?.color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(
            fontSize: 10,
            letterSpacing: 0.3,
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}
