import 'package:flutter/material.dart';
import '../../models/avatar_model.dart';
import '../../theme/app_theme.dart';

/// Phase 21 — Select Avatar Screen
/// Figma: "Premium/Select Avatar"
/// 
/// Shows a grid of Basic (free) avatars and Premium (locked) avatars.
/// Tapping a free avatar selects it and pops back.
/// Tapping a premium avatar shows an "Upgrade Plan" nudge.
class SelectAvatarScreen extends StatefulWidget {
  final AvatarModel currentAvatar;
  const SelectAvatarScreen({super.key, required this.currentAvatar});

  @override
  State<SelectAvatarScreen> createState() => _SelectAvatarScreenState();
}

class _SelectAvatarScreenState extends State<SelectAvatarScreen> {
  late AvatarModel _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentAvatar;
  }

  void _onTapAvatar(AvatarModel avatar) {
    if (avatar.isPremium) {
      _showUpgradeDialog();
      return;
    }
    setState(() => _selected = avatar);
    Navigator.of(context).pop(avatar);
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Text('👑 ', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 4),
            Text('Premium Avatar', style: AppTextStyles.heading2),
          ],
        ),
        content: Text(
          'This avatar is available with Kausap AI Premium. Upgrade your plan to unlock all premium avatars and exclusive features.',
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Upgrade Plan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final basicAvatars = AvatarData.all.where((a) => !a.isPremium).toList();
    final premiumAvatars = AvatarData.all.where((a) => a.isPremium).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, size: 16, color: Color(0xFF191C21)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text('Select Avatar', style: AppTextStyles.heading2.copyWith(fontSize: 18)),
                ],
              ),
            ),

            // ── Create Custom Avatar Banner ──────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Custom avatar creation coming soon!')),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Create Custom Avatar',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Scrollable Avatar Grid ───────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  // Basic Section
                  Text('Basic', style: AppTextStyles.heading2.copyWith(fontSize: 16)),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: basicAvatars.length,
                    itemBuilder: (_, i) => _AvatarCard(
                      avatar: basicAvatars[i],
                      isSelected: _selected.id == basicAvatars[i].id,
                      onTap: () => _onTapAvatar(basicAvatars[i]),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Premium Section
                  Row(
                    children: [
                      Text('Premium', style: AppTextStyles.heading2.copyWith(fontSize: 16)),
                      const SizedBox(width: 8),
                      const Text('👑', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: premiumAvatars.length,
                    itemBuilder: (_, i) => _AvatarCard(
                      avatar: premiumAvatars[i],
                      isSelected: _selected.id == premiumAvatars[i].id,
                      onTap: () => _onTapAvatar(premiumAvatars[i]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarCard extends StatelessWidget {
  final AvatarModel avatar;
  final bool isSelected;
  final VoidCallback onTap;

  const _AvatarCard({
    required this.avatar,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      avatar.imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, _) => Container(
                        color: const Color(0xFFEEF2FF),
                        child: Icon(Icons.person, color: AppColors.primary, size: 40),
                      ),
                    ),
                  ),
                ),
                if (avatar.isPremium)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFC107),
                        shape: BoxShape.circle,
                      ),
                      child: const Text('👑', style: TextStyle(fontSize: 10)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              avatar.name,
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF191C21),
              ),
            ),
            if (avatar.isPremium)
              Text(
                'Premium',
                style: AppTextStyles.body.copyWith(
                  fontSize: 11,
                  color: const Color(0xFFFFC107),
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
