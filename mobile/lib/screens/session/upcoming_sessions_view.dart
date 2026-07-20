import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_client.dart';
import '../../config/api_config.dart';
import 'package:intl/intl.dart';

class UpcomingSessionsView extends StatefulWidget {
  const UpcomingSessionsView({super.key});

  @override
  State<UpcomingSessionsView> createState() => _UpcomingSessionsViewState();
}

class _UpcomingSessionsViewState extends State<UpcomingSessionsView> {
  bool _isLoading = true;
  List<dynamic> _sessions = [];
  String? _error;

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

    if (_sessions.isEmpty) {
      return Center(
        child: Text(
          'No upcoming sessions.',
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24.0),
      itemCount: _sessions.length,
      itemBuilder: (context, index) {
        final session = _sessions[index];
        final dt = DateTime.parse(session['date_time']).toLocal();
        final formattedDate = DateFormat('EEEE, MMM d').format(dt);
        final formattedTime = DateFormat('h:mm a').format(dt);

        return _buildSessionCard(
          date: formattedDate,
          time: formattedTime,
          professionalName: 'Dr. Jane Doe', // Mocked professional name
          reason: session['reason'] ?? '',
          mode: session['mode'] ?? '',
        );
      },
    );
  }

  Widget _buildSessionCard({
    required String date,
    required String time,
    required String professionalName,
    required String reason,
    required String mode,
  }) {
    return Container(
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
            ],
          ),
        ],
      ),
    );
  }
}
