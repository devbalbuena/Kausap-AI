import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../chat/direct_message_screen.dart';
import '../session/book_session_screen.dart';

class ProfessionalProfileScreen extends StatelessWidget {
  final Map<String, dynamic> professionalData;
  final String? heroTag;

  const ProfessionalProfileScreen({
    super.key,
    required this.professionalData,
    this.heroTag,
  });

  String _getInitials(String firstName, String lastName) {
    return '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}';
  }

  @override
  Widget build(BuildContext context) {
    final firstName = professionalData['first_name'] ?? '';
    final lastName = professionalData['last_name'] ?? '';
    final fullName = '$firstName $lastName';
    final profession = professionalData['profession'] ?? 'Therapist';
    final specialization = professionalData['specialization'] ?? '';
    final experience = professionalData['years_of_experience'] ?? 0;
    final bio = professionalData['bio'] ?? 'No biography provided.';
    final location = professionalData['location'] ?? 'Virtual';
    final profId = professionalData['user_id'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded, size: 28, color: AppColors.textPrimary),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          'Professional Profile',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Avatar
                        Hero(
                          tag: heroTag ?? 'avatar_${professionalData['user_id'] ?? fullName}',
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: AppColors.primary.withAlpha(20),
                            child: Text(
                              _getInitials(firstName, lastName),
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                fontSize: 32,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Name & Title
                        Text(
                          fullName,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 22,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profession,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Stats Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildStatItem(Icons.star_rounded, const Color(0xFFF59E0B), '5.0', 'Rating'),
                            Container(width: 1, height: 30, color: const Color(0xFFE2E8F0), margin: const EdgeInsets.symmetric(horizontal: 16)),
                            _buildStatItem(Icons.work_outline_rounded, const Color(0xFF3B82F6), '$experience yrs', 'Experience'),
                            Container(width: 1, height: 30, color: const Color(0xFFE2E8F0), margin: const EdgeInsets.symmetric(horizontal: 16)),
                            _buildStatItem(Icons.location_on_outlined, const Color(0xFFEF4444), location, 'Location'),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // About Section
                        _buildSectionCard(
                          title: 'About Me',
                          child: Text(
                            bio,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              height: 1.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Specialization Section
                        _buildSectionCard(
                          title: 'Specializations',
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: specialization.split(',').map((spec) {
                              final s = spec.trim();
                              if (s.isEmpty) return const SizedBox.shrink();
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withAlpha(20),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  s,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Actions
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DirectMessageScreen(
                                        otherUserId: profId,
                                        otherUserName: fullName,
                                        otherUserRole: 'professional',
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                                label: const Text('Message', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const BookSessionScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.calendar_today_rounded, size: 20),
                                label: const Text('Book Session', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, Color color, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
        Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
