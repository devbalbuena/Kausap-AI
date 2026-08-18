import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../services/api_client.dart';
import '../../chat/direct_message_screen.dart';

class AppointmentItem {
  final String id;
  final String clientName;
  final String initials;
  final String startTime;
  final String endTime;
  final String date;
  final String mode; // Virtual, In-Person
  final String reason;
  final String status; // SCHEDULED, COMPLETED, CANCELLED

  AppointmentItem({
    required this.id,
    required this.clientName,
    required this.initials,
    required this.startTime,
    required this.endTime,
    required this.date,
    required this.mode,
    required this.reason,
    required this.status,
  });

  factory AppointmentItem.fromJson(Map<String, dynamic> json) {
    return AppointmentItem(
      id: json['id']?.toString() ?? '',
      clientName: json['client_name']?.toString() ?? 'Client',
      initials: json['initials']?.toString() ?? 'C',
      startTime: json['start_time']?.toString() ?? '10:00 AM',
      endTime: json['end_time']?.toString() ?? '11:00 AM',
      date: json['date']?.toString() ?? DateTime.now().toIso8601String().substring(0, 10),
      mode: json['mode']?.toString() ?? 'Virtual',
      reason: json['reason']?.toString() ?? 'Therapy Consultation',
      status: json['status']?.toString() ?? 'SCHEDULED',
    );
  }
}

class PendingRequest {
  final String id;
  final String clientName;
  final String requestedDate;
  final String requestedTime;
  final String mode;
  final String reason;
  final String tag;

  PendingRequest({
    required this.id,
    required this.clientName,
    required this.requestedDate,
    required this.requestedTime,
    required this.mode,
    required this.reason,
    required this.tag,
  });

  factory PendingRequest.fromJson(Map<String, dynamic> json) {
    return PendingRequest(
      id: json['id']?.toString() ?? '',
      clientName: json['client_name']?.toString() ?? 'Client',
      requestedDate: json['requested_date']?.toString() ?? 'Tomorrow',
      requestedTime: json['requested_time']?.toString() ?? '2:00 PM',
      mode: json['mode']?.toString() ?? 'Virtual',
      reason: json['reason']?.toString() ?? 'Initial Clinical Intake',
      tag: json['tag']?.toString() ?? 'AI REFERRAL',
    );
  }
}

class ProfessionalAppointmentsScreen extends StatefulWidget {
  const ProfessionalAppointmentsScreen({super.key});

  @override
  State<ProfessionalAppointmentsScreen> createState() => _ProfessionalAppointmentsScreenState();
}

