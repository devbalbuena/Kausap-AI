import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../services/api_client.dart';

class FlaggedConversation {
  final String id;
  final String clientName;
  final String initials;
  final String timeAgo;
  final String preview;
  final String severity;
  final bool isResolved;

  FlaggedConversation.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        clientName = json['client_name'],
        initials = json['initials'],
        timeAgo = json['time_ago'],
        preview = json['preview'],
        severity = json['severity'],
        isResolved = json['is_resolved'];
}

class AIInsightReport {
  final String clientName;
  final String flaggedQuote;
  final List<String> tags;
  final String aiAnalysis;
  final List<String> recommendedActions;

  AIInsightReport.fromJson(Map<String, dynamic> json)
      : clientName = json['client_name'],
        flaggedQuote = json['flagged_quote'],
        tags = (json['tags'] as List).map((t) => t['label'].toString()).toList(),
        aiAnalysis = json['ai_analysis'],
        recommendedActions = (json['recommended_actions'] as List).cast<String>();
}

class MetricCardModel {
  final String label;
  final String value;
  final String sublabel;
  final String? trend;

  MetricCardModel.fromJson(Map<String, dynamic> json)
      : label = json['label'],
        value = json['value'],
        sublabel = json['sublabel'],
        trend = json['trend'];
}

class ProfessionalAIInsightsScreen extends StatefulWidget {
  const ProfessionalAIInsightsScreen({super.key});

  @override
  State<ProfessionalAIInsightsScreen> createState() => _ProfessionalAIInsightsScreenState();
}

