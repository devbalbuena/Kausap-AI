import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/api_client.dart';
import '../../utils/haptic_service.dart';

class GuidanceNoticesScreen extends StatefulWidget {
  const GuidanceNoticesScreen({super.key});

  @override
  State<GuidanceNoticesScreen> createState() => _GuidanceNoticesScreenState();
}

class _GuidanceNoticesScreenState extends State<GuidanceNoticesScreen> {
  final ApiClient _api = ApiClient();
  List<Map<String, dynamic>> _notices = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchNotices();
  }

  Future<void> _fetchNotices() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await _api.get('/notifications/guidance-notices', silent: true);
      if (mounted) {
        if (res is List) {
          setState(() {
            _notices = res.map((e) => Map<String, dynamic>.from(e as Map)).toList();
            _isLoading = false;
          });
        } else {
          setState(() {
            _notices = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Unable to load guidance notices.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _acknowledgeNotice(Map<String, dynamic> notice) async {
    final notifId = notice['id']?.toString() ?? '';
    if (notifId.isEmpty) return;

    HapticService.heavyTap();

    try {
      await _api.post('/notifications/$notifId/acknowledge', body: {});
      if (mounted) {
        setState(() {
          notice['is_acknowledged'] = true;
          notice['acknowledged_at'] = DateTime.now().toIso8601String();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Visit Confirmed! The Guidance Counselor has been notified.',
                    style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to confirm notice: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Guidance Office Notices',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 42, color: Color(0xFF94A3B8)),
                        const SizedBox(height: 12),
                        Text(_error!, style: const TextStyle(fontFamily: 'Poppins', color: Color(0xFF64748B))),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _fetchNotices,
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                          child: const Text('Retry', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  )
                : _notices.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withAlpha(20),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.mark_email_read_outlined, size: 44, color: AppColors.primary),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'No Guidance Notices',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'When the Urios Guidance & Counseling Center sends you an official call-slip or invitation, it will appear here.',
                                style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF64748B), height: 1.4),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchNotices,
                        color: AppColors.primary,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: _notices.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final notice = _notices[index];
                            return _buildNoticeCard(notice);
                          },
                        ),
                      ),
      ),
    );
  }

  Widget _buildNoticeCard(Map<String, dynamic> notice) {
    final title = notice['title'] ?? 'Guidance Consultation Notice';
    final body = notice['body'] ?? '';
    final isAck = notice['is_acknowledged'] == true;
    final createdAt = notice['created_at'];

    String dateStr = '';
    if (createdAt != null) {
      try {
        final dt = DateTime.parse(createdAt.toString());
        dateStr = DateFormat('MMM d, yyyy • h:mm a').format(dt.toLocal());
      } catch (_) {
        dateStr = createdAt.toString();
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAck ? const Color(0xFFE2E8F0) : const Color(0xFF0284C7).withAlpha(120),
          width: isAck ? 1 : 1.5,
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: isAck ? const Color(0xFFF1F5F9) : const Color(0xFFE0F2FE),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isAck ? const Color(0xFFE2E8F0) : const Color(0xFF0284C7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.account_balance_rounded,
                    color: isAck ? const Color(0xFF475569) : Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Father Saturnino Urios University',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isAck ? const Color(0xFF64748B) : const Color(0xFF0369A1),
                          letterSpacing: 0.3,
                        ),
                      ),
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isAck)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Confirmed',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Action Needed',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFD97706),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Body Content
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Box
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        Icons.location_on_rounded,
                        'Location',
                        'Urios Guidance Center (Main Campus, 2nd Floor)',
                        const Color(0xFF0284C7),
                      ),
                      const Divider(height: 16, color: Color(0xFFE2E8F0)),
                      _buildInfoRow(
                        Icons.access_time_filled_rounded,
                        'Notice Issued',
                        dateStr.isNotEmpty ? dateStr : 'Recently',
                        const Color(0xFF64748B),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Counselor Message
                const Text(
                  'Counselor Instructions:',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: Color(0xFF1E293B),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),

                // Action Area
                if (isAck)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.verified_rounded, color: Color(0xFF16A34A), size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'You confirmed this visit. The Guidance Counselor is expecting you at the office!',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF15803D),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _acknowledgeNotice(notice),
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                      label: const Text(
                        'Acknowledge & Confirm Visit',
                        style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 13.5),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
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

  Widget _buildInfoRow(IconData icon, String label, String value, Color iconColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }
}
