import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/privacy_settings_service.dart';
import '../../utils/app_routes.dart';
import '../../utils/haptic_service.dart';

/// Privacy Center — enterprise-grade screen explaining how Kausap AI
/// protects user data with encryption, compliance, and user controls.
class PrivacyCenterScreen extends StatefulWidget {
  const PrivacyCenterScreen({super.key});

  @override
  State<PrivacyCenterScreen> createState() => _PrivacyCenterScreenState();
}

class _PrivacyCenterScreenState extends State<PrivacyCenterScreen> {
  bool _privacyScreenEnabled = true;
  bool _analyticsEnabled = true;
  bool _marketingEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final privacy = await PrivacySettingsService.isPrivacyScreenEnabled();
    if (mounted) {
      setState(() {
        _privacyScreenEnabled = privacy;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
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
                          'Privacy Center',
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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    children: [
                      // Hero card
                      _buildHeroCard(),
                      const SizedBox(height: 20),

                      // Encryption pillars
                      _sectionLabel('HOW WE PROTECT YOUR DATA'),
                      const SizedBox(height: 10),
                      _buildEncryptionPillar(
                        icon: Icons.lock_rounded,
                        color: const Color(0xFF2563EB),
                        title: 'End-to-End Encryption',
                        description: 'All messages between you and your professional are encrypted with AES-256. Only you and your therapist can read them.',
                      ),
                      const SizedBox(height: 10),
                      _buildEncryptionPillar(
                        icon: Icons.storage_rounded,
                        color: const Color(0xFF059669),
                        title: 'Encrypted at Rest',
                        description: 'Your mood data, session history, and personal information are encrypted in our database using industry-standard encryption.',
                      ),
                      const SizedBox(height: 10),
                      _buildEncryptionPillar(
                        icon: Icons.verified_user_rounded,
                        color: const Color(0xFF7C3AED),
                        title: 'HIPAA Compliant',
                        description: 'Kausap AI follows HIPAA standards for healthcare data. Your mental health information is treated with the highest level of confidentiality.',
                      ),
                      const SizedBox(height: 10),
                      _buildEncryptionPillar(
                        icon: Icons.public_rounded,
                        color: const Color(0xFFD97706),
                        title: 'GDPR Ready',
                        description: 'If you are based in the EU or EEA, you have full rights over your data — including the right to access, correct, and erase your data.',
                      ),
                      const SizedBox(height: 20),

                      // Privacy controls
                      _sectionLabel('YOUR PRIVACY CONTROLS'),
                      const SizedBox(height: 10),
                      _buildPrivacyControlCard(),
                      const SizedBox(height: 20),

                      // Data summary
                      _sectionLabel('DATA WE COLLECT'),
                      const SizedBox(height: 10),
                      _buildDataSummaryCard(),
                      const SizedBox(height: 20),

                      // Contact
                      _buildContactCard(),
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

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A3A6B), Color(0xFF0D2140)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x30153058), blurRadius: 20, offset: Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(20),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.security_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Privacy Matters',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'We use military-grade encryption to protect your sensitive mental health data at every step.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEncryptionPillar({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyControlCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          _buildControlTile(
            icon: Icons.blur_on_rounded,
            color: const Color(0xFF7C3AED),
            label: 'Privacy Screen',
            subtitle: 'Blur app in recent apps switcher',
            value: _privacyScreenEnabled,
            onChanged: (v) async {
              HapticService.mediumTap();
              await PrivacySettingsService.setPrivacyScreen(v);
              if (mounted) setState(() => _privacyScreenEnabled = v);
            },
          ),
          const Divider(height: 1, indent: 72),
          _buildControlTile(
            icon: Icons.bar_chart_rounded,
            color: const Color(0xFF2563EB),
            label: 'Usage Analytics',
            subtitle: 'Help improve app with anonymous usage data',
            value: _analyticsEnabled,
            onChanged: (v) {
              HapticService.mediumTap();
              setState(() => _analyticsEnabled = v);
            },
          ),
          const Divider(height: 1, indent: 72),
          _buildControlTile(
            icon: Icons.campaign_rounded,
            color: const Color(0xFFD97706),
            label: 'Marketing Emails',
            subtitle: 'Receive tips and feature updates',
            value: _marketingEnabled,
            onChanged: (v) {
              HapticService.mediumTap();
              setState(() => _marketingEnabled = v);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildControlTile({
    required IconData icon,
    required Color color,
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500, fontSize: 14, color: AppColors.textPrimary)),
                Text(subtitle, style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildDataSummaryCard() {
    final items = [
      ('Account Info', 'Name, email, profile photo', Icons.person_outline_rounded),
      ('Mood Entries', 'Daily check-ins and emotion logs', Icons.favorite_border_rounded),
      ('Chat History', 'AI and professional messages', Icons.chat_bubble_outline_rounded),
      ('Session Records', 'Booking and appointment data', Icons.calendar_today_rounded),
      ('Device Info', 'OS version, device model (anonymous)', Icons.phone_android_rounded),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(item.$3, color: AppColors.primary, size: 20),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.$1, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500, fontSize: 14, color: AppColors.textPrimary)),
                          Text(item.$2, style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('Encrypted', style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF15803D))),
                    ),
                  ],
                ),
              ),
              if (i < items.length - 1)
                const Divider(height: 1, indent: 50),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          const Icon(Icons.mail_outline_rounded, color: Color(0xFF2563EB), size: 22),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Privacy Questions?', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1E3A8A))),
                SizedBox(height: 2),
                Text('Contact us at privacy@kausap.ai', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Color(0xFF3B82F6))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w600,
        fontSize: 11,
        letterSpacing: 0.8,
        color: AppColors.textSecondary,
      ),
    );
  }
}