class _ProfessionalAppointmentsScreenState extends State<ProfessionalAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  late TabController _tabController;

  DateTime _selectedDate = DateTime.now();
  List<AppointmentItem> _appointments = [];
  List<PendingRequest> _pendingRequests = [];
  List<AppointmentItem> _pastAppointments = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSampleAndFetchAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadSampleAndFetchAppointments() {
    // Seed initial appointments so the schedule is immediately useful and dynamic
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final tomorrowStr = DateTime.now().add(const Duration(days: 1)).toIso8601String().substring(0, 10);

    _appointments = [
      AppointmentItem(
        id: 'apt-01',
        clientName: 'Van Balbuena',
        initials: 'VB',
        startTime: '10:00 AM',
        endTime: '11:00 AM',
        date: todayStr,
        mode: 'Virtual',
        reason: 'CBT Cognitive Reframing Session',
        status: 'SCHEDULED',
      ),
      AppointmentItem(
        id: 'apt-02',
        clientName: 'Juan Dela Cruz',
        initials: 'JD',
        startTime: '02:30 PM',
        endTime: '03:30 PM',
        date: todayStr,
        mode: 'In-Person',
        reason: 'General Anxiety & Somatic Stress',
        status: 'SCHEDULED',
      ),
      AppointmentItem(
        id: 'apt-03',
        clientName: 'Sai Usa',
        initials: 'SU',
        startTime: '04:00 PM',
        endTime: '05:00 PM',
        date: tomorrowStr,
        mode: 'Virtual',
        reason: 'Weekly Affect & Mood Review',
        status: 'SCHEDULED',
      ),
    ];

    _pendingRequests = [
      PendingRequest(
        id: 'req-01',
        clientName: 'Van Balbuena',
        requestedDate: 'Friday, Aug 21',
        requestedTime: '11:00 AM',
        mode: 'Virtual',
        reason: 'Follow-up on Panic Grounding Exercises',
        tag: 'FOLLOW-UP',
      ),
      PendingRequest(
        id: 'req-02',
        clientName: 'New Patient (Maria Santos)',
        requestedDate: 'Monday, Aug 24',
        requestedTime: '03:00 PM',
        mode: 'In-Person',
        reason: 'Kausap AI Crisis Screener Referral (PHQ-9 Score 16)',
        tag: 'AI REFERRAL',
      ),
    ];

    _pastAppointments = [
      AppointmentItem(
        id: 'past-01',
        clientName: 'Juan Dela Cruz',
        initials: 'JD',
        startTime: '09:00 AM',
        endTime: '10:00 AM',
        date: 'Aug 14, 2026',
        mode: 'Virtual',
        reason: 'Initial Clinical Intake & Baseline Assessment',
        status: 'COMPLETED',
      ),
    ];

    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.get('/professional/appointments');
      if (res != null) {
        if (res['appointments'] != null && (res['appointments'] as List).isNotEmpty) {
          _appointments = (res['appointments'] as List).map((a) => AppointmentItem.fromJson(a)).toList();
        }
        if (res['pending_requests'] != null && (res['pending_requests'] as List).isNotEmpty) {
          _pendingRequests = (res['pending_requests'] as List).map((p) => PendingRequest.fromJson(p)).toList();
        }
      }
    } catch (e) {
      debugPrint("Info: Using initialized appointment state: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<AppointmentItem> get _selectedDayAppointments {
    final selectedStr = _selectedDate.toIso8601String().substring(0, 10);
    return _appointments.where((a) => a.date == selectedStr).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 800;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ───────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(20, isMobile ? 54 : 32, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Sessions & Schedule",
                              style: AppTextStyles.heading1.copyWith(
                                fontSize: 26,
                                letterSpacing: -0.5,
                                color: const Color(0xFF2C3E50),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Manage client consultations, bookings & clinical calendar.",
                              style: AppTextStyles.body.copyWith(
                                color: const Color(0xFF707974),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _showScheduleNewSessionModal(context),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text("New Session"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // ── 7-Day Date Strip ──────────────────────────────────
                    _buildDateStrip(),
                    const SizedBox(height: 14),
                    // ── Tab Bar (Upcoming, Pending, Past) ─────────────────
                    Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE8EAED)),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        labelColor: AppColors.primary,
                        unselectedLabelColor: const Color(0xFF707974),
                        indicatorColor: AppColors.primary,
                        indicatorWeight: 3,
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        tabs: [
                          Tab(text: "Upcoming (${_appointments.length})"),
                          Tab(text: "Pending (${_pendingRequests.length})"),
                          Tab(text: "Past History (${_pastAppointments.length})"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildUpcomingTab(),
                    _buildPendingTab(),
                    _buildPastTab(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Horizontal Date Strip ───────────────────────────────────────────────
  Widget _buildDateStrip() {
    final now = DateTime.now();
    final days = List.generate(7, (index) => now.add(Duration(days: index - 1))); // Yesterday to +5 days

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: days.map((day) {
          final isSelected = _selectedDate.year == day.year &&
              _selectedDate.month == day.month &&
              _selectedDate.day == day.day;
          final isToday = now.year == day.year && now.month == day.month && now.day == day.day;
          final dayStr = day.toIso8601String().substring(0, 10);
          final bool hasSessions = _appointments.any((a) => a.date == dayStr);

          final weekdayName = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"][day.weekday - 1];

          return GestureDetector(
            onTap: () => setState(() => _selectedDate = day),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSelected ? AppColors.primary : const Color(0xFFE8EAED)),
                boxShadow: [
                  if (isSelected)
                    const BoxShadow(color: Color(0x2A0077B6), blurRadius: 8, offset: Offset(0, 3)),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    isToday ? "Today" : weekdayName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white70 : const Color(0xFF707974),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${day.day}",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : const Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (hasSessions)
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    )
                  else
                    const SizedBox(height: 5),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Tab 1: Upcoming Sessions ────────────────────────────────────────────
  Widget _buildUpcomingTab() {
    final list = _selectedDayAppointments;

    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(color: Color(0xFFE3F2FD), shape: BoxShape.circle),
                child: const Icon(Icons.event_available_rounded, color: AppColors.primary, size: 36),
              ),
              const SizedBox(height: 16),
              const Text(
                "No Sessions on Selected Date",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
              ),
              const SizedBox(height: 6),
              const Text(
                "You have no scheduled consultations on this day.",
                style: TextStyle(fontSize: 13, color: Color(0xFF707974)),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _showScheduleNewSessionModal(context),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text("Book Session for this Day"),
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

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 80),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final apt = list[index];
        final isVirtual = apt.mode == 'Virtual';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8EAED)),
            boxShadow: const [
              BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 3)),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF334155)),
                        const SizedBox(width: 6),
                        Text(
                          "${apt.startTime} - ${apt.endTime}",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF334155)),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isVirtual ? const Color(0xFFE8F5E9) : const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isVirtual ? Icons.videocam_rounded : Icons.location_on_rounded,
                          size: 13,
                          color: isVirtual ? const Color(0xFF2E7D32) : const Color(0xFF1565C0),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isVirtual ? "Virtual Session" : "In-Person Clinic",
                          style: TextStyle(
                            color: isVirtual ? const Color(0xFF2E7D32) : const Color(0xFF1565C0),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFFD6F1FC),
                    radius: 20,
                    child: Text(
                      apt.initials,
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          apt.clientName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2C3E50)),
                        ),
                        Text(
                          apt.reason,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF707974)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DirectMessageScreen(
                              otherUserId: apt.id,
                              otherUserName: apt.clientName,
                              otherUserRole: 'client',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14),
                      label: const Text("Message", style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: Color(0xFFD6F1FC)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isVirtual
                                ? "Launching secure telehealth video room for ${apt.clientName}..."
                                : "Viewing appointment check-in details for ${apt.clientName}..."),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      },
                      icon: Icon(isVirtual ? Icons.videocam_rounded : Icons.info_outline_rounded, size: 16),
                      label: Text(isVirtual ? "Join Call" : "Check-in", style: const TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isVirtual ? AppColors.primary : const Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Tab 2: Pending Booking Requests ─────────────────────────────────────
  Widget _buildPendingTab() {
    if (_pendingRequests.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.mark_email_read_rounded, color: Color(0xFF4CAF50), size: 40),
              SizedBox(height: 12),
              Text("No Pending Booking Requests", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 4),
              Text("All incoming referral and client appointments have been reviewed.", style: TextStyle(color: Color(0xFF707974), fontSize: 13)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 80),
      itemCount: _pendingRequests.length,
      itemBuilder: (context, index) {
        final req = _pendingRequests[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8EAED)),
            boxShadow: const [
              BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 3)),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Color(0xFFFFF3E0),
                        child: Icon(Icons.calendar_month_rounded, color: Color(0xFFE65100), size: 20),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(req.clientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2C3E50))),
                          Text("Requested: ${req.requestedDate} • ${req.requestedTime}", style: const TextStyle(fontSize: 12, color: Color(0xFF707974))),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      req.tag,
                      style: const TextStyle(color: Color(0xFF1565C0), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: Text(
                  "Session Topic: ${req.reason} (${req.mode} Mode)",
                  style: const TextStyle(fontSize: 12, color: Color(0xFF4A5568)),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _pendingRequests.removeAt(index);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Declined booking request from ${req.clientName}"), backgroundColor: const Color(0xFF707974)),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF707974),
                        side: const BorderSide(color: Color(0xFFE0E0E0)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text("Decline"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _pendingRequests.removeAt(index);
                          _appointments.add(
                            AppointmentItem(
                              id: 'confirmed-${DateTime.now().millisecondsSinceEpoch}',
                              clientName: req.clientName,
                              initials: req.clientName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join(),
                              startTime: req.requestedTime,
                              endTime: '1 hour session',
                              date: DateTime.now().toIso8601String().substring(0, 10),
                              mode: req.mode,
                              reason: req.reason,
                              status: 'SCHEDULED',
                            ),
                          );
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Appointment confirmed with ${req.clientName}! Added to your schedule."),
                            backgroundColor: const Color(0xFF2E7D32),
                          ),
                        );
                      },
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: const Text("Accept Booking"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Tab 3: Past Sessions History ─────────────────────────────────────────
  Widget _buildPastTab() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 80),
      itemCount: _pastAppointments.length,
      itemBuilder: (context, index) {
        final past = _pastAppointments[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8EAED)),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFE8F5E9),
                child: Text(past.initials, style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(past.clientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2C3E50))),
                    Text("${past.date} • ${past.startTime} (${past.mode})", style: const TextStyle(fontSize: 12, color: Color(0xFF707974))),
                    const SizedBox(height: 2),
                    Text(past.reason, style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
                child: const Text("Notes Recorded ✓", style: TextStyle(color: Color(0xFF2E7D32), fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Modal: Schedule New Session ─────────────────────────────────────────
  void _showScheduleNewSessionModal(BuildContext context) {
    final clientCtrl = TextEditingController(text: "Van Balbuena");
    final reasonCtrl = TextEditingController(text: "Therapy Consultation & Check-in");
    String selectedMode = "Virtual";
    String selectedTime = "11:00 AM";

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
                  const Text("Book New Clinical Consultation", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                  const SizedBox(height: 14),
                  TextField(
                    controller: clientCtrl,
                    decoration: InputDecoration(
                      labelText: "Patient / Client Name",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonCtrl,
                    decoration: InputDecoration(
                      labelText: "Consultation Focus / Reason",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text("Select Mode", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text("Virtual (Video Room)"),
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
                  const SizedBox(height: 14),
                  const Text("Time Slot", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ["09:00 AM", "11:00 AM", "02:00 PM", "04:30 PM"].map((t) {
                      return ChoiceChip(
                        label: Text(t),
                        selected: selectedTime == t,
                        onSelected: (v) => setModalState(() => selectedTime = t),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          _appointments.add(
                            AppointmentItem(
                              id: 'new-${DateTime.now().millisecondsSinceEpoch}',
                              clientName: clientCtrl.text.isNotEmpty ? clientCtrl.text : "Client",
                              initials: clientCtrl.text.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join(),
                              startTime: selectedTime,
                              endTime: '1 hour session',
                              date: _selectedDate.toIso8601String().substring(0, 10),
                              mode: selectedMode,
                              reason: reasonCtrl.text,
                              status: 'SCHEDULED',
                            ),
                          );
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Session confirmed for ${clientCtrl.text} at $selectedTime ($selectedMode)!"),
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
                      child: const Text("Confirm & Schedule Session", style: TextStyle(fontWeight: FontWeight.bold)),
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
}
