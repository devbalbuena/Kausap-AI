import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../services/api_client.dart';

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
  });

  factory ClientItem.fromJson(Map<String, dynamic> json) {
    Color parseColor(String hexColor) {
      hexColor = hexColor.replaceAll("#", "");
      if (hexColor.length == 6) {
        hexColor = "FF$hexColor";
      }
      return Color(int.parse(hexColor, radix: 16));
    }

    return ClientItem(
      id: json['id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      initials: json['initials'],
      avatarColor: parseColor(json['avatar_color']),
      clientIdLabel: json['client_id_label'],
      paymentType: json['payment_type'],
      nextAppointment: json['next_appointment'],
      status: json['status'],
      location: json['location'],
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
  String _selectedRiskLevel = 'all';

  @override
  void initState() {
    super.initState();
    _fetchClients();
  }

  Future<void> _fetchClients() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.get('/professional/clients', queryParams: {'risk_level': _selectedRiskLevel});
      if (res != null) {
        setState(() {
          _clients = (res['clients'] as List).map((c) => ClientItem.fromJson(c)).toList();
        });
      }
    } catch (e) {
      debugPrint("Error fetching clients: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 800;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(24, isMobile ? 60 : 32, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Clients", style: AppTextStyles.heading1.copyWith(color: const Color(0xFF3D405B))),
                        const SizedBox(height: 8),
                        Text("Manage and track your active caseload.", style: AppTextStyles.body.copyWith(color: const Color(0xFF707974))),
                      ],
                    ),
                    if (isMobile)
                      IconButton(
                        icon: const Icon(Icons.filter_list_rounded, color: AppColors.primary),
                        onPressed: _showMobileFilters,
                      )
                    else
                      _buildDesktopFilters(),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _clients.isEmpty
                        ? const Center(child: Text("No clients found."))
                        : isMobile
                            ? _buildMobileList()
                            : _buildDesktopTable(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDesktopFilters() {
    return Row(
      children: [
        _buildDropdown("Account Type"),
        const SizedBox(width: 12),
        _buildDropdown("Location (Barangay)"),
        const SizedBox(width: 12),
        _buildRiskLevelDropdown(),
      ],
    );
  }

  Widget _buildDropdown(String hint) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE8EAED)),
      ),
      child: Row(
        children: [
          Text(hint, style: const TextStyle(fontSize: 14, color: Color(0xFF3D405B), fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Color(0xFF3D405B)),
        ],
      ),
    );
  }

  Widget _buildRiskLevelDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE8EAED)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedRiskLevel,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Color(0xFF3D405B)),
          style: const TextStyle(fontSize: 14, color: Color(0xFF3D405B), fontWeight: FontWeight.w500, fontFamily: 'Urbanist'),
          items: const [
            DropdownMenuItem(value: 'all', child: Text("All Risk Levels")),
            DropdownMenuItem(value: 'active', child: Text("Active")),
            DropdownMenuItem(value: 'high_risk', child: Text("High Risk")),
            DropdownMenuItem(value: 'maintenance', child: Text("Maintenance")),
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedRiskLevel = val);
              _fetchClients();
            }
          },
        ),
      ),
    );
  }

  void _showMobileFilters() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Filters", style: AppTextStyles.heading2),
              const SizedBox(height: 24),
              const Text("Risk Level", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildRiskLevelDropdown(),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text("Apply"),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    Color dotColor;

    if (status == "High Risk") {
      bgColor = const Color(0xFFFFF5F5);
      textColor = const Color(0xFFFF5858);
      dotColor = const Color(0xFFFF5858);
    } else if (status == "Active") {
      bgColor = const Color(0xFFF0F5FF);
      textColor = AppColors.primary;
      dotColor = AppColors.primary;
    } else {
      bgColor = const Color(0xFFEBF7DC);
      textColor = const Color(0xFF4E6D36);
      dotColor = const Color(0xFF4E6D36);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(status, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDesktopTable() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EAED)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE8EAED))),
            ),
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text("PATIENT INFO", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF707974)))),
                Expanded(flex: 2, child: Text("NEXT APPOINTMENT", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF707974)))),
                Expanded(flex: 1, child: Text("STATUS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF707974)))),
                Expanded(flex: 1, child: Text("LOCATION", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF707974)))),
                SizedBox(width: 100, child: Text("ACTIONS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF707974)))),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: _clients.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE8EAED)),
              itemBuilder: (context, index) {
                final client = _clients[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: client.avatarColor,
                              child: Text(client.initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("${client.firstName} ${client.lastName}", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3D405B))),
                                Text("ID: ${client.clientIdLabel} • ${client.paymentType}", style: const TextStyle(fontSize: 12, color: Color(0xFF707974))),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(client.nextAppointment ?? "None", style: const TextStyle(color: Color(0xFF3D405B))),
                      ),
                      Expanded(
                        flex: 1,
                        child: Align(alignment: Alignment.centerLeft, child: _buildStatusBadge(client.status)),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(client.location, style: const TextStyle(color: Color(0xFF3D405B))),
                      ),
                      const SizedBox(
                        width: 100,
                        child: Row(
                          children: [
                            Icon(Icons.more_horiz_rounded, color: Color(0xFFC0C9C2)),
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

  Widget _buildMobileList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: _clients.length,
      itemBuilder: (context, index) {
        final client = _clients[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8EAED)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: client.avatarColor,
                        child: Text(client.initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("${client.firstName} ${client.lastName}", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3D405B))),
                          Text(client.clientIdLabel, style: const TextStyle(fontSize: 12, color: Color(0xFF707974))),
                        ],
                      ),
                    ],
                  ),
                  _buildStatusBadge(client.status),
                ],
              ),
              const SizedBox(height: 16),
              const Text("NEXT APPOINTMENT", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF707974))),
              const SizedBox(height: 4),
              Text(client.nextAppointment ?? "None", style: const TextStyle(color: Color(0xFF3D405B), fontSize: 14)),
            ],
          ),
        );
      },
    );
  }
}
