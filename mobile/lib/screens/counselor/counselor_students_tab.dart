import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../utils/haptic_service.dart';
import 'widgets/student_clinical_modal.dart';

class CounselorStudentsTab extends StatefulWidget {
  final Map<String, dynamic>? initialStudent;
  final int initialTabIndex;

  const CounselorStudentsTab({
    super.key,
    this.initialStudent,
    this.initialTabIndex = 0,
  });

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

  @override
  void initState() {
    super.initState();
    _fetchStudents();
    if (widget.initialStudent != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showStudentDetailModal(widget.initialStudent!, initialTabIndex: widget.initialTabIndex);
      });
    }
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

  void _showStudentDetailModal(Map<String, dynamic> student, {int initialTabIndex = 0}) {
    HapticService.lightTap();
    StudentClinicalModal.show(
      context,
      student: student,
      onStatusChanged: _fetchStudents,
      initialTabIndex: initialTabIndex,
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
