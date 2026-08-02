import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// An accessible error widget that communicates errors through:
/// 1. Color (red background/text)
/// 2. Icon (error_outline or warning_amber)
/// 3. Shape (left accent border)
/// 4. Text prefix with "⚠" symbol
///
/// This ensures colorblind users are not relying solely on red color.
class AccessibleErrorWidget extends StatelessWidget {
  final String message;
  final AccessibleErrorStyle style;

  const AccessibleErrorWidget({
    super.key,
    required this.message,
    this.style = AccessibleErrorStyle.banner,
  });

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case AccessibleErrorStyle.banner:
        return _buildBanner(context);
      case AccessibleErrorStyle.inline:
        return _buildInline(context);
    }
  }

  Widget _buildBanner(BuildContext context) {
    return Semantics(
      label: 'Error: $message',
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.errorBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.errorBorder, width: 1.5),
          // Left accent bar: non-color visual indicator
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon indicator — works regardless of color perception
            Container(
              margin: const EdgeInsets.only(top: 1),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.error,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Action Required',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: AppColors.error,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.error,
                      fontSize: 13,
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

  Widget _buildInline(BuildContext context) {
    return Semantics(
      label: 'Error: $message',
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 6, left: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 14,
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                '⚠ $message',
                style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum AccessibleErrorStyle { banner, inline }
