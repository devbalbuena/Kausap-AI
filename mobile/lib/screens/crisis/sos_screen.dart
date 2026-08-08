import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'crisis_resources_sheet.dart';
import 'emergency_contacts_screen.dart';

class SosScreen extends StatelessWidget {
  const SosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF1F1),
      appBar: AppBar(
        title: Text('Get Help Now', style: AppTextStyles.heading2.copyWith(color: Colors.red.shade700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.red.shade700),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.favorite_rounded, color: Colors.red.shade400, size: 40),
                    const SizedBox(height: 12),
                    Text(
                      'You are not alone.',
                      style: AppTextStyles.heading2.copyWith(color: Colors.red.shade700),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Reaching out takes courage. We are here to help you find the support you deserve.',
                      style: AppTextStyles.subheading.copyWith(color: Colors.red.shade600),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text('Quick Actions', style: AppTextStyles.heading2),
              const SizedBox(height: 16),
              _buildActionTile(
                context,
                icon: Icons.phone_rounded,
                color: Colors.red,
                title: 'Crisis Hotlines',
                subtitle: 'View local emergency numbers and helplines',
                onTap: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const CrisisResourcesSheet(),
                ),
              ),
              const SizedBox(height: 12),
              _buildActionTile(
                context,
                icon: Icons.contacts_rounded,
                color: Colors.orange,
                title: 'Emergency Contacts',
                subtitle: 'Reach out to your trusted contacts',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EmergencyContactsScreen()),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('I am safe, go back', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppTextStyles.subheading.copyWith(fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
