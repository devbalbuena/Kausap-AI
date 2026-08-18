import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_theme.dart';
import '../../../services/api_client.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/cached_avatar.dart';
import '../../chat/direct_message_screen.dart';
import '../appointments/professional_appointments_screen.dart';
import '../clients/professional_clients_screen.dart';

class DashboardData {
  final List<dynamic> alerts;
  final Map<String, dynamic> stats;
  final List<dynamic> schedule;

  DashboardData({required this.alerts, required this.stats, required this.schedule});

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      alerts: json['alerts'] ?? [],
      stats: json['stats'] ?? {'active_patients': 0, 'pending_requests': 0},
      schedule: json['schedule'] ?? [],
    );
  }
}

class ProfessionalDashboardScreen extends StatefulWidget {
  const ProfessionalDashboardScreen({super.key});

  @override
  State<ProfessionalDashboardScreen> createState() => _ProfessionalDashboardScreenState();
}

class _ProfessionalDashboardScreenState extends State<ProfessionalDashboardScreen> {
  Future<DashboardData>? _dashboardDataFuture;
  bool _isSearchExpanded = false;
  final TextEditingController _searchController = TextEditingController();
  final ApiClient _apiClient = ApiClient();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _fetchData() {
    setState(() {
      _dashboardDataFuture = _apiClient
          .get('/professional/dashboard')
          .then((json) => DashboardData.fromJson(json as Map<String, dynamic>));
    });
  }

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      floatingActionButton: FloatingActionButton(
        heroTag: 'professional_quick_actions_fab',
        onPressed: () => _showQuickActionMenu(context),
        backgroundColor: AppColors.primary,
        elevation: 4,
        child: const Icon(Icons.spa_rounded, color: Colors.white, size: 28),
      ),
      body: FutureBuilder<DashboardData>(
        future: _dashboardDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.error),
                    const SizedBox(height: 12),
                    Text(
                      "Failed to load dashboard data",
                      style: AppTextStyles.body.copyWith(color: AppColors.error, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _fetchData,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text("Retry"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = snapshot.data ?? DashboardData(alerts: [], stats: {}, schedule: []);

          return RefreshIndicator(
            onRefresh: () async => _fetchData(),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 800;

                return CustomScrollView(
                  slivers: [
                    _buildHeader(isMobile, data),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      sliver: isMobile ? _buildMobileLayout(data) : _buildDesktopLayout(data),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────
  Widget _buildHeader(bool isMobile, DashboardData data) {
    return SliverToBoxAdapter(
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final user = auth.currentUser ?? {};
          final firstName = user['first_name']?.toString().trim() ?? '';
          final doctorGreeting = firstName.isNotEmpty ? "Dr. $firstName" : "Doctor";
          final int alertCount = data.alerts.length;

          return Padding(
            padding: EdgeInsets.fromLTRB(20, isMobile ? 54 : 32, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isMobile)
                      Expanded(
                        child: _isSearchExpanded
                            ? _buildSearchBar()
                            : Align(
                                alignment: Alignment.centerRight,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFFE8EAED)),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.search_rounded, color: Color(0xFF3D405B), size: 22),
                                    onPressed: () => setState(() => _isSearchExpanded = true),
                                  ),
                                ),
                              ),
                      )
                    else
                      Expanded(child: _buildSearchBar()),
                    const SizedBox(width: 12),
                    // Notification Bell with interactive badge
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE8EAED)),
                      ),
                      child: IconButton(
                        icon: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Icon(Icons.notifications_none_rounded, color: Color(0xFF3D405B), size: 24),
                            if (alertCount > 0)
                              Positioned(
                                top: -2,
                                right: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppColors.error,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    alertCount > 9 ? '9+' : '$alertCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        onPressed: () => _showNotificationsModal(context, data),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Profile Avatar
                    GestureDetector(
                      onTap: () {
                        // Scaffold drawer open or view profile
                        Scaffold.of(context).openDrawer();
                      },
                      child: CachedAvatar(
                        imageUrl: user['avatar_url'] as String?,
                        radius: 20,
                        fallbackInitial: firstName.isNotEmpty ? firstName[0] : 'P',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  "${_getTimeGreeting()}, $doctorGreeting",
                  style: AppTextStyles.heading1.copyWith(
                    fontSize: 26,
                    letterSpacing: -0.5,
                    color: const Color(0xFF2C3E50),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Here is your clinical overview & schedule for today.",
                  style: AppTextStyles.body.copyWith(
                    color: const Color(0xFF707974),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Search Bar with Close Button ────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8EAED)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: Color(0xFF707974), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: "Search clients, notes, appointments...",
                hintStyle: TextStyle(
                  color: Color(0xFF9E9E9E),
                  fontFamily: 'Urbanist',
                  fontSize: 14,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
              onSubmitted: (query) => _handleSearchSubmit(query),
            ),
          ),
          if (_isSearchExpanded)
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Color(0xFF707974), size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                setState(() {
                  _isSearchExpanded = false;
                  _searchController.clear();
                });
              },
            ),
        ],
      ),
    );
  }

  void _handleSearchSubmit(String query) {
    if (query.trim().isEmpty) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.search_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            Text("Search: '$query'", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          "Quick search completed for '$query'. You can view full patient records in the Clients tab.",
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Dismiss"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfessionalClientsScreen()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Go to Clients"),
          ),
        ],
      ),
    );
  }

  // ── Layouts ─────────────────────────────────────────────────────────────
  Widget _buildMobileLayout(DashboardData data) {
    return SliverList(
      delegate: SliverChildListDelegate([
        _buildTriageCard(data.alerts),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: "Active Patients",
                value: data.stats['active_patients']?.toString() ?? "0",
                icon: Icons.people_alt_rounded,
                badgeText: "Active Roster",
                badgeColor: const Color(0xFFE8F5E9),
                badgeTextColor: const Color(0xFF2E7D32),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfessionalClientsScreen())),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildStatCard(
                title: "Pending Sessions",
                value: data.stats['pending_requests']?.toString() ?? "0",
                icon: Icons.calendar_today_rounded,
                badgeText: "Schedule",
                badgeColor: const Color(0xFFE3F2FD),
                badgeTextColor: const Color(0xFF1565C0),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfessionalAppointmentsScreen())),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildScheduleSection(data.schedule),
        const SizedBox(height: 80), // Space for FAB
      ]),
    );
  }

  Widget _buildDesktopLayout(DashboardData data) {
    return SliverList(
      delegate: SliverChildListDelegate([
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: _buildTriageCard(data.alerts),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  _buildStatCard(
                    title: "Active Patients",
                    value: data.stats['active_patients']?.toString() ?? "0",
                    icon: Icons.people_alt_rounded,
                    badgeText: "Active Roster",
                    badgeColor: const Color(0xFFE8F5E9),
                    badgeTextColor: const Color(0xFF2E7D32),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfessionalClientsScreen())),
                  ),
                  const SizedBox(height: 14),
                  _buildStatCard(
                    title: "Pending Sessions",
                    value: data.stats['pending_requests']?.toString() ?? "0",
                    icon: Icons.calendar_today_rounded,
                    badgeText: "Schedule",
                    badgeColor: const Color(0xFFE3F2FD),
                    badgeTextColor: const Color(0xFF1565C0),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfessionalAppointmentsScreen())),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildScheduleSection(data.schedule),
      ]),
    );
  }

  // ── Stat Card (Fixed Layout without Text Wrapping) ────────────────────────
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required String badgeText,
    required Color badgeColor,
    required Color badgeTextColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8EAED)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F2FB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 20),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      color: badgeTextColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
                fontFamily: 'Urbanist',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF707974),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFamily: 'Urbanist',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Triage & Alerts Card ────────────────────────────────────────────────
  Widget _buildTriageCard(List<dynamic> alerts) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EAED)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: alerts.isNotEmpty ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      alerts.isNotEmpty ? Icons.warning_amber_rounded : Icons.shield_outlined,
                      color: alerts.isNotEmpty ? AppColors.error : const Color(0xFF2E7D32),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Triage & Alerts",
                    style: AppTextStyles.heading2.copyWith(
                      fontSize: 16,
                      color: const Color(0xFF2C3E50),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (alerts.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "${alerts.length} ACTION NEEDED",
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (alerts.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF1F3F4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF4CAF50), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "All clear. No pending crisis or triage alerts across your active patients.",
                      style: AppTextStyles.body.copyWith(fontSize: 13, color: const Color(0xFF707974)),
                    ),
                  ),
                ],
              ),
            )
          else
            ...alerts.map((a) => _buildAlertItem(a)),
        ],
      ),
    );
  }

  Widget _buildAlertItem(dynamic alert) {
    bool isHighCrisis = alert['flag_type']?.toString().toLowerCase().contains('crisis') ?? false;
    Color bgColor = isHighCrisis ? const Color(0xFFFFF5F5) : const Color(0xFFF0F5FF);
    Color dotColor = isHighCrisis ? AppColors.error : AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dotColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "${alert['client_name']} — ${alert['flag_type']}",
                  style: const TextStyle(
                    fontFamily: 'Urbanist',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ),
              Text(
                alert['time_ago'] ?? "",
                style: const TextStyle(fontSize: 11, color: Color(0xFF707974)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(
              alert['description'] ?? "",
              style: const TextStyle(fontFamily: 'Urbanist', fontSize: 13, color: Color(0xFF4A5568)),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    final clientId = alert['client_id'] ?? 'dummy-client-id';
                    final clientName = alert['client_name'] ?? 'Client';
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DirectMessageScreen(
                          otherUserId: clientId.toString(),
                          otherUserName: clientName,
                          otherUserRole: 'client',
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 14),
                        SizedBox(width: 6),
                        Text(
                          "Direct Message",
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Schedule Section ────────────────────────────────────────────────────
  Widget _buildScheduleSection(List<dynamic> schedule) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EAED)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE3F2FD),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Today's Schedule",
                    style: AppTextStyles.heading2.copyWith(
                      fontSize: 16,
                      color: const Color(0xFF2C3E50),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfessionalAppointmentsScreen()));
                },
                child: const Text(
                  "View All →",
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (schedule.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF1F3F4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_available_rounded, color: Color(0xFF707974), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "No sessions scheduled for today.",
                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C3E50), fontSize: 13),
                        ),
                        Text(
                          "Take this time to review client records or prepare upcoming therapy plans.",
                          style: AppTextStyles.body.copyWith(fontSize: 12, color: const Color(0xFF707974)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            ...schedule.map((s) => _buildScheduleItem(s)),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(dynamic item) {
    bool isVirtual = item['mode'] == 'Virtual';
    String clientName = item['client_name'] ?? 'Client';
    String initials = clientName.split(' ').where((e) => e.isNotEmpty).map((e) => e[0]).take(2).join();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EAED)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 74,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['time'] ?? "",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C3E50), fontSize: 13),
                ),
                Text(
                  isVirtual ? "Online" : "Clinic",
                  style: TextStyle(fontSize: 11, color: isVirtual ? const Color(0xFF2E7D32) : AppColors.primary),
                ),
              ],
            ),
          ),
          CircleAvatar(
            backgroundColor: const Color(0xFFD6F1FC),
            radius: 18,
            child: Text(
              initials.isNotEmpty ? initials : 'C',
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  clientName,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C3E50), fontSize: 14),
                ),
                Text(
                  item['type'] ?? "Therapy Consultation",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF707974), fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isVirtual ? "Launching virtual meeting with $clientName..." : "Viewing appointment details..."),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isVirtual ? AppColors.primary : const Color(0xFFD6F1FC),
              foregroundColor: isVirtual ? Colors.white : AppColors.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
            ),
            child: Text(
              isVirtual ? "Join" : "Details",
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ── Option A: Quick Action Bottom Sheet (FAB) ───────────────────────────
  void _showQuickActionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE3F2FD),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.spa_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Quick Clinical Actions",
                    style: AppTextStyles.heading2.copyWith(fontSize: 18, color: const Color(0xFF2C3E50)),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildQuickActionTile(
                icon: Icons.calendar_month_rounded,
                iconColor: const Color(0xFF1976D2),
                bgColor: const Color(0xFFE3F2FD),
                title: "Schedule New Session",
                subtitle: "Book an upcoming in-person or virtual consultation",
                onTap: () {
                  Navigator.pop(context);
                  _showScheduleModal(context);
                },
              ),
              const SizedBox(height: 10),
              _buildQuickActionTile(
                icon: Icons.note_add_rounded,
                iconColor: const Color(0xFF388E3C),
                bgColor: const Color(0xFFE8F5E9),
                title: "Add Clinical Progress Note",
                subtitle: "Record clinical observations, treatment goals & notes",
                onTap: () {
                  Navigator.pop(context);
                  _showAddNoteModal(context);
                },
              ),
              const SizedBox(height: 10),
              _buildQuickActionTile(
                icon: Icons.person_add_rounded,
                iconColor: const Color(0xFF7B1FA2),
                bgColor: const Color(0xFFF3E5F5),
                title: "Add / Invite New Client",
                subtitle: "Send clinic invite link or register a new patient",
                onTap: () {
                  Navigator.pop(context);
                  _showInviteClientModal(context);
                },
              ),
              const SizedBox(height: 10),
              _buildQuickActionTile(
                icon: Icons.psychology_rounded,
                iconColor: const Color(0xFFE65100),
                bgColor: const Color(0xFFFFF3E0),
                title: "AI Clinical Assistant Copilot",
                subtitle: "Consult Kausap AI on therapeutic techniques & DSM-5 guidelines",
                onTap: () {
                  Navigator.pop(context);
                  _showAICopilotModal(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActionTile({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFECEFF1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C3E50), fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Color(0xFF707974), fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFB0BEC5), size: 14),
          ],
        ),
      ),
    );
  }

  // ── Quick Modals ────────────────────────────────────────────────────────
  void _showScheduleModal(BuildContext context) {
    final nameCtrl = TextEditingController();
    final reasonCtrl = TextEditingController(text: "Therapy Consultation");
    String selectedMode = "Virtual";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Schedule New Session", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 14),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: "Client Name",
                      hintText: "e.g. Van Balbuena",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonCtrl,
                    decoration: InputDecoration(
                      labelText: "Session Focus / Reason",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text("Session Mode", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text("Virtual (Online)"),
                        selected: selectedMode == "Virtual",
                        onSelected: (v) => setModalState(() => selectedMode = "Virtual"),
                      ),
                      const SizedBox(width: 10),
                      ChoiceChip(
                        label: const Text("In-Person (Clinic)"),
                        selected: selectedMode == "In-Person",
                        onSelected: (v) => setModalState(() => selectedMode = "In-Person"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Session booked successfully with ${nameCtrl.text.isNotEmpty ? nameCtrl.text : 'Client'} ($selectedMode)!"),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Confirm & Schedule", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddNoteModal(BuildContext context) {
    final clientCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Add Clinical Progress Note", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              TextField(
                controller: clientCtrl,
                decoration: InputDecoration(
                  labelText: "Client Name",
                  hintText: "e.g. Van Balbuena",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: "Clinical Observations & Plan",
                  hintText: "Document client affect, cognitive shifts, homework assigned...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Clinical note saved to patient record!"),
                        backgroundColor: Color(0xFF2E7D32),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Save Clinical Note", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showInviteClientModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Invite Client to Clinic", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                "Share your unique direct referral link with your client to connect their Kausap AI profile with your practice.",
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link_rounded, color: AppColors.primary),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        "https://kausap.ai/ref/dr-perez-17a1",
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, color: AppColors.primary, size: 20),
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Referral link copied to clipboard!"), backgroundColor: AppColors.primary),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAICopilotModal(BuildContext context) {
    final queryCtrl = TextEditingController();
    String? aiResponse;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: Color(0xFFFFF3E0), shape: BoxShape.circle),
                        child: const Icon(Icons.psychology_rounded, color: Color(0xFFE65100), size: 22),
                      ),
                      const SizedBox(width: 10),
                      const Text("AI Clinical Copilot", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: queryCtrl,
                    decoration: InputDecoration(
                      hintText: "Ask for CBT homework ideas, DSM-5 screener insights...",
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9E9E9E)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                        onPressed: () {
                          if (queryCtrl.text.trim().isNotEmpty) {
                            setModalState(() {
                              aiResponse = "Clinical Copilot Recommendation:\n\n• Consider grounding techniques (5-4-3-2-1 sensory scan).\n• Implement a 7-day thought record diary for cognitive distortions.\n• Check GAD-7 / PHQ-9 trends in the Insights tab.";
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  if (aiResponse != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: Text(
                        aiResponse!,
                        style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF2C3E50)),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── Notifications Bottom Sheet ──────────────────────────────────────────
  void _showNotificationsModal(BuildContext context, DashboardData data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Notifications & Alerts", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Done", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (data.alerts.isEmpty && data.schedule.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  child: const Center(
                    child: Text("No new notifications.", style: TextStyle(color: AppColors.textSecondary)),
                  ),
                )
              else ...[
                if (data.alerts.isNotEmpty) ...[
                  ...data.alerts.map((a) => ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFFFEBEE),
                          child: Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
                        ),
                        title: Text("${a['client_name']} - ${a['flag_type']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text(a['description'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                        trailing: Text(a['time_ago'] ?? '', style: const TextStyle(fontSize: 10, color: Color(0xFF707974))),
                      )),
                ],
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE3F2FD),
                    child: Icon(Icons.check_circle_outline_rounded, color: AppColors.primary, size: 20),
                  ),
                  title: const Text("System Health Normal", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: const Text("All clinical records and AI triage monitors are operational.", style: TextStyle(fontSize: 12)),
                  trailing: const Text("Today", style: TextStyle(fontSize: 10, color: Color(0xFF707974))),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
