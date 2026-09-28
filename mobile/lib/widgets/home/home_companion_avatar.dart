import 'package:flutter/material.dart';
import 'human_companion_mascot.dart';

export 'human_companion_mascot.dart';

/// Backward-compatible wrapper for [HomeCompanionAvatar], now powered by
/// the human [HumanCompanionMascot] digital wellness companion.
class HomeCompanionAvatar extends StatelessWidget {
  final int? todayMood;
  final String firstName;
  final ValueChanged<String>? onAffirmation;
  final double size;

  const HomeCompanionAvatar({
    super.key,
    required this.todayMood,
    required this.firstName,
    this.onAffirmation,
    this.size = 72.0,
  });

  @override
  Widget build(BuildContext context) {
    return HumanCompanionMascot(
      mood: todayMood,
      size: size,
      firstName: firstName,
      onAffirmation: onAffirmation,
    );
  }
}
