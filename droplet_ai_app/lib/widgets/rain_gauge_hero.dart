import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// The historical rainfall range observed in the Tarkwa dataset (1996-2019),
// used to scale the gauge fill proportionally — shared by every screen
// that shows a gauge, so the scale stays consistent app-wide.
const double historicalMinMm = 0.6;
const double historicalMaxMm = 525.9;

// Reusable hero widget: a rain gauge + headline number + category pill.
// Used on the Home screen (next month) and the Predict screen (any
// user-chosen month), so both feel like the same instrument, not two
// different designs bolted together.
class RainGaugeHero extends StatelessWidget {
  final String monthName;
  final int year;
  final double mm;
  final String category;

  const RainGaugeHero({
    super.key,
    required this.monthName,
    required this.year,
    required this.mm,
    required this.category,
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 56,
              height: 140,
              child: CustomPaint(
                painter: RainGaugePainter(
                  fillRatio: fillRatio,
                  fillColor: theme.colorScheme.primary,
                  trackColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$monthName $year",
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: theme.textTheme.bodySmall?.color?.withValues(
                        alpha: 0.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        mm.toStringAsFixed(1),
                        style: GoogleFonts.fraunces(
                          fontSize: 40,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                          height: 1.0,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6, left: 4),
                        child: Text(
                          "mm",
                          style: GoogleFonts.manrope(
                            fontSize: 15,
                            color: theme.textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
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
      ),
    );
  }
}

// The gauge visual itself — a rounded capsule that fills from the bottom
// proportional to fillRatio, with a midpoint tick mark for reference.
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
    canvas.drawLine(
      Offset(0, midY),
      Offset(size.width * 0.25, midY),
      tickPaint,
    );
  }

  @override
  bool shouldRepaint(covariant RainGaugePainter oldDelegate) {
    return oldDelegate.fillRatio != fillRatio ||
        oldDelegate.fillColor != fillColor;
  }
}
