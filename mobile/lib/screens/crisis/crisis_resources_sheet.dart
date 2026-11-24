import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../services/api_client.dart';
import '../../utils/haptic_service.dart';
import '../../utils/crisis_defaults.dart';

class CrisisResourcesSheet extends StatefulWidget {
  const CrisisResourcesSheet({super.key});

  @override
  State<CrisisResourcesSheet> createState() => _CrisisResourcesSheetState();
}

class _CrisisResourcesSheetState extends State<CrisisResourcesSheet> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;

  // Fallback list of hotlines in case of offline state
  static const List<Map<String, dynamic>> _fallbackHotlines = CrisisDefaults.fallbackHotlines;

  List<Map<String, dynamic>> _hotlines = [];
  String _selectedCategory = 'all'; // 'all', 'campus', 'national', 'emergency'

  Widget _buildCategoryChip(String label, String category, Color activeColor) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () {
        HapticService.lightTap();
        setState(() => _selectedCategory = category);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _hotlines = List<Map<String, dynamic>>.from(_fallbackHotlines);
    _fetchLiveHotlines();
  }

  Future<void> _fetchLiveHotlines() async {
    try {
      final res = await _api.get('/crisis/hotlines');
      if (mounted && res is List && res.isNotEmpty) {
        setState(() {
          _hotlines = res.map((e) => {
            'name': e['name']?.toString() ?? '',
            'number': e['phone']?.toString() ?? '',
            'email': e['email']?.toString() ?? '',
            'description': e['description']?.toString() ?? '',
            'category': e['category']?.toString() ?? 'national',
            'type': e['type']?.toString() ?? 'call',
          }).toList();
          _isLoading = false;
        });
        return;
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredHotlines = _hotlines.where((h) {
      if (_selectedCategory == 'all') return true;
      return (h['category'] ?? 'national').toString().toLowerCase() == _selectedCategory;
    }).toList();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.phone_rounded, color: Colors.red.shade500),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Crisis Resources & Hotlines', style: AppTextStyles.heading2.copyWith(fontSize: 18)),
                        Text('Live university & 24/7 national hotlines', style: AppTextStyles.subheading.copyWith(fontSize: 12)),
                      ],
                    ),
                  ),
                  if (_isLoading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCategoryChip('All (${_hotlines.length})', 'all', AppColors.primary),
                    const SizedBox(width: 8),
                    _buildCategoryChip('🏫 Campus Guidance', 'campus', const Color(0xFF0284C7)),
                    const SizedBox(width: 8),
                    _buildCategoryChip('🇵🇭 National 24/7', 'national', const Color(0xFF16A34A)),
                    const SizedBox(width: 8),
                    _buildCategoryChip('🚑 911 Emergency', 'emergency', const Color(0xFFDC2626)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.56,
              ),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shrinkWrap: true,
                itemCount: filteredHotlines.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final hotline = filteredHotlines[index];
                  final isSms = hotline['type'] == 'sms';
                  final category = hotline['category'] ?? 'national';

                  Color cardColor;
                  Color iconColor;
                  String badgeText;
                  IconData leadIcon;

                  if (category == 'campus') {
                    cardColor = const Color(0xFFF0F9FF);
                    iconColor = const Color(0xFF0284C7);
                    badgeText = '🏫 Campus Guidance';
                    leadIcon = Icons.school_rounded;
                  } else if (category == 'emergency') {
                    cardColor = const Color(0xFFFEF2F2);
                    iconColor = const Color(0xFFDC2626);
                    badgeText = '🚑 911 Emergency';
                    leadIcon = Icons.emergency_rounded;
                  } else {
                    cardColor = const Color(0xFFF9FAFB);
                    iconColor = isSms ? const Color(0xFF2563EB) : const Color(0xFF16A34A);
                    badgeText = '🇵🇭 National 24/7';
                    leadIcon = isSms ? Icons.sms_rounded : Icons.health_and_safety_rounded;
                  }

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: iconColor.withAlpha(25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(leadIcon, color: iconColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      hotline['name'] ?? '',
                                      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700, fontSize: 13.5),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: iconColor.withAlpha(20),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      badgeText,
                                      style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 9.5, color: iconColor),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                (hotline['number'] ?? hotline['phone'] ?? '').toString(),
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: iconColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              if (hotline['email'] != null && (hotline['email'] as String).isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  hotline['email']!,
                                  style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF64748B)),
                                ),
                              ],
                              if (hotline['description'] != null && (hotline['description'] as String).isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  hotline['description']!,
                                  style: AppTextStyles.subheading.copyWith(fontSize: 11, height: 1.3),
                                ),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.textSecondary),
                          tooltip: 'Copy number',
                          onPressed: () {
                            HapticService.lightTap();
                            final number = (hotline['number'] ?? hotline['phone'] ?? '').toString();
                            Clipboard.setData(ClipboardData(text: number));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('$number copied to clipboard'),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

