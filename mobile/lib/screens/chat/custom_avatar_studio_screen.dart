import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../models/avatar_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/haptic_service.dart';
import '../../widgets/chat/custom_avatar_painter.dart';

class CustomAvatarStudioScreen extends StatefulWidget {
  final AvatarModel? editAvatar;

  const CustomAvatarStudioScreen({super.key, this.editAvatar});

  @override
  State<CustomAvatarStudioScreen> createState() => _CustomAvatarStudioScreenState();
}

class _CustomAvatarStudioScreenState extends State<CustomAvatarStudioScreen> {
  static const _storage = FlutterSecureStorage();

  int _currentStep = 0; // 0: Look, 1: Identity, 2: Voice & Dialect
  bool _isMascotMode = false;

  // Visual Customization States
  int _skinIndex = 1;
  int _hairIndex = 1;
  int _hairColorIndex = 0;
  int _eyeStyleIndex = 0;
  int _eyeColorIndex = 0;
  int _accIndex = 0;
  int _outfitIndex = 0;
  int _outfitColorIndex = 0;
  int _mascotHueIndex = 0;

  // Identity & Relationship States
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _callSignController = TextEditingController(text: 'Beshie');
  final TextEditingController _catchphraseController = TextEditingController();

  String _selectedRelationship = 'Best Friend / Barkada';
  String _selectedDialect = 'taglish';
  String _selectedTone = 'warm';

  final List<Map<String, dynamic>> _relationshipArchetypes = [
    {
      'title': 'Best Friend / Barkada',
      'role': 'Best Friend & Barkada',
      'icon': '👯',
      'desc': 'Casual, relatable campus peer who hypes you up, gossips, and gives comforting energy without judgment.',
      'defaultCallSign': 'Beshie',
      'sampleGreeting': 'Kumusta ka today, beshie? Pahinga ka muna, deserve mo \'yan! ✨',
    },
    {
      'title': 'Ate / Kuya (Older Sibling)',
      'role': 'Ate/Kuya Senior Mentor',
      'icon': '👩‍🏫',
      'desc': 'Protective, gentle older sibling advice. Always checks if you ate and gives seasoned campus guidance.',
      'defaultCallSign': 'Bunso',
      'sampleGreeting': 'Kumusta ka, bunso? Huwag magpapalipas ng gutom ha, nandito lang si Ate/Kuya para sa\'yo. 🌿',
    },
    {
      'title': 'Thesis & Study Partner',
      'role': 'Academic Study Partner',
      'icon': '🎓',
      'desc': 'Focus-driven, anti-procrastination buddy. Helps break down deadlines and study sprints step-by-step.',
      'defaultCallSign': 'Partner',
      'sampleGreeting': 'One chapter at a time tayo, partner. Let\'s conquer today\'s deadlines together! 📚',
    },
    {
      'title': 'Gentle Safe Haven',
      'role': 'Emotional Safe Space',
      'icon': '🌿',
      'desc': 'Pure active listening and validation. Zero unsolicited advice unless you explicitly ask for it.',
      'defaultCallSign': 'Friend',
      'sampleGreeting': 'Nandito ako para makinig sa lahat ng nararamdaman mo. Take all the time you need. 💜',
    },
    {
      'title': 'Loving Parent / Tita Figure',
      'role': 'Nurturing Mentor',
      'icon': '☕',
      'desc': 'Warm maternal comfort, soothing life reminders, and unconditional emotional safety.',
      'defaultCallSign': 'Anak',
      'sampleGreeting': 'Anak, it\'s okay to rest. You are doing so well and I am very proud of you. ❤️',
    },
  ];

