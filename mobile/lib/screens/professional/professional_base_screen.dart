import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../auth/role_selection_screen.dart';
import 'dashboard/professional_dashboard_screen.dart';

class ProfessionalBaseScreen extends StatefulWidget {
  const ProfessionalBaseScreen({super.key});

  @override
  State<ProfessionalBaseScreen> createState() => _ProfessionalBaseScreenState();
}

class _ProfessionalBaseScreenState extends State<ProfessionalBaseScreen> {
  int _navIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Widget> _screens = [
    const ProfessionalDashboardScreen(),
    const Center(child: Text("Clients Screen (Coming Soon)")),
    const Center(child: Text("AI Insights Screen (Coming Soon)")),
    const Center(child: Text("Appointments Screen (Coming Soon)")),
    const Center(child: Text("Activity Screen (Coming Soon)")),
    const Center(child: Text("Reports Screen (Coming Soon)")),
    const Center(child: Text("Settings Screen (Coming Soon)")),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: const Color(0xFFF8F9FF),
          drawer: isMobile ? _buildDrawer() : null,
          body: Row(
            children: [
              if (!isMobile) _buildSidebar(),
              Expanded(
                child: _screens[_navIndex],
              ),
            ],
          ),
          bottomNavigationBar: isMobile ? _buildBottomNav() : null,
        );
      },
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 60),
          _buildNavItem(0, "Dashboard", Icons.grid_view_rounded),
          _buildNavItem(1, "Clients", Icons.people_alt_rounded),
          _buildNavItem(2, "AI Insights", Icons.psychology_rounded),
          _buildNavItem(3, "Appointments", Icons.calendar_today_rounded),
          _buildNavItem(4, "Activity", Icons.fitness_center_rounded),
          _buildNavItem(5, "Reports", Icons.bar_chart_rounded),
          _buildNavItem(6, "Settings", Icons.settings_rounded),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.red),
            title: const Text("Logout", style: TextStyle(color: Colors.red)),
            onTap: () {
              context.read<AuthProvider>().logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                (route) => false,
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

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
          _buildNavItem(0, "Dashboard", Icons.grid_view_rounded),
          _buildNavItem(1, "Clients", Icons.people_alt_rounded),
          _buildNavItem(2, "AI Insights", Icons.psychology_rounded),
          _buildNavItem(3, "Appointments", Icons.calendar_today_rounded),
          _buildNavItem(4, "Activity", Icons.fitness_center_rounded),
          _buildNavItem(5, "Reports", Icons.bar_chart_rounded),
          _buildNavItem(6, "Settings", Icons.settings_rounded),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(24),
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add_rounded, size: 18, color: AppColors.primary),
              label: const Text(
                'New Appointment',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD6F1FC),
                elevation: 0,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String title, IconData icon) {
    final isSelected = _navIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _navIndex = index;
        });
        if (MediaQuery.of(context).size.width < 800) {
          Navigator.pop(context); // Close drawer if open
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD6F1FC) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.primary : const Color(0xFF707974),
            ),
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

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _navIndex > 3 ? 0 : _navIndex,
      onTap: (i) {
        if (i == 4) {
          _scaffoldKey.currentState?.openDrawer();
        } else {
          setState(() => _navIndex = i);
        }
      },
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: const Color(0xFF707974),
      showUnselectedLabels: true,
      selectedLabelStyle: const TextStyle(fontFamily: 'Urbanist', fontSize: 10, fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(fontFamily: 'Urbanist', fontSize: 10, fontWeight: FontWeight.w500),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: 'Clients'),
        BottomNavigationBarItem(icon: Icon(Icons.psychology_rounded), label: 'Insights'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today_rounded), label: 'Sessions'),
        BottomNavigationBarItem(icon: Icon(Icons.menu_rounded), label: 'More'),
      ],
    );
  }
}
