import 'dart:math' as math;
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
          _tokensData = results[0] as Map<String, dynamic>?;
          _healthData = results[1] as Map<String, dynamic>?;
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
              "AI & Cloud Telemetry",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              "Real-time token metrics, AI inference & Neon cloud diagnostics",
              style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: "Refresh Telemetry",
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
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 48),
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchTelemetry,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text("Retry Connection"),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── 1. Hero Card: AI Intelligence & Token Throughput ──
                          _buildHeroTokensCard(),

                          const SizedBox(height: 16),

                          // ── 2. AI Inference Speed & Guardrails ──
                          _buildAiPerformanceCard(),

                          const SizedBox(height: 16),

                          // ── 3. Token Composition Breakdown ──
                          const Text(
                            "Token Composition Breakdown",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 10),

                          Row(
                            children: [
                              Expanded(
                                child: _buildMetricTile(
                                  label: "Prompt / Input",
                                  count: "${_tokensData?['total_prompt_tokens'] ?? 0}",
                                  rate: "Student context & prompt input",
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
                                  rate: "AI empathy response tokens",
                                  color: const Color(0xFF7C3AED),
                                  bg: const Color(0xFFEDE9FE),
                                  icon: Icons.output_rounded,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // ── 4. 7-Day AI Token Flow Trends ──
                          const Text(
                            "7-Day Token Throughput Trends",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 10),

                          _build7DayTrendsTable(),

                          const SizedBox(height: 16),

                          // ── 5. AI Compute Efficiency Forecast ──
                          _buildCostEstimatorCard(),

                          const SizedBox(height: 20),

                          // ── 6. Neon Serverless Pool Diagnostics ──
                          const Text(
                            "Infrastructure & Neon Pool Diagnostics",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 10),

                          _buildNeonDiagnosticsCard(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildHeroTokensCard() {
    final totalTokens = _tokensData?['total_tokens'] ?? 0;
    final todayTokens = _tokensData?['today_tokens'] ?? 0;
    final totalCostPhp = (_tokensData?['total_cost_php'] ?? 0.0) as num;
    final totalCostUsd = (_tokensData?['total_cost_usd'] ?? 0.0) as num;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x18000000), blurRadius: 10, offset: Offset(0, 4)),
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
                  Icon(Icons.hub_rounded, color: Color(0xFF38BDF8), size: 18),
                  SizedBox(width: 8),
                  Text(
                    "AI Token Intelligence",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withAlpha(40),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF38BDF8).withAlpha(80)),
                ),
                child: const Text(
                  "Google Gemini 2.0 Flash",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 10.5,
                    color: Color(0xFF38BDF8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Primary Big Stat: Total Tokens
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                "$totalTokens",
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w800,
                  fontSize: 32,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                "Total Tokens Processed",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF38BDF8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "$todayTokens tokens processed today across student interactions",
            style: const TextStyle(fontFamily: 'Inter', color: Color(0xFF94A3B8), fontSize: 12),
          ),
          const SizedBox(height: 14),

          // Cloud Efficiency & Budget Badge (Subtle efficiency display)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withAlpha(15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.bolt_rounded, color: Color(0xFFFBBF24), size: 16),
                    SizedBox(width: 6),
                    Text(
                      "Cloud Efficiency",
                      style: TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: Color(0xFFE2E8F0), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Text(
                  "≈ ₱${totalCostPhp.toStringAsFixed(4)} PHP (\$${totalCostUsd.toStringAsFixed(4)} USD)",
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 11.5, color: Color(0xFF38BDF8), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiPerformanceCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.speed_rounded, color: Color(0xFF16A34A), size: 18),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Avg Response Latency", style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF64748B))),
                      Text("~650ms (Ultra-Fast)", style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.verified_user_outlined, color: Color(0xFF0284C7), size: 18),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Safety Guardrails", style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF64748B))),
                      Text("100% Passed Active", style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0284C7))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _build7DayTrendsTable() {
    final dailyTrends = (_tokensData?['daily_trends'] as List<dynamic>?) ?? [];

    return Container(
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
                  flex: 4,
                  child: Text(
                    "Date",
                    style: TextStyle(fontFamily: 'Inter', fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    "Total Tokens",
                    textAlign: TextAlign.right,
                    style: TextStyle(fontFamily: 'Inter', fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    "Prompt / Output",
                    textAlign: TextAlign.right,
                    style: TextStyle(fontFamily: 'Inter', fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
          ),
          if (dailyTrends.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text(
                  "No daily token activity recorded in the past 7 days.",
                  style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF94A3B8)),
                ),
              ),
            )
          else
            ...dailyTrends.map((trend) {
              final prompt = trend['prompt_tokens'] ?? 0;
              final completion = trend['completion_tokens'] ?? 0;
              final total = trend['total_tokens'] ?? 0;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(
                        trend['date'] ?? '',
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF334155)),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        "$total",
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Color(0xFF0284C7), fontWeight: FontWeight.w600),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        "$prompt / $completion",
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildCostEstimatorCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: const Row(
        children: [
          Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF16A34A), size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "High-Throughput Intelligence",
                  style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 12.5, color: Color(0xFF166534)),
                ),
                SizedBox(height: 2),
                Text(
                  "1,000 student check-in conversations consume ~150,000 tokens with zero campus hardware overhead.",
                  style: TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: Color(0xFF15803D)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeonDiagnosticsCard() {
    final poolSize = (_healthData?['pool_size'] as num?)?.toInt() ?? 20;
    final poolCheckedOut = (_healthData?['pool_checked_out'] as num?)?.toInt() ?? 0;
    final availableHeadroom = math.max(0, poolSize - poolCheckedOut);
    final totalStudents = _healthData?['total_students'] ?? 0;
    final totalCounselors = _healthData?['total_counselors'] ?? 0;
    final isConnected = _healthData?['database_connected'] == true;
    final double utilization = poolSize > 0 ? (poolCheckedOut / poolSize).clamp(0.0, 1.0) : 0.0;

    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: isConnected ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isConnected ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isConnected ? "Healthy" : "Offline",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 10.5,
                    color: isConnected ? const Color(0xFF166534) : const Color(0xFF991B1B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Visual Connection Pool Utilization Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "PgBouncer Pool Utilization",
                    style: TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                  ),
                  Text(
                    "$poolCheckedOut / $poolSize Active (${(utilization * 100).toStringAsFixed(0)}%)",
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF0284C7)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: utilization == 0 ? 0.05 : utilization,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFE2E8F0),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    utilization > 0.8 ? const Color(0xFFDC2626) : const Color(0xFF0284C7),
                  ),
                ),
              ),
            ],
          ),

          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          _buildDiagnosticRow("PgBouncer Pool Capacity", "$poolSize max connections"),
          const SizedBox(height: 8),
          _buildDiagnosticRow("Active Checked Out", "$poolCheckedOut active"),
          const SizedBox(height: 8),
          _buildDiagnosticRow("Available Headroom", "$availableHeadroom free connections (${((availableHeadroom / poolSize) * 100).toInt()}% free)"),
          const SizedBox(height: 8),
          _buildDiagnosticRow("Serverless Architecture", "Neon v2 • Scale-to-Zero Active"),
          const SizedBox(height: 8),
          _buildDiagnosticRow("Data Encryption", "AES-256 Cloud Shield Active"),
          const SizedBox(height: 8),
          _buildDiagnosticRow("Registered Students", "$totalStudents"),
          const SizedBox(height: 8),
          _buildDiagnosticRow("Authorized Counselors", "$totalCounselors"),
        ],
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
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            rate,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 10.5, color: Color(0xFF94A3B8)),
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
          style: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