  final List<Map<String, String>> _dialects = [
    {
      'id': 'taglish',
      'title': 'Metro Taglish 🇵🇭',
      'desc': 'Natural, relatable campus Taglish (e.g. "Kumusta ka today, besh? Kaya mo \'yan!")',
    },
    {
      'id': 'bisaya',
      'title': 'Bisaya / Cebuano 🌴',
      'desc': 'Warm VisMin campus dialect (e.g. "Kumusta man ka karon? Ayaw kabalaka, kaya ra na nimo!")',
    },
    {
      'id': 'filipino',
      'title': 'Conversational Filipino 🇵🇭',
      'desc': 'Warm, deeply comforting Tagalog (e.g. "Nandito ako palagi para makinig sa iyo nang buong puso.")',
    },
    {
      'id': 'english',
      'title': 'Calm & Academic English 🌍',
      'desc': 'Structured, reassuring English (e.g. "Take a breath. Let\'s break this down together step by step.")',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingAvatarData();
  }

  void _loadExistingAvatarData() {
    if (widget.editAvatar != null) {
      final a = widget.editAvatar!;
      _nameController.text = a.name;
      if (a.customConfig != null) {
        final c = a.customConfig!;
        _isMascotMode = c['type'] == 'mascot';
        _skinIndex = (c['skinIndex'] as int? ?? 1).clamp(0, 3);
        _hairIndex = (c['hairIndex'] as int? ?? 1).clamp(0, 4);
        _hairColorIndex = (c['hairColorIndex'] as int? ?? 0).clamp(0, 4);
        _eyeStyleIndex = (c['eyeStyleIndex'] as int? ?? 0).clamp(0, 2);
        _eyeColorIndex = (c['eyeColorIndex'] as int? ?? 0).clamp(0, 4);
        _accIndex = (c['accIndex'] as int? ?? 0).clamp(0, 4);
        _outfitIndex = (c['outfitIndex'] as int? ?? 0).clamp(0, 3);
        _outfitColorIndex = (c['outfitColorIndex'] as int? ?? 0).clamp(0, 4);
        _mascotHueIndex = (c['mascotHueIndex'] as int? ?? 0).clamp(0, 4);
        _selectedRelationship = c['relationship'] as String? ?? 'Best Friend / Barkada';
        _selectedDialect = c['dialect'] as String? ?? 'taglish';
        _selectedTone = c['tone'] as String? ?? 'warm';
        _callSignController.text = c['callSign'] as String? ?? 'Beshie';
        _catchphraseController.text = c['catchphrase'] as String? ?? '';
      }
    } else {
      _nameController.text = 'Bestie Sam';
      _catchphraseController.text = 'Proud of you palagi, kaya natin \'to! ✨';
    }
  }

  Map<String, dynamic> _buildConfig() {
    return {
      'type': _isMascotMode ? 'mascot' : 'human',
      'skinIndex': _skinIndex,
      'hairIndex': _hairIndex,
      'hairColorIndex': _hairColorIndex,
      'eyeStyleIndex': _eyeStyleIndex,
      'eyeColorIndex': _eyeColorIndex,
      'accIndex': _accIndex,
      'outfitIndex': _outfitIndex,
      'outfitColorIndex': _outfitColorIndex,
      'mascotHueIndex': _mascotHueIndex,
      'relationship': _selectedRelationship,
      'dialect': _selectedDialect,
      'tone': _selectedTone,
      'callSign': _callSignController.text.trim().isNotEmpty ? _callSignController.text.trim() : 'Friend',
      'catchphrase': _catchphraseController.text.trim(),
    };
  }

  String _generateSystemPrompt(String name, Map<String, dynamic> config) {
    final callSign = config['callSign'] as String? ?? 'Friend';
    final relationship = config['relationship'] as String? ?? 'Best Friend';
    final dialect = config['dialect'] as String? ?? 'taglish';
    final catchphrase = config['catchphrase'] as String? ?? '';

    String dialectInstruction = '';
    if (dialect == 'bisaya') {
      dialectInstruction = 'Speak in warm, conversational Bisaya / Cebuano blended with Taglish when appropriate. Use comforting Visayan phrases like "Kaya ra na nimo", "Amping kanunay", "Ayaw kabalaka".';
    } else if (dialect == 'filipino') {
      dialectInstruction = 'Speak in comforting, eloquent Conversational Filipino (Tagalog) with deep emotional warmth and validation.';
    } else if (dialect == 'english') {
      dialectInstruction = 'Speak in calm, supportive, and thoughtful English tailored for university mental health and student pacing.';
    } else {
      dialectInstruction = 'Speak in relatable, warm Metro Taglish like a caring university student. Be natural and comforting without overly clinical jargon.';
    }

    return 'You are $name, a personalized AI companion customized by the student. '
        'Your relationship with the student is: $relationship. '
        'Always address the student warmly using their chosen call-sign "$callSign". '
        '$dialectInstruction '
        '${catchphrase.isNotEmpty ? 'Your signature encouragement phrase is: "$catchphrase". ' : ''}'
        'Support philosophy: Provide unconditional positive regard, active listening, gentle perspective, and empathetic emotional grounding for student wellness.';
  }

  Future<void> _handleSaveAndChat() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a companion name! ✍️'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      setState(() => _currentStep = 1);
      return;
    }

