import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import '../../utils/haptic_service.dart';
import 'login_screen.dart';

class DeactivatedAccountScreen extends StatefulWidget {
  final Map<String, dynamic>? userProfile;

  const DeactivatedAccountScreen({super.key, this.userProfile});

  @override
  State<DeactivatedAccountScreen> createState() => _DeactivatedAccountScreenState();
}

class _DeactivatedAccountScreenState extends State<DeactivatedAccountScreen> {
  bool _isSubmittingAppeal = false;
  String? _submittedAppeal;
  String? _deactivationReason;
  String? _deactivatedDate;

  @override
  void initState() {
    super.initState();
    _extractUserData();
  }

  void _extractUserData() {
    final user = widget.userProfile ?? context.read<AuthProvider>().currentUser;
    if (user != null) {
      _deactivationReason = user['deactivation_reason']?.toString();
      _submittedAppeal = user['reactivation_appeal']?.toString();
      if (user['deactivated_at'] != null) {
        _deactivatedDate = user['deactivated_at'].toString().split('T')[0];
      }
    }
    _deactivationReason ??= "Account temporarily placed on hold by the University Guidance & Counseling Center.";
    _deactivatedDate ??= "Recently";
  }

  Future<void> _openAppealSheet() async {
    HapticService.lightTap();
    final textController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Icon(Icons.mark_email_unread_rounded, color: Color(0xFF0284C7), size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Reactivation Appeal',
                        style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Explain your request to the Guidance Counselor. Your message will be reviewed by the university counseling staff.',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 12.5, color: Color(0xFF64748B), height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: textController,
                    maxLines: 4,
                    maxLength: 300,
                    decoration: InputDecoration(
                      hintText: "E.g., I have completed my student verification / I'd like to resume using Kausap AI...",
                      hintStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF0284C7))),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmittingAppeal
                          ? null
                          : () async {
                              final text = textController.text.trim();
                              if (text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please write a brief explanation for your appeal.')),
                                );
                                return;
                              }
                              setModalState(() => _isSubmittingAppeal = true);
                              try {
                                await ApiClient().post('/auth/appeal', body: {'appeal_message': text}, silent: true);
                                if (context.mounted) {
                                  Navigator.pop(ctx);
                                  setState(() {
                                    _submittedAppeal = text;
                                    _isSubmittingAppeal = false;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Reactivation appeal sent to Guidance Office! 📨'),
                                      backgroundColor: Color(0xFF16A34A),
                                    ),
                                  );
                                }
                              } catch (e) {
                                setModalState(() => _isSubmittingAppeal = false);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to submit appeal: $e'), backgroundColor: const Color(0xFFDC2626)),
                                  );
                                }
                              }
                            },
                      icon: _isSubmittingAppeal
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send_rounded, size: 18),
                      label: Text(
                        _isSubmittingAppeal ? 'Submitting...' : 'Submit Appeal to Counselors',
                        style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13.5),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _launchEmail() async {
    await Clipboard.setData(const ClipboardData(text: 'guidance@csu.edu.ph'));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📧 Official email copied: guidance@csu.edu.ph'),
          backgroundColor: Color(0xFF0284C7),
        ),
      );
    }
  }

  Future<void> _launchPhone() async {
    await Clipboard.setData(const ClipboardData(text: '(085) 341-2786'));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📞 Guidance Hotline copied: (085) 341-2786'),
          backgroundColor: Color(0xFF16A34A),
        ),
      );
    }
  }

  Future<void> _handleSignOut() async {
    HapticService.lightTap();
    await context.read<AuthProvider>().logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.userProfile ?? context.watch<AuthProvider>().currentUser;
    final userName = user?['full_name'] ?? (user?['first_name'] != null ? '${user?['first_name']} ${user?['last_name'] ?? ''}' : 'Student');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const SizedBox.shrink(), // No back arrow to prevent bypassing
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.shield_outlined, color: Color(0xFFDC2626), size: 18),
            ),
            const SizedBox(width: 8),
            const Text(
              'CSU Guidance & Counseling',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFF64748B), size: 20),
            tooltip: 'Sign Out',
            onPressed: _handleSignOut,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),

              // ── Notice Hero ──────────────────────────────────────────────
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFECACA), width: 2),
                ),
                child: const Icon(Icons.pause_circle_outline_rounded, color: Color(0xFFDC2626), size: 40),
              ),
              const SizedBox(height: 16),
              const Text(
                'Account Temporarily Deactivated',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Hello $userName, your Kausap AI account access is currently on hold.',
                style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF64748B), height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // ── Reason Card ──────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 3))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFD97706)),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Counselor Notice & Reason',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Inactive',
                            style: TextStyle(fontFamily: 'Inter', fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFFDC2626)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        _deactivationReason!,
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF334155), height: 1.45, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Date of Deactivation:', style: TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: Color(0xFF94A3B8))),
                        Text(_deactivatedDate!, style: const TextStyle(fontFamily: 'Inter', fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Appeal Status / Action ───────────────────────────────────
              if (_submittedAppeal != null && _submittedAppeal!.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 18),
                          SizedBox(width: 6),
                          Text('Reactivation Appeal Under Review ⏳',
                              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF166534))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your appeal message: "$_submittedAppeal"',
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 12.5, color: Color(0xFF14532D), height: 1.4),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'The guidance counselor will review your request shortly.',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: Color(0xFF15803D)),
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _openAppealSheet,
                    icon: const Icon(Icons.mark_email_unread_rounded, size: 18),
                    label: const Text('Submit Reactivation Appeal 📩', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13.5)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              // ── University Counseling Office Contacts ─────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'University Guidance Office Contacts',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.email_outlined, size: 18, color: Color(0xFF0284C7)),
                      ),
                      title: const Text('guidance@csu.edu.ph', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                      subtitle: const Text('Official Counseling Office Email', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF64748B))),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF94A3B8)),
                      onTap: _launchEmail,
                    ),
                    const Divider(height: 16),
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.phone_in_talk_rounded, size: 18, color: Color(0xFF16A34A)),
                      ),
                      title: const Text('(085) 341-2786', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                      subtitle: const Text('Guidance Hotline (Mon-Fri 8am-5pm)', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF64748B))),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF94A3B8)),
                      onTap: _launchPhone,
                    ),
                    const Divider(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Office Location', style: TextStyle(fontFamily: 'Inter', fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                              SizedBox(height: 2),
                              Text('2nd Floor, Admin Bldg, CSU Main Campus, Ampayon, Butuan City',
                                  style: TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: Color(0xFF64748B), height: 1.35)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Sign Out Button ──────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: _handleSignOut,
                  icon: const Icon(Icons.logout_rounded, size: 18, color: Color(0xFF64748B)),
                  label: const Text('Sign Out of Account', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF64748B))),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
