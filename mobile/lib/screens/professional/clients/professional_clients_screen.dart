import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../services/api_client.dart';
import '../../chat/direct_message_screen.dart';

class ClientItem {
  final String id;
  final String firstName;
  final String lastName;
  final String initials;
  final Color avatarColor;
  final String clientIdLabel;
  final String paymentType;
  final String? nextAppointment;
  final String status;
  final String location;
  final String? phq9Score;
  final String? gad7Score;
  final String? lastCheckIn;

  ClientItem({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.initials,
    required this.avatarColor,
    required this.clientIdLabel,
    required this.paymentType,
    this.nextAppointment,
    required this.status,
    required this.location,
    this.phq9Score,
    this.gad7Score,
    this.lastCheckIn,
  });

  factory ClientItem.fromJson(Map<String, dynamic> json) {
    Color parseColor(dynamic hexColor) {
      if (hexColor == null) return AppColors.primary;
      String str = hexColor.toString().replaceAll("#", "");
      if (str.length == 6) str = "FF$str";
      return Color(int.tryParse(str, radix: 16) ?? 0xFF0077B6);
    }

    return ClientItem(
      id: json['id']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? 'Client',
      lastName: json['last_name']?.toString() ?? '',
      initials: (json['initials']?.toString().isNotEmpty == true)
          ? json['initials'].toString()
          : (json['first_name']?.toString().isNotEmpty == true ? json['first_name'][0] : 'C'),
      avatarColor: parseColor(json['avatar_color']),
      clientIdLabel: json['client_id_label']?.toString() ?? 'MC-84920',
      paymentType: json['payment_type']?.toString() ?? 'Private Pay',
      nextAppointment: json['next_appointment']?.toString(),
      status: json['status']?.toString() ?? 'Active',
      location: json['location']?.toString() ?? 'Philippines',
      phq9Score: json['phq9_score']?.toString() ?? 'Mild (6/27)',
      gad7Score: json['gad7_score']?.toString() ?? 'Minimal (3/21)',
      lastCheckIn: json['last_check_in']?.toString() ?? 'Today',
    );
  }
}

class ProfessionalClientsScreen extends StatefulWidget {
  const ProfessionalClientsScreen({super.key});

  @override
  State<ProfessionalClientsScreen> createState() => _ProfessionalClientsScreenState();
}

