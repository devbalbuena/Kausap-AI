import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../services/api_client.dart';

class AppointmentItem {
  final String id;
  final String clientName;
  final String initials;
  final String startTime;
  final String endTime;
  final String date;
  final String mode;
  final String reason;
  final String status;

  AppointmentItem.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        clientName = json['client_name'],
        initials = json['initials'],
        startTime = json['start_time'],
        endTime = json['end_time'],
        date = json['date'],
        mode = json['mode'],
        reason = json['reason'],
        status = json['status'];
}

class PendingRequest {
  final String id;
  final String clientName;
  final String requestedDate;
  final String requestedTime;
  final String mode;
  final String reason;
  final String tag;

  PendingRequest.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        clientName = json['client_name'],
        requestedDate = json['requested_date'],
        requestedTime = json['requested_time'],
        mode = json['mode'],
        reason = json['reason'],
        tag = json['tag'];
}

class ProfessionalAppointmentsScreen extends StatefulWidget {
  const ProfessionalAppointmentsScreen({super.key});

  @override
  State<ProfessionalAppointmentsScreen> createState() => _ProfessionalAppointmentsScreenState();
}

class _ProfessionalAppointmentsScreenState extends State<ProfessionalAppointmentsScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  List<AppointmentItem> _appointments = [];
  List<PendingRequest> _pendingRequests = [];
  String _selectedView = 'Day';

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.get('/professional/appointments');
      if (res != null) {
        setState(() {
          _appointments = (res['appointments'] as List).map((a) => AppointmentItem.fromJson(a)).toList();
          _pendingRequests = (res['pending_requests'] as List).map((p) => PendingRequest.fromJson(p)).toList();
        });
      }
    } catch (e) {
      debugPrint("Error fetching appointments: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 800;
                
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(24, isMobile ? 60 : 32, 24, 24),
                  child: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
                );
              },
            ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 7,
          child: _buildCalendarSection(),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 3,
          child: _buildPendingRequestsPanel(),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCalendarSection(),
        const SizedBox(height: 24),
        _buildPendingRequestsPanel(),
      ],
    );
  }

  Widget _buildCalendarSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EAED)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.chevron_left_rounded, color: Color(0xFF3D405B)),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right_rounded, color: Color(0xFF3D405B)),
                    const SizedBox(width: 16),
                    Text(
                      "Today", // Or formatted current date
                      style: AppTextStyles.heading2.copyWith(color: const Color(0xFF3D405B)),
                    ),
                  ],
                ),
                _buildViewToggle(),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE8EAED)),
          _buildDayViewGrid(), // Simplification for Phase 17
        ],
      ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F2FB),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['Day', 'Week', 'Month', 'Year'].map((view) {
          final isSelected = _selectedView == view;
          return GestureDetector(
            onTap: () => setState(() => _selectedView = view),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                boxShadow: isSelected
                    ? [const BoxShadow(color: Color(0x1A000000), blurRadius: 4, offset: Offset(0, 2))]
                    : [],
              ),
              child: Text(
                view,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppColors.primary : const Color(0xFF707974),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDayViewGrid() {
    // Simple mock time grid
    final hours = List.generate(12, (index) => index + 8); // 8 AM to 7 PM

    return Container(
      height: 600, // Fixed height for scrollable area
      child: ListView.builder(
        itemCount: hours.length,
        itemBuilder: (context, index) {
          final hour = hours[index];
          final timeLabel = hour > 12 ? '${hour - 12} PM' : (hour == 12 ? '12 PM' : '$hour AM');
          
          // Check if there's an appointment starting at this hour
          final appointment = _appointments.firstWhere(
            (a) => a.startTime.startsWith('${hour > 12 ? (hour - 12).toString().padLeft(2, '0') : hour.toString().padLeft(2, '0')}'),
            orElse: () => AppointmentItem.fromJson({'id': 'none', 'client_name': '', 'initials': '', 'start_time': '', 'end_time': '', 'date': '', 'mode': '', 'reason': '', 'status': ''}),
          );
          
          final hasAppointment = appointment.id != 'none';

          return Container(
            height: 60,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF3F2FB))),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  child: Center(
                    child: Text(
                      timeLabel,
                      style: const TextStyle(fontSize: 10, color: Color(0xFF707974), fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                const VerticalDivider(width: 1, color: Color(0xFFF3F2FB)),
                Expanded(
                  child: hasAppointment
                      ? Container(
                          margin: const EdgeInsets.only(top: 2, bottom: 2, right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE4F9FF),
                            border: Border(left: BorderSide(color: AppColors.primary, width: 4)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(appointment.reason, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                              Text(appointment.clientName, style: const TextStyle(fontSize: 10, color: AppColors.primary)),
                            ],
                          ),
                        )
                      : const SizedBox(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPendingRequestsPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EAED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.inbox_rounded, color: Color(0xFF3D405B), size: 20),
                    SizedBox(width: 8),
                    Text("Pending Requests", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3D405B))),
                  ],
                ),
                if (_pendingRequests.isNotEmpty)
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: const Color(0xFFFF5858),
                    child: Text(_pendingRequests.length.toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE8EAED)),
          if (_pendingRequests.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text("No pending requests.", style: TextStyle(color: Color(0xFF707974))),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _pendingRequests.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE8EAED)),
              itemBuilder: (context, index) {
                final req = _pendingRequests[index];
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(req.clientName, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3D405B))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: req.tag == 'NEW' ? const Color(0xFFE4F9FF) : const Color(0xFFFFE5E5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              req.tag,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: req.tag == 'NEW' ? AppColors.primary : const Color(0xFFFF5858),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF707974)),
                          const SizedBox(width: 4),
                          Text("${req.requestedDate}, ${req.requestedTime}", style: const TextStyle(fontSize: 12, color: Color(0xFF707974))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(req.mode == 'Virtual' ? Icons.videocam_rounded : Icons.location_on_rounded, size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(req.mode, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE8EAED)),
                        ),
                        child: Text(
                          "\"${req.reason}\"",
                          style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Color(0xFF707974)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text("Approve"),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: const BorderSide(color: Color(0xFFE8EAED)),
                              ),
                              child: const Text("Decline", style: TextStyle(color: Color(0xFF3D405B))),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
