import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

class AssessmentReportItem {
  final String id;
  final String clientName;
  final String screenerType; // PHQ-9, GAD-7, Mood Analytics
  final int score;
  final int maxScore;
  final String severity; // Minimal, Mild, Moderate, Severe
  final Color severityColor;
  final String dateStr;
  final String aiSummary;
  final List<String> primarySymptoms;
  final List<String> recommendedInterventions;

  AssessmentReportItem({
    required this.id,
    required this.clientName,
    required this.screenerType,
    required this.score,
    required this.maxScore,
    required this.severity,
    required this.severityColor,
    required this.dateStr,
    required this.aiSummary,
    required this.primarySymptoms,
    required this.recommendedInterventions,
  });
}

class ProfessionalAIInsightsScreen extends StatefulWidget {
  const ProfessionalAIInsightsScreen({super.key});

  @override
  State<ProfessionalAIInsightsScreen> createState() => _ProfessionalAIInsightsScreenState();
}

class _ProfessionalAIInsightsScreenState extends State<ProfessionalAIInsightsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final TextEditingController _copilotQueryController = TextEditingController();
  bool _isCopilotGenerating = false;
  String? _copilotResult;

  List<AssessmentReportItem> _reports = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSampleReports();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _copilotQueryController.dispose();
    super.dispose();
  }

  void _loadSampleReports() {
    _reports = [
      AssessmentReportItem(
        id: 'rep-01',
        clientName: 'Van Balbuena',
        screenerType: 'PHQ-9 Depression Screener',
        score: 14,
        maxScore: 27,
        severity: 'Moderate Depression',
        severityColor: const Color(0xFFE65100),
        dateStr: 'Today at 2:30 PM',
        aiSummary:
            'Client reported pronounced sleep disturbance (early awakenings) and mid-day fatigue with moderate anhedonia. No suicidal ideation flagged (Item 9: 0).',
        primarySymptoms: ['Sleep Disturbance', 'Low Energy', 'Mild Anhedonia'],
        recommendedInterventions: [
          'Behavioral Activation (Morning Sunlight & Walking Routine)',
          'Sleep Hygiene Protocol',
          'Review Thought Records for Cognitive Fatigue Distortions'
        ],
      ),
      AssessmentReportItem(
        id: 'rep-02',
        clientName: 'Juan Dela Cruz',
        screenerType: 'GAD-7 Anxiety Assessment',
        score: 8,
        maxScore: 21,
        severity: 'Mild Anxiety',
        severityColor: const Color(0xFF1976D2),
        dateStr: 'Yesterday at 5:15 PM',
        aiSummary:
            'Occasional somatic tension and situational worry linked to upcoming academic deadlines. Shows good self-awareness and active coping response.',
        primarySymptoms: ['Situational Worry', 'Muscle Tension'],
        recommendedInterventions: [
          '5-4-3-2-1 Sensory Grounding Technique',
          'Box Breathing (4-4-4-4) before study sessions',
          'Progressive Muscle Relaxation (PMR)'
        ],
      ),
      AssessmentReportItem(
        id: 'rep-03',
        clientName: 'Sai Usa',
        screenerType: 'Weekly Mood & Affect Analysis',
        score: 82,
        maxScore: 100,
        severity: 'Stable & Improving',
        severityColor: const Color(0xFF2E7D32),
        dateStr: 'Aug 16, 2026',
        aiSummary:
            'Consecutive 5-day check-in streak logged. Mood shifted positively from "Okay" to "Good" following introduction of daily journaling and breathing exercises.',
        primarySymptoms: ['Optimism', 'Improved Routine Compliance'],
        recommendedInterventions: [
          'Reinforce Positive Self-Talk',
          'Maintain 15-min Evening Mindfulness Routine'
        ],
      ),
    ];
  }

  void _handleCopilotQuery(String query) {
    if (query.trim().isEmpty) return;
    setState(() {
      _isCopilotGenerating = true;
      _copilotResult = null;
    });

    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() {
        _isCopilotGenerating = false;
        _copilotResult = _generateCopilotInsights(query);
      });
    });
  }

  String _generateCopilotInsights(String query) {
    final q = query.toLowerCase();
    if (q.contains('anxiety') || q.contains('panic') || q.contains('gad')) {
      return """🧠 Clinical Copilot Assessment & Strategy:

• Primary Clinical Focus: Somatic down-regulation and decatastrophizing.
• Recommended CBT Techniques:
  1. Cognitive Reframing: Test the probability of catastrophic outcomes vs worst-case beliefs.
  2. Physiological Sigh Breathing: 2 quick nasal inhales followed by 1 long oral exhale (activates parasympathetic tone).
  3. Grounding Homework: 5-4-3-2-1 sensory awareness scan when anticipatory worry starts.
• Screener Follow-up: Re-administer GAD-7 after 14 days to monitor trajectory.""";
    } else if (q.contains('depression') || q.contains('phq') || q.contains('fatigue')) {
      return """🧠 Clinical Copilot Assessment & Strategy:

• Primary Clinical Focus: Behavioral Activation (BA) and graded task assignment.
• Recommended Interventions:
  1. Micro-Action Scheduling: Identify 2 daily low-friction, high-mastery activities (e.g., 10-min morning walk, listening to music).
  2. Mastery & Pleasure Rating: Have the client log activities and score pleasure (1-10) vs predicted enjoyment.
  3. Sleep Hygiene: Fixed wake-up time regardless of nocturnal awakenings.
• Diagnostic Note: Score pattern matches DSM-5 Mild-to-Moderate Depressive Episode without melancholic features.""";
    } else {
      return """🧠 Clinical Copilot Assessment & Strategy:

• Case Synthesis: Formulate treatment goals centered on cognitive flexibility and emotional regulation.
• Recommended Therapeutic Protocol:
  1. Collaborative Agenda Setting: Dedicate initial 5 minutes of session to prioritize primary distress trigger.
  2. Thought Record Worksheet: Identify automatic negative thoughts (ANTs) and cognitive distortions (all-or-nothing, mind reading).
  3. Mindfulness & Grounding: Assign the Kausap AI Daily Breathwork activity as home practice.""";
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
                padding: EdgeInsets.fromLTRB(20, isMobile ? 54 : 32, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Clinical Insights & Reports",
                      style: AppTextStyles.heading1.copyWith(
                        fontSize: 26,
                        letterSpacing: -0.5,
                        color: const Color(0xFF2C3E50),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Review patient diagnostic screeners, AI case summaries & clinical copilot.",
                      style: AppTextStyles.body.copyWith(color: const Color(0xFF707974), fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    // Tab Bar
                    Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE8EAED)),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        labelColor: AppColors.primary,
                        unselectedLabelColor: const Color(0xFF707974),
                        indicatorColor: AppColors.primary,
                        indicatorWeight: 3,
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        tabs: const [
                          Tab(text: "Assessment Reports"),
                          Tab(text: "AI Clinical Copilot"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAssessmentReportsTab(),
                    _buildAICopilotTab(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Tab 1: Assessment Reports ───────────────────────────────────────────
  Widget _buildAssessmentReportsTab() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 80),
      itemCount: _reports.length,
      itemBuilder: (context, index) {
        final report = _reports[index];
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
              // Header: Client Name, Date & Screener Type
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: report.severityColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.assignment_outlined, color: report.severityColor, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            report.clientName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2C3E50)),
                          ),
                          Text(
                            report.screenerType,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF707974), fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: report.severityColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      report.severity,
                      style: TextStyle(color: report.severityColor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFF1F3F4)),
              const SizedBox(height: 10),

              // Score & AI Analysis Summary
              Row(
                children: [
                  const Text("Diagnostic Score: ", style: TextStyle(fontSize: 12, color: Color(0xFF707974))),
                  Text(
                    "${report.score} / ${report.maxScore}",
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                  ),
                  const Spacer(),
                  Text(report.dateStr, style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: Text(
                  report.aiSummary,
                  style: const TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF4A5568)),
                ),
              ),
              const SizedBox(height: 10),

              // Symptom Tags
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: report.primarySymptoms
                    .map((s) => Chip(
                          label: Text(s, style: const TextStyle(fontSize: 10, color: Color(0xFF334155))),
                          backgroundColor: const Color(0xFFF1F5F9),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6), side: BorderSide.none),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 12),

              // Action Buttons: View Full Report & Export PDF
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showFullReportModal(context, report),
                      icon: const Icon(Icons.visibility_outlined, size: 14),
                      label: const Text("View Full Report", style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: Color(0xFFD6F1FC)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Exported clinical PDF report for ${report.clientName}!"),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      },
                      icon: const Icon(Icons.download_rounded, size: 14),
                      label: const Text("Export PDF", style: TextStyle(fontSize: 12)),
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
      },
    );
  }

  // ── Tab 2: AI Clinical Copilot ───────────────────────────────────────────
  Widget _buildAICopilotTab() {
    final promptPills = [
      "CBT thought record for panic anxiety",
      "Behavioral activation plan for depression",
      "Grounding sensory scans for trauma triggers",
      "PHQ-9 clinical score interpretation guidelines",
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Copilot Introduction Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0077B6), Color(0xFF023E8A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Color(0x1A0077B6), blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Kausap AI Clinical Copilot",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "Enter client symptoms, test scores, or treatment dilemmas for instant evidence-based CBT/DBT protocols.",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Quick Prompt Pills
          const Text("Quick Clinical Prompts:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2C3E50))),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: promptPills.map((pill) {
              return ActionChip(
                label: Text(pill, style: const TextStyle(fontSize: 11, color: Color(0xFF0077B6), fontWeight: FontWeight.w600)),
                backgroundColor: const Color(0xFFE3F2FD),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
                onPressed: () {
                  _copilotQueryController.text = pill;
                  _handleCopilotQuery(pill);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Search & Query Field
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8EAED)),
              boxShadow: const [
                BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 3)),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _copilotQueryController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: "Describe patient presentation or ask for therapeutic homework ideas...",
                    hintStyle: TextStyle(fontSize: 13, color: Color(0xFF9E9E9E)),
                    border: InputBorder.none,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Evidence-Based CBT/DBT", style: TextStyle(fontSize: 11, color: Color(0xFF707974))),
                    ElevatedButton.icon(
                      onPressed: () => _handleCopilotQuery(_copilotQueryController.text),
                      icon: const Icon(Icons.auto_awesome_rounded, size: 14),
                      label: const Text("Generate Strategy"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Generating Spinner or Copilot Result Card
          if (_isCopilotGenerating)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text("Synthesizing clinical strategy with DSM-5 guidelines...", style: TextStyle(fontSize: 12, color: Color(0xFF707974))),
                  ],
                ),
              ),
            )
          else if (_copilotResult != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD6F1FC)),
                boxShadow: const [
                  BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 3)),
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
                          Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 18),
                          SizedBox(width: 8),
                          Text("Clinical Copilot Strategy", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2C3E50))),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, color: Color(0xFF707974), size: 16),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Strategy copied to clipboard!"), backgroundColor: AppColors.primary),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1, color: Color(0xFFF1F3F4)),
                  const SizedBox(height: 12),
                  Text(
                    _copilotResult!,
                    style: const TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF2C3E50)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Full Report Modal ──────────────────────────────────────────────────
  void _showFullReportModal(BuildContext context, AssessmentReportItem report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(report.clientName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                          Text(report.screenerType, style: const TextStyle(fontSize: 12, color: Color(0xFF707974))),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: report.severityColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          report.severity,
                          style: TextStyle(color: report.severityColor, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Divider(height: 1, color: Color(0xFFF1F3F4)),
                  const SizedBox(height: 16),

                  // Assessment Breakdown
                  const Text("Screener Score Interpretation", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2C3E50))),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE8EAED))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Total Calculated Score:", style: TextStyle(fontSize: 13, color: Color(0xFF555F6D))),
                            Text("${report.score} / ${report.maxScore}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(report.aiSummary, style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF4A5568))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Recommended Interventions
                  const Text("Evidence-Based Recommendations", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2C3E50))),
                  const SizedBox(height: 8),
                  ...report.recommendedInterventions.map((rec) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle_outline_rounded, color: AppColors.primary, size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text(rec, style: const TextStyle(fontSize: 13, color: Color(0xFF334155)))),
                          ],
                        ),
                      )),
                  const SizedBox(height: 24),

                  // Actions: Print/Export & Close
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Exported PDF chart for ${report.clientName}!"), backgroundColor: AppColors.primary),
                            );
                          },
                          icon: const Icon(Icons.download_rounded, size: 16),
                          label: const Text("Export PDF"),
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
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("Close"),
                        ),
                      ),
                    ],
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
