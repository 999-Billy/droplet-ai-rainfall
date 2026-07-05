import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
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

const List<String> modelOrder = ["gbr", "lgbm", "xgboost", "random_forest"];
const Map<String, String> modelDisplayNames = {
  "gbr": "GBR",
  "lgbm": "LightGBM",
  "xgboost": "XGBoost",
  "random_forest": "Random Forest",
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
  List<dynamic>? _historicalValues;
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
      if (newYear >= _minYear && newYear <= _maxYear) _selectedYear = newYear;
    });
  }

  Future<void> _getComparison() async {
    setState(() {
      _isLoading = true;
      _showSlowLoadMessage = false;
      _errorMessage = null;
      _result = null;
      _historicalValues = null;
    });

    _slowLoadTimer?.cancel();
    _slowLoadTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _isLoading) setState(() => _showSlowLoadMessage = true);
    });

    try {
      final responses = await Future.wait([
        http.post(
          Uri.parse("$apiBaseUrl/compare"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"year": _selectedYear, "month": _selectedMonth}),
        ),
        http.get(Uri.parse("$apiBaseUrl/historical/$_selectedMonth")),
      ]);

      _slowLoadTimer?.cancel();

      if (responses[0].statusCode == 200) {
        final data = jsonDecode(responses[0].body);
        final histData = jsonDecode(responses[1].body);
        setState(() {
          _result = data;
          _historicalValues = histData["yearly_values"] as List<dynamic>? ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "Server returned status ${responses[0].statusCode}";
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
            "Compare Models",
            style: GoogleFonts.manrope(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "See how all four models forecast the same month",
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
                      "Compare All Models",
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
          if (_result != null) ...[
            _buildModelAgreementCard(theme),
            const SizedBox(height: 16),
            _buildComparisonBarsCard(theme),
            const SizedBox(height: 16),
            if (_historicalValues != null && _historicalValues!.isNotEmpty) ...[
              _buildHistoricalContextChart(theme),
              const SizedBox(height: 16),
              _buildThreeYearChart(theme),
              const SizedBox(height: 16),
            ],
            _buildClimateStrip(theme),
          ],
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

  Widget _buildModelAgreementCard(ThemeData theme) {
    final agreement =
        _result!["model_agreement"] as Map<String, dynamic>? ?? {};
    final pct = (agreement["agreement_pct"] as num?)?.toInt() ?? 0;
    final consensus = agreement["consensus_category"] as String? ?? "--";
    final count = (agreement["models_in_agreement"] as num?)?.toInt() ?? 0;
    final total = (agreement["total_models"] as num?)?.toInt() ?? 0;
    final probability = _result!["rainfall_probability_pct"] ?? "--";

    Color confidenceColor;
    String confidenceLabel;
    if (pct == 100) {
      confidenceColor = Colors.green;
      confidenceLabel = "High Confidence";
    } else if (pct >= 75) {
      confidenceColor = Colors.orange;
      confidenceLabel = "Moderate Confidence";
    } else {
      confidenceColor = Colors.red;
      confidenceLabel = "Low Confidence";
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Model Consensus",
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "$count of $total models agree: $consensus",
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: theme.textTheme.bodySmall?.color?.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: confidenceColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: confidenceColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    confidenceLabel,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: confidenceColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct / 100,
                backgroundColor: theme.colorScheme.primary.withValues(
                  alpha: 0.12,
                ),
                valueColor: AlwaysStoppedAnimation<Color>(confidenceColor),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "$pct% agreement",
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: confidenceColor,
                  ),
                ),
                Text(
                  "Rainfall intensity: $probability%",
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

  Widget _buildComparisonBarsCard(ThemeData theme) {
    final models = _result!["models"] as Map<String, dynamic>? ?? {};

    double maxMm = 1;
    for (final key in modelOrder) {
      final entry = models[key];
      if (entry != null && entry["predicted_rainfall_mm"] != null) {
        final mm = (entry["predicted_rainfall_mm"] as num?)?.toDouble() ?? 0.0;
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
              "Model Predictions — ${_result!["month_name"] ?? ""} ${_result!["year"] ?? ""}",
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w700,
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
                  "GBR is the recommended default model",
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
    final isDefault = key == "gbr";
    final barColor = isDefault
        ? theme.colorScheme.primary
        : theme.colorScheme.primary.withValues(alpha: 0.45);

    if (entry == null || entry["error"] != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 90,
              child: Text(
                modelDisplayNames[key]!,
                style: GoogleFonts.manrope(
                  fontSize: 12,
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

    final mm = (entry["predicted_rainfall_mm"] as num?)?.toDouble() ?? 0.0;
    final category = entry["category"] as String? ?? "";
    final ratio = maxMm > 0 ? (mm / maxMm).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 90,
            child: Row(
              children: [
                if (isDefault)
                  Icon(Icons.star, size: 12, color: theme.colorScheme.primary),
                if (isDefault) const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    modelDisplayNames[key]!,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
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
            width: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${mm.toStringAsFixed(1)}mm",
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

  Widget _buildHistoricalContextChart(ThemeData theme) {
    final values = _historicalValues!;
    if (values.isEmpty) return const SizedBox.shrink();

    final mmValues = values
        .map((e) => (e["rainfall_mm"] as num?)?.toDouble() ?? 0.0)
        .toList();
    final maxVal = mmValues.isEmpty
        ? 1.0
        : mmValues.reduce((a, b) => a > b ? a : b);

    final models = _result!["models"] as Map<String, dynamic>? ?? {};
    final gbrEntry = models["gbr"];
    final gbrPred = gbrEntry != null
        ? (gbrEntry["predicted_rainfall_mm"] as num?)?.toDouble()
        : null;

    final spots = values.map((e) {
      return FlSpot(
        (e["year"] as num?)?.toDouble() ?? 0,
        (e["rainfall_mm"] as num?)?.toDouble() ?? 0,
      );
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Historical Context — ${monthNamesCompare[_selectedMonth] ?? ""}",
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              "Actual recorded rainfall for this month (1990–2025)",
              style: GoogleFonts.manrope(
                fontSize: 11,
                color: theme.textTheme.bodySmall?.color?.withValues(
                  alpha: 0.55,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxVal * 1.25,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: theme.colorScheme.primary.withValues(alpha: 0.6),
                      barWidth: 2,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, index) =>
                            FlDotCirclePainter(
                              radius: 3,
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.6,
                              ),
                              strokeWidth: 0,
                              strokeColor: Colors.transparent,
                            ),
                      ),
                    ),
                    if (gbrPred != null)
                      LineChartBarData(
                        spots: [FlSpot(_selectedYear.toDouble(), gbrPred)],
                        isCurved: false,
                        color: theme.colorScheme.primary,
                        barWidth: 0,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, bar, index) =>
                              FlDotCirclePainter(
                                radius: 6,
                                color: theme.colorScheme.primary,
                                strokeWidth: 2,
                                strokeColor: Colors.white,
                              ),
                        ),
                      ),
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 5,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: GoogleFonts.manrope(fontSize: 9),
                        ),
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 35,
                        getTitlesWidget: (value, meta) => Text(
                          "${value.toInt()}",
                          style: GoogleFonts.manrope(fontSize: 9),
                        ),
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: theme.dividerColor.withValues(alpha: 0.3),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  "GBR prediction for $_selectedYear",
                  style: GoogleFonts.manrope(
                    fontSize: 10,
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

  Widget _buildThreeYearChart(ThemeData theme) {
    final values = _historicalValues!;
    final models = _result!["models"] as Map<String, dynamic>? ?? {};
    final List<Map<String, dynamic>> chartPoints = [];

    for (int offset = -3; offset <= 3; offset++) {
      final y = _selectedYear + offset;
      if (offset < 0) {
        final match = values.where((e) => e["year"] == y).toList();
        if (match.isNotEmpty) {
          chartPoints.add({
            "year": y,
            "value": (match.first["rainfall_mm"] as num?)?.toDouble() ?? 0.0,
            "isActual": true,
            "isSelected": false,
          });
        }
      } else if (offset == 0) {
        final gbrEntry = models["gbr"];
        final pred = gbrEntry != null
            ? (gbrEntry["predicted_rainfall_mm"] as num?)?.toDouble()
            : null;
        if (pred != null) {
          chartPoints.add({
            "year": y,
            "value": pred,
            "isActual": false,
            "isSelected": true,
          });
        }
      } else {
        final histAvg = values.isNotEmpty
            ? values
                      .map((e) => (e["rainfall_mm"] as num?)?.toDouble() ?? 0.0)
                      .reduce((a, b) => a + b) /
                  values.length
            : 0.0;
        chartPoints.add({
          "year": y,
          "value": histAvg,
          "isActual": false,
          "isSelected": false,
        });
      }
    }

    if (chartPoints.isEmpty) return const SizedBox.shrink();

    final maxVal = chartPoints
        .map((e) => e["value"] as double)
        .reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "3-Year Trend View",
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              "3 years before and after $_selectedYear — ${monthNamesCompare[_selectedMonth] ?? ""}",
              style: GoogleFonts.manrope(
                fontSize: 11,
                color: theme.textTheme.bodySmall?.color?.withValues(
                  alpha: 0.55,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 140,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxVal * 1.3,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        if (groupIndex >= chartPoints.length) {
                          return null;
                        }
                        final point = chartPoints[groupIndex];
                        final label = point["isActual"] == true
                            ? "Actual"
                            : point["isSelected"] == true
                            ? "Predicted"
                            : "Est. avg";
                        return BarTooltipItem(
                          "${point["year"]}\n${rod.toY.toStringAsFixed(0)}mm ($label)",
                          GoogleFonts.manrope(
                            fontSize: 11,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= chartPoints.length) {
                            return const SizedBox.shrink();
                          }
                          final point = chartPoints[idx];
                          return Text(
                            "${point["year"]}",
                            style: GoogleFonts.manrope(
                              fontSize: 9,
                              fontWeight: point["isSelected"] == true
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: point["isSelected"] == true
                                  ? theme.colorScheme.primary
                                  : theme.textTheme.bodySmall?.color
                                        ?.withValues(alpha: 0.6),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: theme.dividerColor.withValues(alpha: 0.3),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(chartPoints.length, (i) {
                    final point = chartPoints[i];
                    final val = point["value"] as double;
                    final isSelected = point["isSelected"] == true;
                    final isActual = point["isActual"] == true;
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: val,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : isActual
                              ? theme.colorScheme.primary.withValues(alpha: 0.5)
                              : theme.colorScheme.primary.withValues(
                                  alpha: 0.25,
                                ),
                          width: 22,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              children: [
                _legend(
                  theme,
                  theme.colorScheme.primary,
                  "Predicted (selected year)",
                ),
                _legend(
                  theme,
                  theme.colorScheme.primary.withValues(alpha: 0.5),
                  "Actual (past)",
                ),
                _legend(
                  theme,
                  theme.colorScheme.primary.withValues(alpha: 0.25),
                  "Est. average (future)",
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _legend(ThemeData theme, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 10,
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  // Climate inputs as a unified divided stat strip —
  // same visual language as Home and Predict screens
  Widget _buildClimateStrip(ThemeData theme) {
    final climate = _result!["climate_inputs"] as Map<String, dynamic>? ?? {};
    final dividerColor =
        theme.textTheme.bodySmall?.color?.withValues(alpha: 0.12) ??
        Colors.grey.withValues(alpha: 0.12);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Climate Inputs Used",
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    "Historical averages for ${monthNamesCompare[_selectedMonth] ?? ""} — NASA POWER (1990–2026)",
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
            // Row 1: humidity, avg temp, max temp
            Row(
              children: [
                Expanded(
                  child: _climateColumn(
                    theme,
                    "${climate["humidity_pct"] ?? '--'}%",
                    "Humidity",
                  ),
                ),
                Container(width: 1, height: 40, color: dividerColor),
                Expanded(
                  child: _climateColumn(
                    theme,
                    "${climate["temp_mean_C"] ?? '--'}°C",
                    "Avg Temp",
                  ),
                ),
                Container(width: 1, height: 40, color: dividerColor),
                Expanded(
                  child: _climateColumn(
                    theme,
                    "${climate["temp_max_C"] ?? '--'}°C",
                    "Max Temp",
                  ),
                ),
              ],
            ),
            Divider(height: 16, color: dividerColor),
            // Row 2: min temp, pressure, wind
            Row(
              children: [
                Expanded(
                  child: _climateColumn(
                    theme,
                    "${climate["temp_min_C"] ?? '--'}°C",
                    "Min Temp",
                  ),
                ),
                Container(width: 1, height: 40, color: dividerColor),
                Expanded(
                  child: _climateColumn(
                    theme,
                    "${climate["pressure_kPa"] ?? '--'} kPa",
                    "Pressure",
                  ),
                ),
                Container(width: 1, height: 40, color: dividerColor),
                Expanded(
                  child: _climateColumn(
                    theme,
                    "${climate["wind_speed_ms"] ?? '--'} m/s",
                    "Wind",
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _climateColumn(ThemeData theme, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: theme.textTheme.titleMedium?.color,
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
