import 'package:flutter/material.dart';
import '../../utils/haptic_service.dart';

class MoodInfluenceSheet extends StatefulWidget {
  final int moodLevel;
  final String firstName;
  final Function(List<String> selectedFactors, String? note) onSave;

  const MoodInfluenceSheet({
    super.key,
    required this.moodLevel,
    required this.firstName,
    required this.onSave,
  });

  @override
  State<MoodInfluenceSheet> createState() => _MoodInfluenceSheetState();
}

class _MoodInfluenceSheetState extends State<MoodInfluenceSheet> {
  final Set<String> _selectedFactors = {};
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _customReasonController = TextEditingController();
  final FocusNode _customReasonFocus = FocusNode();
  bool _showCustomInput = false;

  static const String _otherChipKey = '✍️ Other / Custom';

  static const List<String> _availableFactors = [
    '📚 Academics & Thesis',
    '⚡ Exams & Deadlines',
    '😴 Sleep & Fatigue',
    '👨‍👩‍👧 Family & Home',
    '👥 Friends & Social',
    '💸 Allowance & Finances',
    '🌿 Health & Energy',
    '❤️ Relationships',
    '☕ Daily Routine & Focus',
    '🧘 Personal Well-Being',
  ];

  String _getMoodLabel(int level) {
    switch (level) {
      case 5:
        return 'Great 😄';
      case 4:
        return 'Good 🙂';
      case 3:
        return 'Okay 😐';
      case 2:
        return 'Low 😟';
      case 1:
        return 'Rough 😞';
      default:
        return 'Good 🙂';
    }
  }

  Color _getMoodColor(int level) {
    switch (level) {
      case 5:
        return const Color(0xFF0284C7);
      case 4:
        return const Color(0xFF10B981);
      case 3:
        return const Color(0xFFF59E0B);
      case 2:
        return const Color(0xFFEA580C);
      case 1:
        return const Color(0xFFE11D48);
      default:
        return const Color(0xFF0284C7);
    }
  }

  void _toggleFactor(String factor) {
    HapticService.lightTap();
    if (factor == _otherChipKey) {
      setState(() {
        _showCustomInput = !_showCustomInput;
        if (_showCustomInput) {
          // Mark as selected visually while input is open
          _selectedFactors.add(_otherChipKey);
          Future.delayed(const Duration(milliseconds: 150), () {
            _customReasonFocus.requestFocus();
          });
        } else {
          // Remove the placeholder key; user cancelled
          _selectedFactors.remove(_otherChipKey);
          _customReasonController.clear();
        }
      });
    } else {
      setState(() {
        if (_selectedFactors.contains(factor)) {
          _selectedFactors.remove(factor);
        } else {
          _selectedFactors.add(factor);
        }
      });
    }
  }

  /// Commits the typed custom reason as a real tag in the factor set.
  void _addCustomReason() {
    final text = _customReasonController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _showCustomInput = false;
        _selectedFactors.remove(_otherChipKey);
      });
      return;
    }
    setState(() {
      _selectedFactors.remove(_otherChipKey); // Remove placeholder
      _selectedFactors.add(text);             // Add real tag
      _showCustomInput = false;
      _customReasonController.clear();
    });
    HapticService.lightTap();
  }

  /// Returns the final list of factors, excluding internal placeholder keys.
  List<String> _getFinalFactors() {
    return _selectedFactors
        .where((f) => f != _otherChipKey)
        .toList();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _customReasonController.dispose();
    _customReasonFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final moodColor = _getMoodColor(widget.moodLevel);
    final moodLabel = _getMoodLabel(widget.moodLevel);

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: moodColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: moodColor.withAlpha(60)),
                    ),
                    child: Text(
                      moodLabel,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: moodColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Checked in for today',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              const Text(
                'What is influencing your mood today?',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Select key campus or life factors affecting how you feel:',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),

              // Factors Chips Wrap (default + Other chip at end)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._availableFactors.map((factor) => _buildChip(factor, moodColor)),
                  _buildChip(_otherChipKey, const Color(0xFF7C3AED)),
                ],
              ),

              // ── Custom Reason Inline Input (shown when ✍️ Other is tapped) ──
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: _showCustomInput
                    ? Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Describe your own factor:',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: Color(0xFF7C3AED),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _customReasonController,
                                    focusNode: _customReasonFocus,
                                    style: const TextStyle(fontFamily: 'Inter', fontSize: 13),
                                    textCapitalization: TextCapitalization.sentences,
                                    onSubmitted: (_) => _addCustomReason(),
                                    decoration: InputDecoration(
                                      hintText: 'e.g. Thesis deadline, Part-time work, Traffic...',
                                      hintStyle: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 11.5,
                                        color: Color(0xFF94A3B8),
                                      ),
                                      filled: true,
                                      fillColor: const Color(0xFFF5F3FF),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(color: Color(0xFFDDD6FE)),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(color: Color(0xFFDDD6FE)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF7C3AED),
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: _addCustomReason,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF7C3AED),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      'Add ✓',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '✨ Your custom tag will appear in your Emotion Breakdown chart!',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10.5,
                                color: Color(0xFF7C3AED),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              // Show added custom tags as removable pills
              if (_getFinalFactors().any((f) => !_availableFactors.contains(f))) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _getFinalFactors()
                      .where((f) => !_availableFactors.contains(f))
                      .map((tag) => _buildCustomTagPill(tag))
                      .toList(),
                ),
              ],

              const SizedBox(height: 18),

              // Optional Note field
              TextField(
                controller: _noteController,
                maxLines: 2,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Add a personal note or reflection (optional)...',
                  hintStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: moodColor),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons Row
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: TextButton(
                      onPressed: () {
                        HapticService.lightTap();
                        widget.onSave([], null);
                      },
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticService.mediumTap();
                        // If custom input is still open, auto-commit it before saving
                        if (_showCustomInput) {
                          _addCustomReason();
                        }
                        final note = _noteController.text.trim().isNotEmpty
                            ? _noteController.text.trim()
                            : null;
                        widget.onSave(_getFinalFactors(), note);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: moodColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Save Check-In ✅',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String factor, Color chipColor) {
    final isOther = factor == _otherChipKey;
    final isSelected = _selectedFactors.contains(factor);

    return GestureDetector(
      onTap: () => _toggleFactor(factor),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? chipColor.withAlpha(25) : (isOther ? const Color(0xFFF5F3FF) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? chipColor : (isOther ? const Color(0xFFDDD6FE) : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          factor,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? chipColor : (isOther ? const Color(0xFF7C3AED) : const Color(0xFF334155)),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomTagPill(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF7C3AED), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '✍️ ',
            style: TextStyle(fontSize: 11),
          ),
          Text(
            tag,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5B21B6),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () {
              HapticService.lightTap();
              setState(() => _selectedFactors.remove(tag));
            },
            child: const Icon(Icons.close_rounded, size: 13, color: Color(0xFF7C3AED)),
          ),
        ],
      ),
    );
  }
}
