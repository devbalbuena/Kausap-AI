import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

class DailyJournalScreen extends StatefulWidget {
  const DailyJournalScreen({super.key});

  @override
  State<DailyJournalScreen> createState() => _DailyJournalScreenState();
}

class _DailyJournalScreenState extends State<DailyJournalScreen> {
  final TextEditingController _journalController = TextEditingController();
  final _storage = const FlutterSecureStorage();
  DateTime _selectedDate = DateTime.now();
  double _moodValue = 5;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadJournal();
  }

  Future<void> _loadJournal() async {
    setState(() {
      _isLoading = true;
    });
    
    final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final savedJournal = await _storage.read(key: 'journal_$dateKey');
    final savedMood = await _storage.read(key: 'mood_$dateKey');
    
    if (mounted) {
      setState(() {
        if (savedJournal != null) {
          _journalController.text = savedJournal;
        } else {
          _journalController.clear();
        }
        
        if (savedMood != null) {
          _moodValue = double.tryParse(savedMood) ?? 5;
        } else {
          _moodValue = 5;
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _saveJournal() async {
    setState(() {
      _isSaving = true;
    });
    
    final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
    await _storage.write(key: 'journal_$dateKey', value: _journalController.text);
    await _storage.write(key: 'mood_$dateKey', value: _moodValue.toString());
    
    if (mounted) {
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Journal entry saved successfully.')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadJournal();
    }
  }

  @override
  void dispose() {
    _journalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateDisplay = DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Daily Journal', style: AppTextStyles.heading3),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              dateDisplay,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Mood: ${_getMoodEmoji(_moodValue)}',
                      style: AppTextStyles.heading2,
                    ),
                    Slider(
                      value: _moodValue,
                      min: 1,
                      max: 10,
                      divisions: 9,
                      activeColor: AppColors.primary,
                      label: _moodValue.round().toString(),
                      onChanged: (value) {
                        setState(() {
                          _moodValue = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'How was your day?',
                      style: AppTextStyles.heading2,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Write down your thoughts, feelings, or whatever comes to mind.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x05000000),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _journalController,
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            height: 1.5,
                            color: AppColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Start typing here...',
                            hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.all(20),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveJournal,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isSaving
                            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Save Entry', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  String _getMoodEmoji(double value) {
    if (value <= 2) return '😢 (Very Bad)';
    if (value <= 4) return '😕 (Bad)';
    if (value <= 6) return '😐 (Okay)';
    if (value <= 8) return '🙂 (Good)';
    return '😁 (Awesome)';
  }
}
