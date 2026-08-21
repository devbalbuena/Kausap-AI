import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_client.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../auth/login_screen.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 24),
            SizedBox(width: 8),
            Text(
              'Delete Account',
              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 18, color: Color(0xFFEF4444)),
            ),
          ],
        ),
        content: const Text(
          'This action is irreversible. All your personal information, mood logs, journal entries, screener history, and AI conversations will be permanently deleted.',
          style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF475569), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(fontFamily: 'Poppins', color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final authProvider = context.read<AuthProvider>();
                final userId = authProvider.currentUser?['id'];
                if (userId != null) {
                  await ApiClient().delete('/admin/users/$userId');
                }
                await authProvider.logout();
                if (!mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              } catch (_) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Account deletion requested. If you encounter issues, contact support@kausap.ai'),
                    backgroundColor: Color(0xFFEF4444),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete Permanently', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Privacy & Legal Terms',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: const Color(0xFF64748B),
          labelStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500, fontSize: 13),
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Terms'),
            Tab(text: 'Privacy'),
            Tab(text: 'Rights & Safety'),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildTermsTab(),
              _buildPrivacyTab(),
              _buildRightsTab(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Tab 1: Terms of Service ────────────────────────────────────────────────
  Widget _buildTermsTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        _buildHighlightCard(
          icon: Icons.gavel_rounded,
          color: const Color(0xFF0284C7),
          title: "Student Terms of Service",
          subtitle: "Last Updated: August 2026 • Version 2.4",
        ),
        const SizedBox(height: 16),

        _buildLegalCard(
          title: "1. Agreement & Purpose",
          content:
              "Welcome to Kausap AI. By accessing or using our mobile application and services, you agree to comply with and be bound by these Terms of Service. Kausap AI is designed to provide AI-powered conversational emotional support, mood tracking, daily journaling, and mental wellness tools for students.",
        ),
        const SizedBox(height: 12),

        _buildLegalCard(
          title: "2. Medical & Clinical Disclaimer",
          isAlert: true,
          content:
              "IMPORTANT: Kausap AI is an AI wellness and emotional support companion, NOT a licensed healthcare provider, medical professional, or clinical psychiatric service.\n\n"
              "• Kausap AI does not provide medical diagnoses, treatment prescriptions, or psychotherapy.\n"
              "• The platform is NOT a substitute for professional mental health therapy or emergency services.\n"
              "• If you are experiencing an acute mental health crisis or suicidal thoughts, immediately call 1553 (NCMH 24/7 Toll-Free), Hopeline PH (0917-558-4673), or dial 911.",
        ),
        const SizedBox(height: 12),

        _buildLegalCard(
          title: "3. User Eligibility & Student Accounts",
          content:
              "You must be at least 13 years of age to use Kausap AI. You agree to provide accurate registration information and maintain the security of your login credentials. You are responsible for all activities occurring under your account.",
        ),
        const SizedBox(height: 12),

        _buildLegalCard(
          title: "4. Acceptable Conduct & AI Usage",
          content:
              "You agree to use Kausap AI respectfully and solely for lawful self-care purposes. You must not attempt to reverse engineer the AI model, harvest data, or input abusive, threatening, or illegal content.",
        ),
        const SizedBox(height: 12),

        _buildLegalCard(
          title: "5. Limitation of Liability",
          content:
              "Kausap AI and its developers provide this platform on an 'as-is' and 'as-available' basis. To the maximum extent permitted by law, Kausap AI disclaims liability for any indirect, incidental, or consequential damages resulting from platform usage.",
        ),
      ],
    );
  }

  // ── Tab 2: Privacy Policy ──────────────────────────────────────────────────
  Widget _buildPrivacyTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        _buildHighlightCard(
          icon: Icons.shield_rounded,
          color: const Color(0xFF16A34A),
          title: "Student Privacy Policy",
          subtitle: "Your mental health data belongs strictly to you.",
        ),
        const SizedBox(height: 16),

        _buildLegalCard(
          title: "1. Information We Collect",
          content:
              "We collect only the information necessary to provide supportive wellness features:\n\n"
              "• Account Information: Name, email address, student/occupation status.\n"
              "• Mood & Wellness Logs: Daily mood levels, feeling tags, journal reflections, and clinical screener scores (PHQ-9 & GAD-7).\n"
              "• Chat Interactions: Messages shared with Kausap AI to generate empathetic context.",
        ),
        const SizedBox(height: 12),

        _buildLegalCard(
          title: "2. AES-256 Encryption & Zero Data Selling",
          content:
              "• Zero Advertising & No Data Selling: We NEVER sell, rent, or monetize your personal mental health data, journals, or chat conversations to any third party or advertiser.\n"
              "• Encryption at Rest & In Transit: All data transfers use TLS 1.3 encryption, and sensitive wellness entries are encrypted with AES-256 database protection.",
        ),
        const SizedBox(height: 12),

        _buildLegalCard(
          title: "3. How We Use Your Data",
          content:
              "Your information is strictly used to:\n"
              "• Provide personalized mood analytics and wellness insights.\n"
              "• Power empathetic AI chatbot responses.\n"
              "• Calculate weekly/monthly health trends and streak milestones.",
        ),
        const SizedBox(height: 12),

        _buildLegalCard(
          title: "4. Data Retention & Erasure",
          content:
              "Your data is retained only while your account remains active. You have the right at any time to request complete data export or immediate permanent erasure of all stored logs.",
        ),
      ],
    );
  }

  // ── Tab 3: Rights & Safety ─────────────────────────────────────────────────
  Widget _buildRightsTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        _buildHighlightCard(
          icon: Icons.verified_user_rounded,
          color: const Color(0xFF7C3AED),
          title: "Your Rights & Emergency Safety",
          subtitle: "Student protections and crisis response protocols.",
        ),
        const SizedBox(height: 16),

        _buildLegalCard(
          title: "1. Your Data Rights",
          content:
              "Under applicable privacy regulations (including GDPR and Philippine Data Privacy Act standards), you have full rights over your data:\n\n"
              "• Right to Access: View all your mood records, screeners, and journals anytime.\n"
              "• Right to Portability: Download your Personal Wellness Report directly to your device.\n"
              "• Right to Erasure: Permanently delete your account and all associated records.",
        ),
        const SizedBox(height: 16),

        // 24/7 Crisis Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFECACA)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Row(
                children: [
                  Icon(Icons.emergency_rounded, color: Color(0xFFDC2626), size: 20),
                  SizedBox(width: 8),
                  Text(
                    "24/7 Crisis Hotline Directory",
                    style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF991B1B)),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                "If you are ever in severe emotional distress or require urgent human help, please contact:\n"
                "• NCMH Toll-Free (24/7): 1553 / 0917-899-8727\n"
                "• Hopeline Philippines: 0917-558-4673\n"
                "• National Emergency: 911",
                style: TextStyle(fontFamily: 'Inter', fontSize: 12.5, height: 1.5, color: Color(0xFF7F1D1D)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Danger zone
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFCA5A5)),
            boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.delete_forever_rounded, color: Color(0xFFEF4444), size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Danger Zone',
                    style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 14.5, color: Color(0xFFEF4444)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Permanently delete your account and all stored mental health records. This action cannot be reversed.',
                style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF64748B), height: 1.4),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _showDeleteAccountDialog,
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Delete My Account Permanently'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFEF4444)),
                    foregroundColor: const Color(0xFFEF4444),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHighlightCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 3))],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 14.5, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalCard({
    required String title,
    required String content,
    bool isAlert = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAlert ? const Color(0xFFFFFBEB) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isAlert ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
              color: isAlert ? const Color(0xFF92400E) : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              height: 1.5,
              color: isAlert ? const Color(0xFF78350F) : const Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }
}
