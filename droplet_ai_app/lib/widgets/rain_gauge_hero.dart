import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const double historicalMinMm = 0.0;
const double historicalMaxMm = 574.0;

class RainGaugeHero extends StatelessWidget {
  final String monthName;
  final int year;
  final double mm;
  final String category;
  final double probabilityPct;
  final String advisory;

  const RainGaugeHero({
    super.key,
    required this.monthName,
    required this.year,
    required this.mm,
    required this.category,
    required this.probabilityPct,
    required this.advisory,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fillRatio =
        ((mm - historicalMinMm) / (historicalMaxMm - historicalMinMm)).clamp(
          0.0,
          1.0,
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month/year label
            Text(
              "$monthName $year",
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Gauge
                SizedBox(
                  width: 52,
                  height: 130,
                  child: CustomPaint(
                    painter: RainGaugePainter(
                      fillRatio: fillRatio,
                      fillColor: theme.colorScheme.primary,
                      trackColor: theme.colorScheme.primary.withValues(
                        alpha: 0.12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Probability percentage — the headline number
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "${probabilityPct.toStringAsFixed(0)}%",
                            style: GoogleFonts.fraunces(
                              fontSize: 48,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                      // mm value beneath the percentage
                      Text(
                        "${mm.toStringAsFixed(1)} mm expected",
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          color: theme.textTheme.bodyMedium?.color?.withValues(
                            alpha: 0.65,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Category pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          category,
                          style: GoogleFonts.manrope(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Advisory text — full width beneath the gauge row
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      advisory,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        height: 1.5,
                        color: theme.textTheme.bodyMedium?.color?.withValues(
                          alpha: 0.8,
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
}

class RainGaugePainter extends CustomPainter {
  final double fillRatio;
  final Color fillColor;
  final Color trackColor;

  RainGaugePainter({
    required this.fillRatio,
    required this.fillColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width / 2;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    final trackPaint = Paint()..color = trackColor;
    canvas.drawRRect(rrect, trackPaint);

    canvas.save();
    canvas.clipRRect(rrect);
    final fillHeight = size.height * fillRatio;
    final fillRect = Rect.fromLTWH(
      0,
      size.height - fillHeight,
      size.width,
      fillHeight,
    );
    final fillPaint = Paint()..color = fillColor;
    canvas.drawRect(fillRect, fillPaint);
    canvas.restore();

    final outlinePaint = Paint()
      ..color = fillColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(rrect, outlinePaint);

    final tickPaint = Paint()
      ..color = trackColor.withValues(alpha: 0.8)
      ..strokeWidth = 1.5;
    final midY = size.height / 2;
    canvas.drawLine(Offset(0, midY), Offset(size.width * 0.3, midY), tickPaint);
  }

  @override
  bool shouldRepaint(covariant RainGaugePainter oldDelegate) {
    return oldDelegate.fillRatio != fillRatio ||
        oldDelegate.fillColor != fillColor;
  }
}
