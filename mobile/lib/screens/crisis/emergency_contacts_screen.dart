import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../utils/haptic_service.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  final _storage = const FlutterSecureStorage();
  List<Map<String, String>> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    try {
      final raw = await _storage.read(key: 'emergency_contacts');
      if (raw != null && raw.isNotEmpty) {
        final decoded = json.decode(raw) as List<dynamic>;
        _contacts = decoded.map((e) => Map<String, String>.from(e as Map)).toList();
      }
    } catch (e) {
      debugPrint('Error loading emergency contacts: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveContacts() async {
    try {
      await _storage.write(key: 'emergency_contacts', value: json.encode(_contacts));
    } catch (e) {
      debugPrint('Error saving emergency contacts: $e');
    }
  }

  Future<void> _callContact(Map<String, String> contact) async {
    final name = contact['name'] ?? 'Emergency Contact';
    final rawPhone = contact['phone'] ?? '';
    final cleanPhone = rawPhone.replaceAll(RegExp(r'[^0-9+]'), '');

    if (cleanPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Invalid phone number for this contact.'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    HapticService.heavyTap();

    // Copy to clipboard as universal fallback
    await Clipboard.setData(ClipboardData(text: cleanPhone));

    final Uri phoneUri = Uri(scheme: 'tel', path: cleanPhone);
    bool launched = false;

    try {
      if (await canLaunchUrl(phoneUri)) {
        launched = await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}

    // Fallback if mode not supported
    if (!launched) {
      try {
        await launchUrl(phoneUri);
        launched = true;
      } catch (_) {}
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Dialing $name ($rawPhone)...',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showContactDialog({int? editIndex}) {
    HapticService.lightTap();
    final isEditing = editIndex != null;
    final existing = isEditing ? _contacts[editIndex] : null;

    final nameCtrl = TextEditingController(text: existing?['name'] ?? '');
    final phoneCtrl = TextEditingController(text: existing?['phone'] ?? '');
    final relationCtrl = TextEditingController(text: existing?['relation'] ?? '');
    String selectedRelation = existing?['relation'] ?? '';
    String? errorText;

    final presetRelations = ['Parent', 'Sibling', 'Best Friend', 'Therapist', 'Counselor', 'Partner'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isEditing ? Icons.edit_note_rounded : Icons.person_add_alt_1_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isEditing ? 'Edit Contact' : 'Add Emergency Contact',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing
                      ? 'Update the contact information for your trusted supporter.'
                      : 'Add someone you trust completely to reach out to during overwhelming moments.',
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF64748B), height: 1.35),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Full Name *',
                    hintText: 'e.g. Mama, Kuya Marcus, Dr. Lee',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Phone Number *',
                    hintText: 'e.g. 0917-123-4567 or +63 917...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Relationship (Quick select):',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: presetRelations.map((tag) {
                    final isSelected = selectedRelation.toLowerCase() == tag.toLowerCase();
                    return ChoiceChip(
                      label: Text(tag),
                      selected: isSelected,
                      labelStyle: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : const Color(0xFF475569),
                      ),
                      selectedColor: AppColors.primary,
                      backgroundColor: const Color(0xFFF1F5F9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      onSelected: (val) {
                        setDialogState(() {
                          selectedRelation = val ? tag : '';
                          relationCtrl.text = selectedRelation;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: relationCtrl,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: 'Custom Relationship',
                    hintText: 'e.g. Dorm Roommate, Aunt',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    prefixIcon: const Icon(Icons.group_outlined, color: AppColors.primary),
                  ),
                  onChanged: (val) {
                    if (selectedRelation != val) {
                      setDialogState(() => selectedRelation = '');
                    }
                  },
                ),
                if (errorText != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    errorText!,
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Colors.red, fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(fontFamily: 'Poppins', color: Color(0xFF64748B))),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final phone = phoneCtrl.text.trim();
                final relation = relationCtrl.text.trim();

                if (name.isEmpty || phone.isEmpty) {
                  setDialogState(() {
                    errorText = 'Please provide both Name and Phone Number.';
                  });
                  return;
                }

                final messenger = ScaffoldMessenger.of(context);
                setState(() {
                  if (isEditing) {
                    _contacts[editIndex] = {'name': name, 'phone': phone, 'relation': relation};
                  } else {
                    _contacts.add({'name': name, 'phone': phone, 'relation': relation});
                  }
                });
                await _saveContacts();

                if (ctx.mounted) Navigator.pop(ctx);

                if (mounted) {
                  HapticService.mediumTap();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(isEditing ? 'Updated $name.' : 'Saved $name to trusted contacts.'),
                      backgroundColor: const Color(0xFF059669),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              },
              icon: Icon(isEditing ? Icons.save_rounded : Icons.check_rounded, size: 18),
              label: Text(
                isEditing ? 'Save Changes' : 'Save Contact',
                style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteContact(int index) {
    final contact = _contacts[index];
    final name = contact['name'] ?? 'this contact';

    HapticService.lightTap();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 24),
            SizedBox(width: 8),
            Text(
              'Remove Contact',
              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to remove "$name" from your trusted emergency contacts?',
          style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(fontFamily: 'Poppins', color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final deleted = _contacts[index];
              setState(() {
                _contacts.removeAt(index);
              });
              await _saveContacts();

              if (mounted) {
                HapticService.mediumTap();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Removed ${deleted['name']} from emergency contacts.'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    action: SnackBarAction(
                      label: 'Undo',
                      textColor: const Color(0xFF38BDF8),
                      onPressed: () async {
                        setState(() {
                          _contacts.insert(index, deleted);
                        });
                        await _saveContacts();
                      },
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Emergency Contacts',
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
        // Header button removed to eliminate UI clutter
        actions: const [],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _contacts.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
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
                            child: const Icon(Icons.contact_phone_outlined, size: 46, color: AppColors.primary),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'No emergency contacts saved yet',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Save trusted family members, friends, or counselors here. You can call them with one tap during times of distress.',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: Color(0xFF64748B),
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
                    itemCount: _contacts.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final contact = _contacts[index];
                      final name = contact['name'] ?? '';
                      final phone = contact['phone'] ?? '';
                      final relation = contact['relation'] ?? '';
                      final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: const [
                            BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 3)),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(18),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () => _callContact(contact),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  // Contact Initial Avatar
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: AppColors.primary.withAlpha(25),
                                    child: Text(
                                      initial,
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  // Name, Phone & Relation
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                name,
                                                style: const TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 15,
                                                  color: Color(0xFF0F172A),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (relation.isNotEmpty) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFEEF2FF),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  relation,
                                                  style: const TextStyle(
                                                    fontFamily: 'Inter',
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    color: Color(0xFF4F46E5),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.phone_outlined, size: 13, color: Color(0xFF059669)),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                phone,
                                                style: const TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF059669),
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),

                                  // 1. Direct Call Button
                                  IconButton.filled(
                                    icon: const Icon(Icons.call_rounded, size: 18),
                                    style: IconButton.styleFrom(
                                      backgroundColor: const Color(0xFF059669),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.all(9),
                                      minimumSize: const Size(36, 36),
                                    ),
                                    tooltip: 'Call $name',
                                    onPressed: () => _callContact(contact),
                                  ),

                                  // 2. Edit Contact Button
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: Color(0xFF64748B), size: 19),
                                    tooltip: 'Edit $name',
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () => _showContactDialog(editIndex: index),
                                  ),

                                  // 3. Delete Contact Button
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 19),
                                    tooltip: 'Remove $name',
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () => _confirmDeleteContact(index),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showContactDialog(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text(
          'Add Contact',
          style: TextStyle(fontFamily: 'Poppins', color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
