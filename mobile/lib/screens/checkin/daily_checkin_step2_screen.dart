import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'daily_checkin_step3_screen.dart';

class DailyCheckinStep2Screen extends StatefulWidget {
  final int moodLevel;
  
  const DailyCheckinStep2Screen({super.key, required this.moodLevel});

  @override
  State<DailyCheckinStep2Screen> createState() => _DailyCheckinStep2ScreenState();
}

class _DailyCheckinStep2ScreenState extends State<DailyCheckinStep2Screen> {
  final List<String> _emotionOptions = [
    'Anxious', 'Sad', 'Hopeful', 'Overwhelmed', 'Calm', 'Stressed', 'Irritable'
  ];
  
  final Set<String> _selectedEmotions = {};
  double _intensity = 5.0; // 1 to 10 slider

  void _onNext() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DailyCheckinStep3Screen(
          moodLevel: widget.moodLevel,
          emotions: _selectedEmotions.isNotEmpty ? _selectedEmotions.join(',') : null,
          intensity: _intensity.toInt(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header & Progress
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(Icons.chevron_left, color: AppColors.textPrimary, size: 28),
                      ),
                      Text('2/3', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                      GestureDetector(
                        onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
                        child: const Icon(Icons.close, color: AppColors.textPrimary, size: 28),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Daily Check-in', style: AppTextStyles.heading1),
                  ),
                  const SizedBox(height: 12),
                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: 0.66,
                      backgroundColor: const Color(0xFFE1E2E9),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: Column(
                  children: [
                    Text(
                      "What are you feeling?",
                      style: AppTextStyles.heading1.copyWith(fontSize: 26, height: 1.2),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "(Select what fits, or skip)",
                      style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),

                    // Emotion Chips
                    Wrap(
                      spacing: 12,
                      runSpacing: 16,
                      alignment: WrapAlignment.center,
                      children: _emotionOptions.map((emotion) {
                        final isSelected = _selectedEmotions.contains(emotion);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedEmotions.remove(emotion);
                              } else {
                                _selectedEmotions.add(emotion);
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFE4F9FF) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : const Color(0xFFD0D5DD),
                              ),
                            ),
                            child: Text(
                              emotion,
                              style: AppTextStyles.body.copyWith(
                                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 60),

                    // Slider
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppColors.primary,
                        inactiveTrackColor: const Color(0xFFE1E2E9),
                        thumbColor: Colors.white,
                        trackHeight: 8,
                        overlayColor: AppColors.primary.withValues(alpha: 0.1),
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12, elevation: 4),
                        // Add border to thumb to match Figma (blue outer ring, white center)
                      ),
                      child: Slider(
                        value: _intensity,
                        min: 1,
                        max: 10,
                        divisions: 9,
                        onChanged: (val) {
                          setState(() => _intensity = val);
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Mild', style: AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
                        Text('Very Intense', style: AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Next', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