    HapticService.mediumTap();
    final config = _buildConfig();
    final prompt = _generateSystemPrompt(name, config);
    final id = widget.editAvatar?.id ?? 'custom_${DateTime.now().millisecondsSinceEpoch}';

    final customCompanion = AvatarModel(
      id: id,
      name: name,
      roleTitle: _selectedRelationship,
      tier: 'basic',
      imagePath: 'assets/avatars/avatar_basic_kim.png',
      systemPrompt: prompt,
      bio: 'Custom AI companion created by you as your $_selectedRelationship.',
      sampleQuote: _catchphraseController.text.trim().isNotEmpty
          ? '"${_catchphraseController.text.trim()}"'
          : '"Nandito lang ako para makinig sa\'yo, ${_callSignController.text.trim()}."',
      specialties: [_selectedRelationship, 'Personalized Support'],
      customConfig: config,
    );

    // Save to local storage list
    try {
      final jsonStr = await _storage.read(key: 'custom_avatars_list_json');
      List<AvatarModel> currentList = [];
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> raw = jsonDecode(jsonStr);
        currentList = raw.map((item) => AvatarModel.fromJson(item as Map<String, dynamic>)).toList();
      }

      if (widget.editAvatar != null) {
        final idx = currentList.indexWhere((a) => a.id == widget.editAvatar!.id);
        if (idx != -1) {
          currentList[idx] = customCompanion;
        } else {
          currentList.add(customCompanion);
        }
      } else {
        currentList.add(customCompanion);
      }

