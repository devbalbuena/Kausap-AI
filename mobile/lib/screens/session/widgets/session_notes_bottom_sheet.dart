import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../theme/app_theme.dart';

class SessionNotesBottomSheet extends StatefulWidget {
  final String sessionId;
  final String professionalName;

  const SessionNotesBottomSheet({
    super.key,
    required this.sessionId,
    required this.professionalName,
  });

  @override
  State<SessionNotesBottomSheet> createState() => _SessionNotesBottomSheetState();
}

class _SessionNotesBottomSheetState extends State<SessionNotesBottomSheet> {
  final TextEditingController _notesController = TextEditingController();
  final _storage = const FlutterSecureStorage();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final savedNotes = await _storage.read(key: 'notes_${widget.sessionId}');
    if (mounted) {
      setState(() {
        if (savedNotes != null) {
          _notesController.text = savedNotes;
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _saveNotes() async {
    setState(() {
      _isSaving = true;
    });
    
    await _storage.write(key: 'notes_${widget.sessionId}', value: _notesController.text);
    
    if (mounted) {
      setState(() {
        _isSaving = false;
      });
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Private session notes saved.')),
      );
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Private Notes',
                    style: AppTextStyles.heading2.copyWith(fontSize: 20),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Session with ${widget.professionalName}',
                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                TextField(
                  controller: _notesController,
                  maxLines: 6,
                  decoration: InputDecoration(
                    hintText: 'Write down your personal reflections, key takeaways, or things you want to remember from this session...',
                    hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                    filled: true,
                    fillColor: const Color(0xFFF3F4F6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveNotes,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save Notes', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
