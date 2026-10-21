import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Skeleton loader for loading states.
class SkeletonLoader extends StatelessWidget {
  const SkeletonLoader({
    super.key,
    this.height = 100,
    this.width,
    this.borderRadius = 16,
  });

  final double height;
  final double? width;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
      highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
      child: Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Dashboard skeleton layout.
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          SkeletonLoader(height: 180),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: SkeletonLoader(height: 90)),
              SizedBox(width: 12),
              Expanded(child: SkeletonLoader(height: 90)),
            ],
          ),
          SizedBox(height: 16),
          SkeletonLoader(height: 120),
        ],
      ),
    );
  }
}