class _ProfessionalClientsScreenState extends State<ProfessionalClientsScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  List<ClientItem> _clients = [];
  String _selectedRiskFilter = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchClients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchClients() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.get(
        '/professional/clients',
        queryParams: {'risk_level': _selectedRiskFilter},
      );
      if (res != null && res['clients'] != null) {
        final rawList = res['clients'] as List;
        setState(() {
          _clients = rawList.map((c) => ClientItem.fromJson(c as Map<String, dynamic>)).toList();
        });
      }
    } catch (e) {
      debugPrint("Error fetching clients: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<ClientItem> get _filteredClients {
    if (_searchQuery.trim().isEmpty) return _clients;
    final q = _searchQuery.toLowerCase();
    return _clients.where((c) {
      final name = "${c.firstName} ${c.lastName}".toLowerCase();
      final id = c.clientIdLabel.toLowerCase();
      return name.contains(q) || id.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 800;

          return RefreshIndicator(
            onRefresh: _fetchClients,
            child: CustomScrollView(
              slivers: [
                // ── Header ───────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, isMobile ? 54 : 32, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Clinical Caseload",
                                  style: AppTextStyles.heading1.copyWith(
                                    fontSize: 26,
                                    letterSpacing: -0.5,
                                    color: const Color(0xFF2C3E50),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Manage active patients, treatment charts & diagnostic screeners.",
                                  style: AppTextStyles.body.copyWith(
                                    color: const Color(0xFF707974),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _showAddClientModal(context),
                              icon: const Icon(Icons.person_add_rounded, size: 16),
                              label: const Text("Add Client"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        // ── Search Field ──────────────────────────────────
                        Container(
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE8EAED)),
                            boxShadow: const [
                              BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2)),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Row(
                            children: [
                              const Icon(Icons.search_rounded, color: Color(0xFF707974), size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  decoration: const InputDecoration(
                                    hintText: "Search by client name or ID (e.g. Van, MC-102)...",
                                    hintStyle: TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                  onChanged: (val) => setState(() => _searchQuery = val),
                                ),
                              ),
                              if (_searchQuery.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.close_rounded, color: Color(0xFF707974), size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // ── Filter Chips ──────────────────────────────────
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChip("All Clients", "all"),
                              const SizedBox(width: 8),
                              _buildFilterChip("Active", "active"),
                              const SizedBox(width: 8),
                              _buildFilterChip("High Priority", "high_risk"),
                              const SizedBox(width: 8),
                              _buildFilterChip("Maintenance", "maintenance"),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Client List / Empty State ─────────────────────────────
                if (_isLoading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_filteredClients.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: _buildEmptyCaseloadCard(context),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 80),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildClientCard(context, _filteredClients[index]),
                        childCount: _filteredClients.length,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final bool isSelected = _selectedRiskFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedRiskFilter = value);
          _fetchClients();
        }
      },
      selectedColor: AppColors.primary,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF555F6D),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? AppColors.primary : const Color(0xFFE8EAED)),
      ),
    );
  }

  // ── Rich Client Card ───────────────────────────────────────────────────
  Widget _buildClientCard(BuildContext context, ClientItem client) {
    bool isHighRisk = client.status.toLowerCase().contains("high");
    Color statusBg = isHighRisk ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9);
    Color statusText = isHighRisk ? AppColors.error : const Color(0xFF2E7D32);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EAED)),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar, Name, ID & Status Badge
          Row(
            children: [
              CircleAvatar(
                backgroundColor: client.avatarColor.withValues(alpha: 0.15),
                radius: 24,
                child: Text(
                  client.initials,
                  style: TextStyle(color: client.avatarColor, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${client.firstName} ${client.lastName}".trim(),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2C3E50)),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(client.clientIdLabel, style: const TextStyle(fontSize: 11, color: Color(0xFF707974), fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        Text("•  ${client.location}", style: const TextStyle(fontSize: 11, color: Color(0xFF707974))),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(12)),
                child: Text(
                  client.status,
                  style: TextStyle(color: statusText, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F3F4)),
          const SizedBox(height: 12),

          // Clinical Details: Screener Status & Appointments
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Clinical Screeners", style: TextStyle(fontSize: 11, color: Color(0xFF707974))),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                          child: Text("PHQ-9: ${client.phq9Score}", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                          child: Text("GAD-7: ${client.gad7Score}", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text("Next Session", style: TextStyle(fontSize: 11, color: Color(0xFF707974))),
                  const SizedBox(height: 3),
                  Text(
                    client.nextAppointment ?? "Not scheduled",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: client.nextAppointment != null ? AppColors.primary : const Color(0xFF9E9E9E),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Action Buttons: Direct Message, Book Session, View Clinical Chart
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DirectMessageScreen(
                          otherUserId: client.id,
                          otherUserName: "${client.firstName} ${client.lastName}".trim(),
                          otherUserRole: 'client',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14),
                  label: const Text("Message", style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: Color(0xFFD6F1FC)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showBookSessionForClient(context, client),
                  icon: const Icon(Icons.calendar_month_rounded, size: 14),
                  label: const Text("Schedule", style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2E7D32),
                    side: const BorderSide(color: Color(0xFFC8E6C9)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showClientChartModal(context, client),
                  icon: const Icon(Icons.analytics_outlined, size: 14),
                  label: const Text("Chart", style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Actionable Empty State ─────────────────────────────────────────────
  Widget _buildEmptyCaseloadCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EAED)),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFE3F2FD),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.people_outline_rounded, color: AppColors.primary, size: 36),
          ),
          const SizedBox(height: 16),
          const Text(
            "Start Building Your Clinical Caseload",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
          ),
          const SizedBox(height: 8),
          const Text(
            "You don't have any clients assigned to your practice yet. Connect with registered platform clients or share your direct clinic referral link.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF707974), height: 1.4),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Referral link copied: https://kausap.ai/ref/dr-perez-17a1"),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  },
                  icon: const Icon(Icons.link_rounded, size: 16),
                  label: const Text("Copy Invite Link"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showAddClientModal(context),
                  icon: const Icon(Icons.person_add_rounded, size: 16),
                  label: const Text("Connect Client"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Modals: Add Client, Book Session, Full Clinical Chart ───────────────
  void _showAddClientModal(BuildContext context) {
    // Sample platform clients available for quick connection
    final sampleClients = [
      {'name': 'Van Balbuena', 'email': 'balbuenadexter2@gmail.com', 'phq': 'Moderate (14/27)', 'gad': 'Mild (7/21)'},
      {'name': 'Juan Dela Cruz', 'email': 'client1@example.com', 'phq': 'Mild (6/27)', 'gad': 'Minimal (3/21)'},
      {'name': 'Sai Usa', 'email': 'sai.usa@urios.edu.ph', 'phq': 'Minimal (4/27)', 'gad': 'Mild (5/21)'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Connect Client to Caseload", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
              const SizedBox(height: 6),
              const Text("Select an active registered user to assign to your clinical practice:", style: TextStyle(fontSize: 13, color: Color(0xFF707974))),
              const SizedBox(height: 16),
              ...sampleClients.map((client) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE8EAED)),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFD6F1FC),
                        child: Text(client['name']![0], style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(client['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text("${client['email']} • Screeners: PHQ-9 ${client['phq']}", style: const TextStyle(fontSize: 11)),
                      trailing: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {
                            _clients.add(ClientItem(
                              id: 'connected-${DateTime.now().millisecondsSinceEpoch}',
                              firstName: client['name']!.split(' ')[0],
                              lastName: client['name']!.split(' ').length > 1 ? client['name']!.split(' ')[1] : '',
                              initials: client['name']!.split(' ').map((e) => e[0]).take(2).join(),
                              avatarColor: AppColors.primary,
                              clientIdLabel: 'MC-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                              paymentType: 'Private Pay',
                              status: 'Active',
                              location: 'Cebu, PH',
                              phq9Score: client['phq'],
                              gad7Score: client['gad'],
                              lastCheckIn: 'Today',
                            ));
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("${client['name']} has been connected to your caseload!"), backgroundColor: AppColors.primary),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text("Connect", style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  )),
            ],
          ),
        );
      },
    );
  }

  void _showBookSessionForClient(BuildContext context, ClientItem client) {
    String selectedMode = "Virtual";
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Schedule Session with ${client.firstName}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 14),
                  const Text("Session Consultation Mode", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text("Virtual (Online)"),
                        selected: selectedMode == "Virtual",
                        onSelected: (v) => setModalState(() => selectedMode = "Virtual"),
                      ),
                      const SizedBox(width: 10),
                      ChoiceChip(
                        label: const Text("In-Person (Clinic)"),
                        selected: selectedMode == "In-Person",
                        onSelected: (v) => setModalState(() => selectedMode = "In-Person"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Upcoming $selectedMode session scheduled for ${client.firstName} ${client.lastName}!"),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Confirm Appointment", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showClientChartModal(BuildContext context, ClientItem client) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollCtrl) {
            return SingleChildScrollView(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
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
                        backgroundColor: client.avatarColor.withValues(alpha: 0.2),
                        radius: 22,
                        child: Text(client.initials, style: TextStyle(color: client.avatarColor, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("${client.firstName} ${client.lastName}".trim(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                            Text("${client.clientIdLabel} • Caseload Status: ${client.status}", style: const TextStyle(fontSize: 12, color: Color(0xFF707974))),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Clinical Screener Summary
                  const Text("Diagnostic Screener History", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2C3E50))),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE8EAED))),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("PHQ-9 Depression Screener", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            Text(client.phq9Score ?? "Mild", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1565C0), fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("GAD-7 Anxiety Screener", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            Text(client.gad7Score ?? "Minimal", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32), fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Progress Notes Section
                  const Text("Latest Clinical Note", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2C3E50))),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE8EAED))),
                    child: const Text(
                      "Client demonstrated good engagement with CBT cognitive reframing exercises. Sleep regularity has improved from 4 to 6.5 hours. Recommended continuation of 7-day thought records.",
                      style: TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF4A5568)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.check_rounded),
                      label: const Text("Close Chart"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
