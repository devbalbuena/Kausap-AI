import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  
  late String _firstName;
  late String _lastName;
  late String _email;
  late DateTime _birthday;
  late String _gender;
  
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _firstName = user?['first_name'] ?? 'John';
    _lastName = user?['last_name'] ?? 'Doe';
    _email = user?['email'] ?? 'john.doe@example.com';
    try {
      _birthday = DateTime.parse(user?['birthday'] ?? '2000-01-01');
    } catch (e) {
      _birthday = DateTime(2000, 1, 1);
    }
    _gender = user?['gender'] ?? 'Prefer not to say';
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  void _showEditDialog(String title, String initialValue, Function(String) onSave) {
    final TextEditingController controller = TextEditingController(text: initialValue);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Edit $title', style: AppTextStyles.heading2.copyWith(fontSize: 18)),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Enter $title',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                onSave(controller.text.trim());
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthday,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _birthday) {
      setState(() {
        _birthday = picked;
      });
    }
  }

  void _showGenderDialog() {
    final genders = ['Male', 'Female', 'Non-binary', 'Prefer not to say', 'Other'];
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Select Gender', style: AppTextStyles.heading2.copyWith(fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: genders.map((g) => ListTile(
              title: Text(g),
              onTap: () {
                setState(() {
                  _gender = g;
                });
                Navigator.pop(context);
              },
            )).toList(),
          ),
        );
      },
    );
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.updateProfile({
        'first_name': _firstName,
        'last_name': _lastName,
        'birthday': DateFormat('yyyy-MM-dd').format(_birthday),
        'gender': _gender,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.chevron_left_rounded, size: 28, color: AppColors.textPrimary),
                      ),
                      const Expanded(
                        child: Text(
                          'Profile',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: 22,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 28), // Balance for back button
                    ],
                  ),
                ),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: [
                      const SizedBox(height: 16),
                      // Profile Image
                      Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(10),
                                      blurRadius: 10,
                                    )
                                  ],
                                  image: DecorationImage(
                                    image: _imageFile != null
                                        ? FileImage(_imageFile!)
                                        : const NetworkImage('https://i.pravatar.cc/150?img=11') as ImageProvider,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(20),
                                        blurRadius: 10,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.camera_alt_rounded, size: 16, color: AppColors.primary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Settings Container
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x140078D4),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildItem(
                              title: 'First Name',
                              value: _firstName,
                              onTap: () => _showEditDialog('First Name', _firstName, (val) => setState(() => _firstName = val)),
                            ),
                            _buildDivider(),
                            _buildItem(
                              title: 'Last Name',
                              value: _lastName,
                              onTap: () => _showEditDialog('Last Name', _lastName, (val) => setState(() => _lastName = val)),
                            ),
                            _buildDivider(),
                            _buildItem(
                              title: 'Email',
                              value: _email,
                              onTap: () {}, // Make email read-only for now
                              isReadOnly: true,
                            ),
                            _buildDivider(),
                            _buildItem(
                              title: 'Birthday',
                              value: DateFormat('MMMM dd, yyyy').format(_birthday),
                              onTap: _selectDate,
                            ),
                            _buildDivider(),
                            _buildItem(
                              title: 'Gender',
                              value: _gender,
                              onTap: _showGenderDialog,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Save Changes Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveChanges,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366f1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            elevation: 0,
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text(
                                  'Save Changes',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItem({required String title, required String value, required VoidCallback onTap, bool isReadOnly = false}) {
    return InkWell(
      onTap: isReadOnly ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w400,
                fontSize: 14,
                color: isReadOnly ? AppColors.textSecondary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: const Color(0x4DC0C9C2),
      margin: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}
