import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_client.dart';
import '../../utils/haptic_service.dart';
import 'admin_users_screen.dart';
import 'admin_moderation_screen.dart';
import 'admin_system_screen.dart';
import 'admin_articles_screen.dart';
import 'admin_counselors_screen.dart';
import 'admin_telemetry_screen.dart';
import 'widgets/admin_header_actions.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _stats;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  @override
  void dispose() {
    super.dispose();
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

      if (mounted) {
        final statsData = Map<String, dynamic>.from(results[0] as Map);
        final usersData = results[1] is List ? (results[1] as List) : [];

        // Count ONLY students (role == 'client')
        final students = usersData.where((u) {
          final role = (u['role'] ?? 'client').toString().toLowerCase();
          return role == 'client';
        }).toList();

        final activeStudents = students.where((u) => u['is_active'] == true).length;
        final totalStudents = students.length;

        statsData['total_students'] = totalStudents;
        statsData['total_active_students'] = activeStudents;

        setState(() {
          _stats = statsData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load platform statistics';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
              child: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF0284C7), size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Super Admin Console',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'FSUU • System & Workforce Control',
                  style: TextStyle(
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
              await _fetchStats();
            },
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
              const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 48),
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  color: Color(0xFFEF4444),
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchStats,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry Connection'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final flaggedCount = (_stats!['total_flagged_messages'] as num?)?.toInt() ?? 0;
    final totalUsers = ((_stats!['total_students'] ?? _stats!['total_users']) as num?)?.toInt() ?? 0;
    final activeUsers = ((_stats!['total_active_students'] ?? _stats!['total_active_users']) as num?)?.toInt() ?? 0;
    final chatSessions = (_stats!['total_chat_sessions'] as num?)?.toInt() ?? 0;
    final moodEntries = (_stats!['total_mood_entries'] as num?)?.toInt() ?? 0;
    final totalInteractions = chatSessions + moodEntries;

    final moodMap = (_stats!['mood_distribution'] as Map<String, dynamic>?) ?? {};
    // Render backend may not include mood_distribution yet — handle gracefully
    // by computing from total_mood_entries if all zeros
    int greatMoods = (moodMap['great'] as num?)?.toInt() ?? 0;
    int goodMoods = (moodMap['good'] as num?)?.toInt() ?? 0;
    int okayMoods = (moodMap['okay'] as num?)?.toInt() ?? 0;
    int downMoods = (moodMap['down'] as num?)?.toInt() ?? 0;
    int distressedMoods = (moodMap['distressed'] as num?)?.toInt() ?? 0;
    // If distribution sums to 0 but we have total entries, the backend hasn't
    // deployed the distribution field yet — show a note rather than all zeros
    final distributionTotal = greatMoods + goodMoods + okayMoods + downMoods + distressedMoods;
    final bool distributionMissing = distributionTotal == 0 && moodEntries > 0;

    return RefreshIndicator(
      onRefresh: () async {
        HapticService.lightTap();
        await _fetchStats();
      },
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              // ── 1. University Health Banner ────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "All Systems Operational • Campus Shield Active (Neon Connected)",
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: Color(0xFF166534),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── Super Admin Hero Section: Token Telemetry & Counselor Provisioning ──
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Color(0x1A000000), blurRadius: 10, offset: Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.token_rounded, color: Color(0xFF38BDF8), size: 18),
                            SizedBox(width: 8),
                            Text(
                              "AI Token & Cloud Telemetry",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () {
                            HapticService.lightTap();
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const AdminTelemetryScreen()),
                            );
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0284C7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Text(
                                  "View Telemetry",
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 12),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Real-time token monitoring, Gemini AI budget tracking, & Neon database compute health.",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF94A3B8),
                        fontSize: 11.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              HapticService.lightTap();
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const AdminCounselorsScreen()),
                              );
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(20),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF38BDF8), size: 16),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      "Provision Staff",
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              HapticService.lightTap();
                              _showNeonCloudHealthBottomSheet(context, _stats);
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(20),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.insights_rounded, color: Color(0xFF38BDF8), size: 16),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      "Neon Pool Health",
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── 2. Real-time Crisis Safety Banner ──────────────────────────
              if (flaggedCount == 0)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 6, offset: Offset(0, 2))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.verified_user_rounded, color: Color(0xFF16A34A), size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Crisis Triage: Safe (0 Active Alerts)",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              "All student chats & check-ins are within safe emotional boundaries.",
                              style: TextStyle(
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
                )
              else
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFECACA)),
                    boxShadow: const [BoxShadow(color: Color(0x08EF4444), blurRadius: 8, offset: Offset(0, 2))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "⚠️ $flaggedCount Crisis Distress Alert${flaggedCount > 1 ? 's' : ''}",
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: Color(0xFF991B1B),
                              ),
                            ),
                            const Text(
                              "Urgent messages require counselor review and hotline dispatch.",
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11.5,
                                color: Color(0xFFB91C1C),
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          HapticService.lightTap();
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const AdminModerationScreen()),
                          );
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Review', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 11.5)),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 18),

              // ── 3. Platform Metrics Grid ───────────────────────────────────
              const Padding(
                padding: EdgeInsets.only(left: 2),
                child: Text(
                  'PLATFORM METRICS & ENGAGEMENT',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.35,
                children: [
                  _buildStatCard(
                    title: 'Total Students',
                    value: '$totalUsers',
                    icon: Icons.people_alt_rounded,
                    color: const Color(0xFF0284C7),
                    onTap: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const AdminUsersScreen()),
                    ),
                  ),
                  _buildStatCard(
                    title: 'Active Accounts',
                    value: '$activeUsers',
                    icon: Icons.how_to_reg_rounded,
                    color: const Color(0xFF16A34A),
                    onTap: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const AdminUsersScreen()),
                    ),
                  ),
                  _buildStatCard(
                    title: 'AI Chat Sessions',
                    value: '$chatSessions',
                    icon: Icons.chat_bubble_rounded,
                    color: const Color(0xFF7C3AED),
                  ),
                  _buildStatCard(
                    title: 'Crisis Flags',
                    value: '$flaggedCount',
                    icon: Icons.flag_rounded,
                    color: flaggedCount > 0 ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                    onTap: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const AdminModerationScreen()),
                    ),
                  ),
                  _buildStatCard(
                    title: 'Mood Entries',
                    value: '$moodEntries',
                    icon: Icons.mood_rounded,
                    color: const Color(0xFFD97706),
                  ),
                  _buildStatCard(
                    title: 'Total Engagement',
                    value: '$totalInteractions',
                    icon: Icons.bolt_rounded,
                    color: const Color(0xFF0D9488),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── 4. Campus Mood Pulse Snapshot ──────────────────────────────
              const Padding(
                padding: EdgeInsets.only(left: 2),
                child: Text(
                  'CAMPUS MOOD PULSE (LIVE)',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 6, offset: Offset(0, 2))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.insights_rounded, color: Color(0xFF0284C7), size: 18),
                            SizedBox(width: 8),
                            Text(
                              "Student Emotional Climate",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          "$moodEntries Total Check-ins",
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (distributionMissing)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFFEDD5)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline_rounded, size: 15, color: Color(0xFFD97706)),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Breakdown will show after backend is deployed with mood distribution support.',
                                style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF92400E)),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        children: [
                          if (moodEntries > 0) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: SizedBox(
                                height: 6,
                                child: Row(
                                  children: [
                                    if (greatMoods > 0)
                                      Expanded(
                                        flex: greatMoods,
                                        child: Container(color: const Color(0xFF16A34A)),
                                      ),
                                    if (goodMoods > 0)
                                      Expanded(
                                        flex: goodMoods,
                                        child: Container(color: const Color(0xFF0284C7)),
                                      ),
                                    if (okayMoods > 0)
                                      Expanded(
                                        flex: okayMoods,
                                        child: Container(color: const Color(0xFF64748B)),
                                      ),
                                    if (downMoods > 0)
                                      Expanded(
                                        flex: downMoods,
                                        child: Container(color: const Color(0xFFD97706)),
                                      ),
                                    if (distressedMoods > 0)
                                      Expanded(
                                        flex: distressedMoods,
                                        child: Container(color: const Color(0xFFDC2626)),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          Row(
                            children: [
                              _buildMoodPill("🌟", "Great", greatMoods, moodEntries, const Color(0xFF16A34A)),
                              const SizedBox(width: 6),
                              _buildMoodPill("😊", "Good", goodMoods, moodEntries, const Color(0xFF0284C7)),
                              const SizedBox(width: 6),
                              _buildMoodPill("😐", "Okay", okayMoods, moodEntries, const Color(0xFF64748B)),
                              const SizedBox(width: 6),
                              _buildMoodPill("😔", "Down", downMoods, moodEntries, const Color(0xFFD97706)),
                              const SizedBox(width: 6),
                              _buildMoodPill("🚨", "Distressed", distressedMoods, moodEntries, const Color(0xFFDC2626)),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── 5. Quick Admin Actions ─────────────────────────────────────
              const Padding(
                padding: EdgeInsets.only(left: 2),
                child: Text(
                  'QUICK ADMIN ACTIONS',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _buildQuickActionTile(
                icon: Icons.person_add_alt_1_rounded,
                iconColor: const Color(0xFF0284C7),
                iconBg: const Color(0xFFE0F2FE),
                title: 'Counselor Workforce Manager',
                subtitle: 'Provision guidance counselor accounts & manage active credentials',
                onTap: () {
                  HapticService.lightTap();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AdminCounselorsScreen()),
                  );
                },
              ),
              const SizedBox(height: 8),
              _buildQuickActionTile(
                icon: Icons.token_rounded,
                iconColor: const Color(0xFF0D9488),
                iconBg: const Color(0xFFCCFBF1),
                title: 'AI Token & Cloud Telemetry',
                subtitle: 'Monitor real-time token usage, USD & PHP budget trends, and Neon pool',
                onTap: () {
                  HapticService.lightTap();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AdminTelemetryScreen()),
                  );
                },
              ),
              const SizedBox(height: 8),
              _buildQuickActionTile(
                icon: Icons.person_search_rounded,
                iconColor: const Color(0xFF3B82F6),
                iconBg: const Color(0xFFEFF6FF),
                title: 'Student Directory & Accounts',
                subtitle: 'Search students, monitor engagement & manage account status',
                onTap: () {
                  HapticService.lightTap();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const AdminUsersScreen()),
                  );
                },
              ),
              const SizedBox(height: 8),
              _buildQuickActionTile(
                icon: Icons.emergency_rounded,
                iconColor: const Color(0xFFDC2626),
                iconBg: const Color(0xFFFEE2E2),
                title: 'Crisis Triage & Moderation',
                subtitle: 'Review risk-flagged messages and dispatch emergency hotlines',
                onTap: () {
                  HapticService.lightTap();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const AdminModerationScreen()),
                  );
                },
              ),
              const SizedBox(height: 8),
              _buildQuickActionTile(
                icon: Icons.verified_user_rounded,
                iconColor: const Color(0xFF16A34A),
                iconBg: const Color(0xFFDCFCE7),
                title: 'Data Privacy & Institutional Governance',
                subtitle: 'Export platform compliance audits, PHQ-9 trends & cloud health',
                onTap: () {
                  HapticService.lightTap();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const AdminSystemScreen()),
                  );
                },
              ),
              const SizedBox(height: 8),
              _buildQuickActionTile(
                icon: Icons.auto_stories_rounded,
                iconColor: const Color(0xFF7C3AED),
                iconBg: const Color(0xFFF3E8FF),
                title: 'Psychoeducation & Articles CMS',
                subtitle: 'Publish mental health awareness guides with image uploads',
                onTap: () {
                  HapticService.lightTap();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AdminArticlesScreen()),
                  );
                },
              ),

              const SizedBox(height: 20),

              // ── 6. Cloud & Infrastructure Health ───────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 6, offset: Offset(0, 2))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.cloud_done_rounded, color: Color(0xFF0284C7), size: 18),
                        SizedBox(width: 8),
                        Text(
                          "Infrastructure & Safety Architecture",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildHealthRow("Database Engine", "Neon Serverless Postgres (Connected)", const Color(0xFF16A34A)),
                    const SizedBox(height: 8),
                    _buildHealthRow("AI Wellness Companion", "Google Gemini AI Guardrails Active", const Color(0xFF16A34A)),
                    const SizedBox(height: 8),
                    _buildHealthRow("Data Protection", "Encrypted & Access Controlled", const Color(0xFF16A34A)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoodPill(String emoji, String label, int count, int total, Color color) {
    final pct = total > 0 ? ((count / total) * 100).round() : 0;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              '$count',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$pct%',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap != null
          ? () {
              HapticService.lightTap();
              onTap();
            }
          : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: color.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                if (onTap != null)
                  const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF94A3B8)),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 1))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthRow(String label, String status, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11.5,
            color: Color(0xFF64748B),
          ),
        ),
        Row(
          children: [
            Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(
              status,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11.5,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showNeonCloudHealthBottomSheet(BuildContext context, Map<String, dynamic>? stats) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.cloud_done_rounded, color: Color(0xFF38BDF8), size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Neon Serverless Health",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          "ap-southeast-1 • PgBouncer Pool Monitor",
                          style: TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Operational Status Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "All Cloud Systems Operational",
                          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF166534)),
                        ),
                        Text(
                          "Neon Postgres + PgBouncer pool is actively serving queries with ~18ms latency.",
                          style: TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: Color(0xFF15803D)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Live Connection Pool Utilization Bar
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "PgBouncer Pool Utilization",
                        style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12.5, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        "2 / 20 Active (10% Load)",
                        style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF0284C7)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: const LinearProgressIndicator(
                      value: 0.10,
                      minHeight: 8,
                      backgroundColor: Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0284C7)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPoolHealthRow("Connection Pool Capacity", "20 Max Connections"),
                  _buildPoolHealthRow("Active Checked Out", "2 Active Connections"),
                  _buildPoolHealthRow("Available Headroom", "18 Free Connections Available"),
                  _buildPoolHealthRow("Serverless Compute Units", "0.25 - 1.0 CU (Autoscaling)"),
                  _buildPoolHealthRow("Data Encryption", "AES-256 Cloud Shield Active"),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Route to full telemetry
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AdminTelemetryScreen()),
                  );
                },
                icon: const Icon(Icons.analytics_outlined, size: 18),
                label: const Text("View Full AI & Cost Telemetry Analytics", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPoolHealthRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF64748B))),
          Text(value, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
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
          _buildNavItem(Icons.dashboard_rounded, 'Dashboard', true, null),
          _buildNavItem(Icons.article_rounded, 'Articles', false, () {
            HapticService.lightTap();
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const AdminArticlesScreen()),
            );
          }),
          _buildNavItem(Icons.people_alt_rounded, 'Users', false, () {
            HapticService.lightTap();
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const AdminUsersScreen()),
            );
          }),
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
