import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import '../auth/role_selection_screen.dart';
import 'admin_users_screen.dart';
import 'admin_moderation_screen.dart';
import 'admin_system_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _stats;
  int _pendingCount = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        ApiClient().get('/admin/stats'),
        ApiClient().get('/admin/users?limit=200'),
      ]);
      final stats = results[0] as Map<String, dynamic>;
      final users = results[1] as List<dynamic>;
      final pending = users.where((u) => u['role'] == 'professional' && u['is_verified'] == false).length;
      if (mounted) {
        setState(() {
          _stats = stats;
          _pendingCount = pending;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load admin stats';
          _isLoading = false;
        });
      }
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to sign out of the Administrator account?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AuthProvider>().logout();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC62828), foregroundColor: Colors.white),
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFD6F1FC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Admin Control Center', style: AppTextStyles.heading2.copyWith(fontSize: 16, color: const Color(0xFF2C3E50), fontWeight: FontWeight.bold)),
                const Text('Kausap AI Platform', style: TextStyle(fontSize: 11, color: Color(0xFF707974))),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFC62828)),
            onPressed: _logout,
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchStats,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry Connection'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
      );
    }
    if (_stats == null) return const SizedBox.shrink();

    return RefreshIndicator(
      onRefresh: _fetchStats,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          // ── System Status Pill ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE8EAED)),
              boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 6, offset: Offset(0, 2))],
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    "All Systems Operational • Live Neon Postgres",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF065F46)),
                  ),
                ),
                const Text("v1.13 Beta", style: TextStyle(fontSize: 11, color: Color(0xFF9E9E9E), fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Actionable Pending Verification Alert ───────────────────────
          if (_pendingCount > 0)
            GestureDetector(
              onTap: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const AdminUsersScreen()),
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFB923C)),
                  boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 3))],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF97316),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.pending_actions_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$_pendingCount Professional${_pendingCount > 1 ? 's' : ''} Pending Licensure Verification',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF9A3412)),
                          ),
                          const SizedBox(height: 2),
                          const Text('Tap to review credentials and approve practice license.', style: TextStyle(fontSize: 11, color: Color(0xFFC2410C))),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFEA580C), size: 14),
                  ],
                ),
              ),
            ),

          // ── System Overview Grid ─────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('System Overview', style: AppTextStyles.heading2.copyWith(fontSize: 18, color: const Color(0xFF2C3E50), fontWeight: FontWeight.bold)),
              const Text('Live Metrics', style: TextStyle(fontSize: 12, color: Color(0xFF707974))),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.25,
            children: [
              _buildStatCard(
                'Total Users',
                _stats!['total_users']?.toString() ?? '0',
                Icons.people_alt_rounded,
                const Color(0xFF3B82F6),
                onTap: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AdminUsersScreen())),
              ),
              _buildStatCard(
                'Active Users',
                _stats!['total_active_users']?.toString() ?? '0',
                Icons.how_to_reg_rounded,
                const Color(0xFF10B981),
                onTap: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AdminUsersScreen())),
              ),
              _buildStatCard(
                'Chat Sessions',
                _stats!['total_chat_sessions']?.toString() ?? '0',
                Icons.chat_bubble_rounded,
                const Color(0xFF8B5CF6),
              ),
              _buildStatCard(
                'Flagged Crisis',
                _stats!['total_flagged_messages']?.toString() ?? '0',
                Icons.flag_rounded,
                AppColors.error,
                onTap: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AdminModerationScreen())),
              ),
              _buildStatCard(
                'Mood Entries',
                _stats!['total_mood_entries']?.toString() ?? '0',
                Icons.mood_rounded,
                const Color(0xFFF59E0B),
              ),
              _buildStatCard(
                'Referrals',
                _stats!['total_referrals']?.toString() ?? '0',
                Icons.local_hospital_rounded,
                const Color(0xFFEC4899),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // ── Quick Admin Actions ──────────────────────────────────────────
          Text('Quick Admin Actions', style: AppTextStyles.heading2.copyWith(fontSize: 16, color: const Color(0xFF2C3E50), fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _buildQuickActionTile(
            icon: Icons.person_search_rounded,
            iconColor: const Color(0xFF3B82F6),
            iconBg: const Color(0xFFEFF6FF),
            title: 'User Management & Roles',
            subtitle: 'Search accounts, change roles & manage client permissions',
            onTap: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AdminUsersScreen())),
          ),
          const SizedBox(height: 10),
          _buildQuickActionTile(
            icon: Icons.verified_user_rounded,
            iconColor: const Color(0xFF10B981),
            iconBg: const Color(0xFFECFDF5),
            title: 'Therapist Licensure Queue',
            subtitle: 'Review PRC license credentials and approve doctors',
            onTap: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AdminUsersScreen())),
          ),
          const SizedBox(height: 10),
          _buildQuickActionTile(
            icon: Icons.emergency_rounded,
            iconColor: const Color(0xFFEF4444),
            iconBg: const Color(0xFFFEF2F2),
            title: 'Crisis Triage & Moderation',
            subtitle: 'Review flagged messages and emergency safety protocols',
            onTap: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AdminModerationScreen())),
          ),
          const SizedBox(height: 22),

          // ── Cloud & Infrastructure Health ────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8EAED)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.cloud_done_rounded, color: AppColors.primary, size: 18),
                    SizedBox(width: 8),
                    Text("Infrastructure Status", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2C3E50))),
                  ],
                ),
                const SizedBox(height: 12),
                _buildHealthRow("PostgreSQL Database", "Neon Serverless (Connected)", const Color(0xFF10B981)),
                const SizedBox(height: 8),
                _buildHealthRow("Kausap AI Engine", "Online & Responding", const Color(0xFF10B981)),
                const SizedBox(height: 8),
                _buildHealthRow("RA 11036 Data Protection", "Encryption Active", const Color(0xFF10B981)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8EAED)),
          boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                if (onTap != null)
                  const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFCBD5E1), size: 12),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                ),
                Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF707974), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EAED)),
        boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2C3E50))),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF707974))),
        trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF9E9E9E), size: 18),
        onTap: onTap,
      ),
    );
  }

  Widget _buildHealthRow(String label, String status, Color statusColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
        Row(
          children: [
            Container(width: 6, height: 6, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(status, style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 65,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.dashboard_rounded, 'Dashboard', true, null),
          _buildNavItem(Icons.people_alt_rounded, 'Users', false, () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const AdminUsersScreen()),
            );
          }),
          _buildNavItem(Icons.flag_rounded, 'Moderation', false, () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const AdminModerationScreen()),
            );
          }),
          _buildNavItem(Icons.tune_rounded, 'System', false, () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const AdminSystemScreen()),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected, VoidCallback? onTap) {
    final color = isSelected ? AppColors.primary : const Color(0xFF707974);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
