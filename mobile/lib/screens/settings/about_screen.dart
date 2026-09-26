import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_routes.dart';
import 'privacy_screen.dart';
import '../../utils/haptic_service.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const String _appVersion = '1.0.0';
  static const String _buildNumber = '31';

  void _showFeedbackDialog(BuildContext context) {
    final controller = TextEditingController();
    final accent = KausapColors.accent(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: KausapColors.cardBg(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Icon(Icons.rate_review_rounded, color: accent, size: 22),
            const SizedBox(width: 10),
            Text(
              'Send App Feedback',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: KausapColors.textPrimary(context),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How can we make Kausap AI better for you? Your feedback is anonymous and helps us improve student wellness.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: KausapColors.textMuted(context),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 4,
              style: TextStyle(color: KausapColors.textPrimary(context), fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Share your thoughts, suggestions, or report an issue...',
                hintStyle: TextStyle(fontFamily: 'Inter', fontSize: 12, color: KausapColors.textMuted(context)),
                filled: true,
                fillColor: KausapColors.subtleBg(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: KausapColors.border(context)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: KausapColors.border(context)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: accent, width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(fontFamily: 'Poppins', color: KausapColors.textMuted(context))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              HapticService.success();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Thank you! Your feedback has been received.'),
                  backgroundColor: Color(0xFF16A34A),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Submit', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = KausapColors.accent(context);

    return Scaffold(
      backgroundColor: KausapColors.scaffoldBg(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: KausapColors.textPrimary(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'About Kausap AI',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: KausapColors.textPrimary(context),
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              // Logo & App Header
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [accent, KausapColors.accentLight(context)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withAlpha(60),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 48),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Kausap AI',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                        color: KausapColors.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Student Mental Health Companion',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: KausapColors.textMuted(context),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 14),
                          SizedBox(width: 6),
                          Text(
                            'Version $_appVersion (Build $_buildNumber)',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF166534),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── 1. About Kausap AI ─────────────────────────────────────────
              _sectionLabel(context, 'ABOUT KAUSAP AI'),
              const SizedBox(height: 8),
              _card(context, [
                _buildInfoRow(
                  context: context,
                  icon: Icons.info_outline_rounded,
                  iconColor: accent,
                  label: 'What is Kausap AI?',
                  value: 'A Filipino-first mental health companion offering safe AI emotional support, daily mood tracking, and self-care tools.',
                ),
                _divider(context),
                _buildInfoRow(
                  context: context,
                  icon: Icons.school_rounded,
                  iconColor: const Color(0xFF16A34A),
                  label: 'Campus Initiative',
                  value: 'Caraga State University (CSU) Student Mental Wellness Project',
                ),
                _divider(context),
                _buildInfoRow(
                  context: context,
                  icon: Icons.assignment_turned_in_outlined,
                  iconColor: const Color(0xFF7C3AED),
                  label: 'Clinical Instruments',
                  value: 'Standardized PHQ-9 (Depression) & GAD-7 (Anxiety) licensed assessments',
                ),
                _divider(context),
                _buildInfoRow(
                  context: context,
                  icon: Icons.language_rounded,
                  iconColor: const Color(0xFFEA580C),
                  label: 'Language Support',
                  value: 'English & Conversational Taglish',
                ),
              ]),

              const SizedBox(height: 20),

              // ── 2. Security & AI Architecture ──────────────────────────────
              _sectionLabel(context, 'SECURITY & AI ARCHITECTURE'),
              const SizedBox(height: 8),
              _card(context, [
                _buildInfoRow(
                  context: context,
                  icon: Icons.lock_outline_rounded,
                  iconColor: const Color(0xFF16A34A),
                  label: 'Data Encryption',
                  value: 'Confidential encrypted storage for all mood entries, journals & screeners',
                ),
                _divider(context),
                _buildInfoRow(
                  context: context,
                  icon: Icons.smart_toy_outlined,
                  iconColor: accent,
                  label: 'AI Model',
                  value: 'Google Gemini AI with mental wellness crisis guardrails',
                ),
                _divider(context),
                _buildInfoRow(
                  context: context,
                  icon: Icons.devices_rounded,
                  iconColor: const Color(0xFF64748B),
                  label: 'Platform Architecture',
                  value: 'Flutter Multi-Platform • FastAPI • Neon Serverless Postgres',
                ),
              ]),

              const SizedBox(height: 20),

              // ── 3. Legal & Privacy Policies ────────────────────────────────
              _sectionLabel(context, 'LEGAL & PRIVACY POLICIES'),
              const SizedBox(height: 8),
              _card(context, [
                _buildNavRow(
                  context: context,
                  icon: Icons.article_outlined,
                  iconColor: accent,
                  label: 'Terms of Service',
                  subtitle: 'User agreement, account rules & fair usage',
                  onTap: () {
                    HapticService.lightTap();
                    Navigator.push(context, slideRoute(const PrivacyScreen()));
                  },
                ),
                _divider(context),
                _buildNavRow(
                  context: context,
                  icon: Icons.shield_outlined,
                  iconColor: const Color(0xFF16A34A),
                  label: 'Privacy Policy',
                  subtitle: 'How your data is protected & stored',
                  onTap: () {
                    HapticService.lightTap();
                    Navigator.push(context, slideRoute(const PrivacyScreen()));
                  },
                ),
                _divider(context),
                _buildNavRow(
                  context: context,
                  icon: Icons.gavel_rounded,
                  iconColor: const Color(0xFF7C3AED),
                  label: 'Clinical & Safety Disclaimers',
                  subtitle: 'Crisis hotline directory & medical boundaries',
                  onTap: () {
                    HapticService.lightTap();
                    Navigator.push(context, slideRoute(const PrivacyScreen()));
                  },
                ),
              ]),

              const SizedBox(height: 24),

              // Feedback Button
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => _showFeedbackDialog(context),
                  icon: Icon(Icons.feedback_outlined, size: 18, color: accent),
                  label: Text(
                    'Send App Feedback / Suggestions',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: accent,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: accent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Footer
              Center(
                child: Text(
                  '© 2026 Kausap AI. All rights reserved.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    color: KausapColors.textMuted(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 0.7,
          color: KausapColors.textMuted(context),
        ),
      ),
    );
  }

  Widget _card(BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: KausapColors.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KausapColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: KausapColors.isDark(context) ? Colors.transparent : const Color(0x04000000),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: KausapColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    color: KausapColors.textMuted(context),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavRow({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: KausapColors.textPrimary(context),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11.5,
                      color: KausapColors.textMuted(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: KausapColors.textMuted(context)),
          ],
        ),
      ),
    );
  }

  Widget _divider(BuildContext context) {
    return Divider(height: 1, indent: 60, color: KausapColors.border(context));
  }
}
