import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/privacy_settings_service.dart';
import '../../utils/haptic_service.dart';
import '../../widgets/chat/counselor_sharing_dialog.dart';
import 'download_data_screen.dart';
import 'privacy_screen.dart';

/// Privacy Center — Interactive security dashboard explaining how Kausap AI
/// protects student data with AES-256 encryption, HIPAA compliance, and live privacy controls.
class PrivacyCenterScreen extends StatefulWidget {
  const PrivacyCenterScreen({super.key});

  @override
  State<PrivacyCenterScreen> createState() => _PrivacyCenterScreenState();
}

class _PrivacyCenterScreenState extends State<PrivacyCenterScreen> {
  bool _privacyScreenEnabled = true;
  bool _quickEscapeEnabled = false;
  bool _analyticsEnabled = true;
  bool _updatesEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final privacy = await PrivacySettingsService.isPrivacyScreenEnabled();
    final quickEscape = await PrivacySettingsService.isQuickEscapeEnabled();
    if (mounted) {
      setState(() {
        _privacyScreenEnabled = privacy;
        _quickEscapeEnabled = quickEscape;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KausapColors.scaffoldBg(context),
      appBar: AppBar(
        backgroundColor: KausapColors.cardBg(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: KausapColors.textPrimary(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Privacy Controls & Shield',
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
              // Hero card
              _buildHeroCard(context),
              const SizedBox(height: 20),

              // Encryption pillars
              _sectionLabel(context, 'HOW WE SAFEGUARD YOUR WELLNESS DATA'),
              const SizedBox(height: 10),
              _buildEncryptionPillar(
                context: context,
                icon: Icons.lock_rounded,
                color: const Color(0xFF2563EB),
                title: 'AES-256 Encrypted Chats & Reflections',
                description: 'All AI conversations and personal journal reflections are safeguarded with AES-256 encryption.',
              ),
              const SizedBox(height: 10),
              _buildEncryptionPillar(
                context: context,
                icon: Icons.storage_rounded,
                color: const Color(0xFF059669),
                title: 'Encrypted Database at Rest',
                description: 'Your daily mood logs, journal entries, and screener results are encrypted in our secure database.',
              ),
              const SizedBox(height: 10),
              _buildEncryptionPillar(
                context: context,
                icon: Icons.verified_user_rounded,
                color: const Color(0xFF7C3AED),
                title: 'HIPAA-Aligned Privacy',
                description: 'Kausap AI follows strict mental health data confidentiality principles. We NEVER sell your data.',
              ),
              const SizedBox(height: 10),
              _buildEncryptionPillar(
                context: context,
                icon: Icons.public_rounded,
                color: const Color(0xFFD97706),
                title: 'Data Ownership & Rights',
                description: 'You own 100% of your data. You can export a copy or permanently erase all your records anytime.',
              ),
              const SizedBox(height: 24),

              // Privacy controls
              _sectionLabel(context, 'ACTIVE PRIVACY CONTROLS'),
              const SizedBox(height: 10),
              _buildPrivacyControlCard(context),
              const SizedBox(height: 24),

              // Data summary
              _sectionLabel(context, 'DATA WE STORE & ENCRYPT'),
              const SizedBox(height: 10),
              _buildDataSummaryCard(context),
              const SizedBox(height: 24),

              // Quick Actions
              _sectionLabel(context, 'DATA & LEGAL ACTIONS'),
              const SizedBox(height: 10),
              _buildQuickActionsCard(context),
              const SizedBox(height: 20),

              // Contact
              _buildContactCard(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    final isDark = KausapColors.isDark(context);
    final accent = KausapColors.accent(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [accent.withAlpha(230), accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: isDark ? const Color(0x20000000) : accent.withAlpha(40), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(35),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.shield_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Privacy Is Our Priority',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 15.5,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Your emotions, journals, and conversations are strictly confidential and protected.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: Color(0xFFE2E8F0),
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

  Widget _buildEncryptionPillar({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    final isDark = KausapColors.isDark(context);
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: KausapColors.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KausapColors.border(context)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(isDark ? 0 : 8), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                    color: KausapColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
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

  Widget _buildPrivacyControlCard(BuildContext context) {
    final bool shareChatEnabled = context.watch<AuthProvider>().currentUser?['share_chat_with_counselor'] == true;
    final isDark = KausapColors.isDark(context);

    return Container(
      decoration: BoxDecoration(
        color: KausapColors.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KausapColors.border(context)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(isDark ? 0 : 8), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          _buildControlTile(
            context: context,
            icon: Icons.lock_person_rounded,
            color: const Color(0xFF0284C7),
            label: 'Share AI Chats with Counselors',
            subtitle: shareChatEnabled
                ? 'Shared with university guidance counselors'
                : '100% Confidential • Hidden from counselors (Default)',
            value: shareChatEnabled,
            onChanged: (v) {
              CounselorSharingDialog.show(context, onStatusChanged: (_) {
                if (mounted) setState(() {});
              });
            },
          ),
          Divider(height: 1, indent: 68, color: KausapColors.border(context)),
          _buildControlTile(
            context: context,
            icon: Icons.blur_on_rounded,
            color: const Color(0xFF7C3AED),
            label: 'Privacy Screen',
            subtitle: 'Blur app content in recent apps switcher',
            value: _privacyScreenEnabled,
            onChanged: (v) async {
              HapticService.mediumTap();
              await PrivacySettingsService.setPrivacyScreen(v);
              if (mounted) setState(() => _privacyScreenEnabled = v);
            },
          ),
          Divider(height: 1, indent: 68, color: KausapColors.border(context)),
          _buildControlTile(
            context: context,
            icon: Icons.shield_outlined,
            color: const Color(0xFFEF4444),
            label: 'Quick Escape Button',
            subtitle: 'Show quick disguise button on Home screen',
            value: _quickEscapeEnabled,
            onChanged: (v) async {
              HapticService.mediumTap();
              await PrivacySettingsService.setQuickEscape(v);
              if (mounted) setState(() => _quickEscapeEnabled = v);
            },
          ),
          Divider(height: 1, indent: 68, color: KausapColors.border(context)),
          _buildControlTile(
            context: context,
            icon: Icons.bar_chart_rounded,
            color: const Color(0xFF2563EB),
            label: 'Anonymous Usage Analytics',
            subtitle: 'Help improve AI responses without identifying data',
            value: _analyticsEnabled,
            onChanged: (v) {
              HapticService.mediumTap();
              setState(() => _analyticsEnabled = v);
            },
          ),
          Divider(height: 1, indent: 68, color: KausapColors.border(context)),
          _buildControlTile(
            context: context,
            icon: Icons.notifications_active_outlined,
            color: const Color(0xFF16A34A),
            label: 'App & Feature Updates',
            subtitle: 'Receive new wellness feature notifications',
            value: _updatesEnabled,
            onChanged: (v) {
              HapticService.mediumTap();
              setState(() => _updatesEnabled = v);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildControlTile({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13.5, color: KausapColors.textPrimary(context))),
                Text(subtitle, style: TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: KausapColors.textMuted(context))),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: KausapColors.accentLight(context),
            activeThumbColor: KausapColors.accent(context),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildDataSummaryCard(BuildContext context) {
    final isDark = KausapColors.isDark(context);
    final accent = KausapColors.accent(context);

    final items = [
      ('Student Profile Info', 'Name, student email, avatar', Icons.person_outline_rounded),
      ('Mood & Feeling Entries', 'Daily emotional check-ins & feeling logs', Icons.favorite_border_rounded),
      ('AI Companion Chat History', 'Empathetic conversation transcripts', Icons.chat_bubble_outline_rounded),
      ('Journals & Voice Dictations', 'Private written reflections & voice logs', Icons.book_outlined),
      ('Clinical Screeners', 'PHQ-9 & GAD-7 wellness assessment results', Icons.assignment_outlined),
      ('Device Telemetry', 'OS version & app performance (anonymous)', Icons.phone_android_rounded),
    ];

    return Container(
      decoration: BoxDecoration(
        color: KausapColors.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KausapColors.border(context)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(isDark ? 0 : 8), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                child: Row(
                  children: [
                    Icon(item.$3, color: accent, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.$1, style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13.5, color: KausapColors.textPrimary(context))),
                          Text(item.$2, style: TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: KausapColors.textMuted(context))),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF14532D).withAlpha(120) : const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('Encrypted', style: TextStyle(fontFamily: 'Poppins', fontSize: 10.5, fontWeight: FontWeight.w700, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D))),
                    ),
                  ],
                ),
              ),
              if (i < items.length - 1)
                Divider(height: 1, indent: 46, color: KausapColors.border(context)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuickActionsCard(BuildContext context) {
    final isDark = KausapColors.isDark(context);
    return Container(
      decoration: BoxDecoration(
        color: KausapColors.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KausapColors.border(context)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(isDark ? 0 : 8), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: const Color(0xFF0284C7).withAlpha(25), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.download_rounded, color: Color(0xFF0284C7), size: 18),
            ),
            title: Text('Download My Wellness Data', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13.5, color: KausapColors.textPrimary(context))),
            subtitle: Text('Export a copy of your records to JSON', style: TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: KausapColors.textMuted(context))),
            trailing: Icon(Icons.chevron_right_rounded, color: KausapColors.textMuted(context)),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DownloadDataScreen())),
          ),
          Divider(height: 1, indent: 64, color: KausapColors.border(context)),
          ListTile(
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: const Color(0xFF7C3AED).withAlpha(25), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.gavel_rounded, color: Color(0xFF7C3AED), size: 18),
            ),
            title: Text('Terms & Legal Policies', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13.5, color: KausapColors.textPrimary(context))),
            subtitle: Text('Read full Terms of Service & Clinical Disclaimers', style: TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: KausapColors.textMuted(context))),
            trailing: Icon(Icons.chevron_right_rounded, color: KausapColors.textMuted(context)),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyScreen())),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(BuildContext context) {
    final isDark = KausapColors.isDark(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14532D).withAlpha(40) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF15803D).withAlpha(80) : const Color(0xFFBBF7D0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined, color: Color(0xFF16A34A), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Privacy Inquiries & Student Rights', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 13, color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF166534))),
                const SizedBox(height: 2),
                Text('Contact our data protection team at privacy@kausap.ai', style: TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String label) {
    return Text(
      label,
      style: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w700,
        fontSize: 11,
        letterSpacing: 0.8,
        color: KausapColors.textMuted(context),
      ),
    );
  }
}

