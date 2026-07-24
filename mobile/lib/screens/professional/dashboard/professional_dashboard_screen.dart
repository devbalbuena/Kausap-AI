import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../services/api_client.dart';
import '../../chat/direct_message_screen.dart';

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

  final ApiClient _apiClient = ApiClient();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    _dashboardDataFuture = _apiClient
        .get('/professional/dashboard')
        .then((json) => DashboardData.fromJson(json as Map<String, dynamic>));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.spa_rounded, color: Colors.white),
      ),
      body: FutureBuilder<DashboardData>(
        future: _dashboardDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          
          final data = snapshot.data;
          if (data == null) return const Center(child: Text("No data"));

          return LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 800;
              
              return CustomScrollView(
                slivers: [
                  _buildHeader(isMobile),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    sliver: isMobile 
                      ? _buildMobileLayout(data)
                      : _buildDesktopLayout(data),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, isMobile ? 60 : 32, 24, 24),
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
                          child: IconButton(
                            icon: const Icon(Icons.search_rounded),
                            onPressed: () => setState(() => _isSearchExpanded = true),
                          ),
                        )
                  )
                else
                  Expanded(
                    child: _buildSearchBar(),
                  ),
                const SizedBox(width: 16),
                const Icon(Icons.notifications_none_rounded, color: Color(0xFF3D405B)),
                const SizedBox(width: 16),
                const CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              "Good Morning, Dr. Jin",
              style: AppTextStyles.heading1.copyWith(
                fontSize: 28,
                letterSpacing: -0.64,
                color: const Color(0xFF3D405B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Here is your summary for today.",
              style: AppTextStyles.body.copyWith(
                color: const Color(0xFF707974),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F2FB),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: Color(0xFFC0C9C2), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Search clients, appointments...",
                hintStyle: TextStyle(
                  color: Color(0xFFC0C9C2),
                  fontFamily: 'Urbanist',
                  fontSize: 14,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
              onSubmitted: (_) {
                if (MediaQuery.of(context).size.width < 800) {
                  setState(() => _isSearchExpanded = false);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(DashboardData data) {
    return SliverList(
      delegate: SliverChildListDelegate([
        _buildTriageCard(data.alerts),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildStatCard("Active Patients", data.stats['active_patients'].toString(), Icons.people_alt_rounded, "↑3 vs last month")),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard("Pending Requests", data.stats['pending_requests'].toString(), Icons.calendar_today_rounded, null)),
          ],
        ),
        const SizedBox(height: 24),
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
              flex: 2,
              child: _buildTriageCard(data.alerts),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  _buildStatCard("Active Patients", data.stats['active_patients'].toString(), Icons.people_alt_rounded, "↑3 vs last month"),
                  const SizedBox(height: 24),
                  _buildStatCard("Pending Requests", data.stats['pending_requests'].toString(), Icons.calendar_today_rounded, null),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildScheduleSection(data.schedule),
      ]),
    );
  }

  Widget _buildTriageCard(List<dynamic> alerts) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EAED)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFF3D405B), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "Triage & Alerts",
                    style: AppTextStyles.heading2.copyWith(fontSize: 16, color: const Color(0xFF3D405B)),
                  ),
                ],
              ),
              if (alerts.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE5E5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    "${alerts.length} ACTION NEEDED",
                    style: const TextStyle(
                      color: Color(0xFFFF5858),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          if (alerts.isEmpty)
            const Text("No pending alerts.")
          else
            ...alerts.map((a) => _buildAlertItem(a)),
        ],
      ),
    );
  }

  Widget _buildAlertItem(dynamic alert) {
    // Determine background color based on alert type (Red for High Crisis, Blue for Missed Check-in, etc.)
    bool isHighCrisis = alert['flag_type']?.toString().toLowerCase().contains('crisis') ?? false;
    Color bgColor = isHighCrisis ? const Color(0xFFFFF5F5) : const Color(0xFFF0F5FF);
    Color dotColor = isHighCrisis ? const Color(0xFFFF5858) : AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "${alert['client_name']} - ${alert['flag_type']}",
                  style: const TextStyle(
                    fontFamily: 'Urbanist',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF3D405B),
                  ),
                ),
              ),
              Text(
                alert['time_ago'] ?? "",
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF707974),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Text(
              alert['description'] ?? "",
              style: const TextStyle(
                fontFamily: 'Urbanist',
                fontSize: 12,
                color: Color(0xFF3D405B),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Row(
              children: [
                Text(
                  "Review Entry",
                  style: TextStyle(
                    color: dotColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
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
                  child: const Text(
                    "Message Client",
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
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

  Widget _buildStatCard(String title, String value, IconData icon, String? subtext) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EAED)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F2FB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF707974),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          if (subtext != null) ...[
            const SizedBox(height: 8),
            Text(
              subtext,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.primary,
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            const Text(
              "Review Schedule",
              style: TextStyle(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildScheduleSection(List<dynamic> schedule) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EAED)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, color: Color(0xFF3D405B), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "Today's Schedule",
                    style: AppTextStyles.heading2.copyWith(fontSize: 16, color: const Color(0xFF3D405B)),
                  ),
                ],
              ),
              const Text(
                "View All",
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (schedule.isEmpty)
            const Text("No appointments today.")
          else
            ...schedule.map((s) => _buildScheduleItem(s)),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(dynamic item) {
    bool isVirtual = item['mode'] == 'Virtual';
    String initials = item['client_name'].toString().split(' ').map((e) => e[0]).take(2).join();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FF), // light grey background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EAED)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              item['time'] ?? "",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF707974),
                fontSize: 14,
              ),
            ),
          ),
          CircleAvatar(
            backgroundColor: const Color(0xFFD6F1FC),
            child: Text(
              initials,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['client_name'] ?? "",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3D405B),
                    fontSize: 14,
                  ),
                ),
                Text(
                  item['type'] ?? "",
                  style: const TextStyle(
                    color: Color(0xFF707974),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (MediaQuery.of(context).size.width > 600)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isVirtual ? const Color(0xFFEBF7DC) : const Color(0xFFF0F5FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(isVirtual ? Icons.videocam_rounded : Icons.location_on_rounded, size: 14, color: isVirtual ? const Color(0xFF4E6D36) : AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    isVirtual ? "Virtual" : "In-Person",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isVirtual ? const Color(0xFF4E6D36) : AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: isVirtual ? AppColors.primary : const Color(0xFFD6F1FC),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: Size.zero,
            ),
            child: Text(
              isVirtual ? "Join" : "Details",
              style: TextStyle(
                color: isVirtual ? Colors.white : AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
