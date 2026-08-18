import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_client.dart';
import 'admin_dashboard_screen.dart';
import 'admin_moderation_screen.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<dynamic> _users = [];
  String? _error;

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  String _clientFilter = 'all';
  String _profFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await ApiClient().get('/admin/users?limit=200');
      if (mounted) {
        setState(() {
          _users = data as List<dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load users';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _verifyProfessional(String userId, String name) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verify Professional License', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text('Are you sure you want to verify the clinical practice license for $name?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF707974))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Verify & Approve', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ApiClient().patch('/admin/users/$userId/verify', body: {});
      _fetchUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name has been verified as a licensed professional!'), backgroundColor: AppColors.primary),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification failed.'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _toggleUserStatus(String userId, String name, bool currentStatus) async {
    final bool nextStatus = !currentStatus;
    final String actionText = nextStatus ? "Reactivate" : "Deactivate";

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$actionText Account', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text('Are you sure you want to $actionText the account for $name?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF707974))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: nextStatus ? const Color(0xFF10B981) : const Color(0xFFC62828),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(actionText, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ApiClient().patch('/admin/users/$userId/status', body: {'is_active': nextStatus});
      _fetchUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name account has been ${nextStatus ? "reactivated" : "deactivated"}.'),
            backgroundColor: nextStatus ? const Color(0xFF10B981) : const Color(0xFFC62828),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status update failed.'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showUserDetailsModal(Map<String, dynamic> user) {
    final name = user['full_name'] ?? 'User';
    final email = user['email'] ?? '';
    final role = (user['role'] ?? 'client').toString().toUpperCase();
    final bool isActive = user['is_active'] != false;
    final bool isVerified = user['is_verified'] == true;
    final moodCount = user['mood_entries_count'] ?? 0;
    final chatCount = user['chat_sessions_count'] ?? 0;
    final createdAt = user['created_at']?.toString().split('T')[0] ?? 'Recently';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: const Color(0xFFD6F1FC),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'U',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2C3E50))),
                        Text(email, style: const TextStyle(fontSize: 12, color: Color(0xFF707974))),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      isActive ? "Active" : "Inactive",
                      style: TextStyle(
                        color: isActive ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(height: 1, color: Color(0xFFF1F3F4)),
              const SizedBox(height: 16),

              // Account Details Info
              const Text("Account Overview", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2C3E50))),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE8EAED)),
                ),
                child: Column(
                  children: [
                    _buildDetailRow("Role", role),
                    const SizedBox(height: 8),
                    _buildDetailRow("Registration Date", createdAt),
                    const SizedBox(height: 8),
                    _buildDetailRow("AI Chat Sessions", "$chatCount sessions"),
                    const SizedBox(height: 8),
                    _buildDetailRow("Mood Check-ins", "$moodCount entries"),
                    if (role == 'PROFESSIONAL') ...[
                      const SizedBox(height: 8),
                      _buildDetailRow("Licensure Verification", isVerified ? "Verified Specialist ✓" : "Pending Verification ⏳"),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Modal Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _toggleUserStatus(user['id'], name, isActive);
                      },
                      icon: Icon(isActive ? Icons.block_rounded : Icons.check_circle_outline, size: 16),
                      label: Text(isActive ? "Deactivate User" : "Activate User"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isActive ? const Color(0xFFC62828) : const Color(0xFF10B981),
                        side: BorderSide(color: isActive ? const Color(0xFFFFCDD2) : const Color(0xFFA7F3D0)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  if (role == 'PROFESSIONAL' && !isVerified) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _verifyProfessional(user['id'], name);
                        },
                        icon: const Icon(Icons.verified_rounded, size: 16),
                        label: const Text("Verify License"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF707974))),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
      ],
    );
  }

  List<dynamic> _filterList(List<dynamic> list, bool isProf) {
    var result = list;

    // Search query filter
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((u) {
        final name = (u['full_name'] ?? '').toString().toLowerCase();
        final email = (u['email'] ?? '').toString().toLowerCase();
        return name.contains(q) || email.contains(q);
      }).toList();
    }

    // Chip filter
    if (isProf) {
      if (_profFilter == 'pending') {
        result = result.where((u) => u['is_verified'] != true).toList();
      } else if (_profFilter == 'verified') {
        result = result.where((u) => u['is_verified'] == true).toList();
      }
    } else {
      if (_clientFilter == 'active') {
        result = result.where((u) => u['is_active'] != false).toList();
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final allClients = _users.where((u) => u['role'] == 'client').toList();
    final allProfessionals = _users.where((u) => u['role'] == 'professional').toList();

    final filteredClients = _filterList(allClients, false);
    final filteredProfessionals = _filterList(allProfessionals, true);

    final pendingProfCount = allProfessionals.where((u) => u['is_verified'] != true).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFD6F1FC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.people_alt_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('User Directory', style: AppTextStyles.heading2.copyWith(fontSize: 16, color: const Color(0xFF2C3E50), fontWeight: FontWeight.bold)),
                Text('${_users.length} Total Registered Accounts', style: const TextStyle(fontSize: 11, color: Color(0xFF707974))),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(108),
          child: Column(
            children: [
              // ── Search Field ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE8EAED)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, color: Color(0xFF707974), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: "Search by name or email (e.g. Van, dr.smith)...",
                            hintStyle: TextStyle(color: Color(0xFF9E9E9E), fontSize: 12),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          onChanged: (val) => setState(() => _searchQuery = val),
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF707974), size: 16),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // ── Tab Bar ───────────────────────────────────────────────────
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: const Color(0xFF707974),
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: [
                  Tab(text: 'Clients (${allClients.length})'),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Professionals (${allProfessionals.length})'),
                        if (pendingProfCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xFFF97316), borderRadius: BorderRadius.circular(10)),
                            child: Text('$pendingProfCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!, style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _fetchUsers, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildClientsTab(filteredClients),
                    _buildProfessionalsTab(filteredProfessionals),
                  ],
                ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── Clients Tab ────────────────────────────────────────────────────────────
  Widget _buildClientsTab(List<dynamic> clients) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              _buildFilterChip("All Clients", _clientFilter == 'all', () => setState(() => _clientFilter = 'all')),
              const SizedBox(width: 8),
              _buildFilterChip("Active Only", _clientFilter == 'active', () => setState(() => _clientFilter = 'active')),
            ],
          ),
        ),
        Expanded(
          child: clients.isEmpty
              ? const Center(child: Text('No client accounts match criteria.', style: TextStyle(color: Color(0xFF707974))))
              : RefreshIndicator(
                  onRefresh: _fetchUsers,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: clients.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => _buildUserCard(clients[index], false),
                  ),
                ),
        ),
      ],
    );
  }

  // ── Professionals Tab ──────────────────────────────────────────────────────
  Widget _buildProfessionalsTab(List<dynamic> professionals) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              _buildFilterChip("All Therapists", _profFilter == 'all', () => setState(() => _profFilter = 'all')),
              const SizedBox(width: 8),
              _buildFilterChip("Pending Verification", _profFilter == 'pending', () => setState(() => _profFilter = 'pending')),
              const SizedBox(width: 8),
              _buildFilterChip("Verified", _profFilter == 'verified', () => setState(() => _profFilter = 'verified')),
            ],
          ),
        ),
        Expanded(
          child: professionals.isEmpty
              ? const Center(child: Text('No professional accounts match criteria.', style: TextStyle(color: Color(0xFF707974))))
              : RefreshIndicator(
                  onRefresh: _fetchUsers,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: professionals.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => _buildUserCard(professionals[index], true),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onSelected) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: AppColors.primary,
      backgroundColor: const Color(0xFFF1F5F9),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF555F6D),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        fontSize: 11,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
    );
  }

  // ── User Card ──────────────────────────────────────────────────────────────
  Widget _buildUserCard(dynamic user, bool isProfessionalList) {
    final name = user['full_name'] ?? 'Unknown';
    final email = user['email'] ?? '';
    final bool isVerified = user['is_verified'] == true;
    final bool isActive = user['is_active'] != false;
    final moodCount = user['mood_entries_count'] ?? 0;
    final chatCount = user['chat_sessions_count'] ?? 0;
    final joinDate = user['created_at'] != null ? user['created_at'].toString().split('T')[0] : '2026-08-16';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EAED)),
        boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFFD6F1FC),
                    radius: 22,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2C3E50)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isProfessionalList) ...[
                          if (isVerified)
                            const Row(
                              children: [
                                Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 16),
                                SizedBox(width: 2),
                                Text("Verified", style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(6)),
                              child: const Text("Pending Review", style: TextStyle(color: Color(0xFFF97316), fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(email, style: const TextStyle(fontSize: 12, color: Color(0xFF707974))),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text("Joined: $joinDate", style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
                        const Spacer(),
                        Text("💬 $chatCount  •  📈 $moodCount", style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF1F3F4)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showUserDetailsModal(user),
                icon: const Icon(Icons.info_outline_rounded, size: 14),
                label: const Text("Details", style: TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF555F6D),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                ),
              ),
              if (isProfessionalList && !isVerified) ...[
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _verifyProfessional(user['id'], name),
                  icon: const Icon(Icons.verified_rounded, size: 14),
                  label: const Text("Verify License", style: TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ── Bottom Navigation ──────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      height: 65,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.dashboard_rounded, 'Dashboard', false, () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
            );
          }),
          _buildNavItem(Icons.people_alt_rounded, 'Users', true, null),
          _buildNavItem(Icons.flag_rounded, 'Moderation', false, () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const AdminModerationScreen()),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected, VoidCallback? onTap) {
    final color = isSelected ? AppColors.primary : const Color(0xFF707974);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
