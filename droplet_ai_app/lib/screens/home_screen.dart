import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import '../widgets/rain_gauge_hero.dart';
import '../config.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _prediction;
  List<dynamic>? _seasonalProfile;
  bool _isLoading = true;
  bool _showSlowLoadMessage = false;
  String? _errorMessage;
  Timer? _slowLoadTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _slowLoadTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _showSlowLoadMessage = false;
      _errorMessage = null;
      _prediction = null;
      _seasonalProfile = null;
    });

    _slowLoadTimer?.cancel();
    _slowLoadTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _isLoading) {
        setState(() => _showSlowLoadMessage = true);
      }
    });

    final now = DateTime.now();
    int targetYear = now.year;
    int targetMonth = now.month + 1;
    if (targetMonth > 12) {
      targetMonth = 1;
      targetYear += 1;
    }

    try {
      final results = await Future.wait([
        http
            .post(
              Uri.parse("$apiBaseUrl/predict"),
              headers: {"Content-Type": "application/json"},
              body: jsonEncode({"year": targetYear, "month": targetMonth}),
            )
            .timeout(const Duration(seconds: 90)),
        http
            .get(Uri.parse("$apiBaseUrl/seasonal"))
            .timeout(const Duration(seconds: 90)),
      ]);

      _slowLoadTimer?.cancel();

      if (results[0].statusCode == 200) {
        final predData = jsonDecode(results[0].body);
        final seasonalData = jsonDecode(results[1].body);

        if (predData.containsKey("error")) {
          setState(() {
            _errorMessage = predData["error"];
            _isLoading = false;
          });
        } else {
          setState(() {
            _prediction = predData;
            _seasonalProfile = seasonalData["profile"] as List<dynamic>;
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = "Server returned status ${results[0].statusCode}";
          _isLoading = false;
        });
      }
    } on TimeoutException {
      _slowLoadTimer?.cancel();
      setState(() {
        _errorMessage =
            "The server is taking too long to respond.\nPlease tap Try Again — it may still be waking up.";
        _isLoading = false;
      });
    } catch (e) {
      _slowLoadTimer?.cancel();
      setState(() {
        _errorMessage =
            "Could not reach the prediction server.\nPlease check your connection and try again.";
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
      onRefresh: _loadData,
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
            if (!_isLoading &&
                _prediction != null &&
                _seasonalProfile != null) ...[
              RainGaugeHero(
                monthName: _prediction!["month_name"] as String? ?? "",
                year: (_prediction!["year"] as num?)?.toInt() ?? 0,
                mm:
                    (_prediction!["predicted_rainfall_mm"] as num?)
                        ?.toDouble() ??
                    0.0,
                category: _prediction!["category"] as String? ?? "",
                probabilityPct:
                    (_prediction!["rainfall_probability_pct"] as num?)
                        ?.toDouble() ??
                    0.0,
                advisory: _prediction!["advisory"] as String? ?? "",
              ),
              const SizedBox(height: 16),
              _buildStatStrip(theme),
              const SizedBox(height: 16),
              _buildSeasonalChart(theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            CircularProgressIndicator(color: theme.colorScheme.primary),
            if (_showSlowLoadMessage) ...[
              const SizedBox(height: 16),
              Text(
                "Waking up the server — this can take up to a minute\nif it hasn't been used recently.",
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: theme.textTheme.bodySmall?.color?.withValues(
                    alpha: 0.6,
                  ),
                ),
              ),
            ],
          ],
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
              onPressed: _loadData,
              child: const Text("Try Again"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatStrip(ThemeData theme) {
    final historicalAvg = _prediction!["historical_avg_mm"];
    final historicalMin = _prediction!["historical_min_mm"];
    final historicalMax = _prediction!["historical_max_mm"];
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
                "${historicalAvg ?? '--'}",
                "mm",
                "Avg",
              ),
            ),
            Container(width: 1, height: 40, color: dividerColor),
            Expanded(
              child: _statColumn(
                theme,
                "${historicalMin ?? '--'}",
                "mm",
                "Min",
              ),
            ),
            Container(width: 1, height: 40, color: dividerColor),
            Expanded(
              child: _statColumn(
                theme,
                "${historicalMax ?? '--'}",
                "mm",
                "Max",
              ),
            ),
            Container(width: 1, height: 40, color: dividerColor),
            Expanded(
              child: _statColumn(
                theme,
                _prediction!["category"] as String? ?? "--",
                "",
                "Level",
              ),
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
            fontSize: 13,
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

  Widget _buildSeasonalChart(ThemeData theme) {
    final profile = _seasonalProfile!;
    if (profile.isEmpty) return const SizedBox.shrink();

    final maxVal = profile
        .map((e) => (e["avg_rainfall_mm"] as num?)?.toDouble() ?? 0.0)
        .reduce((a, b) => a > b ? a : b);

    final currentMonth = () {
      int m = DateTime.now().month + 1;
      return m > 12 ? 1 : m;
    }();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Annual Rainfall Pattern",
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              "Historical monthly averages — Tarkwa (1990–2026)",
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
                  maxY: maxVal * 1.2,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final entry = profile[groupIndex];
                        return BarTooltipItem(
                          "${entry["month_name"]}\n${rod.toY.toStringAsFixed(0)}mm",
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
                          const labels = [
                            'J',
                            'F',
                            'M',
                            'A',
                            'M',
                            'J',
                            'J',
                            'A',
                            'S',
                            'O',
                            'N',
                            'D',
                          ];
                          final idx = value.toInt();
                          if (idx < 0 || idx >= labels.length) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            labels[idx],
                            style: GoogleFonts.manrope(
                              fontSize: 10,
                              fontWeight: idx + 1 == currentMonth
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: idx + 1 == currentMonth
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
                  barGroups: List.generate(profile.length, (i) {
                    final val =
                        (profile[i]["avg_rainfall_mm"] as num?)?.toDouble() ??
                        0.0;
                    final isHighlighted = i + 1 == currentMonth;
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: val,
                          color: isHighlighted
                              ? theme.colorScheme.primary
                              : theme.colorScheme.primary.withValues(
                                  alpha: 0.35,
                                ),
                          width: 14,
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
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  "Upcoming month",
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    color: theme.textTheme.bodySmall?.color?.withValues(
                      alpha: 0.6,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  "Other months",
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
}
