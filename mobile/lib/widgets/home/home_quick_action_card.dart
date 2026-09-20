import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class HomeQuickActionCard extends StatelessWidget {
  final Color iconBg;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const HomeQuickActionCard({
    super.key,
    required this.iconBg,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$title. $subtitle',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: KausapColors.border(context)),
            boxShadow: [
              BoxShadow(
                color: KausapColors.accentShadow(context),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24, semanticLabel: title),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTextStyles.caption),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: KausapColors.textMuted(context),
                size: 24,
                semanticLabel: 'navigate',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeQuoteCard extends StatelessWidget {
  const HomeQuoteCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KausapColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: KausapColors.accentShadow(context),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Text('"', style: TextStyle(fontSize: 32, color: KausapColors.border(context))),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'It is better to conquer yourself than to win a thousand battles',
              style: AppTextStyles.body.copyWith(
                color: KausapColors.textMuted(context),
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeScreenerPromoCard extends StatelessWidget {
  final VoidCallback onTakeAssessment;

  const HomeScreenerPromoCard({
    super.key,
    required this.onTakeAssessment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            KausapColors.accent(context),
            KausapColors.accent(context).withAlpha(210),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: KausapColors.accentShadow(context),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MENTAL HEALTH SCREENERS',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Take evidence-based PHQ-9 & GAD-7 screeners to track depression and anxiety trends.',
                  style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: KausapColors.accent(context),
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 1,
              textStyle: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            onPressed: onTakeAssessment,
            child: const Text('Take Assessment'),
          ),
        ],
      ),
    );
  }
}
