import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';

/// A reusable cached avatar widget that replaces NetworkImage throughout the app.
/// Shows a shimmer placeholder while loading and a fallback initial letter on error.
class CachedAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final String? fallbackInitial;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final BoxFit fit;

  const CachedAvatar({
    super.key,
    this.imageUrl,
    this.radius = 24,
    this.fallbackInitial,
    this.backgroundColor,
    this.foregroundColor,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.primary.withAlpha(30);
    final fg = foregroundColor ?? AppColors.primary;
    final size = radius * 2;
    final initial = (fallbackInitial?.isNotEmpty == true)
        ? fallbackInitial![0].toUpperCase()
        : '?';

    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildFallback(size, bg, fg, initial);
    }

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        width: size,
        height: size,
        fit: fit,
        placeholder: (context, url) => _buildShimmer(size),
        errorWidget: (context, url, error) => _buildFallback(size, bg, fg, initial),
      ),
    );
  }

  Widget _buildShimmer(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Colors.grey.shade200,
            Colors.grey.shade100,
            Colors.grey.shade200,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }

  Widget _buildFallback(double size, Color bg, Color fg, String initial) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bg,
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: fg,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.35,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }
}

/// A reusable cached decoration image for containers (replaces NetworkImage in BoxDecoration).
/// Returns a [DecorationImage] backed by [CachedNetworkImageProvider].
DecorationImage cachedDecorationImage(
  String? url, {
  BoxFit fit = BoxFit.cover,
  String fallback = 'https://i.pravatar.cc/150?img=11',
}) {
  return DecorationImage(
    image: CachedNetworkImageProvider(
      (url != null && url.isNotEmpty) ? url : fallback,
    ),
    fit: fit,
  );
}
