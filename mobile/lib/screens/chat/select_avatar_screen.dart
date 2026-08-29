import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../models/avatar_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_routes.dart';
import '../../utils/haptic_service.dart';
import '../../widgets/chat/custom_avatar_painter.dart';
import '../subscription/upgrade_plan_screen.dart';
import 'custom_avatar_studio_screen.dart';

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
  int _selectedFilterIndex = 0; // 0: All, 1: Campus Peers, 2: Premium Specialists, 3: My Custom

  final List<String> _filters = ['All', '🌱 Campus Peers', '👑 Premium Specialists', '✨ My Custom'];

  @override
  void initState() {
    super.initState();
    _selected = widget.currentAvatar;
    _loadCustomAvatars();
  }

  Future<void> _loadCustomAvatars() async {
    try {
      final jsonStr = await _storage.read(key: 'custom_avatars_list_json');
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> list = jsonDecode(jsonStr);
        final loaded = list.map((item) => AvatarModel.fromJson(item as Map<String, dynamic>)).toList();
        if (mounted) {
          setState(() {
            _customAvatars = loaded;
          });
        }
      }
    } catch (_) {
      // Fallback if legacy single avatar exists
      final customName = await _storage.read(key: 'custom_avatar_name');
      final customPrompt = await _storage.read(key: 'custom_avatar_prompt');
      if (mounted && customName != null && customName.isNotEmpty) {
        setState(() {
          _customAvatars = [
            AvatarModel(
              id: 'custom_user_avatar',
              name: customName,
              roleTitle: 'Custom Companion',
              tier: 'basic',
              imagePath: 'assets/avatars/avatar_basic_kim.png',
              systemPrompt: customPrompt ?? 'You are $customName, a personalized mental wellness AI companion.',
              bio: 'Your personalized custom AI wellness companion.',
              sampleQuote: '"Nandito ako para makinig sa\'yo anumang oras."',
              specialties: const ['Personalized Support'],
            ),
          ];
        });
      }
    }
  }

  Future<void> _saveCustomAvatarsList() async {
    final list = _customAvatars.map((a) => a.toJson()).toList();
    await _storage.write(key: 'custom_avatars_list_json', value: jsonEncode(list));
  }

  Future<void> _onSelectAvatar(AvatarModel avatar) async {
    HapticService.lightTap();
    setState(() => _selected = avatar);
    await _storage.write(key: 'selected_chatbot_avatar_id', value: avatar.id);
    if (mounted) {
      Navigator.of(context).pop(avatar);
    }
  }

  void _showAvatarDetailSheet(AvatarModel avatar) {
    HapticService.mediumTap();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Avatar Preview Circle
              Stack(
                alignment: Alignment.topRight,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: avatar.isMascot ? const Color(0x330077B6) : Colors.black.withAlpha(25),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: avatar.customConfig != null
                        ? CustomAvatarWidget(config: avatar.customConfig!, size: 84)
                        : (avatar.isMascot
                            ? Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF0077B6), Color(0xFF00B4D8)],
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(Icons.smart_toy_rounded, color: Colors.white, size: 48),
                                ),
                              )
                            : ClipOval(
                                child: Image.asset(
                                  avatar.imagePath,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Container(
                                    color: const Color(0xFFEEF2FF),
                                    child: const Icon(Icons.person, color: AppColors.primary, size: 44),
                                  ),
                                ),
                              )),
                  ),
                  if (avatar.isPremium)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFF59E0B)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('👑', style: TextStyle(fontSize: 10)),
                          SizedBox(width: 2),
                          Text(
                            'SPECIALIST',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFB45309),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                avatar.name,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                avatar.roleTitle,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0284C7),
                ),
              ),
              const SizedBox(height: 14),
              // Bio & Quote
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      avatar.bio,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        color: Color(0xFF334155),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('💬 ', style: TextStyle(fontSize: 12)),
                        Expanded(
                          child: Text(
                            avatar.sampleQuote,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11.5,
                              fontStyle: FontStyle.italic,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Specialty Chips
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: avatar.specialties.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '# $tag',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              // Select Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _onSelectAvatar(avatar);
                  },
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: Text(_selected.id == avatar.id ? 'Already Selected' : 'Chat with ${avatar.name}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: avatar.isPremium ? const Color(0xFFD97706) : AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
              if (avatar.id.startsWith('custom_') || avatar.customConfig != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _openCustomAvatarStudio(editAvatar: avatar);
                        },
                        icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
                        label: const Text('Edit Persona', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: AppColors.primary)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          side: const BorderSide(color: AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _deleteCustomAvatar(avatar.id);
                      },
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                      tooltip: 'Delete Custom Avatar',
                    ),
                  ],
                ),
              ],
              if (avatar.isPremium) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.of(context).push(slideRoute(const UpgradePlanScreen()));
                    },
                    icon: const Text('👑', style: TextStyle(fontSize: 14)),
                    label: const Text(
                      'View Kausap Premium Subscription Plans',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openCustomAvatarStudio({AvatarModel? editAvatar}) async {
    HapticService.lightTap();
    final result = await Navigator.push<AvatarModel>(
      context,
      MaterialPageRoute(builder: (_) => CustomAvatarStudioScreen(editAvatar: editAvatar)),
    );
    if (result != null) {
      await _loadCustomAvatars();
      await _onSelectAvatar(result);
    }
  }

  Future<void> _deleteCustomAvatar(String id) async {
    _customAvatars.removeWhere((a) => a.id == id);
    await _saveCustomAvatarsList();
    if (_selected.id == id) {
      _selected = AvatarData.defaultAvatar;
      await _storage.write(key: 'selected_chatbot_avatar_id', value: _selected.id);
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Filter avatars based on selected tab
    List<AvatarModel> displayedAvatars = [];
    if (_selectedFilterIndex == 0) {
      // All
      displayedAvatars = [...AvatarData.all, ..._customAvatars];
    } else if (_selectedFilterIndex == 1) {
      // Campus Peers
      displayedAvatars = AvatarData.all.where((a) => !a.isPremium).toList();
    } else if (_selectedFilterIndex == 2) {
      // Premium Specialists
      displayedAvatars = AvatarData.all.where((a) => a.isPremium).toList();
    } else if (_selectedFilterIndex == 3) {
      // My Custom
      displayedAvatars = _customAvatars;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Header ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x10000000),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, size: 16, color: Color(0xFF1E293B)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select AI Companion',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Choose who you want to talk with today',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Create Custom Avatar Action Bar ──────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: GestureDetector(
                onTap: () => _openCustomAvatarStudio(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEEF2FF), Color(0xFFE0F2FE)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withAlpha(60)),
                    boxShadow: const [
                      BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_circle_outline_rounded, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        '+ Create Custom Companion Persona',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Filter Chips Row ─────────────────────────────────────────
            Container(
              height: 38,
              margin: const EdgeInsets.only(top: 4, bottom: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _filters.length,
                itemBuilder: (context, idx) {
                  final isSelected = _selectedFilterIndex == idx;
                  return GestureDetector(
                    onTap: () {
                      HapticService.lightTap();
                      setState(() => _selectedFilterIndex = idx);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withAlpha(50),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        _filters[idx],
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.white : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            if (_selectedFilterIndex == 2)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: GestureDetector(
                  onTap: () {
                    HapticService.lightTap();
                    Navigator.push(context, slideRoute(const UpgradePlanScreen()));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFEF3C7), Color(0xFFFFFBEB)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                      boxShadow: const [
                        BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Text('👑', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Unlock All Premium Specialists',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF92400E),
                                ),
                              ),
                              Text(
                                'Unlimited deep clinical & CBT guidance',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD97706),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'View Plans',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // ── Avatars Grid ─────────────────────────────────────────────
            Expanded(
              child: displayedAvatars.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.person_add_alt_1_rounded, size: 48, color: Color(0xFFCBD5E1)),
                          const SizedBox(height: 12),
                          const Text(
                            'No custom companions yet',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Tap the button above to build your own persona!',
                            style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 0.78,
                      ),
                      itemCount: displayedAvatars.length,
                      itemBuilder: (_, i) {
                        final avatar = displayedAvatars[i];
                        final isCustom = avatar.id.startsWith('custom_');
                        return _AvatarCard(
                          avatar: avatar,
                          isSelected: _selected.id == avatar.id,
                          isCustom: isCustom,
                          onTap: () => _onSelectAvatar(avatar),
                          onInfoTap: () => _showAvatarDetailSheet(avatar),
                          onEditTap: isCustom ? () => _openCustomAvatarStudio(editAvatar: avatar) : null,
                        );
                      },
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
  final bool isCustom;
  final VoidCallback onTap;
  final VoidCallback onInfoTap;
  final VoidCallback? onEditTap;

  const _AvatarCard({
    required this.avatar,
    required this.isSelected,
    this.isCustom = false,
    required this.onTap,
    required this.onInfoTap,
    this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (avatar.isPremium ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0)),
            width: isSelected ? 2.5 : (avatar.isPremium ? 1.5 : 1),
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.primary.withAlpha(25)
                  : (avatar.isPremium ? const Color(0x10D97706) : const Color(0x06000000)),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Top Right Badges (Crown, Edit button, or Info icon)
            Positioned(
              top: 0,
              right: 0,
              child: Row(
                children: [
                  if (avatar.isPremium)
                    Container(
                      margin: const EdgeInsets.only(right: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('👑', style: TextStyle(fontSize: 10)),
                    ),
                  if (isCustom || avatar.customConfig != null)
                    GestureDetector(
                      onTap: onEditTap,
                      child: Container(
                        margin: const EdgeInsets.only(right: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primary.withAlpha(90)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit_outlined, size: 10, color: AppColors.primary),
                            SizedBox(width: 2),
                            Text(
                              'Edit',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  GestureDetector(
                    onTap: onInfoTap,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),
            ),

            // Main Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 66,
                    height: 66,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: avatar.isMascot && avatar.customConfig == null
                          ? const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF0077B6), Color(0xFF00B4D8)],
                            )
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: avatar.isMascot ? const Color(0x330077B6) : Colors.black.withAlpha(20),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: avatar.customConfig != null
                        ? CustomAvatarWidget(config: avatar.customConfig!, size: 66)
                        : (avatar.isMascot
                            ? Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF0077B6), Color(0xFF00B4D8)],
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(Icons.smart_toy_rounded, color: Colors.white, size: 36),
                                ),
                              )
                            : ClipOval(
                                child: Image.asset(
                                  avatar.imagePath,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Container(
                                    color: const Color(0xFFEEF2FF),
                                    child: const Icon(Icons.person, color: AppColors.primary, size: 34),
                                  ),
                                ),
                              )),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    avatar.name,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      color: Color(0xFF0F172A),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    avatar.roleTitle,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      color: avatar.isPremium ? const Color(0xFFB45309) : const Color(0xFF64748B),
                      fontWeight: avatar.isPremium ? FontWeight.w600 : FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  if (isSelected)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Active ✓',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0284C7),
                            ),
                          ),
                        ),
                        if (isCustom || avatar.customConfig != null) ...[
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: onEditTap,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              child: const Text(
                                'Edit ✏️',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    )
                  else if (isCustom || avatar.customConfig != null)
                    GestureDetector(
                      onTap: onEditTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primary.withAlpha(70)),
                        ),
                        child: const Text(
                          'Edit ✏️',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
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
