import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../theme/app_theme.dart';
import '../../utils/haptic_service.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  static const String _languageKey = 'app_language';
  static const String _regionKey = 'app_region';
  static const String _timeFormatKey = 'app_time_format';

  String _selectedLanguageCode = 'en'; // default
  String _selectedRegionCode = 'ph'; // default Philippines
  String _selectedTimeFormat = '12h'; // 12h default
  bool _isLoading = true;

  final List<Map<String, String>> _languages = [
    {
      'code': 'en',
      'name': 'English',
      'nativeName': 'English',
      'flag': '🇺🇸',
      'subtitle': 'Default Global English',
    },
    {
      'code': 'taglish',
      'name': 'Taglish (Conversational)',
      'nativeName': 'Filipino + English',
      'flag': '🇵🇭',
      'subtitle': 'Recommended for student AI chats',
    },
    {
      'code': 'tl',
      'name': 'Tagalog',
      'nativeName': 'Filipino',
      'flag': '🇵🇭',
      'subtitle': 'Formal Tagalog',
    },
    {
      'code': 'es',
      'name': 'Spanish',
      'nativeName': 'Español',
      'flag': '🇪🇸',
      'subtitle': 'Castilian & Latin American',
    },
    {
      'code': 'ja',
      'name': 'Japanese',
      'nativeName': '日本語',
      'flag': '🇯🇵',
      'subtitle': 'Standard Japanese',
    },
    {
      'code': 'ko',
      'name': 'Korean',
      'nativeName': '한국어',
      'flag': '🇰🇷',
      'subtitle': 'Standard Korean',
    },
  ];

  final List<Map<String, String>> _regions = [
    {
      'code': 'ph',
      'name': 'Philippines',
      'flag': '🇵🇭',
      'hotline': 'NCMH 1553 • Hopeline 0917-558-4673',
      'desc': 'Connects to Philippine national mental health hotlines',
    },
    {
      'code': 'global',
      'name': 'International / Global',
      'flag': '🌐',
      'hotline': '988 Lifeline • Crisis Text Line 741741',
      'desc': 'International mental health and emergency services',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    const storage = FlutterSecureStorage();
    final savedLang = await storage.read(key: _languageKey);
    final savedRegion = await storage.read(key: _regionKey);
    final savedTime = await storage.read(key: _timeFormatKey);

    if (mounted) {
      setState(() {
        _selectedLanguageCode = savedLang ?? 'en';
        _selectedRegionCode = savedRegion ?? 'ph';
        _selectedTimeFormat = savedTime ?? '12h';
        _isLoading = false;
      });
    }
  }

  Future<void> _setLanguage(String code) async {
    HapticService.selectionChanged();
    setState(() => _selectedLanguageCode = code);
    const storage = FlutterSecureStorage();
    await storage.write(key: _languageKey, value: code);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Language preference saved.')),
      );
    }
  }

  Future<void> _setRegion(String code) async {
    HapticService.selectionChanged();
    setState(() => _selectedRegionCode = code);
    const storage = FlutterSecureStorage();
    await storage.write(key: _regionKey, value: code);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Region & Emergency directory updated.')),
      );
    }
  }

  Future<void> _setTimeFormat(String format) async {
    HapticService.selectionChanged();
    setState(() => _selectedTimeFormat = format);
    const storage = FlutterSecureStorage();
    await storage.write(key: _timeFormatKey, value: format);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Language & Region',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    // Info banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.language_rounded, color: Color(0xFF2563EB), size: 26),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Choose your preferred language, conversational AI style, and emergency hotline region.',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12.5,
                                color: Color(0xFF1E3A8A),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── 1. App & AI Conversation Language ────────────────────
                    _sectionLabel('APP & AI CONVERSATION LANGUAGE'),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 8, offset: Offset(0, 2))],
                      ),
                      child: Column(
                        children: _languages.asMap().entries.map((entry) {
                          final i = entry.key;
                          final lang = entry.value;
                          final isSelected = _selectedLanguageCode == lang['code'];
                          final isTaglish = lang['code'] == 'taglish';

                          return Column(
                            children: [
                              InkWell(
                                onTap: () => _setLanguage(lang['code']!),
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Row(
                                    children: [
                                      Text(lang['flag']!, style: const TextStyle(fontSize: 24)),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  lang['nativeName']!,
                                                  style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                                    fontSize: 14,
                                                    color: isSelected ? AppColors.primary : const Color(0xFF0F172A),
                                                  ),
                                                ),
                                                if (isTaglish) ...[
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFFEF3C7),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: const Text(
                                                      'Popular 🇵🇭',
                                                      style: TextStyle(
                                                        fontFamily: 'Poppins',
                                                        fontSize: 9.5,
                                                        fontWeight: FontWeight.w700,
                                                        color: Color(0xFF92400E),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            Text(
                                              '${lang['name']} • ${lang['subtitle']}',
                                              style: const TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 11.5,
                                                color: Color(0xFF64748B),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isSelected)
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          color: AppColors.primary,
                                          size: 22,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              if (i < _languages.length - 1)
                                const Divider(height: 1, indent: 54, color: Color(0x12000000)),
                            ],
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── 2. Regional Crisis Directory ─────────────────────────
                    _sectionLabel('REGIONAL EMERGENCY & HOTLINES'),
                    const SizedBox(height: 4),
                    const Text(
                      'Configures crisis hotlines displayed in emergency assistance and SOS menus.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 8, offset: Offset(0, 2))],
                      ),
                      child: Column(
                        children: _regions.asMap().entries.map((entry) {
                          final i = entry.key;
                          final reg = entry.value;
                          final isSelected = _selectedRegionCode == reg['code'];

                          return Column(
                            children: [
                              InkWell(
                                onTap: () => _setRegion(reg['code']!),
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Row(
                                    children: [
                                      Text(reg['flag']!, style: const TextStyle(fontSize: 24)),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              reg['name']!,
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                                fontSize: 14,
                                                color: isSelected ? AppColors.primary : const Color(0xFF0F172A),
                                              ),
                                            ),
                                            Text(
                                              reg['hotline']!,
                                              style: const TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFFDC2626),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isSelected)
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          color: AppColors.primary,
                                          size: 22,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              if (i < _regions.length - 1)
                                const Divider(height: 1, indent: 54, color: Color(0x12000000)),
                            ],
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── 3. Time Display Format ───────────────────────────────
                    _sectionLabel('TIME DISPLAY FORMAT'),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 8, offset: Offset(0, 2))],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildTimeFormatButton(
                              label: '12-Hour',
                              example: '8:30 PM',
                              isSelected: _selectedTimeFormat == '12h',
                              onTap: () => _setTimeFormat('12h'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildTimeFormatButton(
                              label: '24-Hour',
                              example: '20:30',
                              isSelected: _selectedTimeFormat == '24h',
                              onTap: () => _setTimeFormat('24h'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTimeFormatButton({
    required String label,
    required String example,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withAlpha(15) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                fontSize: 13,
                color: isSelected ? AppColors.primary : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              example,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11.5,
                color: isSelected ? AppColors.primary : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 0.7,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }
}
