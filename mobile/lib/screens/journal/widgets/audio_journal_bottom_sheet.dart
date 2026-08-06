import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../theme/app_theme.dart';

class AudioJournalBottomSheet extends StatefulWidget {
  const AudioJournalBottomSheet({super.key});

  @override
  State<AudioJournalBottomSheet> createState() => _AudioJournalBottomSheetState();
}

class _AudioJournalBottomSheetState extends State<AudioJournalBottomSheet> with SingleTickerProviderStateMixin {
  bool _isRecording = false;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
    });
    if (_isRecording) {
      _waveController.repeat();
    } else {
      _waveController.stop();
      _waveController.reset();
    }
  }

  void _saveAudio() {
    Navigator.pop(context, true); // true = saved successfully
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Audio Journal',
                    style: AppTextStyles.heading2.copyWith(fontSize: 20),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // Soundwave Animation
              SizedBox(
                height: 80,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(20, (index) {
                    return AnimatedBuilder(
                      animation: _waveController,
                      builder: (context, child) {
                        final double t = _waveController.value * 2 * math.pi;
                        final double phase = index * (math.pi / 5);
                        final double waveHeight = _isRecording ? (math.sin(t + phase) * 0.5 + 0.5) * 40 + 10 : 10;
                        
                        return Container(
                          width: 6,
                          height: waveHeight,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: _isRecording ? AppColors.primary : AppColors.divider,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        );
                      },
                    );
                  }),
                ),
              ),
              
              const SizedBox(height: 32),
              Text(
                _isRecording ? 'Listening...' : 'Tap to start recording',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!_isRecording && _waveController.value == 0.0)
                    Container()
                  else
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _isRecording = false;
                          _waveController.stop();
                          _waveController.reset();
                        });
                      },
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                      iconSize: 32,
                    ),
                  const SizedBox(width: 24),
                  GestureDetector(
                    onTap: _toggleRecording,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: EdgeInsets.all(_isRecording ? 16 : 20),
                      decoration: BoxDecoration(
                        color: _isRecording ? Colors.red : AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (_isRecording ? Colors.red : AppColors.primary).withAlpha(100),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  if (!_isRecording && _waveController.value == 0.0)
                    Container()
                  else
                    IconButton(
                      onPressed: _saveAudio,
                      icon: const Icon(Icons.check_circle_outline_rounded, color: AppColors.primary),
                      iconSize: 32,
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
