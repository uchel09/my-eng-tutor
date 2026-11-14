import 'package:flutter/material.dart';

/// Compact circular progress indicator whose stroke and percentage text
/// automatically adapt to mastery percentage ranges.
class FlashcardProgressCircle extends StatelessWidget {
  const FlashcardProgressCircle({
    super.key,
    required this.percent,
    this.hasCards = true,
    this.size = 48,
    this.strokeWidth = 5,
  });

  final int percent;
  final bool hasCards;
  final double size;
  final double strokeWidth;

  /// Resolves indicator ring color according to `[0%, 1..39%, 40..79%, 80..99%, 100%]`.
  static Color colorForProgress(
    int percent,
    bool hasCards,
    ColorScheme colorScheme,
  ) {
    final clamped = percent.clamp(0, 100);
    if (!hasCards || clamped == 0) {
      return colorScheme.outlineVariant;
    }
    if (clamped <= 39) {
      return Colors.red.shade600;
    }
    if (clamped <= 79) {
      return Colors.amber.shade700;
    }
    if (clamped <= 99) {
      return Colors.blue.shade600;
    }
    return Colors.green.shade600;
  }

  /// Resolves percentage text color (`onSurfaceVariant` when `0%` or empty).
  static Color textColorForProgress(
    int percent,
    bool hasCards,
    ColorScheme colorScheme,
  ) {
    final clamped = percent.clamp(0, 100);
    if (!hasCards || clamped == 0) {
      return colorScheme.onSurfaceVariant;
    }
    return colorForProgress(clamped, hasCards, colorScheme);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final clamped = hasCards ? percent.clamp(0, 100) : 0;
    final indicatorColor = colorForProgress(clamped, hasCards, colorScheme);
    final labelColor = textColorForProgress(clamped, hasCards, colorScheme);
    final trackColor = (!hasCards || clamped == 0)
        ? colorScheme.outlineVariant.withValues(alpha: 0.45)
        : colorScheme.outlineVariant.withValues(alpha: 0.25);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: !hasCards ? 0.0 : clamped / 100.0,
              strokeWidth: strokeWidth,
              strokeCap: StrokeCap.round,
              backgroundColor: trackColor,
              valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(strokeWidth + 3),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '$clamped%',
                maxLines: 1,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: labelColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
