import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class CancelSessionBottomSheet extends StatefulWidget {
  final String sessionId;
  final String professionalName;
  final String date;
  final String time;

  const CancelSessionBottomSheet({
    super.key,
    required this.sessionId,
    required this.professionalName,
    required this.date,
    required this.time,
  });

  @override
  State<CancelSessionBottomSheet> createState() => _CancelSessionBottomSheetState();
}

class _CancelSessionBottomSheetState extends State<CancelSessionBottomSheet> {
  int? _selectedReasonIndex;
  final List<String> _reasons = [
    'I have a schedule conflict',
    'I am feeling sick',
    'I forgot about it',
    'Other (Please specify)',
  ];

  void _onConfirm() {
    if (_selectedReasonIndex == null) return;
    Navigator.pop(context, true); // true = confirmed cancellation
  }

  void _onReschedule() {
    Navigator.pop(context, 'reschedule'); // reschedule action
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Modify Session',
                    style: AppTextStyles.heading2.copyWith(fontSize: 20),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.professionalName} • ${widget.date} at ${widget.time}',
                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              const Text(
                'Why do you want to cancel or reschedule?',
                style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 12),
              ...List.generate(_reasons.length, (index) {
                final isSelected = _selectedReasonIndex == index;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedReasonIndex = index;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withAlpha(20) : Colors.white,
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.divider,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                          color: isSelected ? AppColors.primary : AppColors.textSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _reasons[index],
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: isSelected ? AppColors.primary : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _selectedReasonIndex == null ? null : _onReschedule,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Reschedule', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _selectedReasonIndex == null ? null : _onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel Session', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
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
}
