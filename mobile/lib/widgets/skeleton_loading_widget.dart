import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';

class SkeletonLoadingWidget extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonLoadingWidget({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.primary.withAlpha(20),
      highlightColor: AppColors.primary.withAlpha(50),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

// Pre-built skeleton for Upcoming Session
class UpcomingSessionSkeleton extends StatelessWidget {
  const UpcomingSessionSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(100),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SkeletonLoadingWidget(width: 48, height: 48, borderRadius: 12),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonLoadingWidget(width: 140, height: 18, borderRadius: 4),
                    SizedBox(height: 6),
                    SkeletonLoadingWidget(width: 100, height: 14, borderRadius: 4),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: const [
              Expanded(child: SkeletonLoadingWidget(width: double.infinity, height: 44, borderRadius: 12)),
              SizedBox(width: 12),
              Expanded(child: SkeletonLoadingWidget(width: double.infinity, height: 44, borderRadius: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
