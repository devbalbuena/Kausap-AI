import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_client.dart';
import '../../config/api_config.dart';
import 'package:intl/intl.dart';

class PastSessionsView extends StatefulWidget {
  const PastSessionsView({super.key});

  @override
  State<PastSessionsView> createState() => _PastSessionsViewState();
}

class _PastSessionsViewState extends State<PastSessionsView> {
  bool _isLoading = true;
  List<dynamic> _sessions = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPastSessions();
  }

  Future<void> _fetchPastSessions() async {
    try {
      final data = await ApiClient().get(ApiConfig.sessionsPast);
      if (mounted) {
        setState(() {
          _sessions = data as List<dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load past sessions';
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
                _fetchPastSessions();
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
          'No past sessions.',
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
        final formattedDate = DateFormat('MMM d, yyyy').format(dt);
        final formattedTime = DateFormat('h:mm a').format(dt);

        return _buildPastSessionCard(
          date: formattedDate,
          time: formattedTime,
          professionalName: 'Dr. Jane Doe', // Mocked
          status: session['status'] ?? 'completed',
        );
      },
    );
  }

  Widget _buildPastSessionCard({
    required String date,
    required String time,
    required String professionalName,
    required String status,
  }) {
    final isCancelled = status.toLowerCase() == 'cancelled';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCancelled ? const Color(0xFFFEE9E7) : const Color(0xFFE4F9FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isCancelled ? Icons.cancel_outlined : Icons.check_circle_outline,
              color: isCancelled ? AppColors.error : AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  professionalName,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$date • $time',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isCancelled ? AppColors.errorBackground : const Color(0xFFE7FEEE),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isCancelled ? AppColors.error : const Color(0xFF519C6B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
