import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  final List<_PrivacySection> _sections = [
    _PrivacySection(
      title: 'Terms of Service',
      content:
          'By using Kausap AI, you agree to these terms. Kausap AI is a mental health support platform that provides AI-powered companionship, mood tracking, and access to licensed professionals. This service is not a substitute for professional medical advice. You must be at least 13 years old to use this platform.',
    ),
    _PrivacySection(
      title: 'Data Collection',
      content:
          'We collect information you provide directly, such as name, email, mood entries, and messages. We also collect usage data to improve the platform. All data is encrypted in transit and at rest. You can request a copy of your data at any time.',
    ),
    _PrivacySection(
      title: 'Data Usage',
      content:
          'Your data is used to personalize your experience, improve our AI models, and connect you with appropriate mental health resources. We do not sell your personal information to third parties. Anonymized, aggregated data may be used for research purposes.',
    ),
    _PrivacySection(
      title: 'Data Access',
      content:
          'Only you and the professionals you connect with can view your personal information. Our support team may access your data only when necessary to resolve technical issues, with your consent. All access is logged and audited.',
    ),
    _PrivacySection(
      title: 'Your Legal Rights',
      content:
          'You have the right to access, correct, or delete your data at any time. You can withdraw consent for data processing, request data portability, and lodge a complaint with a supervisory authority. Contact privacy@kausap.ai for any data-related requests.',
    ),
  ];

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Account', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: Color(0xFFEF4444))),
        content: const Text(
          'This action is permanent and cannot be undone. All your data, mood history, conversations, and session records will be permanently deleted.',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Account deletion request submitted. You will receive an email confirmation.')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded, size: 28, color: AppColors.textPrimary),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          'Privacy & Terms',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      const SizedBox(height: 8),

                      // Intro banner
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primary.withAlpha(40)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 22),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Your privacy is our priority. Tap each section to learn more.',
                                style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.primary, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Accordion sections
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 4))],
                        ),
                        child: Column(
                          children: _sections.asMap().entries.map((entry) {
                            final i = entry.key;
                            final section = entry.value;
                            final isLast = i == _sections.length - 1;
                            return _buildAccordionItem(section, isLast);
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Danger zone
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF5F5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 20),
                                SizedBox(width: 8),
                                Text('Danger Zone',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: Color(0xFFEF4444),
                                    )),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Deleting your account is permanent. All data will be erased.',
                              style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: _showDeleteAccountDialog,
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFFEF4444)),
                                  foregroundColor: const Color(0xFFEF4444),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: const Text('Delete My Account',
                                    style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14)),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccordionItem(_PrivacySection section, bool isLast) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isLast ? 0 : 0)),
        collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
        iconColor: AppColors.primary,
        collapsedIconColor: AppColors.textSecondary,
        title: Text(section.title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppColors.textPrimary,
            )),
        children: [
          if (!isLast)
            Container(height: 1, color: const Color(0x18000000)),
          const SizedBox(height: 12),
          Text(section.content,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.6,
              )),
        ],
      ),
    );
  }
}

class _PrivacySection {
  final String title;
  final String content;

  _PrivacySection({required this.title, required this.content});
}
