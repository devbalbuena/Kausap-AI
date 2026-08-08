import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

/// Animated "Typing..." indicator with three bouncing dots
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      ),
    );
    _animations = _controllers.map((ctrl) {
      return Tween<double>(begin: 0, end: -8).animate(
        CurvedAnimation(parent: ctrl, curve: Curves.easeInOut),
      );
    }).toList();

    _startAnimations();
  }

  void _startAnimations() async {
    for (int i = 0; i < _controllers.length; i++) {
      await Future.delayed(Duration(milliseconds: i * 150));
      if (mounted) {
        _controllers[i].repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    for (final ctrl in _controllers) {
      ctrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, bottom: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(20),
            ),
            boxShadow: const [
              BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Typing',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(width: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(3, (i) {
                  return AnimatedBuilder(
                    animation: _animations[i],
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _animations[i].value),
                        child: Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(180),
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
