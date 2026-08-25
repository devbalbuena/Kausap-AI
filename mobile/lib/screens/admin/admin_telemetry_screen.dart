import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_client.dart';
import '../../utils/haptic_service.dart';

class AdminTelemetryScreen extends StatefulWidget {
  const AdminTelemetryScreen({super.key});

  @override
  State<AdminTelemetryScreen> createState() => _AdminTelemetryScreenState();
}

class _AdminTelemetryScreenState extends State<AdminTelemetryScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  Map<String, dynamic>? _tokensData;
  Map<String, dynamic>? _healthData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchTelemetry();
  }

  Future<void> _fetchTelemetry() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _api.get('/admin/telemetry/tokens'),
        _api.get('/admin/telemetry/system-health'),
      ]);
      if (mounted) {
        setState(() {
          _tokensData = results[0] as Map<String, dynamic>;
          _healthData = results[1] as Map<String, dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load telemetry data: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
              "AI & System Telemetry",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              "OpenAI token consumption & cost analytics",
              style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: "Refresh Metrics",
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0284C7)),
            onPressed: () {
              HapticService.lightTap();
              _fetchTelemetry();
            },
          ),
        ],
      ),
      body: _isLoading
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
                        onPressed: _fetchTelemetry,
                        child: const Text("Retry"),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchTelemetry,
                  color: AppColors.primary,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Top Summary Banner ──
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: const [
                              BoxShadow(color: Color(0x1A000000), blurRadius: 10, offset: Offset(0, 4)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.token_rounded, color: Color(0xFF38BDF8), size: 18),
                                      SizedBox(width: 8),
                                      Text(
                                        "OpenAI API Cost Meter",
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          color: Color(0xFF94A3B8),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0284C7).withAlpha(50),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFF0284C7)),
                                    ),
                                    child: const Text(
                                      "GPT-4o-mini",
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        color: Color(0xFF38BDF8),
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "₱${(_tokensData?['estimated_cost_php'] ?? 0.0).toStringAsFixed(2)} PHP",
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 26,
                                ),
                              ),
                              Text(
                                "≈ \$${(_tokensData?['estimated_cost_usd'] ?? 0.0).toStringAsFixed(4)} USD total estimated expense",
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  color: Color(0xFF94A3B8),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Today's Spend: ₱${(_tokensData?['today_cost_php'] ?? 0.0).toStringAsFixed(2)}",
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        color: Color(0xFFE2E8F0),
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      "${_tokensData?['today_tokens'] ?? 0} tokens today",
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        color: Color(0xFF38BDF8),
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── Token Composition Breakdown ──
                        const Text(
                          "Token Composition Breakdown",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricTile(
                                label: "Prompt / Input",
                                count: "${_tokensData?['total_prompt_tokens'] ?? 0}",
                                rate: "\$0.150 / 1M tokens",
                                color: const Color(0xFF0284C7),
                                bg: const Color(0xFFE0F2FE),
                                icon: Icons.input_rounded,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildMetricTile(
                                label: "Completion / Output",
                                count: "${_tokensData?['total_completion_tokens'] ?? 0}",
                                rate: "\$0.600 / 1M tokens",
                                color: const Color(0xFF7C3AED),
                                bg: const Color(0xFFEDE9FE),
                                icon: Icons.output_rounded,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // ── Daily Consumption Trends ──
                        const Text(
                          "7-Day Daily Consumption Trends",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 12),

                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: const [
                              BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 1)),
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                  border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                                ),
                                child: const Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text("Date", style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF64748B))),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text("Tokens", textAlign: TextAlign.right, style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF64748B))),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text("Cost (PHP)", textAlign: TextAlign.right, style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF64748B))),
                                    ),
                                  ],
                                ),
                              ),
                              ...((_tokensData?['daily_trends'] as List<dynamic>?) ?? []).map((trend) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: const BoxDecoration(
                                    border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          "${trend['date']}",
                                          style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          "${trend['total_tokens']}",
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Color(0xFF0284C7), fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          "₱${(trend['cost_php'] ?? 0.0).toStringAsFixed(4)}",
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Color(0xFF16A34A), fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── Infrastructure & Neon Serverless Health ──
                        const Text(
                          "Infrastructure & Neon Pool Diagnostics",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 12),

                        Container(
                          padding: const EdgeInsets.all(16),
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
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: _healthData?['database_connected'] == true
                                          ? const Color(0xFF16A34A)
                                          : const Color(0xFFDC2626),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _healthData?['status'] ?? "Neon Serverless Operational",
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 20, color: Color(0xFFF1F5F9)),
                              _buildDiagnosticRow("PgBouncer Pool Capacity", "${_healthData?['pool_size'] ?? 20} max connections"),
                              const SizedBox(height: 8),
                              _buildDiagnosticRow("Active Checked Out", "${_healthData?['pool_checked_out'] ?? 0} active"),
                              const SizedBox(height: 8),
                              _buildDiagnosticRow("Pool Overflow", "${_healthData?['pool_overflow'] ?? 0}"),
                              const SizedBox(height: 8),
                              _buildDiagnosticRow("Registered Students", "${_healthData?['total_students'] ?? 0}"),
                              const SizedBox(height: 8),
                              _buildDiagnosticRow("Authorized Counselors", "${_healthData?['total_counselors'] ?? 0}"),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String count,
    required String rate,
    required Color color,
    required Color bg,
    required IconData icon,
  }) {
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
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            count,
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 18, color: color),
          ),
          Text(
            rate,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF64748B)),
        ),
        Text(
          value,
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
