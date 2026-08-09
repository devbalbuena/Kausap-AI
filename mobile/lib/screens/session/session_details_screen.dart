import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class SessionDetailsScreen extends StatefulWidget {
  final String sessionId;
  final String date;
  final String time;
  final String professionalName;
  final String reason;
  final String mode;

  const SessionDetailsScreen({
    super.key,
    required this.sessionId,
    required this.date,
    required this.time,
    required this.professionalName,
    required this.reason,
    required this.mode,
  });

  @override
  State<SessionDetailsScreen> createState() => _SessionDetailsScreenState();
}

class _SessionDetailsScreenState extends State<SessionDetailsScreen> with SingleTickerProviderStateMixin {
  bool _isAddedToCalendar = false;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _addToCalendar() {
    if (_isAddedToCalendar) return;

    _animController.forward();
    setState(() {
      _isAddedToCalendar = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 12),
            Text('Session added to device calendar!'),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text('Session Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Session Info Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
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
                    children: [
                      const CircleAvatar(
                        radius: 24,
                        backgroundImage: CachedNetworkImageProvider('https://i.pravatar.cc/150?img=11'),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.professionalName,
                            style: AppTextStyles.heading2.copyWith(fontSize: 18),
                          ),
                          Text(
                            'Therapist',
                            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      )
                    ],
                  ),
                  const Divider(height: 32),
                  _buildDetailRow(Icons.calendar_today_rounded, widget.date),
                  const SizedBox(height: 12),
                  _buildDetailRow(Icons.access_time_rounded, widget.time),
                  const SizedBox(height: 12),
                  _buildDetailRow(Icons.videocam_rounded, widget.mode),
                  const SizedBox(height: 12),
                  _buildDetailRow(Icons.info_outline_rounded, widget.reason),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Add to Calendar Button
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: SizedBox(
                    height: 54,
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _addToCalendar,
                      icon: Icon(
                        _isAddedToCalendar ? Icons.check_rounded : Icons.calendar_month_rounded,
                        color: _isAddedToCalendar ? AppColors.primary : Colors.white,
                      ),
                      label: Text(
                        _isAddedToCalendar ? 'Added to Calendar' : 'Add to Device Calendar',
                        style: AppTextStyles.button.copyWith(
                          color: _isAddedToCalendar ? AppColors.primary : Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isAddedToCalendar ? Colors.white : AppColors.primary,
                        side: _isAddedToCalendar ? const BorderSide(color: AppColors.primary, width: 2) : BorderSide.none,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
