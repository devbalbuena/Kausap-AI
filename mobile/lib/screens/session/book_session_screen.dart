import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_client.dart';
import '../../config/api_config.dart';

class BookSessionScreen extends StatefulWidget {
  const BookSessionScreen({super.key});

  @override
  State<BookSessionScreen> createState() => _BookSessionScreenState();
}

class _BookSessionScreenState extends State<BookSessionScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedTime;
  String? _selectedReason;
  String _selectedMode = 'Online';
  final TextEditingController _notesController = TextEditingController();

  final List<String> _timeSlots = [
    '09:00 AM',
    '10:00 AM',
    '11:00 AM',
    '01:00 PM',
    '02:00 PM',
    '04:00 PM',
  ];

  final List<String> _reasons = [
    'Academic Stress',
    'Anxiety',
    'Can\'t Sleep',
    'Feeling Lonely',
    'Work Stress',
  ];

  bool _isSubmitting = false;

  Future<void> _bookSession() async {
    if (_selectedTime == null || _selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time and a reason.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Parse selected time into DateTime
      // e.g. "09:00 AM"
      final timeParts = _selectedTime!.split(' ');
      final hm = timeParts[0].split(':');
      int hour = int.parse(hm[0]);
      final int minute = int.parse(hm[1]);
      if (timeParts[1] == 'PM' && hour != 12) hour += 12;
      if (timeParts[1] == 'AM' && hour == 12) hour = 0;

      final sessionDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        hour,
        minute,
      );

      final payload = {
        'professional_id': '00000000-0000-0000-0000-000000000000', // Mock professional ID
        'date_time': sessionDateTime.toUtc().toIso8601String(),
        'reason': _selectedReason,
        'mode': _selectedMode,
        'notes': _notesController.text,
      };

      await ApiClient().post(ApiConfig.sessions, body: payload);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session booked successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().contains('409') 
                ? 'This time slot is already booked. Please select another.' 
                : 'Failed to book session.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FF),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Book Counseling Session',
          style: AppTextStyles.heading2,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Calendar Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: CalendarDatePicker(
                initialDate: _selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 90)),
                onDateChanged: (date) {
                  setState(() {
                    _selectedDate = date;
                    _selectedTime = null; // reset time when date changes
                  });
                },
              ),
            ),
            const SizedBox(height: 24),
            Text('Time Slots', style: AppTextStyles.heading2),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _timeSlots.map((time) {
                final isSelected = _selectedTime == time;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTime = time),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.white,
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.inputBorder,
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      time,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text('Session Details', style: AppTextStyles.heading2),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedReason,
              hint: const Text('Select a topic'),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.inputBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.inputBorder),
                ),
              ),
              items: _reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (val) => setState(() => _selectedReason = val),
            ),
            const SizedBox(height: 16),
            // Mode Toggle
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedMode = 'Online'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _selectedMode == 'Online' ? const Color(0xFFE4F9FF) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _selectedMode == 'Online' ? AppColors.primary : AppColors.inputBorder,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Online',
                        style: TextStyle(
                          color: _selectedMode == 'Online' ? AppColors.primary : AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedMode = 'In-person'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _selectedMode == 'In-person' ? const Color(0xFFE4F9FF) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _selectedMode == 'In-person' ? AppColors.primary : AppColors.inputBorder,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'In-person',
                        style: TextStyle(
                          color: _selectedMode == 'In-person' ? AppColors.primary : AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Any additional notes for the therapist (optional)',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.inputBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.inputBorder),
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _bookSession,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Confirm Booking',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.2),
                      ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
