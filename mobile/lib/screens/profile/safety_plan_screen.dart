import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../theme/app_theme.dart';
import '../../utils/haptic_service.dart';
import '../crisis/crisis_resources_sheet.dart';

class SafetyPlanScreen extends StatefulWidget {
  const SafetyPlanScreen({super.key});

  @override
  State<SafetyPlanScreen> createState() => _SafetyPlanScreenState();
}

class _SafetyPlanScreenState extends State<SafetyPlanScreen> {
  static const _storage = FlutterSecureStorage();
  static const String _storageKey = 'kausap_user_safety_plan';

  bool _isLoading = true;

  List<String> _warningSigns = [
    'Feeling overwhelmed or unable to focus',
    'Urge to isolate and skip social interactions',
    'Disrupted sleep patterns or severe fatigue',
  ];

  List<String> _copingStrategies = [
    '5-4-3-2-1 Grounding: Notice 5 things around me',
    '4-7-8 Breathing: Inhale 4s, hold 7s, exhale 8s',
    'Put on favorite calm playlist and step outside',
    'Drink a glass of cold water slowly',
  ];

  List<Map<String, String>> _trustedContacts = [
    {
      'name': 'FSUU Guidance Office',
      'role': 'University Counselor',
      'phone': '(085) 342-1830',
    },
    {
      'name': 'Trusted Peer / Friend',
      'role': 'Close Friend',
      'phone': '0917-000-0000',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadSafetyPlan();
  }

  Future<void> _loadSafetyPlan() async {
    try {
      final raw = await _storage.read(key: _storageKey);
      if (raw != null) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        if (data['warning_signs'] is List) {
          _warningSigns = List<String>.from(data['warning_signs']);
        }
        if (data['coping_strategies'] is List) {
          _copingStrategies = List<String>.from(data['coping_strategies']);
        }
        if (data['trusted_contacts'] is List) {
          _trustedContacts = (data['trusted_contacts'] as List)
              .map((e) => Map<String, String>.from(e as Map))
              .toList();
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveSafetyPlan() async {
    try {
      final payload = {
        'warning_signs': _warningSigns,
        'coping_strategies': _copingStrategies,
        'trusted_contacts': _trustedContacts,
        'updated_at': DateTime.now().toIso8601String(),
      };
      await _storage.write(key: _storageKey, value: jsonEncode(payload));
    } catch (_) {}
  }

  void _showAddWarningSignDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Warning Sign', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'e.g., Withdrawing from group chats',
            hintStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  _warningSigns.add(controller.text.trim());
                });
                _saveSafetyPlan();
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddCopingStrategyDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Coping Strategy', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'e.g., Taking a 10-minute walk around campus',
            hintStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  _copingStrategies.add(controller.text.trim());
                });
                _saveSafetyPlan();
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddContactDialog() {
    final nameCtrl = TextEditingController();
    final roleCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Trusted Contact', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: 'Contact Name',
                hintText: 'e.g., Mama / Guidance Counselor',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: roleCtrl,
              decoration: InputDecoration(
                labelText: 'Relationship / Role',
                hintText: 'e.g., Sister, Best Friend',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number / Social',
                hintText: 'e.g., 0917-123-4567',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                setState(() {
                  _trustedContacts.add({
                    'name': nameCtrl.text.trim(),
                    'role': roleCtrl.text.trim().isNotEmpty ? roleCtrl.text.trim() : 'Support',
                    'phone': phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : 'Contact Info',
                  });
                });
                _saveSafetyPlan();
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Save Contact'),
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
          'Safety Plan & Support',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  children: [
                    // Intro Banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withAlpha(20),
                            const Color(0xFF0284C7).withAlpha(12),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary.withAlpha(40)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(child: Text('🛡️', style: TextStyle(fontSize: 22))),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Personal Crisis Shield',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Your confidential grounding roadmap and trusted contacts to help you during difficult times.',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11.5,
                                    color: Color(0xFF475569),
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // ── 1. My Warning Signs ──────────────────────────────────
                    _buildSectionCard(
                      icon: Icons.warning_amber_rounded,
                      iconColor: const Color(0xFFF59E0B),
                      title: '1. My Warning Signs',
                      subtitle: 'Physical & mental cues that I need to slow down',
                      onAdd: _showAddWarningSignDialog,
                      children: _warningSigns.map((sign) {
                        return _buildRemovableItem(
                          text: sign,
                          onDelete: () {
                            setState(() => _warningSigns.remove(sign));
                            _saveSafetyPlan();
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // ── 2. Coping & Grounding Strategies ─────────────────────
                    _buildSectionCard(
                      icon: Icons.self_improvement_rounded,
                      iconColor: const Color(0xFF10B981),
                      title: '2. Grounding & Coping Strategies',
                      subtitle: 'Things I can do right now by myself to find calm',
                      onAdd: _showAddCopingStrategyDialog,
                      children: _copingStrategies.map((strat) {
                        return _buildRemovableItem(
                          text: strat,
                          onDelete: () {
                            setState(() => _copingStrategies.remove(strat));
                            _saveSafetyPlan();
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // ── 3. Trusted Support Contacts ──────────────────────────
                    _buildSectionCard(
                      icon: Icons.people_alt_outlined,
                      iconColor: const Color(0xFF6366F1),
                      title: '3. Trusted People I Can Talk To',
                      subtitle: 'Friends, family, and mentors who listen and care',
                      onAdd: _showAddContactDialog,
                      children: _trustedContacts.map((contact) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withAlpha(20),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(child: Icon(Icons.person_rounded, size: 18, color: AppColors.primary)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      contact['name'] ?? '',
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12.5,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    Text(
                                      '${contact['role']} • ${contact['phone']}',
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 11,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF94A3B8)),
                                onPressed: () {
                                  setState(() => _trustedContacts.remove(contact));
                                  _saveSafetyPlan();
                                },
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // ── 4. Professional Crisis Hotlines ──────────────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFECACA)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withAlpha(10),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.health_and_safety_rounded, color: Color(0xFFDC2626), size: 18),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  '4. 24/7 Professional Campus Support',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5,
                                    color: Color(0xFF991B1B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'If you are in distress or need immediate help, professional counselors are available 24/7.',
                            style: TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: Color(0xFF475569)),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                HapticService.lightTap();
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => const CrisisResourcesSheet(),
                                );
                              },
                              icon: const Icon(Icons.phone_in_talk_rounded, size: 16),
                              label: const Text('View All Hotlines & Emergency Contacts', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFDC2626),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 11),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onAdd,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 22),
                onPressed: onAdd,
                tooltip: 'Add item',
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (children.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('No items added yet. Tap "+" to add.', style: TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: Colors.grey.shade400, fontStyle: FontStyle.italic)),
            )
          else
            ...children,
        ],
      ),
    );
  }

  Widget _buildRemovableItem({required String text, required VoidCallback onDelete}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded, size: 15, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: Color(0xFF334155),
              ),
            ),
          ),
          InkWell(
            onTap: onDelete,
            borderRadius: BorderRadius.circular(12),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close_rounded, size: 14, color: Color(0xFF94A3B8)),
            ),
          ),
        ],
      ),
    );
  }
}
