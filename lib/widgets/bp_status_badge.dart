import 'package:flutter/material.dart';

import '../core/models/bp_classification.dart';

/// Blood pressure classification badge with color and icon.
class BpStatusBadge extends StatelessWidget {
  const BpStatusBadge({
    super.key,
    required this.classification,
    this.compact = false,
  });

  final BpClassification classification;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: classification.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(classification.icon, size: 16, color: classification.color),
            const SizedBox(width: 6),
            Text(
              classification.label,
              style: TextStyle(
                color: classification.color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: classification.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: classification.color.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: classification.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(classification.icon, color: classification.color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  classification.label,
                  style: TextStyle(
                    color: classification.color,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  classification.explanation,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        height: 1.4,
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
