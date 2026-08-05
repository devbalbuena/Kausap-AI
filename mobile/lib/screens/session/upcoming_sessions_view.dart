import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_client.dart';
import '../../config/api_config.dart';
import 'session_details_screen.dart';
import 'widgets/cancel_session_bottom_sheet.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class UpcomingSessionsView extends StatefulWidget {
  const UpcomingSessionsView({super.key});

  @override
  State<UpcomingSessionsView> createState() => _UpcomingSessionsViewState();
}

class _UpcomingSessionsViewState extends State<UpcomingSessionsView> {
  bool _isLoading = true;
  List<dynamic> _sessions = [];
  String? _error;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _fetchUpcomingSessions();
  }

  Future<void> _fetchUpcomingSessions() async {
    try {
      final data = await ApiClient().get(ApiConfig.sessionsUpcoming);
      if (mounted) {
        setState(() {
          _sessions = data as List<dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load upcoming sessions';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _cancelSession(String id, String date, String time, String professionalName) async {
    final result = await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CancelSessionBottomSheet(
        sessionId: id,
        professionalName: professionalName,
        date: date,
        time: time,
      ),
    );

    if (result == null) return;
    
    if (result == true) {
      // Confirmed cancellation
      // await ApiClient().delete('${ApiConfig.sessions}/$id');
      setState(() {
        _sessions.removeWhere((s) => s['id'] == id);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session cancelled successfully.')),
        );
      }
    } else if (result == 'reschedule') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Redirecting to rescheduling...')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _fetchUpcomingSessions();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: AppColors.primary.withAlpha(50),
              shape: BoxShape.circle,
            ),
            selectedDecoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
        ),
        const SizedBox(height: 24),
        if (_sessions.isEmpty)
          Center(
            child: Text(
              'No upcoming sessions.',
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            ),
          )
        else
          ..._sessions.map((session) {
            final dt = DateTime.parse(session['date_time']).toLocal();
            final formattedDate = DateFormat('EEEE, MMM d').format(dt);
            final formattedTime = DateFormat('h:mm a').format(dt);

            return _buildSessionCard(
              id: session['id'] ?? '',
              date: formattedDate,
              time: formattedTime,
              professionalName: 'Dr. Jane Doe', // Mocked professional name
              reason: session['reason'] ?? '',
              mode: session['mode'] ?? '',
            );
          }),
      ],
    );
  }

  Widget _buildSessionCard({
    required String id,
    required String date,
    required String time,
    required String professionalName,
    required String reason,
    required String mode,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => SessionDetailsScreen(
              sessionId: id,
              date: date,
              time: time,
              professionalName: professionalName,
              reason: reason,
              mode: mode,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.sessionCard, // Teal/light blue from Figma
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                date,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  mode,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            time,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    professionalName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    reason,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (id.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.cancel_rounded, color: Colors.white70),
                  tooltip: 'Cancel or Reschedule Session',
                  onPressed: () => _cancelSession(id, date, time, professionalName),
                ),
            ],
          ),
        ],
      ),
    );
    );
  }
}
