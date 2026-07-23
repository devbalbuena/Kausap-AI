import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../theme/app_theme.dart';
import '../../../../services/api_client.dart';

// ─── Data models ──────────────────────────────────────────────────────────────
class ReportMetric {
  final String label;
  final String value;
  final String sublabel;
  final String icon;
  final String? trend;

  ReportMetric.fromJson(Map<String, dynamic> j)
      : label = j['label'],
        value = j['value'],
        sublabel = j['sublabel'],
        icon = j['icon'],
        trend = j['trend'];
}

class ChartDataPoint {
  final String month;
  final double intakeScore;
  final double currentScore;

  ChartDataPoint.fromJson(Map<String, dynamic> j)
      : month = j['month'],
        intakeScore = (j['intake_score'] as num).toDouble(),
        currentScore = (j['current_score'] as num).toDouble();
}

class CrisisProtocolItem {
  final String label;
  final String value;
  final double percentage;

  CrisisProtocolItem.fromJson(Map<String, dynamic> j)
      : label = j['label'],
        value = j['value'],
        percentage = (j['percentage'] as num).toDouble();
}

class CrisisLogEntry {
  final String dateTime;
  final String patientName;
  final String triggerEvent;
  final String severity;
  final String resolutionStatus;

  CrisisLogEntry.fromJson(Map<String, dynamic> j)
      : dateTime = j['date_time'],
        patientName = j['patient_name'],
        triggerEvent = j['trigger_event'],
        severity = j['severity'],
        resolutionStatus = j['resolution_status'];
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class ProfessionalReportsScreen extends StatefulWidget {
  const ProfessionalReportsScreen({super.key});

  @override
  State<ProfessionalReportsScreen> createState() => _ProfessionalReportsScreenState();
}

class _ProfessionalReportsScreenState extends State<ProfessionalReportsScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  List<ReportMetric> _metrics = [];
  List<ChartDataPoint> _chartData = [];
  List<CrisisProtocolItem> _crisisProtocol = [];
  List<CrisisLogEntry> _crisisLog = [];
  bool _showComplianceModal = false;

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.get('/professional/reports');
      if (res != null) {
        setState(() {
          _metrics = (res['metrics'] as List).map((m) => ReportMetric.fromJson(m)).toList();
          _chartData = (res['chart_data'] as List).map((c) => ChartDataPoint.fromJson(c)).toList();
          _crisisProtocol = (res['crisis_protocol'] as List).map((c) => CrisisProtocolItem.fromJson(c)).toList();
          _crisisLog = (res['crisis_log'] as List).map((c) => CrisisLogEntry.fromJson(c)).toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching reports: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 800;
                    return SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(24, isMobile ? 60 : 32, 24, 24),
                      child: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
                    );
                  },
                ),
          if (_showComplianceModal) _buildComplianceLoadingModal(),
        ],
      ),
    );
  }

  // ─── Layouts ────────────────────────────────────────────────────────────────
  Widget _buildDesktopLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPageHeader(isMobile: false),
        const SizedBox(height: 24),
        _buildMetricsRow(),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 7, child: _buildChartCard()),
            const SizedBox(width: 24),
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  _buildCrisisProtocolCard(),
                  const SizedBox(height: 24),
                  _buildComplianceCard(),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPageHeader(isMobile: true),
        const SizedBox(height: 24),
        _buildMetricsRow(),
        const SizedBox(height: 24),
        _buildChartCard(),
        const SizedBox(height: 24),
        _buildCrisisProtocolCard(),
        const SizedBox(height: 24),
        _buildComplianceCard(),
      ],
    );
  }

  // ─── Page Header ────────────────────────────────────────────────────────────
  Widget _buildPageHeader({required bool isMobile}) {
    return isMobile
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Outcome Analytics & Reports",
                  style: AppTextStyles.heading1.copyWith(fontSize: 20, color: const Color(0xFF3D405B))),
              const SizedBox(height: 6),
              Text("Monitor patient progress metrics, crisis response times, and generate compliance-ready documentation.",
                  style: AppTextStyles.body.copyWith(color: const Color(0xFF707974))),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildDateFilterButton()),
                  const SizedBox(width: 12),
                  Expanded(child: _buildCompliancePDFButton()),
                ],
              ),
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Outcome Analytics & Reports",
                        style: AppTextStyles.heading1.copyWith(color: const Color(0xFF3D405B))),
                    const SizedBox(height: 8),
                    Text("Monitor patient progress metrics, crisis response times, and generate compliance-ready documentation.",
                        style: AppTextStyles.body.copyWith(color: const Color(0xFF707974))),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              _buildDateFilterButton(),
              const SizedBox(width: 12),
              _buildCompliancePDFButton(),
            ],
          );
  }

  Widget _buildDateFilterButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8EAED)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF3D405B)),
          const SizedBox(width: 8),
          Flexible(
            child: Text("Last 30 Days (Oct - Nov 2026)",
                style: const TextStyle(fontSize: 13, color: Color(0xFF3D405B), fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF3D405B)),
        ],
      ),
    );
  }

  Widget _buildCompliancePDFButton() {
    return ElevatedButton.icon(
      onPressed: () {
        setState(() => _showComplianceModal = true);
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _showComplianceModal = false);
        });
      },
      icon: const Icon(Icons.file_download_outlined, size: 16),
      label: const Text("RA 11036 Compliance PDF"),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    );
  }

  // ─── Metric Cards ───────────────────────────────────────────────────────────
  Widget _buildMetricsRow() {
    if (_metrics.isEmpty) return const SizedBox();
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 500;
        if (isMobile) {
          return Column(
            children: _metrics.map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildMetricCard(m),
            )).toList(),
          );
        }
        return Row(
          children: _metrics.asMap().entries.map((e) {
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: e.key < _metrics.length - 1 ? 16 : 0),
                child: _buildMetricCard(e.value),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildMetricCard(ReportMetric metric) {
    final isCrisis = metric.icon == 'crisis';

    Widget iconWidget;
    if (metric.icon == 'trend_up') {
      iconWidget = Container(
        width: 44, height: 44,
        decoration: BoxDecoration(color: const Color(0xFFF0F5FF), shape: BoxShape.circle),
        child: const Icon(Icons.trending_up_rounded, color: AppColors.primary, size: 22),
      );
    } else if (metric.icon == 'document') {
      iconWidget = Container(
        width: 44, height: 44,
        decoration: BoxDecoration(color: const Color(0xFFF0F5FF), shape: BoxShape.circle),
        child: const Icon(Icons.description_outlined, color: AppColors.primary, size: 22),
      );
    } else {
      iconWidget = Container(
        width: 44, height: 44,
        decoration: BoxDecoration(color: const Color(0xFFFFF0F0), shape: BoxShape.circle),
        child: const Icon(Icons.emergency_rounded, color: Color(0xFFFF5858), size: 22),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
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
              Text(metric.label,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                      color: Color(0xFF707974), letterSpacing: 0.5)),
              iconWidget,
            ],
          ),
          const SizedBox(height: 16),
          Text(metric.value,
              style: TextStyle(
                  fontSize: 36, fontWeight: FontWeight.bold,
                  color: isCrisis ? const Color(0xFFFF5858) : const Color(0xFF3D405B))),
          const SizedBox(height: 8),
          if (metric.trend != null)
            Row(
              children: [
                const Icon(Icons.arrow_upward_rounded, size: 14, color: Color(0xFF4E6D36)),
                const SizedBox(width: 4),
                Text(metric.sublabel,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF4E6D36), fontWeight: FontWeight.w500)),
              ],
            )
          else
            Text(metric.sublabel,
                style: TextStyle(fontSize: 13, color: isCrisis ? const Color(0xFFFF5858) : const Color(0xFF707974))),
        ],
      ),
    );
  }

  // ─── Chart Card ─────────────────────────────────────────────────────────────
  Widget _buildChartCard() {
    return Container(
      padding: const EdgeInsets.all(24),
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
              Text("Outcome Tracking (PHQ-9 & GAD-7)",
                  style: AppTextStyles.heading2.copyWith(fontSize: 16, color: const Color(0xFF3D405B))),
              Row(
                children: [
                  _buildLegendDot(const Color(0xFFADD8E6), "Intake Score"),
                  const SizedBox(width: 16),
                  _buildLegendDot(AppColors.primary, "Current Score"),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 260,
            child: _chartData.isEmpty
                ? const Center(child: Text("No chart data."))
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 25,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => const Color(0xFF3D405B),
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              rod.toY.toStringAsFixed(1),
                              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx < 0 || idx >= _chartData.length) return const SizedBox();
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(_chartData[idx].month,
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF707974))),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 5,
                            reservedSize: 32,
                            getTitlesWidget: (value, meta) {
                              return Text(value.toInt().toString(),
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF707974)));
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border(
                          bottom: BorderSide(color: const Color(0xFFE8EAED)),
                          left: BorderSide(color: const Color(0xFFE8EAED)),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        horizontalInterval: 5,
                        getDrawingHorizontalLine: (_) =>
                            const FlLine(color: Color(0xFFF3F2FB), strokeWidth: 1),
                        drawVerticalLine: false,
                      ),
                      barGroups: _chartData.asMap().entries.map((e) {
                        return BarChartGroupData(
                          x: e.key,
                          barRods: [
                            BarChartRodData(
                              toY: e.value.intakeScore,
                              color: const Color(0xFFADD8E6),
                              width: 14,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            ),
                            BarChartRodData(
                              toY: e.value.currentScore,
                              color: AppColors.primary,
                              width: 14,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            ),
                          ],
                          barsSpace: 4,
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF707974))),
      ],
    );
  }

  // ─── Crisis Protocol Card ────────────────────────────────────────────────────
  Widget _buildCrisisProtocolCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EAED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text("Crisis Protocol Metrics",
                  style: AppTextStyles.heading2.copyWith(fontSize: 15, color: const Color(0xFF3D405B))),
            ],
          ),
          const SizedBox(height: 20),
          ..._crisisProtocol.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item.label, style: const TextStyle(fontSize: 13, color: Color(0xFF3D405B))),
                    Text(item.value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF3D405B))),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: item.percentage,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFF3F2FB),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ],
            ),
          )),
          GestureDetector(
            onTap: () => _showCrisisLogModal(),
            child: Row(
              children: [
                Text("View Full Crisis Log",
                    style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Compliance Card ─────────────────────────────────────────────────────────
  Widget _buildComplianceCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EAED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(color: const Color(0xFFF0F5FF), shape: BoxShape.circle),
            child: const Icon(Icons.verified_user_outlined, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 16),
          Text("RA 11036 Compliance",
              style: AppTextStyles.heading2.copyWith(fontSize: 15, color: const Color(0xFF3D405B)),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          const Text(
            "Ensure all patient records and intervention logs meet the Mental Health Act requirements",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFF707974), height: 1.5),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () {
              setState(() => _showComplianceModal = true);
              Future.delayed(const Duration(seconds: 3), () {
                if (mounted) setState(() => _showComplianceModal = false);
              });
            },
            icon: const Icon(Icons.settings_outlined, size: 16, color: Color(0xFF3D405B)),
            label: const Text("Generate Audit Trail", style: TextStyle(color: Color(0xFF3D405B))),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
              side: const BorderSide(color: Color(0xFFE8EAED)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Crisis Log Modal ────────────────────────────────────────────────────────
  void _showCrisisLogModal() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(28),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Crisis Intervention & Escalation Log",
                                style: AppTextStyles.heading2.copyWith(color: const Color(0xFF3D405B))),
                            const SizedBox(height: 4),
                            const Text("Record of triggered safety protocols and immediate interventions.",
                                style: TextStyle(fontSize: 13, color: Color(0xFF707974))),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF707974)),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingTextStyle: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.bold,
                        color: Color(0xFF707974), letterSpacing: 0.5),
                    dataTextStyle: const TextStyle(fontSize: 13, color: Color(0xFF3D405B)),
                    columns: const [
                      DataColumn(label: Text("DATE & TIME")),
                      DataColumn(label: Text("PATIENT")),
                      DataColumn(label: Text("TRIGGER EVENT")),
                      DataColumn(label: Text("SEVERITY")),
                      DataColumn(label: Text("RESOLUTION STATUS")),
                    ],
                    rows: _crisisLog.isEmpty
                        ? []
                        : _crisisLog.map((e) => DataRow(cells: [
                              DataCell(Text(e.dateTime)),
                              DataCell(Text(e.patientName)),
                              DataCell(Text(e.triggerEvent)),
                              DataCell(_buildSeverityBadge(e.severity)),
                              DataCell(Text(e.resolutionStatus)),
                            ])).toList(),
                  ),
                ),
                if (_crisisLog.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text("No crisis log entries found.")),
                  ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Close", style: TextStyle(color: AppColors.primary)),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.download_rounded, size: 16),
                        label: const Text("Export Crisis Report (PDF)"),
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSeverityBadge(String severity) {
    Color bgColor;
    Color textColor;
    if (severity == "High Risk") {
      bgColor = const Color(0xFFFFE5E5);
      textColor = const Color(0xFFFF5858);
    } else if (severity == "Medium Risk") {
      bgColor = const Color(0xFFFFF9E5);
      textColor = const Color(0xFFD6A82A);
    } else {
      bgColor = const Color(0xFFEBF7DC);
      textColor = const Color(0xFF4E6D36);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: textColor, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(severity, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor)),
      ]),
    );
  }

  // ─── Compliance Loading Modal ─────────────────────────────────────────────────
  Widget _buildComplianceLoadingModal() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Generating Compliance\nReport",
                  style: AppTextStyles.heading1.copyWith(fontSize: 20, color: const Color(0xFF3D405B)),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              const LinearProgressIndicator(
                minHeight: 8,
                backgroundColor: Color(0xFFF3F2FB),
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
              const SizedBox(height: 24),
              const Text(
                "Compiling encrypted case records, active safety plans, and triage logs to meet statutory reporting requirements under the Philippine Mental Health Act (RA 11036).",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF707974), height: 1.5),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => setState(() => _showComplianceModal = false),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.close_rounded, size: 16, color: Color(0xFF707974)),
                    const SizedBox(width: 6),
                    const Text("Cancel Export",
                        style: TextStyle(color: Color(0xFF707974), fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