      final encoded = jsonEncode(currentList.map((a) => a.toJson()).toList());
      await _storage.write(key: 'custom_avatars_list_json', value: encoded);
      await _storage.write(key: 'selected_chatbot_avatar_id', value: customCompanion.id);
    } catch (_) {}

    if (mounted) {
      Navigator.of(context).pop(customCompanion);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentConfig = _buildConfig();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.editAvatar != null ? 'Edit Custom Companion' : 'Custom Avatar Studio',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Live Avatar Preview Card ─────────────────────────────────
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(20, 12, 20, 10),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE0F2FE), Color(0xFFEDE9FE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFBAE6FD)),
                boxShadow: const [
                  BoxShadow(color: Color(0x0E0077B6), blurRadius: 16, offset: Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  CustomAvatarWidget(
                    config: currentConfig,
                    size: 96,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'Your Companion',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    '$_selectedRelationship • ${_dialects.firstWhere((d) => d['id'] == _selectedDialect)['title']}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 11.5,
                      color: Color(0xFF0284C7),
                    ),
                  ),
                ],
              ),
            ),

            // ── Step Navigation Tabs ─────────────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _buildTabButton(0, '🎨 1. Look & Style'),
                  _buildTabButton(1, '👤 2. Identity'),
                  _buildTabButton(2, '💬 3. Voice'),
                ],
              ),
            ),

            // ── Step Content ─────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: _currentStep == 0
                    ? _buildStepLook()
                    : (_currentStep == 1 ? _buildStepIdentity() : _buildStepVoice()),
              ),
            ),

            // ── Bottom Action Bar ────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: Row(
                children: [
                  if (_currentStep > 0) ...[
                    OutlinedButton(
                      onPressed: () {
                        HapticService.lightTap();
                        setState(() => _currentStep--);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      child: const Text(
                        'Back',
                        style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentStep < 2) {
                          HapticService.lightTap();
                          setState(() => _currentStep++);
                        } else {
                          _handleSaveAndChat();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Text(
                        _currentStep < 2 ? 'Next Step →' : 'Save & Chat with Companion ✨',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
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

  Widget _buildTabButton(int stepIndex, String title) {
    final isSelected = _currentStep == stepIndex;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticService.lightTap();
          setState(() => _currentStep = stepIndex);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? const [BoxShadow(color: Color(0x10000000), blurRadius: 4, offset: Offset(0, 2))]
                : null,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.primary : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  // ── STEP 1: LOOK & STYLE ───────────────────────────────────────────────────
  Widget _buildStepLook() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mode Selector: Human vs Mascot
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isMascotMode = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: !_isMascotMode ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '🧑‍🎓 Student Persona',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: !_isMascotMode ? Colors.white : const Color(0xFF4F46E5),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isMascotMode = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _isMascotMode ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '🤖 Custom Mascot',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: _isMascotMode ? Colors.white : const Color(0xFF4F46E5),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (!_isMascotMode) ...[
          // Skin Tone
          _buildSectionTitle('1. Skin Tone & Complexion'),
          _buildColorPickerRow(
            items: CustomAvatarPalette.skinTones,
            selectedIndex: _skinIndex,
            onSelect: (i) => setState(() => _skinIndex = i),
          ),

          // Hairstyle
          _buildSectionTitle('2. Hairstyle'),
          _buildItemPickerRow(
            items: CustomAvatarPalette.hairstyles,
            selectedIndex: _hairIndex,
            onSelect: (i) => setState(() => _hairIndex = i),
          ),

          // Hair Color
          _buildSectionTitle('3. Hair Color'),
          _buildColorPickerRow(
            items: CustomAvatarPalette.hairColors,
            selectedIndex: _hairColorIndex,
            onSelect: (i) => setState(() => _hairColorIndex = i),
          ),

          // Eye Style
          _buildSectionTitle('4. Eye Style'),
          _buildItemPickerRow(
            items: CustomAvatarPalette.eyeStyles,
            selectedIndex: _eyeStyleIndex,
            onSelect: (i) => setState(() => _eyeStyleIndex = i),
          ),

          // Eye Color
          _buildSectionTitle('5. Eye Color'),
          _buildColorPickerRow(
            items: CustomAvatarPalette.eyeColors,
            selectedIndex: _eyeColorIndex,
            onSelect: (i) => setState(() => _eyeColorIndex = i),
          ),

          // Accessories & Glasses
          _buildSectionTitle('6. Glasses & Accessories'),
          _buildItemPickerRow(
            items: CustomAvatarPalette.accessories,
            selectedIndex: _accIndex,
            onSelect: (i) => setState(() => _accIndex = i),
          ),

          // Outfit Theme Color
          _buildSectionTitle('7. Outfit Theme Color'),
          _buildColorPickerRow(
            items: CustomAvatarPalette.outfitColors,
            selectedIndex: _outfitColorIndex,
            onSelect: (i) => setState(() => _outfitColorIndex = i),
          ),
        ] else ...[
          // Mascot Hue Theme
          _buildSectionTitle('1. Mascot Body Color Hue'),
          _buildMascotHueRow(),
        ],
      ],
    );
  }

  // ── STEP 2: IDENTITY & RELATIONSHIP ────────────────────────────────────────
  Widget _buildStepIdentity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Companion Display Name'),
        TextField(
          controller: _nameController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'e.g., Bestie Sam, Ate Kim, Kuya Dan, Tita Joy',
            prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.primary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 16),

        _buildSectionTitle('Relationship Archetype'),
        ..._relationshipArchetypes.map((rel) {
          final isSelected = _selectedRelationship == rel['title'];
          return GestureDetector(
            onTap: () {
              HapticService.lightTap();
              setState(() {
                _selectedRelationship = rel['title']!;
                if (_callSignController.text.isEmpty ||
                    _callSignController.text == 'Beshie' ||
                    _callSignController.text == 'Bunso' ||
                    _callSignController.text == 'Partner' ||
                    _callSignController.text == 'Friend' ||
                    _callSignController.text == 'Anak') {
                  _callSignController.text = rel['defaultCallSign']!;
                }
              });
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFEEF2FF) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rel['icon']!, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rel['title']!,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            color: isSelected ? AppColors.primary : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          rel['desc']!,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11.5,
                            color: Color(0xFF64748B),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),

        const SizedBox(height: 12),
        _buildSectionTitle('What should your companion call you?'),
        TextField(
          controller: _callSignController,
          decoration: InputDecoration(
            hintText: 'e.g., Beshie, Bunso, Partner, Bro, or your first name',
            prefixIcon: const Icon(Icons.waving_hand_outlined, color: AppColors.primary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  // ── STEP 3: VOICE & DIALECT ────────────────────────────────────────────────
  Widget _buildStepVoice() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Speaking Dialect & Language'),
        ..._dialects.map((d) {
          final isSelected = _selectedDialect == d['id'];
          return GestureDetector(
            onTap: () {
              HapticService.lightTap();
              setState(() => _selectedDialect = d['id']!);
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFEEF2FF) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: isSelected ? AppColors.primary : const Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d['title']!,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: isSelected ? AppColors.primary : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          d['desc']!,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),

        const SizedBox(height: 12),
        _buildSectionTitle('Custom Greeting / Catchphrase (Optional)'),
        TextField(
          controller: _catchphraseController,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'e.g., "Proud of you palagi!", "Hinga muna bago mag-panic!"',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  // ── REUSABLE UI BUILDERS ───────────────────────────────────────────────────
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: Color(0xFF1E293B),
        ),
      ),
    );
  }

  Widget _buildColorPickerRow({
    required List<Map<String, dynamic>> items,
    required int selectedIndex,
    required ValueChanged<int> onSelect,
  }) {
    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (ctx, i) {
          final isSelected = selectedIndex == i;
          final color = items[i]['color'] as Color;
          return GestureDetector(
            onTap: () {
              HapticService.lightTap();
              onSelect(i);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : const Color(0xFFCBD5E1),
                  width: isSelected ? 2.5 : 1,
                ),
              ),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: color,
                child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildItemPickerRow({
    required List<Map<String, dynamic>> items,
    required int selectedIndex,
    required ValueChanged<int> onSelect,
  }) {
    return Container(
      height: 42,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (ctx, i) {
          final isSelected = selectedIndex == i;
          final name = items[i]['name'] as String;
          final icon = items[i]['icon'] as String;
          return GestureDetector(
            onTap: () {
              HapticService.lightTap();
              onSelect(i);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  Text(icon, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 6),
                  Text(
                    name,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMascotHueRow() {
    return Container(
      height: 52,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: CustomAvatarPalette.mascotHues.length,
        itemBuilder: (ctx, i) {
          final isSelected = _mascotHueIndex == i;
          final gradient = CustomAvatarPalette.mascotHues[i]['gradient'] as List<Color>;
          return GestureDetector(
            onTap: () {
              HapticService.lightTap();
              setState(() => _mascotHueIndex = i);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : const Color(0xFFCBD5E1),
                  width: isSelected ? 2.5 : 1,
                ),
              ),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: gradient),
                ),
                child: isSelected ? const Icon(Icons.check, size: 18, color: Colors.white) : null,
              ),
            ),
          );
        },
      ),
    );
  }
}
