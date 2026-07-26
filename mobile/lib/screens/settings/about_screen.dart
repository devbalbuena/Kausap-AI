import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const String _appVersion = '1.0.0';
  static const String _buildNumber = '31';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('About', style: AppTextStyles.heading2.copyWith(fontSize: 20)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 16),
          // Logo & App Name
          Center(
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7B61FF), Color(0xFF00D4FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [BoxShadow(color: Color(0x307B61FF), blurRadius: 20, offset: Offset(0, 8))],
                  ),
                  child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 56),
                ),
                const SizedBox(height: 16),
                Text('Kausap AI', style: AppTextStyles.heading1.copyWith(fontSize: 26)),
                const SizedBox(height: 4),
                Text(
                  'Mental Health Companion',
                  style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Version $_appVersion (Build $_buildNumber)',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Info cards
          _buildInfoSection('About Kausap AI', [
            _buildInfoRow(Icons.info_outline_rounded, 'What is Kausap AI?',
                'Kausap AI is a Filipino-first mental health app that connects users with AI-powered companionship and licensed mental health professionals.'),
            _buildDivider(),
            _buildInfoRow(Icons.language_rounded, 'Language', 'Filipino / English'),
            _buildDivider(),
            _buildInfoRow(Icons.location_on_rounded, 'Built for', 'Philippines'),
          ]),
          const SizedBox(height: 20),
          _buildInfoSection('Technical Details', [
            _buildInfoRow(Icons.phone_android_rounded, 'Platform', 'Flutter (iOS & Android)'),
            _buildDivider(),
            _buildInfoRow(Icons.cloud_rounded, 'Backend', 'FastAPI + Neon Postgres'),
            _buildDivider(),
            _buildInfoRow(Icons.smart_toy_rounded, 'AI Powered by', 'Gemini API'),
          ]),
          const SizedBox(height: 20),
          _buildInfoSection('Legal', [
            _buildInfoRow(Icons.article_rounded, 'Terms of Service', 'View terms'),
            _buildDivider(),
            _buildInfoRow(Icons.privacy_tip_rounded, 'Privacy Policy', 'View policy'),
          ]),
          const SizedBox(height: 40),
          Center(
            child: Text(
              '© 2026 Kausap AI. All rights reserved.',
              style: AppTextStyles.body.copyWith(fontSize: 11, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 5, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              title,
              style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textSecondary, letterSpacing: 0.8),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
                Text(value, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() => const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.divider);
}
