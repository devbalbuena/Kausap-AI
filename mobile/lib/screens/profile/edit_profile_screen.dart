import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/cached_avatar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;

  File? _imageFile;
  String? _avatarUrl;
  late DateTime _birthday;
  late String _gender;
  bool _isSaving = false;

  final List<String> _presetAvatars = [
    'https://api.dicebear.com/7.x/notionists/png?seed=Felix&backgroundColor=e2e8f0',
    'https://api.dicebear.com/7.x/notionists/png?seed=Aneka&backgroundColor=e2e8f0',
    'https://api.dicebear.com/7.x/notionists/png?seed=Jasper&backgroundColor=e2e8f0',
    'https://api.dicebear.com/7.x/notionists/png?seed=Mia&backgroundColor=e2e8f0',
    'https://api.dicebear.com/7.x/notionists/png?seed=Leo&backgroundColor=e2e8f0',
    'https://api.dicebear.com/7.x/notionists/png?seed=Zoe&backgroundColor=e2e8f0',
  ];

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _firstNameController = TextEditingController(text: user?['first_name'] ?? '');
    _lastNameController = TextEditingController(text: user?['last_name'] ?? '');
    _emailController = TextEditingController(text: user?['email'] ?? '');

    try {
      _birthday = DateTime.parse(user?['birthday'] ?? '2000-01-01');
    } catch (_) {
      _birthday = DateTime(2000, 1, 1);
    }
    _gender = user?['gender'] ?? 'Prefer not to say';
    _avatarUrl = user?['avatar_url'];
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _showImagePickerOptions() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'Change Profile Picture',
                  style: AppTextStyles.heading2.copyWith(fontSize: 16),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                title: const Text('Take a Photo', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500)),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await _picker.pickImage(source: ImageSource.camera, maxWidth: 600, maxHeight: 600);
                  if (image != null) {
                    setState(() {
                      _imageFile = File(image.path);
                      _avatarUrl = image.path;
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                title: const Text('Choose from Gallery', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500)),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 600, maxHeight: 600);
                  if (image != null) {
                    setState(() {
                      _imageFile = File(image.path);
                      _avatarUrl = image.path;
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.face_retouching_natural_rounded, color: AppColors.primary),
                title: const Text('Choose an Avatar Illustration', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pop(context);
                  _showAvatarGrid();
                },
              ),
              if (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                  title: const Text('Remove Photo', style: TextStyle(fontFamily: 'Inter', color: AppColors.error, fontWeight: FontWeight.w500)),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _imageFile = null;
                      _avatarUrl = '';
                    });
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showAvatarGrid() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Choose an Avatar', style: AppTextStyles.heading2.copyWith(fontSize: 18)),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _presetAvatars.length,
                  itemBuilder: (context, index) {
                    final url = _presetAvatars[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _avatarUrl = url;
                          _imageFile = null;
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _avatarUrl == url ? AppColors.primary : const Color(0x33C0C9C2),
                            width: _avatarUrl == url ? 3 : 1.5,
                          ),
                        ),
                        child: CachedAvatar(
                          imageUrl: url,
                          radius: 36,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
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
              title: Text(g, style: const TextStyle(fontFamily: 'Inter')),
              trailing: _gender == g ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20) : null,
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
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final authProvider = context.read<AuthProvider>();

      // Prepare avatar representation
      String? avatarValue = _avatarUrl;
      if (_imageFile != null && _imageFile!.existsSync()) {
        final bytes = await _imageFile!.readAsBytes();
        final base64Str = base64Encode(bytes);
        final ext = _imageFile!.path.split('.').last.toLowerCase();
        final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
        avatarValue = 'data:$mime;base64,$base64Str';
      }

      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();

      await authProvider.updateProfile({
        'first_name': firstName,
        'last_name': lastName,
        'birthday': DateFormat('yyyy-MM-dd').format(_birthday),
        'gender': _gender,
        'avatar_url': avatarValue,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully! ✅'),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 2),
          ),
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
    final user = context.watch<AuthProvider>().currentUser;
    final initial = _firstNameController.text.isNotEmpty
        ? _firstNameController.text[0].toUpperCase()
        : (user?['first_name']?.isNotEmpty == true ? user!['first_name'][0].toUpperCase() : 'U');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xFF191C21)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Edit Profile',
                        style: AppTextStyles.heading2.copyWith(fontSize: 18),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                      children: [
                        const SizedBox(height: 12),

                        // Profile Image with Camera Button
                        Center(
                          child: GestureDetector(
                            onTap: _showImagePickerOptions,
                            child: Stack(
                              children: [
                                Container(
                                  width: 104,
                                  height: 104,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: _imageFile != null
                                      ? ClipOval(
                                          child: Image.file(_imageFile!, width: 104, height: 104, fit: BoxFit.cover),
                                        )
                                      : CachedAvatar(
                                          imageUrl: _avatarUrl,
                                          radius: 52,
                                          fallbackInitial: initial,
                                        ),
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.2),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),
                        Center(
                          child: TextButton(
                            onPressed: _showImagePickerOptions,
                            child: const Text('Change Photo', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Info Form Container
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // First Name
                              _buildFieldLabel('First Name'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _firstNameController,
                                style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500),
                                decoration: _buildInputDecoration(hint: 'Enter your first name'),
                                validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter first name' : null,
                              ),
                              const SizedBox(height: 16),

                              // Last Name
                              _buildFieldLabel('Last Name'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _lastNameController,
                                style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500),
                                decoration: _buildInputDecoration(hint: 'Enter your last name'),
                                validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter last name' : null,
                              ),
                              const SizedBox(height: 16),

                              // Email (Read-only)
                              _buildFieldLabel('Email Address (Cannot be changed)'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _emailController,
                                readOnly: true,
                                style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.textSecondary),
                                decoration: _buildInputDecoration(
                                  hint: 'Email',
                                  isReadOnly: true,
                                  suffixIcon: Icons.lock_outline_rounded,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Birthday Picker
                              _buildFieldLabel('Birthday'),
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: _selectDate,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9FAFB),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0x1AC0C9C2)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        DateFormat('MMMM dd, yyyy').format(_birthday),
                                        style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500),
                                      ),
                                      const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.textSecondary),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Gender Selector
                              _buildFieldLabel('Gender'),
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: _showGenderDialog,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9FAFB),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0x1AC0C9C2)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _gender,
                                        style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500),
                                      ),
                                      const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: AppColors.textSecondary),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Save Changes Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveChanges,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                  )
                                : const Text(
                                    'Save Changes',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(0xFF4B5563),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    bool isReadOnly = false,
    IconData? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary),
      filled: true,
      fillColor: isReadOnly ? const Color(0xFFF3F4F6) : const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0x1AC0C9C2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0x1AC0C9C2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      suffixIcon: suffixIcon != null ? Icon(suffixIcon, size: 18, color: AppColors.textSecondary) : null,
    );
  }
}
