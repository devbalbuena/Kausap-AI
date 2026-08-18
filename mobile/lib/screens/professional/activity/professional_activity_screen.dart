import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

enum ActivityCategory {
  all,
  screeners,
  sessions,
  crisis,
  notes,
}

class ClinicalActivityItem {
  final String id;
  final String title;
  final String description;
  final String clientName;
  final String timestamp;
  final ActivityCategory category;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String? badgeText;
  final Color? badgeColor;

  ClinicalActivityItem({
    required this.id,
    required this.title,
    required this.description,
    required this.clientName,
    required this.timestamp,
    required this.category,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    this.badgeText,
    this.badgeColor,
  });
}

class ProfessionalActivityScreen extends StatefulWidget {
  const ProfessionalActivityScreen({super.key});

  @override
  State<ProfessionalActivityScreen> createState() => _ProfessionalActivityScreenState();
}

class _ProfessionalActivityScreenState extends State<ProfessionalActivityScreen> {
  ActivityCategory _selectedCategory = ActivityCategory.all;

  final List<ClinicalActivityItem> _activities = [
    ClinicalActivityItem(
      id: 'act-01',
      title: 'PHQ-9 Screener Completed',
      description: 'Client completed 9-question depression inventory. Score: 14/27 (Moderate). Flagged for CBT reframing follow-up.',
      clientName: 'Van Balbuena',
      timestamp: 'Today at 2:30 PM',
      category: ActivityCategory.screeners,
      icon: Icons.assignment_outlined,
      iconColor: const Color(0xFFE65100),
      iconBg: const Color(0xFFFFF3E0),
      badgeText: 'PHQ-9: 14/27',
      badgeColor: const Color(0xFFE65100),
    ),
    ClinicalActivityItem(
      id: 'act-02',
      title: 'Telehealth Session Concluded',
      description: 'Completed 50-minute virtual consultation. Discussed somatic anxiety grounding and assigned 5-4-3-2-1 exercise.',
      clientName: 'Juan Dela Cruz',
      timestamp: 'Today at 11:45 AM',
      category: ActivityCategory.sessions,
      icon: Icons.videocam_outlined,
      iconColor: const Color(0xFF1565C0),
      iconBg: const Color(0xFFE3F2FD),
      badgeText: 'Completed',
      badgeColor: const Color(0xFF2E7D32),
    ),
    ClinicalActivityItem(
      id: 'act-03',
      title: 'AI Crisis Safety Protocol Triggered',
      description: 'Automated triage detected acute distress keywords during evening AI chat. Safety coping plan activated and logged for therapist review.',
      clientName: 'Maria Santos',
      timestamp: 'Yesterday at 9:15 PM',
      category: ActivityCategory.crisis,
      icon: Icons.warning_amber_rounded,
      iconColor: const Color(0xFFC62828),
      iconBg: const Color(0xFFFFEBEE),
      badgeText: 'Safety Plan',
      badgeColor: const Color(0xFFC62828),
    ),
    ClinicalActivityItem(
      id: 'act-04',
      title: 'Clinical Progress Note Recorded',
      description: 'Progress note added under Section 4 (Mental Health Act RA 11036 compliance). Sleep regularity improving.',
      clientName: 'Sai Usa',
      timestamp: 'Aug 16, 2026 at 4:10 PM',
      category: ActivityCategory.notes,
      icon: Icons.note_alt_outlined,
      iconColor: const Color(0xFF2E7D32),
      iconBg: const Color(0xFFE8F5E9),
      badgeText: 'Audit Logged',
      badgeColor: const Color(0xFF1565C0),
    ),
    ClinicalActivityItem(
      id: 'act-05',
      title: 'GAD-7 Anxiety Screener Logged',
      description: 'Client completed GAD-7 assessment. Total score: 8/21 (Mild Anxiety). Situational exam worry noted.',
      clientName: 'Juan Dela Cruz',
      timestamp: 'Aug 15, 2026 at 1:20 PM',
      category: ActivityCategory.screeners,
      icon: Icons.psychology_outlined,
      iconColor: const Color(0xFF1565C0),
      iconBg: const Color(0xFFE3F2FD),
      badgeText: 'GAD-7: 8/21',
      badgeColor: const Color(0xFF1565C0),
    ),
  ];

  List<ClinicalActivityItem> get _filteredActivities {
    if (_selectedCategory == ActivityCategory.all) return _activities;
    return _activities.where((a) => a.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        title: const Text("Clinical Activity & Audit Trail", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF2C3E50))),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF2C3E50)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Category Filter Bar ──────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip("All Events", ActivityCategory.all),
                  const SizedBox(width: 8),
                  _buildFilterChip("Screeners", ActivityCategory.screeners),
                  const SizedBox(width: 8),
                  _buildFilterChip("Sessions", ActivityCategory.sessions),
                  const SizedBox(width: 8),
                  _buildFilterChip("Crisis Flags", ActivityCategory.crisis),
                  const SizedBox(width: 8),
                  _buildFilterChip("Case Notes", ActivityCategory.notes),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ── Timeline List ────────────────────────────────────────────────
          Expanded(
            child: _filteredActivities.isEmpty
                ? const Center(
                    child: Text("No clinical activity logged in this category.", style: TextStyle(color: Color(0xFF707974))),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                    itemCount: _filteredActivities.length,
                    itemBuilder: (context, index) {
                      final item = _filteredActivities[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE8EAED)),
                          boxShadow: const [
                            BoxShadow(color: Color(0x04000000), blurRadius: 8, offset: Offset(0, 2)),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: item.iconBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(item.icon, color: item.iconColor, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.title,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2C3E50)),
                                        ),
                                      ),
                                      if (item.badgeText != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: (item.badgeColor ?? AppColors.primary).withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            item.badgeText!,
                                            style: TextStyle(
                                              color: item.badgeColor ?? AppColors.primary,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Patient: ${item.clientName} • ${item.timestamp}",
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF707974), fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    item.description,
                                    style: const TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF4A5568)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, ActivityCategory cat) {
    final isSelected = _selectedCategory == cat;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _selectedCategory = cat);
      },
      selectedColor: AppColors.primary,
      backgroundColor: const Color(0xFFF1F5F9),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF555F6D),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide.none,
      ),
    );
  }
}
