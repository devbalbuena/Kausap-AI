import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';

class CrisisResourcesSheet extends StatelessWidget {
  const CrisisResourcesSheet({super.key});

  // Dynamic list of hotlines — structured data, not just text
  static const List<Map<String, String>> _hotlines = [
    {
      'name': 'National Crisis Hotline',
      'number': '1553',
      'description': 'National Mental Health Crisis Helpline (PH)',
      'type': 'call',
    },
    {
      'name': 'Hopeline Philippines',
      'number': '02-8804-4673',
      'description': '24/7 mental health crisis support',
      'type': 'call',
    },
    {
      'name': 'NCMH Crisis Hotline',
      'number': '1800-10-254-6467',
      'description': 'National Center for Mental Health',
      'type': 'call',
    },
    {
      'name': 'In Touch Crisis Line',
      'number': '02-8893-7603',
      'description': 'Multilingual crisis support services',
      'type': 'call',
    },
    {
      'name': 'Text Crisis Line',
      'number': '09178626820',
      'description': 'Text HELLO to this number for support',
      'type': 'sms',
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
            const SizedBox(height: 20),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Crisis Resources & Hotlines', style: AppTextStyles.heading2.copyWith(fontSize: 18)),
                      Text('Tap to call or copy number', style: AppTextStyles.subheading.copyWith(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.55,
              ),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shrinkWrap: true,
                itemCount: _hotlines.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final hotline = _hotlines[index];
                  final isSms = hotline['type'] == 'sms';

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isSms ? Colors.blue.shade50 : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isSms ? Icons.sms_rounded : Icons.phone_rounded,
                            color: isSms ? Colors.blue.shade500 : Colors.red.shade500,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hotline['name']!,
                                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                hotline['number']!,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  color: isSms ? Colors.blue.shade600 : Colors.red.shade600,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                hotline['description']!,
                                style: AppTextStyles.subheading.copyWith(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.textSecondary),
                          tooltip: 'Copy number',
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: hotline['number']!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${hotline['number']} copied to clipboard'),
                                behavior: SnackBarBehavior.floating,
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
