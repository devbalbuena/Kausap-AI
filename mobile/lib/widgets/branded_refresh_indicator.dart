import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A branded Pull-to-Refresh widget that wraps any scrollable child.
/// Shows an animated Kausap AI logo + "Refreshing..." text.
class BrandedRefreshIndicator extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final String? refreshLabel;

  const BrandedRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.refreshLabel,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      backgroundColor: Theme.of(context).colorScheme.surface,
      strokeWidth: 2.5,
      displacement: 56,
      notificationPredicate: defaultScrollNotificationPredicate,
      triggerMode: RefreshIndicatorTriggerMode.onEdge,
      child: child,
    );
  }
}

/// A custom sliver header that doubles as the pull-to-refresh trigger label.
/// Insert this at the top of a CustomScrollView to show branded "refreshing" state.
class KausapRefreshSliver extends StatelessWidget {
  final String label;
  const KausapRefreshSliver({super.key, this.label = 'Refreshing...'});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(5),
              ),
              child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 13),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
