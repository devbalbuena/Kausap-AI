import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../utils/haptic_service.dart';

class CounselorStudentsTab extends StatefulWidget {
  const CounselorStudentsTab({super.key});

  @override
  State<CounselorStudentsTab> createState() => _CounselorStudentsTabState();
}

class _CounselorStudentsTabState extends State<CounselorStudentsTab> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  List<dynamic> _students = [];
  String? _error;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  String _filter = 'all'; // 'all', 'active', 'deactivated', 'appeals'

  final List<String> _deactivationReasonPresets = [
    "Temporary wellness leave requested by student",
    "Account locked pending guidance office consultation",
    "Student graduated or transferred from FSUU",
    "Administrative clinical review in progress",
  ];

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchStudents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await _api.get('/admin/users?limit=200');
      if (mounted) {
        final allUsers = res is List ? res : [];
        // Filter strictly to students (clients)
        final clients = allUsers.where((u) {
          final role = (u['role'] ?? 'client').toString().toLowerCase();
          return role == 'client';
        }).toList();

        setState(() {
          _students = clients;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load student care records: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _showStudentDetailModal(Map<String, dynamic> student) {
    final studentId = student['id'];
    final name = student['full_name'] ?? 'Student';
    final email = student['email'] ?? '';
    final isActive = student['is_active'] != false;
    final moodCount = student['mood_entries_count'] ?? 0;
    final chatCount = student['chat_sessions_count'] ?? 0;
    final flagCount = student['flagged_messages_count'] ?? 0;
    final appeal = student['reactivation_appeal'];
    final deactivationReason = student['deactivation_reason'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: const Color(0xFFE0F2FE),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'S',
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF0284C7)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          email,
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isActive ? "Active" : "Deactivated",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isActive ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Engagement Stats ──
              Row(
                children: [
                  Expanded(
                    child: _buildModalStatTile("Mood Logs", "$moodCount", Icons.mood_rounded, const Color(0xFF0284C7), const Color(0xFFE0F2FE)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildModalStatTile("Chat Sessions", "$chatCount", Icons.forum_rounded, const Color(0xFF7C3AED), const Color(0xFFEDE9FE)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildModalStatTile("Crisis Flags", "$flagCount", Icons.emergency_rounded, flagCount > 0 ? const Color(0xFFDC2626) : const Color(0xFF16A34A), flagCount > 0 ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7)),
                  ),
                ],
              ),

              if (deactivationReason != null && deactivationReason.toString().isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: Color(0xFFDC2626), size: 16),
                          SizedBox(width: 6),
                          Text("Counselor Deactivation Reason:", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF991B1B))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(deactivationReason, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFFB91C1C))),
                    ],
                  ),
                ),
              ],

              if (appeal != null && appeal.toString().isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.mark_email_unread_outlined, color: Color(0xFFD97706), size: 16),
                          SizedBox(width: 6),
                          Text("Student Reactivation Appeal:", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF92400E))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(appeal, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF78350F))),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          _approveAppeal(studentId, name);
                        },
                        icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        label: const Text("Approve & Restore Account", style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // ── Action Buttons ──
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _toggleStudentStatus(student);
                      },
                      icon: Icon(isActive ? Icons.block_rounded : Icons.check_circle_outline_rounded, size: 16),
                      label: Text(isActive ? "Deactivate Student" : "Activate Student", style: const TextStyle(fontFamily: 'Poppins', fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isActive ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                        side: BorderSide(color: isActive ? const Color(0xFFFCA5A5) : const Color(0xFF86EFAC)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _approveAppeal(String studentId, String name) async {
    try {
      HapticService.lightTap();
      await _api.patch(
        '/admin/users/$studentId/reactivate',
        body: {'status': 'active'},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Reactivation appeal approved for $name."),
          backgroundColor: const Color(0xFF16A34A),
        ),
      );
      _fetchStudents();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to approve appeal: $e"),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  Future<void> _toggleStudentStatus(Map<String, dynamic> student) async {
    final studentId = student['id'];
    final currentStatus = student['is_active'] != false;
    final newStatus = !currentStatus;
    final reasonCtrl = TextEditingController(text: _deactivationReasonPresets[0]);
    String selectedPreset = _deactivationReasonPresets[0];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(
            newStatus ? "Reactivate Student Account" : "Deactivate Student Account",
            style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  newStatus
                      ? "Restore platform access for ${student['full_name']}?"
                      : "Document the counselor reason for deactivating ${student['full_name']}:",
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF64748B)),
                ),
                if (!newStatus) ...[
                  const SizedBox(height: 12),
                  const Text(
                    "Standard Counselor Reasons:",
                    style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 11.5, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _deactivationReasonPresets.map((preset) {
                      final isSelected = selectedPreset == preset;
                      return InkWell(
                        onTap: () {
                          setDialogState(() {
                            selectedPreset = preset;
                            reasonCtrl.text = preset;
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFFEE2E2) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isSelected ? const Color(0xFFDC2626) : const Color(0xFFE2E8F0)),
                          ),
                          child: Text(
                            preset,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: isSelected ? const Color(0xFFDC2626) : const Color(0xFF475569),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: "Custom Counselor Reason *",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: newStatus ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              child: Text(newStatus ? "Reactivate" : "Deactivate"),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      HapticService.lightTap();
      await _api.patch(
        '/admin/users/$studentId/status',
        body: {
          'is_active': newStatus,
          'reason': reasonCtrl.text.trim(),
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Student ${student['full_name']} is now ${newStatus ? 'active' : 'deactivated'}."),
          backgroundColor: newStatus ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
        ),
      );
      _fetchStudents();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error updating student status: $e"),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  Widget _buildModalStatTile(String label, String count, IconData icon, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(count, style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16, color: color)),
          Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 10.5, color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _students.where((s) {
      if (_filter == 'active' && s['is_active'] == false) return false;
      if (_filter == 'deactivated' && s['is_active'] != false) return false;
      if (_filter == 'appeals' && (s['reactivation_appeal'] == null || s['reactivation_appeal'].toString().isEmpty)) return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final name = (s['full_name'] ?? '').toString().toLowerCase();
        final email = (s['email'] ?? '').toString().toLowerCase();
        return name.contains(q) || email.contains(q);
      }
      return true;
    }).toList();

    return Column(
      children: [
        // ── Search & Filter Row ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.white,
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: "Search student by name or email...",
                  hintStyle: const TextStyle(fontFamily: 'Inter', fontSize: 12.5, color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip("all", "All Students (${_students.length})"),
                    const SizedBox(width: 8),
                    _buildFilterChip("active", "Active"),
                    const SizedBox(width: 8),
                    _buildFilterChip("deactivated", "Deactivated"),
                    const SizedBox(width: 8),
                    _buildFilterChip("appeals", "Appeals Pending"),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── List View ──
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)))
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 40),
                          const SizedBox(height: 10),
                          Text(_error!, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: _fetchStudents,
                            child: const Text("Retry"),
                          ),
                        ],
                      ),
                    )
                  : filtered.isEmpty
                      ? const Center(
                          child: Text("No students found matching your criteria.", style: TextStyle(fontFamily: 'Inter', color: Color(0xFF64748B))),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchStudents,
                          color: const Color(0xFF0284C7),
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 10),
                            itemBuilder: (ctx, i) {
                              final s = filtered[i];
                              final isActive = s['is_active'] != false;
                              final hasAppeal = s['reactivation_appeal'] != null && s['reactivation_appeal'].toString().isNotEmpty;

                              return InkWell(
                                onTap: () => _showStudentDetailModal(s),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                    boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 1))],
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: const Color(0xFFE0F2FE),
                                        child: Text(
                                          (s['full_name'] ?? 'S')[0].toUpperCase(),
                                          style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: Color(0xFF0284C7)),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    s['full_name'] ?? 'Student',
                                                    style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13.5, color: Color(0xFF0F172A)),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (hasAppeal) ...[
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                                    decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(6)),
                                                    child: const Text("Appeal", style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFD97706))),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            Text(
                                              s['email'] ?? '',
                                              style: const TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: Color(0xFF64748B)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isActive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          isActive ? "Active" : "Inactive",
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w700,
                                            color: isActive ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 18),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final selected = _filter == key;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (val) {
        if (val) setState(() => _filter = key);
      },
      selectedColor: const Color(0xFFE0F2FE),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 11.5,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: selected ? const Color(0xFF0284C7) : const Color(0xFF64748B),
      ),
      side: BorderSide(color: selected ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0)),
    );
  }
}
