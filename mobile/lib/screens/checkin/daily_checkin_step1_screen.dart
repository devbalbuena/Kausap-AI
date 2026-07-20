import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'daily_checkin_step2_screen.dart';

class DailyCheckinStep1Screen extends StatefulWidget {
  const DailyCheckinStep1Screen({super.key});

  @override
  State<DailyCheckinStep1Screen> createState() => _DailyCheckinStep1ScreenState();
}

class _DailyCheckinStep1ScreenState extends State<DailyCheckinStep1Screen> {
  int? _selectedMood;

  final List<Map<String, dynamic>> _moods = [
    {'label': 'Great', 'value': 5, 'emoji': '🤩'},
    {'label': 'Good', 'value': 4, 'emoji': '😊'},
    {'label': 'Okay', 'value': 3, 'emoji': '😐'},
    {'label': 'Low', 'value': 2, 'emoji': '😨'},
    {'label': 'Very Low', 'value': 1, 'emoji': '😞'},
  ];

  void _onNext() {
    if (_selectedMood == null) return;
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DailyCheckinStep2Screen(
          moodLevel: _selectedMood!,
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
                      Text('1/3', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(), // Close entirely
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
                      value: 0.33,
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
                      "How's your mood\ntoday?",
                      style: AppTextStyles.heading1.copyWith(fontSize: 26, height: 1.2),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),

                    // Mood Options
                    Wrap(
                      spacing: 24,
                      runSpacing: 32,
                      alignment: WrapAlignment.center,
                      children: _moods.map((mood) {
                        final isSelected = _selectedMood == mood['value'];
                        return GestureDetector(
                          onTap: () => setState(() => _selectedMood = mood['value']),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected ? const Color(0xFFC9F2FF) : Colors.transparent,
                                  border: isSelected ? Border.all(color: AppColors.primary, width: 2) : null,
                                ),
                                alignment: Alignment.center,
                                child: Text(mood['emoji'], style: const TextStyle(fontSize: 40)),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                mood['label'],
                                style: AppTextStyles.body.copyWith(
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
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
                  onPressed: _selectedMood != null ? _onNext : null,
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
