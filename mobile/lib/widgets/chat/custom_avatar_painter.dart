import 'package:flutter/material.dart';

/// Predefined trait palette data for Custom Companion Studio
class CustomAvatarPalette {
  static const List<Map<String, dynamic>> skinTones = [
    {'name': 'Fair Light', 'color': Color(0xFFFCE7DB), 'shadow': Color(0xFFE8C8B8)},
    {'name': 'Warm Morena', 'color': Color(0xFFE0A87D), 'shadow': Color(0xFFC48B60)},
    {'name': 'Golden Tan', 'color': Color(0xFFC68B59), 'shadow': Color(0xFFA66E3E)},
    {'name': 'Deep Warm', 'color': Color(0xFF8D5524), 'shadow': Color(0xFF6B3E16)},
  ];

  static const List<Map<String, dynamic>> hairstyles = [
    {'name': 'Classic Crop', 'icon': '✂️'},
    {'name': 'Wavy Long', 'icon': '🌊'},
    {'name': 'High Ponytail', 'icon': '🎀'},
    {'name': 'Sleek Bob', 'icon': '💇‍♀️'},
    {'name': 'Curly Volume', 'icon': '🌀'},
  ];

  static const List<Map<String, dynamic>> hairColors = [
    {'name': 'Natural Black', 'color': Color(0xFF0F172A)},
    {'name': 'Espresso Brown', 'color': Color(0xFF3E2723)},
    {'name': 'Caramel Blonde', 'color': Color(0xFFB45309)},
    {'name': 'Pastel Rose', 'color': Color(0xFFEC4899)},
    {'name': 'Platinum Ash', 'color': Color(0xFF64748B)},
  ];

  static const List<Map<String, dynamic>> eyeStyles = [
    {'name': 'Almond Sparkle', 'icon': '✨'},
    {'name': 'Gentle Round', 'icon': '👀'},
    {'name': 'Happy Crescent', 'icon': '😊'},
  ];

  static const List<Map<String, dynamic>> eyeColors = [
    {'name': 'Obsidian Black', 'color': Color(0xFF0F172A)},
    {'name': 'Warm Chestnut', 'color': Color(0xFF5D4037)},
    {'name': 'Golden Hazel', 'color': Color(0xFF854D0E)},
    {'name': 'Ocean Sapphire', 'color': Color(0xFF0284C7)},
    {'name': 'Forest Emerald', 'color': Color(0xFF059669)},
  ];

  static const List<Map<String, dynamic>> accessories = [
    {'name': 'None', 'icon': '❌'},
    {'name': 'Round Glasses', 'icon': '👓'},
    {'name': 'Modern Frames', 'icon': '🕶️'},
    {'name': 'Star Hairclip', 'icon': '⭐'},
    {'name': 'Campus Headband', 'icon': '👑'},
  ];

  static const List<Map<String, dynamic>> outfits = [
    {'name': 'Campus Hoodie', 'icon': '🧥'},
    {'name': 'Academic Polo', 'icon': '👔'},
    {'name': 'Knit Sweater', 'icon': '🧶'},
    {'name': 'Casual Tee', 'icon': '👕'},
  ];

  static const List<Map<String, dynamic>> outfitColors = [
    {'name': 'Royal Ocean', 'color': Color(0xFF0077B6)},
    {'name': 'Sage Emerald', 'color': Color(0xFF059669)},
    {'name': 'Lavender Dream', 'color': Color(0xFF7C3AED)},
    {'name': 'Sunset Rose', 'color': Color(0xFFE11D48)},
    {'name': 'Slate Indigo', 'color': Color(0xFF334155)},
  ];

  static const List<Map<String, dynamic>> mascotHues = [
    {'name': 'Ocean Blue', 'gradient': [Color(0xFF0077B6), Color(0xFF00B4D8)]},
    {'name': 'Lavender Dream', 'gradient': [Color(0xFF7C3AED), Color(0xFFA78BFA)]},
    {'name': 'Matcha Mint', 'gradient': [Color(0xFF059669), Color(0xFF34D399)]},
    {'name': 'Sakura Rose', 'gradient': [Color(0xFFE11D48), Color(0xFFF472B6)]},
    {'name': 'Golden Sun', 'gradient': [Color(0xFFD97706), Color(0xFFFBBF24)]},
  ];
}

