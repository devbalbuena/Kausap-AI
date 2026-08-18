import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../models/avatar_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_routes.dart';
import '../subscription/upgrade_plan_screen.dart';

class SelectAvatarScreen extends StatefulWidget {
  final AvatarModel currentAvatar;
  const SelectAvatarScreen({super.key, required this.currentAvatar});

  @override
  State<SelectAvatarScreen> createState() => _SelectAvatarScreenState();
}

class _SelectAvatarScreenState extends State<SelectAvatarScreen> {
  static const _storage = FlutterSecureStorage();
  late AvatarModel _selected;
  List<AvatarModel> _customAvatars = [];
  bool _isPro = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentAvatar;
    _loadCustomAvatars();
  }

  Future<void> _loadCustomAvatars() async {
    final pro = await _storage.read(key: 'is_pro_member');
    final customName = await _storage.read(key: 'custom_avatar_name');
    final customPrompt = await _storage.read(key: 'custom_avatar_prompt');

    if (mounted) {
      setState(() {
        _isPro = pro == 'true';
        if (customName != null && customName.isNotEmpty) {
          _customAvatars = [
            AvatarModel(
              id: 'custom_user_avatar',
              name: customName,
              tier: 'basic',
              imagePath: 'assets/avatars/avatar_basic_kim.png',
              systemPrompt: customPrompt ?? 'You are $customName, a personalized mental wellness AI companion.',
            ),
          ];
        }
      });
    }
  }

  Future<void> _onTapAvatar(AvatarModel avatar) async {
    if (avatar.isPremium && !_isPro) {
      _showUpgradeDialog();
      return;
    }
    setState(() => _selected = avatar);
    await _storage.write(key: 'selected_chatbot_avatar_id', value: avatar.id);
    if (mounted) {
      Navigator.of(context).pop(avatar);
    }
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Text('👑 ', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 4),
            Text('Premium Avatar', style: AppTextStyles.heading2),
          ],
        ),
        content: Text(
          'This specialist avatar is available with Kausap AI Pro. Upgrade your plan to unlock all premium AI personas and exclusive features.',
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Maybe Later', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).push(slideRoute(const UpgradePlanScreen()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Upgrade Plan'),
          ),
        ],
      ),
    );
  }

  void _showCreateCustomAvatarSheet() {
    final nameController = TextEditingController();
    String selectedPersona = 'Empathetic & Nurturing';
    final personas = [
      'Empathetic & Nurturing',
      'Cognitive & Solution-Focused',
      'Casual & Sibling/Friend Vibe',
      'Mindful & Zen Coach',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('✨', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Text('Create Custom Companion', style: AppTextStyles.heading2.copyWith(fontSize: 18)),
                ],
              ),
              const SizedBox(height: 16),

              Text('Companion Name', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: nameController,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'e.g. Maya, Coach Leo, Ate Sarah',
                  hintStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary),
                  filled: true,
                  fillColor: const Color(0xFFF3F4F6),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),

              Text('Personality & Tone', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: personas.map((p) {
                  final isSel = selectedPersona == p;
                  return GestureDetector(
                    onTap: () => setSheetState(() => selectedPersona = p),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSel ? AppColors.primary : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSel ? AppColors.primary : const Color(0x22000000)),
                      ),
                      child: Text(
                        p,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSel ? Colors.white : const Color(0xFF374151),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;

                    final prompt = 'You are $name, a $selectedPersona mental wellness companion for the user. Always be warm, safe, and helpful.';
                    await _storage.write(key: 'custom_avatar_name', value: name);
                    await _storage.write(key: 'custom_avatar_prompt', value: prompt);

                    final custom = AvatarModel(
                      id: 'custom_user_avatar',
                      name: name,
                      tier: 'basic',
                      imagePath: 'assets/avatars/avatar_basic_kim.png',
                      systemPrompt: prompt,
                    );

                    if (mounted) {
                      setState(() {
                        _customAvatars = [custom];
                      });
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                    await _onTapAvatar(custom);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save & Select Companion', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final basicAvatars = [
      ...AvatarData.all.where((a) => !a.isPremium),
      ..._customAvatars,
    ];
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
                onTap: _showCreateCustomAvatarSheet,
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
                      const Icon(Icons.add_circle_outline_rounded, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Create Custom Companion Avatar',
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
                  Text('Basic Personas', style: AppTextStyles.heading2.copyWith(fontSize: 16)),
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
                      Text('Specialist Personas', style: AppTextStyles.heading2.copyWith(fontSize: 16)),
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
                      isProUnlocked: _isPro,
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
  final bool isProUnlocked;
  final VoidCallback onTap;

  const _AvatarCard({
    required this.avatar,
    required this.isSelected,
    this.isProUnlocked = false,
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
                      errorBuilder: (_, _, _) => Container(
                        color: const Color(0xFFEEF2FF),
                        child: const Icon(Icons.person, color: AppColors.primary, size: 40),
                      ),
                    ),
                  ),
                ),
                if (avatar.isPremium && !isProUnlocked)
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
                isProUnlocked ? 'Unlocked' : 'Pro Specialist',
                style: AppTextStyles.body.copyWith(
                  fontSize: 11,
                  color: isProUnlocked ? const Color(0xFF10B981) : const Color(0xFFFFC107),
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
