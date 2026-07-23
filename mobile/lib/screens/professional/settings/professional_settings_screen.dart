import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../../auth/role_selection_screen.dart';

class ProfessionalSettingsScreen extends StatefulWidget {
  const ProfessionalSettingsScreen({super.key});

  @override
  State<ProfessionalSettingsScreen> createState() => _ProfessionalSettingsScreenState();
}

class _ProfessionalSettingsScreenState extends State<ProfessionalSettingsScreen> {
  bool _notifySessions = true;
  bool _notifyAlerts = true;
  bool _notifyReports = false;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final firstName = user?['first_name'] ?? '';
    final lastName = user?['last_name'] ?? '';
    final email = user?['email'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 800;
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, isMobile ? 60 : 32, 24, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Settings",
                    style: AppTextStyles.heading1.copyWith(color: const Color(0xFF3D405B))),
                const SizedBox(height: 8),
                Text("Manage your account preferences.",
                    style: AppTextStyles.body.copyWith(color: const Color(0xFF707974))),
                const SizedBox(height: 32),

                // ── Profile Section ───────────────────────────────────────────
                _buildSectionCard(
                  title: "Profile",
                  icon: Icons.person_outline_rounded,
                  children: [
                    _buildProfileHeader(firstName, lastName, email),
                    const SizedBox(height: 24),
                    _buildTextField("First Name", firstName),
                    const SizedBox(height: 16),
                    _buildTextField("Last Name", lastName),
                    const SizedBox(height: 16),
                    _buildTextField("Email", email, enabled: false),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text("Save Changes"),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Notifications Section ─────────────────────────────────────
                _buildSectionCard(
                  title: "Notifications",
                  icon: Icons.notifications_outlined,
                  children: [
                    _buildToggleItem(
                      "Session Reminders",
                      "Get notified before upcoming sessions",
                      _notifySessions,
                      (v) => setState(() => _notifySessions = v),
                    ),
                    const Divider(height: 1, color: Color(0xFFE8EAED)),
                    _buildToggleItem(
                      "Triage Alerts",
                      "Immediate alerts for high-risk flagged messages",
                      _notifyAlerts,
                      (v) => setState(() => _notifyAlerts = v),
                    ),
                    const Divider(height: 1, color: Color(0xFFE8EAED)),
                    _buildToggleItem(
                      "Weekly Reports",
                      "Receive weekly outcome analytics summary",
                      _notifyReports,
                      (v) => setState(() => _notifyReports = v),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Security Section ──────────────────────────────────────────
                _buildSectionCard(
                  title: "Security",
                  icon: Icons.lock_outline_rounded,
                  children: [
                    _buildActionTile(
                      "Change Password",
                      "Update your account password",
                      Icons.key_rounded,
                      onTap: () => _showChangePasswordSheet(context),
                    ),
                    const Divider(height: 1, color: Color(0xFFE8EAED)),
                    _buildActionTile(
                      "Two-Factor Authentication",
                      "Add an extra layer of security",
                      Icons.verified_user_outlined,
                      onTap: () {},
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── About Section ─────────────────────────────────────────────
                _buildSectionCard(
                  title: "About",
                  icon: Icons.info_outline_rounded,
                  children: [
                    _buildActionTile("Kausap AI", "Version 1.0.0", Icons.auto_awesome_rounded),
                    const Divider(height: 1, color: Color(0xFFE8EAED)),
                    _buildActionTile("Privacy Policy", "Read how we handle your data", Icons.privacy_tip_outlined, onTap: () {}),
                    const Divider(height: 1, color: Color(0xFFE8EAED)),
                    _buildActionTile("Terms of Service", "Read our terms", Icons.article_outlined, onTap: () {}),
                  ],
                ),

                const SizedBox(height: 32),

                // ── Logout ────────────────────────────────────────────────────
                OutlinedButton.icon(
                  onPressed: () => _confirmLogout(context),
                  icon: const Icon(Icons.logout_rounded, color: Color(0xFFFF5858)),
                  label: const Text("Logout", style: TextStyle(color: Color(0xFFFF5858), fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    side: const BorderSide(color: Color(0xFFFF5858)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(String firstName, String lastName, String email) {
    final initials = (firstName.isNotEmpty ? firstName[0] : '') + (lastName.isNotEmpty ? lastName[0] : '');
    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: AppColors.primary,
          child: Text(
            initials.toUpperCase(),
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("$firstName $lastName".trim(),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF3D405B))),
            const SizedBox(height: 4),
            Text(email, style: const TextStyle(fontSize: 13, color: Color(0xFF707974))),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFEBF7DC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text("Verified Professional",
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4E6D36))),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField(String label, String initialValue, {bool enabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF3D405B))),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: initialValue,
          enabled: enabled,
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled ? Colors.white : const Color(0xFFF8F9FF),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE8EAED))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE8EAED))),
            disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE8EAED))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
          ),
          style: const TextStyle(fontSize: 14, color: Color(0xFF3D405B)),
        ),
      ],
    );
  }

  Widget _buildToggleItem(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF3D405B))),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF707974))),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(String title, String subtitle, IconData icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: const Color(0xFFF0F5FF), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF3D405B))),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF707974))),
                ],
              ),
            ),
            if (onTap != null) const Icon(Icons.chevron_right_rounded, color: Color(0xFFC0C9C2)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EAED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(title, style: AppTextStyles.heading2.copyWith(fontSize: 15, color: const Color(0xFF3D405B))),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  void _showChangePasswordSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Change Password", style: AppTextStyles.heading2),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                ],
              ),
              const SizedBox(height: 20),
              _buildTextField("Current Password", ""),
              const SizedBox(height: 16),
              _buildTextField("New Password", ""),
              const SizedBox(height: 16),
              _buildTextField("Confirm New Password", ""),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: const Text("Update Password"),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Logout", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                  (_) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5858)),
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }
}
