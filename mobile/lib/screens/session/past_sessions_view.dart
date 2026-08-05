import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_client.dart';
import '../../config/api_config.dart';
import 'package:intl/intl.dart';
import 'widgets/rate_session_bottom_sheet.dart';
import 'widgets/session_notes_bottom_sheet.dart';

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
          sessionId: session['id'],
          date: formattedDate,
          time: formattedTime,
          professionalName: 'Dr. Jane Doe', // Mocked
          status: session['status'] ?? 'completed',
          rating: session['rating'],
        );
      },
    );
  }

  Widget _buildPastSessionCard({
    required String sessionId,
    required String date,
    required String time,
    required String professionalName,
    required String status,
    int? rating,
  }) {
    final isCancelled = status.toLowerCase() == 'cancelled';
    final isCompleted = status.toLowerCase() == 'completed';
    
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
          if (isCompleted) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: AppColors.divider, height: 1),
            ),
            if (rating != null)
              Row(
                children: [
                  const Text('Your Rating: ', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textSecondary)),
                  ...List.generate(5, (i) => Icon(
                    i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: const Color(0xFFF59E0B),
                    size: 16,
                  )),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    final result = await showModalBottomSheet<bool>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => RateSessionBottomSheet(
                        sessionId: sessionId,
                        professionalName: professionalName,
                      ),
                    );
                    if (result == true) {
                      _fetchPastSessions();
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Rate Session', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                ),
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => SessionNotesBottomSheet(
                      sessionId: sessionId,
                      professionalName: professionalName,
                    ),
                  );
                },
                icon: const Icon(Icons.edit_note_rounded, size: 18),
                label: const Text('Private Session Notes', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