/// A crisp, dynamic layered vector avatar widget rendered via CustomPaint
class CustomAvatarWidget extends StatelessWidget {
  final Map<String, dynamic> config;
  final double size;
  final bool isTyping;

  const CustomAvatarWidget({
    super.key,
    required this.config,
    this.size = 64,
    this.isTyping = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMascot = config['type'] == 'mascot';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: size * 0.18,
            offset: Offset(0, size * 0.05),
          ),
        ],
      ),
      child: ClipOval(
        child: CustomPaint(
          size: Size(size, size),
          painter: _LayeredAvatarPainter(
            config: config,
            isMascot: isMascot,
            isTyping: isTyping,
          ),
        ),
      ),
    );
  }
}

class _LayeredAvatarPainter extends CustomPainter {
  final Map<String, dynamic> config;
  final bool isMascot;
  final bool isTyping;

  _LayeredAvatarPainter({
    required this.config,
    required this.isMascot,
    this.isTyping = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    if (isMascot) {
      _paintCustomMascot(canvas, size);
      return;
    }

    // ── 0. BACKGROUND CIRCLE ──
    final bgPaint = Paint()..color = const Color(0xFFF1F5F9);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // Get configuration values with fallbacks
    final int skinIdx = (config['skinIndex'] as int? ?? 1).clamp(0, CustomAvatarPalette.skinTones.length - 1);
    final int hairIdx = (config['hairIndex'] as int? ?? 1).clamp(0, CustomAvatarPalette.hairstyles.length - 1);
    final int hairColIdx = (config['hairColorIndex'] as int? ?? 0).clamp(0, CustomAvatarPalette.hairColors.length - 1);
    final int eyeIdx = (config['eyeStyleIndex'] as int? ?? 0).clamp(0, CustomAvatarPalette.eyeStyles.length - 1);
    final int eyeColIdx = (config['eyeColorIndex'] as int? ?? 0).clamp(0, CustomAvatarPalette.eyeColors.length - 1);
    final int accIdx = (config['accIndex'] as int? ?? 0).clamp(0, CustomAvatarPalette.accessories.length - 1);
    final int outfitColIdx = (config['outfitColorIndex'] as int? ?? 0).clamp(0, CustomAvatarPalette.outfitColors.length - 1);

    final skinColor = CustomAvatarPalette.skinTones[skinIdx]['color'] as Color;
    final skinShadow = CustomAvatarPalette.skinTones[skinIdx]['shadow'] as Color;
    final hairColor = CustomAvatarPalette.hairColors[hairColIdx]['color'] as Color;
    final eyeColor = CustomAvatarPalette.eyeColors[eyeColIdx]['color'] as Color;
    final outfitColor = CustomAvatarPalette.outfitColors[outfitColIdx]['color'] as Color;

    // ── 1. BODY / SHOULDERS & OUTFIT ──
    final outfitPaint = Paint()..color = outfitColor;
    final collarPaint = Paint()..color = Colors.white.withAlpha(200);

    // Shoulder curve
    final bodyPath = Path()
      ..moveTo(w * 0.15, h)
      ..cubicTo(w * 0.18, h * 0.72, w * 0.82, h * 0.72, w * 0.85, h)
      ..close();
    canvas.drawPath(bodyPath, outfitPaint);

    // Collar / Hoodie V
    final collarPath = Path()
      ..moveTo(w * 0.40, h * 0.76)
      ..lineTo(w * 0.50, h * 0.88)
      ..lineTo(w * 0.60, h * 0.76)
      ..close();
    canvas.drawPath(collarPath, collarPaint);

    // ── 2. NECK ──
    final neckPaint = Paint()..color = skinShadow;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.42, h * 0.62, w * 0.16, h * 0.18), Radius.circular(w * 0.05)),
      neckPaint,
    );

    // ── 3. BACK HAIR (for long styles) ──
    if (hairIdx == 1 || hairIdx == 2) {
      final backHairPaint = Paint()..color = hairColor;
      if (hairIdx == 1) {
        // Long wavy sides
        canvas.drawOval(Rect.fromLTWH(w * 0.16, h * 0.32, w * 0.68, h * 0.58), backHairPaint);
      } else if (hairIdx == 2) {
        // High ponytail back bundle
        canvas.drawCircle(Offset(w * 0.50, h * 0.18), w * 0.22, backHairPaint);
      }
    }

    // ── 4. HEAD / FACE ──
    final headPaint = Paint()..color = skinColor;
    final faceRect = Rect.fromCenter(center: Offset(w * 0.50, h * 0.46), width: w * 0.54, height: h * 0.58);
    canvas.drawOval(faceRect, headPaint);

    // Ears
    canvas.drawOval(Rect.fromLTWH(w * 0.20, h * 0.42, w * 0.08, h * 0.13), headPaint);
    canvas.drawOval(Rect.fromLTWH(w * 0.72, h * 0.42, w * 0.08, h * 0.13), headPaint);

    // Rosy Cheeks
    final blushPaint = Paint()..color = const Color(0xFFFF8A80).withAlpha(120);
    canvas.drawCircle(Offset(w * 0.32, h * 0.53), w * 0.065, blushPaint);
    canvas.drawCircle(Offset(w * 0.68, h * 0.53), w * 0.065, blushPaint);

    // ── 5. EYES & BROWS ──
    _paintEyes(canvas, size, eyeIdx, eyeColor, hairColor);

    // ── 6. NOSE & MOUTH ──
    final nosePaint = Paint()
      ..color = skinShadow
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.03
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.50, h * 0.48), Offset(w * 0.50, h * 0.52), nosePaint);

    // Upbeat Smile
    final mouthPaint = Paint()
      ..color = const Color(0xFF9E2A2B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.04
      ..strokeCap = StrokeCap.round;
    final mouthPath = Path()
      ..moveTo(w * 0.42, h * 0.59)
      ..quadraticBezierTo(w * 0.50, h * 0.67, w * 0.58, h * 0.59);
    canvas.drawPath(mouthPath, mouthPaint);

    // ── 7. FRONT HAIR ──
    _paintFrontHair(canvas, size, hairIdx, hairColor);

    // ── 8. GLASSES & ACCESSORIES ──
    _paintAccessories(canvas, size, accIdx);
  }

  void _paintEyes(Canvas canvas, Size size, int eyeStyle, Color eyeColor, Color browColor) {
    final w = size.width;
    final h = size.height;

    final browPaint = Paint()
      ..color = browColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.035
      ..strokeCap = StrokeCap.round;

    // Eyebrows
    final leftBrow = Path()
      ..moveTo(w * 0.30, h * 0.38)
      ..quadraticBezierTo(w * 0.38, h * 0.35, w * 0.44, h * 0.39);
    final rightBrow = Path()
      ..moveTo(w * 0.56, h * 0.39)
      ..quadraticBezierTo(w * 0.62, h * 0.35, w * 0.70, h * 0.38);
    canvas.drawPath(leftBrow, browPaint);
    canvas.drawPath(rightBrow, browPaint);

    if (eyeStyle == 2) {
      // Happy crescent eyes ( ◠ ‿ ◠ )
      final strokeEye = Paint()
        ..color = const Color(0xFF1E293B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.045
        ..strokeCap = StrokeCap.round;
      final leftArc = Path()
        ..moveTo(w * 0.30, h * 0.46)
        ..quadraticBezierTo(w * 0.37, h * 0.41, w * 0.44, h * 0.46);
      final rightArc = Path()
        ..moveTo(w * 0.56, h * 0.46)
        ..quadraticBezierTo(w * 0.63, h * 0.41, w * 0.70, h * 0.46);
      canvas.drawPath(leftArc, strokeEye);
      canvas.drawPath(rightArc, strokeEye);
      return;
    }

    // Eye Whites
    final whitePaint = Paint()..color = Colors.white;
    final leftEyeRect = Rect.fromCenter(center: Offset(w * 0.37, h * 0.45), width: w * 0.14, height: h * 0.10);
    final rightEyeRect = Rect.fromCenter(center: Offset(w * 0.63, h * 0.45), width: w * 0.14, height: h * 0.10);
    canvas.drawOval(leftEyeRect, whitePaint);
    canvas.drawOval(rightEyeRect, whitePaint);

    // Iris
    final irisPaint = Paint()..color = eyeColor;
    canvas.drawCircle(Offset(w * 0.37, h * 0.45), w * 0.048, irisPaint);
    canvas.drawCircle(Offset(w * 0.63, h * 0.45), w * 0.048, irisPaint);

    // Pupil
    final pupilPaint = Paint()..color = Colors.black;
    canvas.drawCircle(Offset(w * 0.37, h * 0.45), w * 0.026, pupilPaint);
    canvas.drawCircle(Offset(w * 0.63, h * 0.45), w * 0.026, pupilPaint);

    // Glint
    final glintPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(w * 0.35, h * 0.43), w * 0.016, glintPaint);
    canvas.drawCircle(Offset(w * 0.61, h * 0.43), w * 0.016, glintPaint);
  }

  void _paintFrontHair(Canvas canvas, Size size, int styleIdx, Color hairColor) {
    final w = size.width;
    final h = size.height;
    final hairPaint = Paint()..color = hairColor;

    if (styleIdx == 0) {
      // Classic Fade / Crop
      final path = Path()
        ..moveTo(w * 0.22, h * 0.38)
        ..cubicTo(w * 0.22, h * 0.14, w * 0.78, h * 0.14, w * 0.78, h * 0.38)
        ..cubicTo(w * 0.68, h * 0.25, w * 0.32, h * 0.25, w * 0.22, h * 0.38)
        ..close();
      canvas.drawPath(path, hairPaint);
    } else if (styleIdx == 1) {
      // Wavy Long Bangs & Framing
      final path = Path()
        ..moveTo(w * 0.20, h * 0.50)
        ..cubicTo(w * 0.18, h * 0.16, w * 0.82, h * 0.16, w * 0.80, h * 0.50)
        ..cubicTo(w * 0.72, h * 0.28, w * 0.56, h * 0.28, w * 0.50, h * 0.34)
        ..cubicTo(w * 0.44, h * 0.28, w * 0.28, h * 0.28, w * 0.20, h * 0.50)
        ..close();
      canvas.drawPath(path, hairPaint);
    } else if (styleIdx == 2) {
      // High Ponytail front swoop
      final path = Path()
        ..moveTo(w * 0.22, h * 0.40)
        ..cubicTo(w * 0.24, h * 0.16, w * 0.76, h * 0.16, w * 0.78, h * 0.40)
        ..cubicTo(w * 0.65, h * 0.26, w * 0.35, h * 0.26, w * 0.22, h * 0.40)
        ..close();
      canvas.drawPath(path, hairPaint);
    } else if (styleIdx == 3) {
      // Sleek Bob
      final path = Path()
        ..moveTo(w * 0.20, h * 0.56)
        ..cubicTo(w * 0.20, h * 0.14, w * 0.80, h * 0.14, w * 0.80, h * 0.56)
        ..lineTo(w * 0.74, h * 0.56)
        ..cubicTo(w * 0.72, h * 0.28, w * 0.28, h * 0.28, w * 0.26, h * 0.56)
        ..close();
      canvas.drawPath(path, hairPaint);
    } else {
      // Curly Volume
      canvas.drawCircle(Offset(w * 0.30, h * 0.24), w * 0.14, hairPaint);
      canvas.drawCircle(Offset(w * 0.50, h * 0.18), w * 0.16, hairPaint);
      canvas.drawCircle(Offset(w * 0.70, h * 0.24), w * 0.14, hairPaint);
      canvas.drawCircle(Offset(w * 0.22, h * 0.36), w * 0.11, hairPaint);
      canvas.drawCircle(Offset(w * 0.78, h * 0.36), w * 0.11, hairPaint);
    }
  }

  void _paintAccessories(Canvas canvas, Size size, int accIdx) {
    final w = size.width;
    final h = size.height;

    if (accIdx == 1) {
      // Round Wire Glasses
      final glassPaint = Paint()
        ..color = const Color(0xFFD97706)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.035;
      canvas.drawCircle(Offset(w * 0.37, h * 0.45), w * 0.10, glassPaint);
      canvas.drawCircle(Offset(w * 0.63, h * 0.45), w * 0.10, glassPaint);
      canvas.drawLine(Offset(w * 0.47, h * 0.45), Offset(w * 0.53, h * 0.45), glassPaint);
    } else if (accIdx == 2) {
      // Modern Rectangle Frames
      final glassPaint = Paint()
        ..color = const Color(0xFF0F172A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.04;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(w * 0.37, h * 0.45), width: w * 0.22, height: h * 0.13), Radius.circular(w * 0.03)),
        glassPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(w * 0.63, h * 0.45), width: w * 0.22, height: h * 0.13), Radius.circular(w * 0.03)),
        glassPaint,
      );
      canvas.drawLine(Offset(w * 0.48, h * 0.45), Offset(w * 0.52, h * 0.45), glassPaint);
    } else if (accIdx == 3) {
      // Star Hairclip
      final starPaint = Paint()..color = const Color(0xFFF59E0B);
      _drawStar(canvas, Offset(w * 0.27, h * 0.27), w * 0.05, starPaint);
    } else if (accIdx == 4) {
      // Campus Headband
      final bandPaint = Paint()
        ..color = const Color(0xFF6366F1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.06
        ..strokeCap = StrokeCap.round;
      final band = Path()
        ..moveTo(w * 0.24, h * 0.38)
        ..quadraticBezierTo(w * 0.50, h * 0.18, w * 0.76, h * 0.38);
      canvas.drawPath(band, bandPaint);
    }
  }

  void _paintCustomMascot(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final int hueIdx = (config['mascotHueIndex'] as int? ?? 0).clamp(0, CustomAvatarPalette.mascotHues.length - 1);
    final gradColors = (CustomAvatarPalette.mascotHues[hueIdx]['gradient'] as List<Color>);

    // Mascot Body Gradient Circle
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: gradColors,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.5, bgPaint);

    // Headset Arc
    final headsetPaint = Paint()
      ..color = Colors.white.withAlpha(220)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.06
      ..strokeCap = StrokeCap.round;
    final arc = Path()
      ..moveTo(w * 0.18, h * 0.45)
      ..quadraticBezierTo(w * 0.50, h * 0.08, w * 0.82, h * 0.45);
    canvas.drawPath(arc, headsetPaint);

    // Ear Cushions
    canvas.drawCircle(Offset(w * 0.16, h * 0.46), w * 0.09, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(w * 0.84, h * 0.46), w * 0.09, Paint()..color = Colors.white);

    // Face Eyes & Smile
    final eyePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(w * 0.35, h * 0.44), w * 0.08, eyePaint);
    canvas.drawCircle(Offset(w * 0.65, h * 0.44), w * 0.08, eyePaint);

    // Rosy Cheeks
    final blushPaint = Paint()..color = const Color(0xFFFFB4A2).withAlpha(180);
    canvas.drawCircle(Offset(w * 0.20, h * 0.57), w * 0.07, blushPaint);
    canvas.drawCircle(Offset(w * 0.80, h * 0.57), w * 0.07, blushPaint);

    // Smile
    final mouth = Path()
      ..moveTo(w * 0.38, h * 0.58)
      ..quadraticBezierTo(w * 0.50, h * 0.72, w * 0.62, h * 0.58);
    canvas.drawPath(
      mouth,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.055
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    path.moveTo(center.dx, center.dy - radius);
    path.lineTo(center.dx + radius * 0.3, center.dy - radius * 0.3);
    path.lineTo(center.dx + radius, center.dy);
    path.lineTo(center.dx + radius * 0.3, center.dy + radius * 0.3);
    path.lineTo(center.dx, center.dy + radius);
    path.lineTo(center.dx - radius * 0.3, center.dy + radius * 0.3);
    path.lineTo(center.dx - radius, center.dy);
    path.lineTo(center.dx - radius * 0.3, center.dy - radius * 0.3);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LayeredAvatarPainter oldDelegate) =>
      oldDelegate.config != config || oldDelegate.isTyping != isTyping || oldDelegate.isMascot != isMascot;
}
