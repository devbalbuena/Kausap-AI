import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';

/// A robust, reusable cached avatar widget.
/// Supports network URLs, base64 data URIs, local file paths, and fallback letter initials.
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
        : 'U';

    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildFallback(size, bg, fg, initial);
    }

    final url = imageUrl!;

    // 1. Base64 Data URI
    if (url.startsWith('data:image')) {
      try {
        final commaIdx = url.indexOf(',');
        if (commaIdx != -1) {
          final base64Data = url.substring(commaIdx + 1);
          final bytes = base64Decode(base64Data);
          return ClipOval(
            child: Image.memory(
              bytes,
              width: size,
              height: size,
              fit: fit,
              errorBuilder: (context, error, stackTrace) => _buildFallback(size, bg, fg, initial),
            ),
          );
        }
      } catch (_) {
        return _buildFallback(size, bg, fg, initial);
      }
    }

    // 2. Local File
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      final file = File(url);
      if (file.existsSync()) {
        return ClipOval(
          child: Image.file(
            file,
            width: size,
            height: size,
            fit: fit,
            errorBuilder: (context, error, stackTrace) => _buildFallback(size, bg, fg, initial),
          ),
        );
      }
    }

    // 3. Network URL
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url,
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
            fontSize: size * 0.4,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }
}

/// Helper function to create an ImageProvider for any URL / Base64 / File / Asset.
ImageProvider getAvatarImageProvider(String? url) {
  if (url == null || url.isEmpty) {
    return const AssetImage('assets/avatars/avatar_basic_kim.png');
  }
  if (url.startsWith('data:image')) {
    try {
      final commaIdx = url.indexOf(',');
      if (commaIdx != -1) {
        return MemoryImage(base64Decode(url.substring(commaIdx + 1)));
      }
    } catch (_) {}
  }
  if (!url.startsWith('http://') && !url.startsWith('https://')) {
    final file = File(url);
    if (file.existsSync()) {
      return FileImage(file);
    }
  }
  return CachedNetworkImageProvider(url);
}
