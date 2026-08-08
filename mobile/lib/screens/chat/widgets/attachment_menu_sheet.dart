import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class AttachmentMenuSheet extends StatelessWidget {
  const AttachmentMenuSheet({super.key});

  static const List<Map<String, dynamic>> _options = [
    {
      'label': 'Photo / Video',
      'icon': Icons.image_rounded,
      'color': Color(0xFF3B82F6),
      'bgColor': Color(0xFFEFF6FF),
    },
    {
      'label': 'Camera',
      'icon': Icons.camera_alt_rounded,
      'color': Color(0xFF8B5CF6),
      'bgColor': Color(0xFFF5F3FF),
    },
    {
      'label': 'Voice Note',
      'icon': Icons.mic_rounded,
      'color': Color(0xFFEF4444),
      'bgColor': Color(0xFFFEF2F2),
    },
    {
      'label': 'Document',
      'icon': Icons.insert_drive_file_rounded,
      'color': Color(0xFFF59E0B),
      'bgColor': Color(0xFFFFFBEB),
    },
    {
      'label': 'Contact',
      'icon': Icons.person_pin_rounded,
      'color': Color(0xFF10B981),
      'bgColor': Color(0xFFECFDF5),
    },
    {
      'label': 'Location',
      'icon': Icons.location_on_rounded,
      'color': Color(0xFFEC4899),
      'bgColor': Color(0xFFFDF2F8),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Send Attachment', style: AppTextStyles.heading2),
              const SizedBox(height: 4),
              const Text(
                'Choose what you want to share',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontFamily: 'Inter'),
              ),
              const SizedBox(height: 24),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.9,
                ),
                itemCount: _options.length,
                itemBuilder: (context, index) {
                  final opt = _options[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${opt['label']} attachment coming soon!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: opt['bgColor'] as Color,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(
                            opt['icon'] as IconData,
                            color: opt['color'] as Color,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          opt['label'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
