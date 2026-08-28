import 'package:flutter/material.dart';
import '../../../utils/haptic_service.dart';
import '../activity_screen.dart';

class GroundingPlayerWidget extends StatefulWidget {
  final ActivityItem activity;
  final VoidCallback onComplete;

  const GroundingPlayerWidget({
    super.key,
    required this.activity,
    required this.onComplete,
  });

  @override
  State<GroundingPlayerWidget> createState() => _GroundingPlayerWidgetState();
}

class _GroundingStepInfo {
  final int stepNum;
  final String title;
  final String subtitle;
  final String prompt;
  final String emoji;
  final Color themeColor;
  final IconData icon;

  const _GroundingStepInfo({
    required this.stepNum,
    required this.title,
    required this.subtitle,
    required this.prompt,
    required this.emoji,
    required this.themeColor,
    required this.icon,
  });
}

class _GroundingPlayerWidgetState extends State<GroundingPlayerWidget> {
  int _currentStepIndex = 0;
  final List<List<String>> _recordedItems = List.generate(5, (_) => []);
  final TextEditingController _itemController = TextEditingController();

  final List<_GroundingStepInfo> _groundingSteps = const [
    _GroundingStepInfo(
      stepNum: 5,
      title: '5 Things You Can SEE',
      subtitle: 'Look around your room or campus.',
      prompt: 'Notice 5 small visual details (a pen, light on the wall, a tree, colors...)',
      emoji: '👀',
      themeColor: Color(0xFF0284C7),
      icon: Icons.visibility_rounded,
    ),
    _GroundingStepInfo(
      stepNum: 4,
      title: '4 Things You Can TOUCH',
      subtitle: 'Feel the physical surfaces around you.',
      prompt: 'Feel 4 physical textures (your desk, fabric of your shirt, your chair, cool air...)',
      emoji: '🖐️',
      themeColor: Color(0xFF059669),
      icon: Icons.touch_app_rounded,
    ),
    _GroundingStepInfo(
      stepNum: 3,
      title: '3 Things You Can HEAR',
      subtitle: 'Listen closely to the room & outdoors.',
      prompt: 'Listen for 3 background sounds (birds outside, ceiling fan, distant voices...)',
      emoji: '👂',
      themeColor: Color(0xFFD97706),
      icon: Icons.hearing_rounded,
    ),
    _GroundingStepInfo(
      stepNum: 2,
      title: '2 Things You Can SMELL',
      subtitle: 'Take a gentle breath in through your nose.',
      prompt: 'Notice 2 subtle scents (fresh air, coffee, your book, your lotion...)',
      emoji: '👃',
      themeColor: Color(0xFF7C3AED),
      icon: Icons.air_rounded,
    ),
    _GroundingStepInfo(
      stepNum: 1,
      title: '1 Thing You Can TASTE',
      subtitle: 'Or name 1 thing you are grateful for.',
      prompt: 'Notice the taste of water, mint, or focus on one comforting grounding thought.',
      emoji: '👅',
      themeColor: Color(0xFFE11D48),
      icon: Icons.favorite_rounded,
    ),
  ];

  @override
  void dispose() {
    _itemController.dispose();
    super.dispose();
  }

  void _addItem() {
    final text = _itemController.text.trim();
    if (text.isEmpty) return;
    HapticService.lightTap();
    setState(() {
      _recordedItems[_currentStepIndex].add(text);
      _itemController.clear();
    });
  }

  void _nextStep() {
    HapticService.mediumTap();
    if (_currentStepIndex < _groundingSteps.length - 1) {
      setState(() {
        _currentStepIndex++;
        _itemController.clear();
      });
    } else {
      widget.onComplete();
    }
  }

  void _prevStep() {
    if (_currentStepIndex > 0) {
      HapticService.lightTap();
      setState(() {
        _currentStepIndex--;
        _itemController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _groundingSteps[_currentStepIndex];
    final items = _recordedItems[_currentStepIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          // Step progress indicator bar
          Row(
            children: List.generate(_groundingSteps.length, (i) {
              final isDone = i < _currentStepIndex;
              final isCurrent = i == _currentStepIndex;
              return Expanded(
                child: Container(
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: isDone
                        ? const Color(0xFF10B981)
                        : (isCurrent ? step.themeColor : const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),

          // Step Card with Soft Glowing Gradient
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: step.themeColor.withAlpha(80), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: step.themeColor.withAlpha(25),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: step.themeColor.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(step.emoji, style: const TextStyle(fontSize: 36)),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  step.title,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: step.themeColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  step.subtitle,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  step.prompt,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Recorded Items chips
                if (items.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: items.map((item) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: step.themeColor.withAlpha(15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: step.themeColor.withAlpha(60)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded, color: step.themeColor, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              item,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: step.themeColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 16),

                // Input Field for item observation
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _itemController,
                        onSubmitted: (_) => _addItem(),
                        decoration: InputDecoration(
                          hintText: 'Type an item (or mentally note it)...',
                          hintStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF94A3B8)),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: step.themeColor, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _addItem,
                      icon: const Icon(Icons.add_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: step.themeColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Navigation buttons (Back & Next Step / Finish)
          Row(
            children: [
              if (_currentStepIndex > 0)
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    onPressed: _prevStep,
                    child: const Text(
                      'Back',
                      style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                    ),
                  ),
                ),
              if (_currentStepIndex > 0) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: step.themeColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _nextStep,
                  child: Text(
                    _currentStepIndex == _groundingSteps.length - 1
                        ? 'Finish Grounding ✨'
                        : 'Next Step (${_currentStepIndex + 1}/5) ➔',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