class _ProfessionalAIInsightsScreenState extends State<ProfessionalAIInsightsScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;

  List<MetricCardModel> _metrics = [];
  List<FlaggedConversation> _unresolved = [];
  AIInsightReport? _selectedInsight;

  // Mobile tab state
  int _mobileTabIndex = 0; // 0 for Queue, 1 for Report

  @override
  void initState() {
    super.initState();
    _fetchInsights();
  }

  Future<void> _fetchInsights() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.get('/professional/ai-insights');
      if (res != null) {
        setState(() {
          _metrics = (res['metrics'] as List).map((m) => MetricCardModel.fromJson(m)).toList();
          _unresolved = (res['unresolved'] as List).map((f) => FlaggedConversation.fromJson(f)).toList();
          if (res['selected_insight'] != null) {
            _selectedInsight = AIInsightReport.fromJson(res['selected_insight']);
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching AI insights: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: _isLoading
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
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMetricsRow(),
        const SizedBox(height: 24),
        _buildMobileTabSwitcher(),
        const SizedBox(height: 16),
        _mobileTabIndex == 0 ? _buildQueuePanel() : _buildReportPanel(),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMetricsRow(),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: _buildQueuePanel(),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 6,
              child: _buildReportPanel(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricsRow() {
    return Row(
      children: _metrics.map((m) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: m == _metrics.last ? 0 : 16),
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
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text(m.label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF707974), letterSpacing: 0.5)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(m.value, style: AppTextStyles.heading1.copyWith(color: AppColors.primary, fontSize: 32)),
                    if (m.trend != null)
                      const Icon(Icons.timer_outlined, color: AppColors.primary),
                  ],
                ),
                const SizedBox(height: 8),
                Text(m.sublabel, style: const TextStyle(color: Color(0xFF707974), fontSize: 14)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMobileTabSwitcher() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F2FB),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _mobileTabIndex = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _mobileTabIndex == 0 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _mobileTabIndex == 0 ? [const BoxShadow(color: Color(0x1A000000), blurRadius: 4, offset: Offset(0, 2))] : [],
                ),
                child: Center(
                  child: Text("Queue", style: TextStyle(fontWeight: _mobileTabIndex == 0 ? FontWeight.bold : FontWeight.w500, color: _mobileTabIndex == 0 ? AppColors.primary : const Color(0xFF707974))),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _mobileTabIndex = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _mobileTabIndex == 1 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _mobileTabIndex == 1 ? [const BoxShadow(color: Color(0x1A000000), blurRadius: 4, offset: Offset(0, 2))] : [],
                ),
                child: Center(
                  child: Text("Report", style: TextStyle(fontWeight: _mobileTabIndex == 1 ? FontWeight.bold : FontWeight.w500, color: _mobileTabIndex == 1 ? AppColors.primary : const Color(0xFF707974))),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueuePanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EAED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text("Flagged Conversations", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3D405B), fontSize: 16)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF3F2FB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 4, offset: Offset(0, 2))]),
                      child: const Center(child: Text("Unresolved", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 12))),
                    ),
                  ),
                  const Expanded(
                    child: Center(child: Text("Resolved", style: TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF707974), fontSize: 12))),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE8EAED)),
          if (_unresolved.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text("No flagged conversations.", style: TextStyle(color: Color(0xFF707974))),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _unresolved.length,
              separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFE8EAED)),
              itemBuilder: (context, index) {
                final item = _unresolved[index];
                final isSelected = index == 0; // Highlight the first one for now

                Color tagBg;
                Color tagText;
                if (item.severity == "CRITICAL") {
                  tagBg = const Color(0xFFFFE5E5);
                  tagText = const Color(0xFFFF5858);
                } else if (item.severity == "HIGH") {
                  tagBg = const Color(0xFFFFF2E5);
                  tagText = const Color(0xFFFF9533);
                } else {
                  tagBg = const Color(0xFFFFFFE5);
                  tagText = const Color(0xFFD6C829);
                }

                return Container(
                  color: isSelected ? const Color(0xFFF8F9FF) : Colors.transparent,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(item.clientName, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3D405B))),
                          Text(item.timeAgo, style: const TextStyle(fontSize: 12, color: Color(0xFF707974))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(item.preview, style: const TextStyle(fontSize: 14, color: Color(0xFF707974))),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: tagBg, borderRadius: BorderRadius.circular(4)),
                        child: Text(item.severity, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: tagText)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildReportPanel() {
    if (_selectedInsight == null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8EAED)),
        ),
        padding: const EdgeInsets.all(24),
        child: const Center(child: Text("Select a conversation to view the report.", style: TextStyle(color: Color(0xFF707974)))),
      );
    }

    final report = _selectedInsight!;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EAED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Insight Report: ${report.clientName}", style: AppTextStyles.heading2.copyWith(color: const Color(0xFF3D405B))),
                    const SizedBox(height: 4),
                    const Text("Generated by Gemini v3.1", style: TextStyle(fontSize: 12, color: Color(0xFF707974))),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF3D405B)),
                  label: const Text("Mark Resolved", style: TextStyle(color: Color(0xFF3D405B))),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE8EAED)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE8EAED)),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF5858), size: 20),
                    const SizedBox(width: 8),
                    Text("Flagged Context", style: AppTextStyles.heading2.copyWith(fontSize: 16, color: const Color(0xFF3D405B))),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    report.flaggedQuote,
                    style: const TextStyle(fontStyle: FontStyle.italic, color: Color(0xFF707974), height: 1.5),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    const Icon(Icons.analytics_outlined, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text("AI Sentiment Analysis", style: AppTextStyles.heading2.copyWith(fontSize: 16, color: const Color(0xFF3D405B))),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: report.tags.map((t) {
                    final isRed = t.contains("Stress");
                    final isOrange = t.contains("Sleep");
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isRed ? const Color(0xFFFFE5E5) : (isOrange ? const Color(0xFFFFF2E5) : const Color(0xFFE4F9FF)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        t,
                        style: TextStyle(
                          fontSize: 12,
                          color: isRed ? const Color(0xFFFF5858) : (isOrange ? const Color(0xFFFF9533) : AppColors.primary),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text(
                  report.aiAnalysis,
                  style: const TextStyle(color: Color(0xFF707974), height: 1.5),
                ),
                const SizedBox(height: 32),
                const Text("Recommended Actions", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3D405B))),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.calendar_today_rounded, size: 16),
                        label: Text(report.recommendedActions.isNotEmpty ? report.recommendedActions[0] : "Schedule Session"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.link_rounded, size: 16, color: AppColors.primary),
                        label: Text(report.recommendedActions.length > 1 ? report.recommendedActions[1] : "Suggest Activity", style: const TextStyle(color: AppColors.primary)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE4F9FF),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
