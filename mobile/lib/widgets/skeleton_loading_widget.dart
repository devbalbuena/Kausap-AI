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

// Pre-built skeleton for Discover Professionals card
class ProfessionalCardSkeleton extends StatelessWidget {
  const ProfessionalCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonLoadingWidget(width: 80, height: 80, borderRadius: 16),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonLoadingWidget(width: 120, height: 20, borderRadius: 4),
                const SizedBox(height: 8),
                const SkeletonLoadingWidget(width: 80, height: 16, borderRadius: 4),
                const SizedBox(height: 12),
                Row(
                  children: const [
                    SkeletonLoadingWidget(width: 60, height: 24, borderRadius: 12),
                    SizedBox(width: 8),
                    SkeletonLoadingWidget(width: 60, height: 24, borderRadius: 12),
                  ],
                ),
              ],
            ),
          ),
        ],
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
