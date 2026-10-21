import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_colors.dart';

/// Premium card with soft shadow and rounded corners.
class VitalCard extends StatelessWidget {
  const VitalCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.color,
    this.gradient,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? color;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget card = Container(
      decoration: BoxDecoration(
        color: gradient == null
            ? (color ?? (isDark ? AppColors.cardDark : AppColors.cardLight))
            : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      padding: padding,
      child: child,
    );

    if (onTap != null) {
      card = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: card,
        ),
      );
    }

    return card.animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }
}
