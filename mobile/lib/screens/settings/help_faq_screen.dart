import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_routes.dart';
import 'privacy_center_screen.dart';
import 'download_data_screen.dart';

class HelpFaqScreen extends StatelessWidget {
  const HelpFaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = KausapColors.accent(context);

    return Scaffold(
      backgroundColor: KausapColors.scaffoldBg(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: KausapColors.textPrimary(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Help & FAQ',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: KausapColors.textPrimary(context),
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              // Support Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accent, KausapColors.accentLight(context)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withAlpha(50),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.support_agent_rounded, size: 40, color: Colors.white),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'How can we support you?',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                              fontSize: 16.5,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Answers to common questions about your mental health companion.',
                            style: TextStyle(
                              color: Color(0xFFE0F2FE),
                              fontFamily: 'Inter',
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'FREQUENTLY ASKED QUESTIONS',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 0.7,
                  color: KausapColors.textMuted(context),
                ),
              ),
              const SizedBox(height: 12),

              _buildFaqItem(
                context,
                'How does Kausap AI companion chat work?',
                'Kausap AI is an empathetic AI chatbot powered by Google Gemini. It offers a safe, non-judgmental space to vent, practice cognitive reframing, and reflect in English or Taglish. Note that Kausap AI is a wellness companion, not a licensed medical substitute.',
              ),
              _buildFaqItem(
                context,
                'Are my daily journals, voice notes, and mood logs private?',
                'Yes. Your journal entries, audio dictations, and emotional check-ins are encrypted. You can also turn on App Lock (PIN & Biometrics) in Security Settings to protect your journal when leaving your phone unattended.',
              ),
              _buildFaqItem(
                context,
                'How do the PHQ-9 and GAD-7 screeners work?',
                'The Patient Health Questionnaire-9 (PHQ-9) and Generalized Anxiety Disorder-7 (GAD-7) are standardized clinical self-assessments. They help you track your depression and anxiety severity over time and generate confidential wellness summaries.',
              ),
              _buildFaqItem(
                context,
                'What should I do if I am in an emotional crisis?',
                'If you or someone you know is experiencing a mental health emergency or suicidal thoughts, please call the 24/7 National Center for Mental Health (NCMH) toll-free hotline at 1553, or dial 911 immediately. You can also access Crisis Resources in the Support menu.',
              ),
              _buildFaqItem(
                context,
                'Can I export or download my wellness data?',
                'Yes. Go to Settings > Privacy Controls & Shield > Download My Wellness Data to export a copy of your journal reflections, screener scores, and mood trends as an encrypted JSON archive.',
              ),

              const SizedBox(height: 24),

              // Quick Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(context, slideRoute(const PrivacyCenterScreen()));
                      },
                      icon: Icon(Icons.shield_outlined, size: 16, color: accent),
                      label: Text(
                        'Privacy Shield',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: accent),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: accent),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(context, slideRoute(const DownloadDataScreen()));
                      },
                      icon: Icon(Icons.download_rounded, size: 16, color: accent),
                      label: Text(
                        'Export Data',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: accent),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: accent),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaqItem(BuildContext context, String question, String answer) {
    final accent = KausapColors.accent(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: KausapColors.cardBg(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: KausapColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: KausapColors.isDark(context) ? Colors.transparent : const Color(0x04000000),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: accent,
          collapsedIconColor: KausapColors.textMuted(context),
          title: Text(
            question,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
              color: KausapColors.textPrimary(context),
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text(
              answer,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                height: 1.5,
                color: KausapColors.textMuted(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
