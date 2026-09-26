import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  final List<Map<String, dynamic>> _languages = [
    {
      'code': 'en',
      'name': 'English',
      'nativeName': 'English',
      'flag': '🇺🇸',
      'subtitle': 'Default Global English',
      'available': true,
    },
    {
      'code': 'tl',
      'name': 'Filipino',
      'nativeName': 'Filipino (Tagalog)',
      'flag': '🇵🇭',
      'subtitle': 'Pambansang Wika • Tagalog',
      'available': true,
    },
    {
      'code': 'es',
      'name': 'Spanish',
      'nativeName': 'Español',
      'flag': '🇪🇸',
      'subtitle': 'Castilian & Latin American',
      'available': false,
      'badge': 'Soon',
    },
    {
      'code': 'ja',
      'name': 'Japanese',
      'nativeName': '日本語',
      'flag': '🇯🇵',
      'subtitle': 'Standard Japanese',
      'available': false,
      'badge': 'Soon',
    },
    {
      'code': 'ko',
      'name': 'Korean',
      'nativeName': '한국어',
      'flag': '🇰🇷',
      'subtitle': 'Standard Korean',
      'available': false,
      'badge': 'Soon',
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
    String? lang;
    String? region;
    String? time;

    // 1. First check SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      lang = prefs.getString(_languageKey);
      region = prefs.getString(_regionKey);
      time = prefs.getString(_timeFormatKey);
    } catch (_) {}

    // 2. Fallback to FlutterSecureStorage
    if (lang == null || region == null || time == null) {
      try {
        const storage = FlutterSecureStorage();
        lang ??= await storage.read(key: _languageKey);
        region ??= await storage.read(key: _regionKey);
        time ??= await storage.read(key: _timeFormatKey);
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _selectedLanguageCode = (lang == 'tl' || lang == 'en') ? lang! : 'en';
        _selectedRegionCode = region ?? 'ph';
        _selectedTimeFormat = time ?? '12h';
        _isLoading = false;
      });
    }
  }

  Future<void> _setLanguage(Map<String, dynamic> lang) async {
    final bool isAvailable = lang['available'] == true;
    if (!isAvailable) {
      HapticService.lightTap();
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${lang['name']} language support is coming soon! We are currently focused on English and Filipino.'),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final code = lang['code'] as String;
    HapticService.selectionChanged();
    setState(() => _selectedLanguageCode = code);

    // Dual-Storage Persistence
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, code);
      const storage = FlutterSecureStorage();
      await storage.write(key: _languageKey, value: code);
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Language set to ${lang['name']}. Auto-saved to your device.'),
          duration: const Duration(seconds: 2),
          backgroundColor: KausapColors.accent(context),
        ),
      );
    }
  }

  Future<void> _setRegion(String code) async {
    HapticService.selectionChanged();
    setState(() => _selectedRegionCode = code);

    // Dual-Storage Persistence
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_regionKey, code);
      const storage = FlutterSecureStorage();
      await storage.write(key: _regionKey, value: code);
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Regional hotlines directory updated.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _setTimeFormat(String format) async {
    HapticService.selectionChanged();
    setState(() => _selectedTimeFormat = format);

    // Dual-Storage Persistence
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_timeFormatKey, format);
      const storage = FlutterSecureStorage();
      await storage.write(key: _timeFormatKey, value: format);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = KausapColors.isDark(context);
    final accent = KausapColors.accent(context);

    return Scaffold(
      backgroundColor: KausapColors.scaffoldBg(context),
      appBar: AppBar(
        backgroundColor: KausapColors.cardBg(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: KausapColors.textPrimary(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Language & Region',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: KausapColors.textPrimary(context),
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: accent))
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
                        color: isDark ? accent.withAlpha(25) : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? accent.withAlpha(50) : const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.language_rounded, color: isDark ? accent : const Color(0xFF2563EB), size: 26),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Choose your preferred language for conversations, and set your emergency crisis region.',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12.5,
                                color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E3A8A),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── 1. App & AI Conversation Language ────────────────────
                    _sectionLabel(context, 'APP & AI CONVERSATION LANGUAGE'),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: KausapColors.cardBg(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: KausapColors.border(context)),
                        boxShadow: [BoxShadow(color: Colors.black.withAlpha(isDark ? 0 : 8), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Column(
                        children: _languages.asMap().entries.map((entry) {
                          final i = entry.key;
                          final lang = entry.value;
                          final isAvailable = lang['available'] == true;
                          final isSelected = _selectedLanguageCode == lang['code'] && isAvailable;
                          final badge = lang['badge'] as String?;

                          return Column(
                            children: [
                              InkWell(
                                onTap: () => _setLanguage(lang),
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Row(
                                    children: [
                                      Opacity(
                                        opacity: isAvailable ? 1.0 : 0.6,
                                        child: Text(lang['flag'] as String, style: const TextStyle(fontSize: 24)),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  lang['nativeName'] as String,
                                                  style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                                    fontSize: 14,
                                                    color: isSelected
                                                        ? accent
                                                        : (isAvailable
                                                            ? KausapColors.textPrimary(context)
                                                            : KausapColors.textMuted(context)),
                                                  ),
                                                ),
                                                if (badge != null) ...[
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: isDark ? Colors.white.withAlpha(15) : const Color(0xFFF1F5F9),
                                                      borderRadius: BorderRadius.circular(6),
                                                      border: Border.all(
                                                        color: isDark ? Colors.white.withAlpha(25) : const Color(0xFFE2E8F0),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      badge,
                                                      style: TextStyle(
                                                        fontFamily: 'Poppins',
                                                        fontSize: 9.5,
                                                        fontWeight: FontWeight.w700,
                                                        color: KausapColors.textMuted(context),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            Text(
                                              '${lang['name']} • ${lang['subtitle']}',
                                              style: TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 11.5,
                                                color: KausapColors.textMuted(context),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isSelected)
                                        Icon(
                                          Icons.check_circle_rounded,
                                          color: accent,
                                          size: 22,
                                        )
                                      else if (!isAvailable)
                                        Icon(
                                          Icons.lock_outline_rounded,
                                          color: KausapColors.textMuted(context).withAlpha(120),
                                          size: 18,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              if (i < _languages.length - 1)
                                Divider(height: 1, indent: 54, color: KausapColors.border(context)),
                            ],
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── 2. Regional Crisis Directory ─────────────────────────
                    _sectionLabel(context, 'REGIONAL EMERGENCY & HOTLINES'),
                    const SizedBox(height: 4),
                    Text(
                      'Configures crisis hotlines displayed in emergency assistance and SOS menus.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: KausapColors.textMuted(context),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: KausapColors.cardBg(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: KausapColors.border(context)),
                        boxShadow: [BoxShadow(color: Colors.black.withAlpha(isDark ? 0 : 8), blurRadius: 8, offset: const Offset(0, 2))],
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
                                                color: isSelected ? accent : KausapColors.textPrimary(context),
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
                                        Icon(
                                          Icons.check_circle_rounded,
                                          color: accent,
                                          size: 22,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              if (i < _regions.length - 1)
                                Divider(height: 1, indent: 54, color: KausapColors.border(context)),
                            ],
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── 3. Time Display Format ───────────────────────────────
                    _sectionLabel(context, 'TIME DISPLAY FORMAT'),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: KausapColors.cardBg(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: KausapColors.border(context)),
                        boxShadow: [BoxShadow(color: Colors.black.withAlpha(isDark ? 0 : 8), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildTimeFormatButton(
                              context: context,
                              label: '12-Hour',
                              example: '8:30 PM',
                              isSelected: _selectedTimeFormat == '12h',
                              onTap: () => _setTimeFormat('12h'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildTimeFormatButton(
                              context: context,
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
    required BuildContext context,
    required String label,
    required String example,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final accent = KausapColors.accent(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? accent.withAlpha(25) : KausapColors.subtleBg(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? accent : KausapColors.border(context),
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
                color: isSelected ? accent : KausapColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              example,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11.5,
                color: isSelected ? accent : KausapColors.textMuted(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 0.7,
          color: KausapColors.textMuted(context),
        ),
      ),
    );
  }
}

