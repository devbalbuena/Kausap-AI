import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../services/api_client.dart';
import '../../utils/haptic_service.dart';

class AdminCounselorsScreen extends StatefulWidget {
  const AdminCounselorsScreen({super.key});

  @override
  State<AdminCounselorsScreen> createState() => _AdminCounselorsScreenState();
}

class _AdminCounselorsScreenState extends State<AdminCounselorsScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  List<dynamic> _counselors = [];
  String? _error;
  String _searchQuery = '';
  String _activeFilter = 'all'; // 'all', 'active', 'inactive'
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCounselors();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCounselors() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await _api.get('/admin/counselors');
      if (mounted) {
        setState(() {
          _counselors = res is List ? res : [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load counselor workforce records';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleCounselorStatus(Map<String, dynamic> counselor) async {
    final counselorId = counselor['id'];
    final currentStatus = counselor['is_active'] == true;
    final newStatus = !currentStatus;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Icon(
              newStatus ? Icons.check_circle_outline_rounded : Icons.block_rounded,
              color: newStatus ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              newStatus ? "Activate Counselor" : "Deactivate Counselor",
              style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ],
        ),
        content: Text(
          newStatus
              ? "Are you sure you want to restore access for ${counselor['full_name']} (${counselor['email']})?"
              : "Are you sure you want to temporarily revoke guidance portal access for ${counselor['full_name']} (${counselor['email']})?",
          style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel", style: TextStyle(fontFamily: 'Poppins', color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              newStatus ? "Activate" : "Deactivate",
              style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      HapticService.lightTap();
      await _api.patch(
        '/admin/counselors/$counselorId/status',
        body: {'is_active': newStatus},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Counselor ${counselor['full_name']} is now ${newStatus ? 'active' : 'inactive'}.",
              style: const TextStyle(fontFamily: 'Inter'),
            ),
            backgroundColor: newStatus ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
          ),
        );
        _fetchCounselors();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error updating status: $e", style: const TextStyle(fontFamily: 'Inter')),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  void _showResetPasswordModal(Map<String, dynamic> counselor) {
    final passwordController = TextEditingController();
    bool obscure = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Reset Counselor Password",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                "Issue a new temporary password for ${counselor['full_name']} (${counselor['email']}).",
                style: const TextStyle(fontFamily: 'Inter', fontSize: 12.5, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: obscure,
                decoration: InputDecoration(
                  labelText: "New Temporary Password",
                  hintText: "Minimum 8 characters",
                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF0284C7)),
                  suffixIcon: IconButton(
                    icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF94A3B8)),
                    onPressed: () => setModalState(() => obscure = !obscure),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final pw = passwordController.text.trim();
                        if (pw.isNotEmpty) {
                          Clipboard.setData(ClipboardData(text: pw));
                          HapticService.lightTap();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Password copied to clipboard! 📋"), backgroundColor: Color(0xFF0284C7)),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text("Copy Password", style: TextStyle(fontFamily: 'Poppins', fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0284C7),
                        side: const BorderSide(color: Color(0xFFBAE6FD)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () async {
                        final newPw = passwordController.text.trim();
                        if (newPw.length < 8) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Password must be at least 8 characters long."),
                              backgroundColor: Color(0xFFDC2626),
                            ),
                          );
                          return;
                        }
                        Navigator.pop(ctx);
                        try {
                          HapticService.lightTap();
                          await _api.post(
                            '/admin/counselors/${counselor['id']}/reset-password',
                            body: {'new_password': newPw},
                          );
                          if (!mounted) return;
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Text("Password reset successfully for ${counselor['email']}."),
                              backgroundColor: const Color(0xFF16A34A),
                            ),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Text("Failed to reset password: $e"),
                              backgroundColor: const Color(0xFFDC2626),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text(
                        "Confirm Reset",
                        style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13),
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

  void _showProvisionCounselorModal() {
    final emailCtrl = TextEditingController();
    final firstNameCtrl = TextEditingController();
    final lastNameCtrl = TextEditingController();
    final deptCtrl = TextEditingController(text: "Guidance Counselor");
    final phoneCtrl = TextEditingController();
    final pwCtrl = TextEditingController();
    String gender = "Female";
    bool obscure = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF0284C7), size: 22),
                        SizedBox(width: 8),
                        Text(
                          "Provision Counselor",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Text(
                  "Create an authorized guidance counselor account with clinical access.",
                  style: TextStyle(fontFamily: 'Inter', fontSize: 12.5, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "FSUU Email Address *",
                    hintText: "e.g. counselor@urios.edu.ph",
                    prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF0284C7)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: firstNameCtrl,
                        decoration: InputDecoration(
                          labelText: "First Name *",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: lastNameCtrl,
                        decoration: InputDecoration(
                          labelText: "Last Name *",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: deptCtrl,
                  decoration: InputDecoration(
                    labelText: "Department / Title *",
                    hintText: "e.g. Guidance Counselor III, Psychometrician",
                    prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF0284C7)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: "Contact Phone Number *",
                    hintText: "e.g. 09123456789",
                    prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF0284C7)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pwCtrl,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    labelText: "Initial Temporary Password *",
                    hintText: "Minimum 8 characters",
                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF0284C7)),
                    suffixIcon: IconButton(
                      icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF94A3B8)),
                      onPressed: () => setModalState(() => obscure = !obscure),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: gender,
                  decoration: InputDecoration(
                    labelText: "Gender",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: const [
                    DropdownMenuItem(value: "Female", child: Text("Female")),
                    DropdownMenuItem(value: "Male", child: Text("Male")),
                    DropdownMenuItem(value: "Prefer not to say", child: Text("Prefer not to say")),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => gender = val);
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final email = emailCtrl.text.trim();
                      final fn = firstNameCtrl.text.trim();
                      final ln = lastNameCtrl.text.trim();
                      final dept = deptCtrl.text.trim();
                      final phone = phoneCtrl.text.trim();
                      final pw = pwCtrl.text.trim();

                      if (email.isEmpty || fn.isEmpty || ln.isEmpty || pw.isEmpty || phone.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Please fill in all required fields."),
                            backgroundColor: Color(0xFFDC2626),
                          ),
                        );
                        return;
                      }

                      if (pw.length < 8) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Password must be at least 8 characters long."),
                            backgroundColor: Color(0xFFDC2626),
                          ),
                        );
                        return;
                      }

                      Navigator.pop(ctx);
                      try {
                        HapticService.lightTap();
                        await _api.post(
                          '/admin/counselors',
                          body: {
                            'email': email,
                            'first_name': fn,
                            'last_name': ln,
                            'department_title': dept.isNotEmpty ? dept : 'Guidance Counselor',
                            'phone_number': phone,
                            'password': pw,
                            'gender': gender,
                          },
                        );
                        if (!mounted) return;

                        // Show success copy modal
                        showDialog(
                          context: this.context,
                          builder: (cDialogCtx) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            title: const Row(
                              children: [
                                Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 24),
                                SizedBox(width: 8),
                                Text("Counselor Provisioned!", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16)),
                              ],
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Successfully created staff account for $fn $ln.", style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF0F172A))),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Email: $email", style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 4),
                                      Text("Temporary Password: $pw", style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0284C7))),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            actions: [
                              OutlinedButton.icon(
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: "Kausap AI Counselor Account\nEmail: $email\nTemporary Password: $pw"));
                                  HapticService.lightTap();
                                  ScaffoldMessenger.of(this.context).showSnackBar(
                                    const SnackBar(content: Text("Credentials copied to clipboard! 📋"), backgroundColor: Color(0xFF0284C7)),
                                  );
                                },
                                icon: const Icon(Icons.copy_rounded, size: 16),
                                label: const Text("Copy Credentials"),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(cDialogCtx),
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7), foregroundColor: Colors.white),
                                child: const Text("Done"),
                              ),
                            ],
                          ),
                        );

                        _fetchCounselors();
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                            content: Text("Failed to provision counselor: $e"),
                            backgroundColor: const Color(0xFFDC2626),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      "Create Counselor Account",
                      style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14),
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

  List<dynamic> _getFilteredCounselors() {
    var list = _counselors;
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((c) {
        final name = (c['full_name'] ?? '').toString().toLowerCase();
        final email = (c['email'] ?? '').toString().toLowerCase();
        final dept = (c['department_title'] ?? '').toString().toLowerCase();
        return name.contains(q) || email.contains(q) || dept.contains(q);
      }).toList();
    }
    if (_activeFilter == 'active') {
      list = list.where((c) => c['is_active'] == true).toList();
    } else if (_activeFilter == 'inactive') {
      list = list.where((c) => c['is_active'] != true).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredCounselors();
    final activeCount = _counselors.where((c) => c['is_active'] == true).length;
    final inactiveCount = _counselors.where((c) => c['is_active'] != true).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Counselor Workforce",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              "Provision & manage university guidance staff",
              style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: "Refresh List",
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0284C7)),
            onPressed: _fetchCounselors,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showProvisionCounselorModal,
        backgroundColor: const Color(0xFF0284C7),
        icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 20),
        label: const Text(
          "Provision Counselor",
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            children: [
              // ── Search & Filter Chips Bar ──
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                color: Colors.white,
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: "Search counselor by name, email, or department...",
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
                    // Status Filter Chips
                    Row(
                      children: [
                        _buildFilterChip("All (${_counselors.length})", 'all'),
                        const SizedBox(width: 8),
                        _buildFilterChip("Active ($activeCount)", 'active'),
                        const SizedBox(width: 8),
                        _buildFilterChip("Inactive ($inactiveCount)", 'inactive'),
                      ],
                    ),
                  ],
                ),
              ),

              // ── List View ──
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
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
                                  onPressed: _fetchCounselors,
                                  child: const Text("Retry"),
                                ),
                              ],
                            ),
                          )
                        : filtered.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFE0F2FE),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.badge_rounded, color: Color(0xFF0284C7), size: 36),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      "No Guidance Counselors Found",
                                      style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      "Tap 'Provision Counselor' below to register your first staff account.",
                                      style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: filtered.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 12),
                                itemBuilder: (ctx, i) {
                                  final c = filtered[i];
                                  final isActive = c['is_active'] == true;
                                  return Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                      boxShadow: const [
                                        BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 1)),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const CircleAvatar(
                                              radius: 20,
                                              backgroundColor: Color(0xFFE0F2FE),
                                              child: Icon(Icons.volunteer_activism_rounded, color: Color(0xFF0284C7), size: 20),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    c['full_name'] ?? 'Counselor',
                                                    style: const TextStyle(
                                                      fontFamily: 'Poppins',
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: 14,
                                                      color: Color(0xFF0F172A),
                                                    ),
                                                  ),
                                                  Text(
                                                    c['department_title'] ?? 'Guidance Counselor',
                                                    style: const TextStyle(
                                                      fontFamily: 'Inter',
                                                      fontSize: 11.5,
                                                      color: Color(0xFF0284C7),
                                                      fontWeight: FontWeight.w600,
                                                    ),
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
                                                isActive ? "Active" : "Inactive",
                                                style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: isActive ? const Color(0xFF16A34A) : const Color(0xFF991B1B),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            const Icon(Icons.email_outlined, size: 14, color: Color(0xFF64748B)),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                c['email'] ?? '',
                                                style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF475569)),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                Clipboard.setData(ClipboardData(text: c['email'] ?? ''));
                                                HapticService.lightTap();
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text("Email copied! 📋"), backgroundColor: Color(0xFF0284C7)),
                                                );
                                              },
                                              child: const Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 4),
                                                child: Icon(Icons.copy_rounded, size: 14, color: Color(0xFF94A3B8)),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (c['phone_number'] != null && c['phone_number'].toString().isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.phone_outlined, size: 14, color: Color(0xFF64748B)),
                                              const SizedBox(width: 6),
                                              Text(
                                                c['phone_number'],
                                                style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF475569)),
                                              ),
                                            ],
                                          ),
                                        ],
                                        const Divider(height: 18, color: Color(0xFFF1F5F9)),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            SizedBox(
                                              height: 34,
                                              child: OutlinedButton.icon(
                                                onPressed: () => _showResetPasswordModal(c),
                                                icon: const Icon(Icons.lock_reset_rounded, size: 15),
                                                label: const Text("Reset PW", style: TextStyle(fontFamily: 'Poppins', fontSize: 11.5)),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: const Color(0xFF64748B),
                                                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            SizedBox(
                                              height: 34,
                                              child: ElevatedButton.icon(
                                                onPressed: () => _toggleCounselorStatus(c),
                                                icon: Icon(isActive ? Icons.block_rounded : Icons.check_circle_outline_rounded, size: 15),
                                                label: Text(
                                                  isActive ? "Deactivate" : "Activate",
                                                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 11.5, fontWeight: FontWeight.w600),
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: isActive ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
                                                  foregroundColor: isActive ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                                                  elevation: 0,
                                                  side: BorderSide(color: isActive ? const Color(0xFFFCA5A5) : const Color(0xFF86EFAC)),
                                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String filterKey) {
    final isSelected = _activeFilter == filterKey;
    return GestureDetector(
      onTap: () {
        HapticService.lightTap();
        setState(() => _activeFilter = filterKey);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}
