import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../auth/role_selection_screen.dart';
import 'dashboard/professional_dashboard_screen.dart';
import 'clients/professional_clients_screen.dart';
import 'ai_insights/professional_ai_insights_screen.dart';
import 'appointments/professional_appointments_screen.dart';
import 'reports/professional_reports_screen.dart';
import 'settings/professional_settings_screen.dart';
import 'activity/professional_activity_screen.dart';
import 'profile/professional_profile_screen.dart';

class ProfessionalBaseScreen extends StatefulWidget {
  const ProfessionalBaseScreen({super.key});

  @override
  State<ProfessionalBaseScreen> createState() => _ProfessionalBaseScreenState();
}

class _ProfessionalBaseScreenState extends State<ProfessionalBaseScreen> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;

        final List<Widget> screens = [
          const ProfessionalDashboardScreen(),
          const ProfessionalClientsScreen(),
          const ProfessionalAIInsightsScreen(),
          const ProfessionalAppointmentsScreen(),
          _buildMoreHubScreen(context),
        ];

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FF),
          body: Row(
            children: [
              if (!isMobile) _buildSidebar(),
              Expanded(
                child: screens[_navIndex],
              ),
            ],
          ),
          bottomNavigationBar: isMobile ? _buildBottomNav() : null,
        );
      },
    );
  }

  // ─── Desktop Sidebar ────────────────────────────────────────────────────────
  Widget _buildSidebar() {
    return Container(
      width: 240,
      color: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const Icon(Icons.spa_rounded, color: AppColors.primary, size: 28),
                const SizedBox(width: 8),
                Text(
                  "Kausap AI",
                  style: AppTextStyles.heading1.copyWith(
                    color: AppColors.primary,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          _buildSidebarNavItem(0, "Dashboard", Icons.grid_view_rounded),
          _buildSidebarNavItem(1, "Clients", Icons.people_alt_rounded),
          _buildSidebarNavItem(2, "AI Insights", Icons.psychology_rounded),
          _buildSidebarNavItem(3, "Appointments", Icons.calendar_today_rounded),
          _buildSidebarNavItem(4, "Practice Hub", Icons.medical_services_outlined),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.red),
            title: const Text("Logout", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: () => _confirmLogout(context),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSidebarNavItem(int index, String title, IconData icon) {
    final isSelected = _navIndex == index;
    return InkWell(
      onTap: () => setState(() => _navIndex = index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD6F1FC) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isSelected ? AppColors.primary : const Color(0xFF707974)),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Urbanist',
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.primary : const Color(0xFF707974),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Mobile Bottom Navigation ───────────────────────────────────────────────
  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _navIndex,
      onTap: (i) => setState(() => _navIndex = i),
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: const Color(0xFF707974),
      showUnselectedLabels: true,
      selectedLabelStyle: const TextStyle(fontFamily: 'Urbanist', fontSize: 11, fontWeight: FontWeight.bold),
      unselectedLabelStyle: const TextStyle(fontFamily: 'Urbanist', fontSize: 11, fontWeight: FontWeight.w500),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: 'Clients'),
        BottomNavigationBarItem(icon: Icon(Icons.psychology_rounded), label: 'Insights'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today_rounded), label: 'Sessions'),
        BottomNavigationBarItem(icon: Icon(Icons.medical_services_outlined), label: 'Practice'),
      ],
    );
  }

  // ─── Dedicated Practice Hub / More Screen ───────────────────────────────────
  Widget _buildMoreHubScreen(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final firstName = user?['first_name'] ?? 'Mark';
    final lastName = user?['last_name'] ?? 'Perez';
    final email = user?['email'] ?? 'shocktandora04@gmail.com';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 54, 20, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Practice Hub & Profile",
            style: AppTextStyles.heading1.copyWith(
              fontSize: 26,
              letterSpacing: -0.5,
              color: const Color(0xFF2C3E50),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Manage credentials, clinical activity audit logs, reports & clinic settings.",
            style: AppTextStyles.body.copyWith(color: const Color(0xFF707974), fontSize: 13),
          ),
          const SizedBox(height: 18),

          // ── Doctor Profile Card ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8EAED)),
              boxShadow: const [
                BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 3)),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: const Color(0xFFD6F1FC),
                      child: Text(
                        firstName.isNotEmpty ? firstName[0] : 'D',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Dr. $firstName $lastName", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2C3E50))),
                          const SizedBox(height: 2),
                          Text(email, style: const TextStyle(fontSize: 12, color: Color(0xFF707974))),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
                            child: const Text("Verified Specialist (RA 11036)", style: TextStyle(color: Color(0xFF2E7D32), fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFF1F3F4)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfessionalProfileScreen()),
                      );
                    },
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text("Edit Doctor Profile & Credentials"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: Color(0xFFD6F1FC)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Clinical Tools & Audit ───────────────────────────────────────
          const Text("Clinical Management", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2C3E50))),
          const SizedBox(height: 10),
          _buildHubTile(
            context,
            icon: Icons.history_edu_rounded,
            iconColor: const Color(0xFF0077B6),
            iconBg: const Color(0xFFE3F2FD),
            title: "Clinical Activity & Audit Trail",
            subtitle: "Review chronological logs of screeners, sessions, and crisis events.",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfessionalActivityScreen()),
              );
            },
          ),
          const SizedBox(height: 10),
          _buildHubTile(
            context,
            icon: Icons.bar_chart_rounded,
            iconColor: const Color(0xFF2E7D32),
            iconBg: const Color(0xFFE8F5E9),
            title: "Outcome Analytics & Reports",
            subtitle: "Mental Health Act (RA 11036) compliance & patient progress metrics.",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfessionalReportsScreen()),
              );
            },
          ),
          const SizedBox(height: 20),

          // ── Settings & Preferences ───────────────────────────────────────
          const Text("Preferences & Security", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2C3E50))),
          const SizedBox(height: 10),
          _buildHubTile(
            context,
            icon: Icons.settings_outlined,
            iconColor: const Color(0xFF555F6D),
            iconBg: const Color(0xFFF1F5F9),
            title: "Clinic & Notification Settings",
            subtitle: "Manage emergency alert SMS, reminders & telehealth preferences.",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfessionalSettingsScreen()),
              );
            },
          ),
          const SizedBox(height: 20),

          // ── Logout ───────────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _confirmLogout(context),
              icon: const Icon(Icons.logout_rounded, color: Color(0xFFC62828)),
              label: const Text("Logout", style: TextStyle(color: Color(0xFFC62828), fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFFCDD2)),
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHubTile(
    BuildContext context, {
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EAED)),
        boxShadow: const [
          BoxShadow(color: Color(0x04000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2C3E50))),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF707974))),
        trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF9E9E9E)),
        onTap: onTap,
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to sign out of your professional account?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthProvider>().logout();
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
}
