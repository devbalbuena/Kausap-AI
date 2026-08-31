import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import '../../utils/haptic_service.dart';
import '../counselor/counselor_dashboard_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_articles_screen.dart';
import 'admin_moderation_screen.dart';
import 'admin_system_screen.dart';
import 'widgets/admin_header_actions.dart';
import '../counselor/widgets/student_clinical_modal.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  bool _isLoading = true;
  List<dynamic> _users = [];
  String? _error;

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  String _activeFilter = 'all'; // all, student, admin, inactive

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await ApiClient().get('/admin/users?limit=200');
      if (mounted) {
        setState(() {
          _users = data as List<dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load user directory';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleUserStatus(String userId, String name, bool currentStatus) async {
    final bool nextStatus = !currentStatus;

    if (nextStatus) {
      // ── Reactivate Flow ──
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_outline_rounded, color: Color(0xFF16A34A), size: 22),
              SizedBox(width: 8),
              Text('Reactivate Account', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16)),
            ],
          ),
          content: Text(
            'Reactivating $name will restore their immediate full access to Kausap AI companion, mood logs, and clinical screeners.',
            style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF64748B), height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(fontFamily: 'Poppins', color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Reactivate', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      try {
        HapticService.heavyTap();
        await ApiClient().patch('/admin/users/$userId/status', body: {'is_active': true}, silent: true);
        _fetchUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$name has been reactivated! ✨'), backgroundColor: const Color(0xFF16A34A)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Reactivation failed: $e'), backgroundColor: const Color(0xFFDC2626)),
          );
        }
      }
      return;
    }

    // ── Deactivate with Reason Flow ──
    final List<String> presetReasons = [
      "Account verification / identity check required",
      "Counselor clinical review / check-in requested",
      "Student requested temporary account pause",
      "Violation of university wellness community guidelines",
      "Custom reason...",
    ];
    String selectedReason = presetReasons[0];
    final customReasonController = TextEditingController();

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.pause_circle_outline_rounded, color: Color(0xFFDC2626), size: 22),
                SizedBox(width: 8),
                Text('Deactivate Account', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select the reason for placing $name\'s account on hold. This will be shown to the student when they log in.',
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 12.5, color: Color(0xFF64748B), height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  ...presetReasons.map((r) {
                    final isChosen = selectedReason == r;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedReason = r),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: isChosen ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isChosen ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Icon(isChosen ? Icons.radio_button_checked : Icons.radio_button_off,
                                size: 16, color: isChosen ? const Color(0xFFDC2626) : const Color(0xFF94A3B8)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                r,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  fontWeight: isChosen ? FontWeight.w600 : FontWeight.w400,
                                  color: isChosen ? const Color(0xFF991B1B) : const Color(0xFF334155),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  if (selectedReason == "Custom reason...") ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: customReasonController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: "Enter custom counselor explanation...",
                        hintStyle: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFDC2626))),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel', style: TextStyle(fontFamily: 'Poppins', color: Color(0xFF64748B))),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Deactivate', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed != true) return;

    final finalReason = selectedReason == "Custom reason..."
        ? (customReasonController.text.trim().isNotEmpty ? customReasonController.text.trim() : "Account temporarily deactivated by Guidance Counselor.")
        : selectedReason;

    try {
      HapticService.heavyTap();
      await ApiClient().patch(
        '/admin/users/$userId/status',
        body: {'is_active': false, 'deactivation_reason': finalReason},
        silent: true,
      );
      _fetchUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name has been deactivated. Reason recorded: "$finalReason"'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deactivation failed: $e'), backgroundColor: const Color(0xFFDC2626)),
        );
      }
    }
  }

  Future<void> _softDeleteUser(String userId, String name) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.inventory_2_outlined, color: Color(0xFFDC2626), size: 22),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Archive Account (Soft Delete)',
                style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to archive $name\'s account?',
              style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield_outlined, color: Color(0xFF0284C7), size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'RA 11036 Compliance Notice: Clinical records, mood entries, and screener assessments are safely preserved in the database for auditing and continuity of care, but removed from active student directory views.',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF1E40AF), height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(fontFamily: 'Poppins', color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Archive Account', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      HapticService.heavyTap();
      await ApiClient().delete('/admin/users/$userId', silent: true);
      _fetchUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name\'s account has been archived. You can view or restore it in the "Archived" tab.'),
            backgroundColor: const Color(0xFF0F172A),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Account archiving failed: $e'), backgroundColor: const Color(0xFFDC2626)),
        );
      }
    }
  }

  Future<void> _restoreUser(String userId, String name) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.restore_from_trash_rounded, color: Color(0xFF16A34A), size: 22),
            SizedBox(width: 8),
            Text('Restore Account', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16)),
          ],
        ),
        content: Text(
          'Restore $name\'s account back to the active student directory? Their full login access and previous logs will be restored.',
          style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF64748B), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(fontFamily: 'Poppins', color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Restore Now', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      HapticService.heavyTap();
      await ApiClient().post('/admin/users/$userId/restore', silent: true);
      _fetchUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name\'s account has been successfully restored! 🎉'), backgroundColor: const Color(0xFF16A34A)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restoration failed: $e'), backgroundColor: const Color(0xFFDC2626)),
        );
      }
    }
  }

  Future<void> _handleAppeal(String userId, String name, bool approve) async {
    try {
      HapticService.mediumTap();
      await ApiClient().post(
        '/admin/users/$userId/resolve-appeal?approved=$approve',
        silent: true,
      );
      _fetchUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approve ? '$name\'s appeal approved & account reactivated! ✨' : '$name\'s appeal was dismissed.'),
            backgroundColor: approve ? const Color(0xFF16A34A) : const Color(0xFF64748B),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to process appeal: $e'), backgroundColor: const Color(0xFFDC2626)),
        );
      }
    }
  }

  void _showUserDetailsModal(Map<String, dynamic> user) {
    HapticService.lightTap();
    final role = (user['role'] ?? 'client').toString().toLowerCase();
    final isAdmin = role == 'admin';

    // If it's a student account, open the rich 3-Tab Clinical Modal with real emojis and chat transcripts!
    if (!isAdmin && role != 'counselor') {
      StudentClinicalModal.show(
        context,
        student: user,
        onStatusChanged: _fetchUsers,
      );
      return;
    }

    final name = user['full_name'] ?? 'User';
    final email = user['email'] ?? '';
    final bool isDeleted = user['is_deleted'] == true;
    final bool isActive = user['is_active'] != false && !isDeleted;
    final String? deactivationReason = user['deactivation_reason'];
    final String? appeal = user['reactivation_appeal'];
    final moodCount = user['mood_entries_count'] ?? 0;
    final chatCount = user['chat_sessions_count'] ?? 0;
    final flagCount = user['flagged_messages_count'] ?? 0;
    final phone = user['phone_number'] ?? 'Not provided';
    final birthday = user['birthday'] ?? 'Not provided';
    final gender = user['gender'] ?? 'Not specified';
    final occupation = user['occupation'] ?? (isAdmin ? 'System Administrator' : 'Student');
    final createdAt = user['created_at']?.toString().split('T')[0] ?? 'Recently';

    final currentAdminEmail = context.read<AuthProvider>().currentUser?['email'] ?? 'admin@kausap.ai';
    final isSelf = email == currentAdminEmail;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: SingleChildScrollView(
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
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: isDeleted
                          ? const Color(0xFFF1F5F9)
                          : (isAdmin
                              ? const Color(0xFFF3E8FF)
                              : (role == 'counselor' ? const Color(0xFFCCFBF1) : const Color(0xFFE0F2FE))),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'U',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isDeleted
                              ? const Color(0xFF64748B)
                              : (isAdmin
                                  ? const Color(0xFF7C3AED)
                                  : (role == 'counselor' ? const Color(0xFF0D9488) : const Color(0xFF0284C7))),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildRoleBadge(role),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            email,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDeleted
                            ? const Color(0xFFF1F5F9)
                            : (isActive ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2)),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDeleted
                              ? const Color(0xFFCBD5E1)
                              : (isActive ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA)),
                        ),
                      ),
                      child: Text(
                        isDeleted ? "Archived" : (isActive ? "Active" : "Inactive"),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: isDeleted
                              ? const Color(0xFF475569)
                              : (isActive ? const Color(0xFF166534) : const Color(0xFF991B1B)),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 16),

                // ── Deactivation Reason Notice (if inactive) ──
                if (!isActive && !isDeleted && deactivationReason != null && deactivationReason.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFFDC2626)),
                            SizedBox(width: 6),
                            Text('Deactivation Reason Recorded:',
                                style: TextStyle(fontFamily: 'Poppins', fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF991B1B))),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '"$deactivationReason"',
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF7F1D1D), height: 1.35),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // ── Student Reactivation Appeal (if pending) ──
                if (appeal != null && appeal.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.mark_email_unread_rounded, size: 15, color: Color(0xFFD97706)),
                            SizedBox(width: 6),
                            Text('Student Reactivation Appeal 📩',
                                style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF92400E))),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '"$appeal"',
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 12.5, color: Color(0xFF78350F), height: 1.35),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _handleAppeal(user['id'], name, true);
                                },
                                icon: const Icon(Icons.check_rounded, size: 14),
                                label: const Text('Approve Appeal', style: TextStyle(fontFamily: 'Poppins', fontSize: 11.5, fontWeight: FontWeight.w600)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF16A34A),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _handleAppeal(user['id'], name, false);
                                },
                                icon: const Icon(Icons.close_rounded, size: 14),
                                label: const Text('Dismiss', style: TextStyle(fontFamily: 'Poppins', fontSize: 11.5, fontWeight: FontWeight.w600)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF64748B),
                                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Account Details Info
                const Text(
                  "Account & Demographics Overview",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow("Account Role", isAdmin ? "Administrator 🛡️" : "Student / Client 🎓"),
                      const SizedBox(height: 8),
                      _buildDetailRow("Occupation", occupation),
                      const SizedBox(height: 8),
                      _buildDetailRow("Phone Number", phone),
                      const SizedBox(height: 8),
                      _buildDetailRow("Birthday", birthday),
                      const SizedBox(height: 8),
                      _buildDetailRow("Gender", gender),
                      const SizedBox(height: 8),
                      _buildDetailRow("Registration Date", createdAt),
                      const SizedBox(height: 8),
                      _buildDetailRow("AI Chat Sessions", "$chatCount sessions"),
                      const SizedBox(height: 8),
                      _buildDetailRow("Mood Check-ins", "$moodCount entries"),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        "Crisis Flags Logged",
                        flagCount > 0 ? "⚠️ $flagCount Flags" : "0 Flags (Safe)",
                        valueColor: flagCount > 0 ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Modal Actions
                if (isAdmin || isSelf)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE9D5FF)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.shield_rounded, color: Color(0xFF7C3AED), size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Administrator Account (System Protected — Cannot be deactivated)",
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6B21A8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (isDeleted) ...[
                  // ── Archived Account Restore Action ──
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _restoreUser(user['id'], name);
                      },
                      icon: const Icon(Icons.restore_from_trash_rounded, size: 18),
                      label: const Text('Restore Account to Active Directory ♻️',
                          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _toggleUserStatus(user['id'], name, isActive);
                          },
                          icon: Icon(isActive ? Icons.pause_circle_outline_rounded : Icons.check_circle_outline, size: 16),
                          label: Text(
                            isActive ? "Deactivate" : "Activate",
                            style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12.5),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isActive ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                            side: BorderSide(color: isActive ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _softDeleteUser(user['id'], name);
                          },
                          icon: const Icon(Icons.inventory_2_outlined, size: 16),
                          label: const Text(
                            "Archive (Delete)",
                            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12.5),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFDC2626),
                            side: const BorderSide(color: Color(0xFFFECACA)),
                            backgroundColor: const Color(0xFFFEF2F2),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoleBadge(String role) {
    final r = role.toLowerCase();
    if (r == 'admin') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFF3E8FF),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE9D5FF)),
        ),
        child: const Text(
          "Admin",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFF7C3AED),
          ),
        ),
      );
    } else if (r == 'counselor') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFCCFBF1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF99F6E4)),
        ),
        child: const Text(
          "Counselor",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0D9488),
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2FE),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFBAE6FD)),
      ),
      child: const Text(
        "Student",
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0284C7),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF64748B)),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: valueColor ?? const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  List<dynamic> _filterUsers(List<dynamic> list) {
    var result = list;

    // Search query filter
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((u) {
        final name = (u['full_name'] ?? '').toString().toLowerCase();
        final email = (u['email'] ?? '').toString().toLowerCase();
        return name.contains(q) || email.contains(q);
      }).toList();
    }

    // Filter chip
    if (_activeFilter == 'student') {
      result = result.where((u) => u['is_deleted'] != true && (u['role'] ?? 'client').toString().toLowerCase() != 'admin').toList();
    } else if (_activeFilter == 'admin') {
      result = result.where((u) => u['is_deleted'] != true && (u['role'] ?? '').toString().toLowerCase() == 'admin').toList();
    } else if (_activeFilter == 'inactive') {
      result = result.where((u) => u['is_deleted'] != true && u['is_active'] == false).toList();
    } else if (_activeFilter == 'archived') {
      result = result.where((u) => u['is_deleted'] == true).toList();
    } else {
      // 'all' shows all active and inactive, excluding soft deleted
      result = result.where((u) => u['is_deleted'] != true).toList();
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filterUsers(_users);
    final activeCount = _users.where((u) => u['is_deleted'] != true).length;
    final studentCount = _users.where((u) => u['is_deleted'] != true && (u['role'] ?? 'client').toString().toLowerCase() != 'admin').length;
    final adminCount = _users.where((u) => u['is_deleted'] != true && (u['role'] ?? '').toString().toLowerCase() == 'admin').length;
    final inactiveCount = _users.where((u) => u['is_deleted'] != true && u['is_active'] == false).length;
    final archivedCount = _users.where((u) => u['is_deleted'] == true).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.people_alt_rounded, color: Color(0xFF0284C7), size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'User Directory',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '$activeCount Active Accounts${archivedCount > 0 ? ' • $archivedCount Archived' : ''}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          AdminHeaderActions(
            onRefresh: () async {
              await _fetchUsers();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search Bar & Filter Chips ──────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: "Search by student name or email...",
                            hintStyle: TextStyle(fontFamily: 'Inter', color: Color(0xFF94A3B8), fontSize: 12),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          onChanged: (val) => setState(() => _searchQuery = val),
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 16),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip("All ($activeCount)", _activeFilter == 'all', () => setState(() => _activeFilter = 'all')),
                      const SizedBox(width: 8),
                      _buildFilterChip("🎓 Students ($studentCount)", _activeFilter == 'student', () => setState(() => _activeFilter = 'student')),
                      const SizedBox(width: 8),
                      _buildFilterChip("🛡️ Admins ($adminCount)", _activeFilter == 'admin', () => setState(() => _activeFilter = 'admin')),
                      const SizedBox(width: 8),
                      _buildFilterChip("⚠️ Inactive ($inactiveCount)", _activeFilter == 'inactive', () => setState(() => _activeFilter = 'inactive')),
                      const SizedBox(width: 8),
                      _buildFilterChip("🗑️ Archived ($archivedCount)", _activeFilter == 'archived', () => setState(() => _activeFilter = 'archived')),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Users List ───────────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _error!,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                color: Color(0xFFDC2626),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _fetchUsers,
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : filtered.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(_activeFilter == 'archived' ? Icons.inventory_2_outlined : Icons.people_outline_rounded,
                                      size: 40, color: const Color(0xFF94A3B8)),
                                  const SizedBox(height: 10),
                                  Text(
                                    _activeFilter == 'archived'
                                        ? 'No archived accounts found.'
                                        : 'No accounts match the selected filter.',
                                    style: const TextStyle(fontFamily: 'Inter', color: Color(0xFF64748B), fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () async {
                              HapticService.lightTap();
                              await _fetchUsers();
                            },
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 480),
                                child: ListView.separated(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                                  itemBuilder: (context, index) => _buildUserCard(filtered[index]),
                                ),
                              ),
                            ),
                          ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onSelected) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        HapticService.lightTap();
        onSelected();
      },
      selectedColor: AppColors.primary,
      backgroundColor: const Color(0xFFF1F5F9),
      labelStyle: TextStyle(
        fontFamily: 'Poppins',
        color: isSelected ? Colors.white : const Color(0xFF475569),
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        fontSize: 11,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
    );
  }

  Widget _buildUserCard(dynamic user) {
    final name = user['full_name'] ?? 'Unknown';
    final email = user['email'] ?? '';
    final role = (user['role'] ?? 'client').toString().toLowerCase();
    final isAdmin = role == 'admin';
    final bool isDeleted = user['is_deleted'] == true;
    final bool isActive = user['is_active'] != false && !isDeleted;
    final String? appeal = user['reactivation_appeal'];
    final moodCount = user['mood_entries_count'] ?? 0;
    final chatCount = user['chat_sessions_count'] ?? 0;
    final flagCount = user['flagged_messages_count'] ?? 0;
    final joinDate = user['created_at'] != null ? user['created_at'].toString().split('T')[0] : 'Recently';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDeleted ? const Color(0xFFF8FAFC) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDeleted ? const Color(0xFFE2E8F0) : const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    backgroundColor: isDeleted
                        ? const Color(0xFFE2E8F0)
                        : (isAdmin ? const Color(0xFFF3E8FF) : const Color(0xFFE0F2FE)),
                    radius: 22,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: isDeleted
                            ? const Color(0xFF64748B)
                            : (isAdmin ? const Color(0xFF7C3AED) : const Color(0xFF0284C7)),
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: isDeleted
                          ? const Color(0xFF94A3B8)
                          : (isActive ? const Color(0xFF16A34A) : const Color(0xFFDC2626)),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: isDeleted ? const Color(0xFF64748B) : const Color(0xFF0F172A),
                              decoration: isDeleted ? TextDecoration.lineThrough : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildRoleBadge(role),
                        if (isDeleted) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('Archived', style: TextStyle(fontFamily: 'Inter', fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (appeal != null && appeal.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.mark_email_unread_rounded, size: 14, color: Color(0xFFD97706)),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Reactivation appeal submitted by student',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF92400E)),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFFD97706)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 12, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 4),
                  Text(
                    'Joined: $joinDate',
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded, size: 12, color: Color(0xFF7C3AED)),
                  const SizedBox(width: 4),
                  Text(
                    '$chatCount',
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF7C3AED)),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.mood_rounded, size: 13, color: Color(0xFFD97706)),
                  const SizedBox(width: 4),
                  Text(
                    '$moodCount',
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFFD97706)),
                  ),
                  if (flagCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '⚠️ $flagCount',
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFFDC2626)),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 34,
            child: OutlinedButton.icon(
              onPressed: () => _showUserDetailsModal(user),
              icon: Icon(isDeleted ? Icons.restore_from_trash_rounded : Icons.info_outline_rounded, size: 14),
              label: Text(
                isDeleted ? 'View Archived / Restore' : 'Account Details',
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.dashboard_rounded, 'Dashboard', false, () {
            HapticService.lightTap();
            final role = context.read<AuthProvider>().currentUser?['role'];
            if (role == 'counselor') {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const CounselorDashboardScreen()),
              );
            } else {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
              );
            }
          }),
          _buildNavItem(Icons.article_rounded, 'Articles', false, () {
            HapticService.lightTap();
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const AdminArticlesScreen()),
            );
          }),
          _buildNavItem(Icons.people_alt_rounded, 'Users', true, null),
          _buildNavItem(Icons.flag_rounded, 'Moderation', false, () {
            HapticService.lightTap();
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const AdminModerationScreen()),
            );
          }),
          _buildNavItem(Icons.tune_rounded, 'System', false, () {
            HapticService.lightTap();
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const AdminSystemScreen()),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected, VoidCallback? onTap) {
    final color = isSelected ? AppColors.primary : const Color(0xFF64748B);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10.5,
              color: color,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
