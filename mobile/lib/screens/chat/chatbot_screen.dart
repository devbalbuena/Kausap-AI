import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../services/api_client.dart';
import '../../config/api_config.dart';
import '../../models/avatar_model.dart';
import 'select_avatar_screen.dart';
import 'chat_history_screen.dart';
import '../settings/account_settings_screen.dart';
import '../articles/articles_screen.dart';
import '../subscription/upgrade_plan_screen.dart';

/// A single message in the chat (either user or assistant).
class _ChatMessage {
  final String role; // 'user' | 'assistant'
  final String content;
  final String? imagePath;
  final Uint8List? imageBytes;
  final bool isCrisis;

  const _ChatMessage({
    required this.role,
    required this.content,
    this.imagePath,
    this.imageBytes,
    this.isCrisis = false,
  });

  Map<String, dynamic> toJson() => {
    'role': role,
    'content': content,
    'imagePath': imagePath,
    'isCrisis': isCrisis,
  };

  factory _ChatMessage.fromJson(Map<String, dynamic> json) => _ChatMessage(
    role: json['role'] as String? ?? 'assistant',
    content: json['content'] as String? ?? '',
    imagePath: json['imagePath'] as String?,
    isCrisis: json['isCrisis'] as bool? ?? false,
  );
}

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen>
    with TickerProviderStateMixin {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<_ChatMessage> _messages = [];
  String? _sessionId;
  bool _isTyping = false;
  bool _showMenu = false;

  AvatarModel _currentAvatar = AvatarData.defaultAvatar;
  final ImagePicker _imagePicker = ImagePicker();

  static const _storage = FlutterSecureStorage();

  // Animated dots for typing indicator
  late AnimationController _dotController;
  late Animation<double> _dotAnimation;

  // Quick-reply chips shown in the empty state
  static const List<String> _quickReplies = [
    'Academic & Exam Stress',
    'Anxiety & Overwhelm',
    "Can't Sleep / Insomnia",
    'Feeling Lonely',
    'CBT Thought Reframing',
    '5-4-3-2-1 Grounding',
  ];

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
    _dotAnimation = Tween<double>(begin: 0, end: 1).animate(_dotController);
    _loadSavedAvatar();
  }

  Future<void> _loadSavedAvatar() async {
    final avatarId = await _storage.read(key: 'selected_chatbot_avatar_id');
    final customName = await _storage.read(key: 'custom_avatar_name');
    final customPrompt = await _storage.read(key: 'custom_avatar_prompt');

    if (avatarId == 'custom_user_avatar' && customName != null && customName.isNotEmpty) {
      if (mounted) {
        setState(() {
          _currentAvatar = AvatarModel(
            id: 'custom_user_avatar',
            name: customName,
            tier: 'basic',
            imagePath: 'assets/avatars/avatar_basic_kim.png',
            systemPrompt: customPrompt ?? 'You are $customName, a personalized mental wellness companion.',
          );
        });
      }
    } else if (avatarId != null) {
      final found = AvatarData.findById(avatarId);
      if (found != null && mounted) {
        setState(() => _currentAvatar = found);
      }
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _dotController.dispose();
    super.dispose();
  }

  // ── Session & History Management ──────────────────────────────────────────

  Future<String> _ensureSession() async {
    if (_sessionId != null) return _sessionId!;
    final data = await ApiClient().post(ApiConfig.chatSessions);
    _sessionId = data['id'] as String;
    return _sessionId!;
  }

  Future<void> _saveSessionToHistory() async {
    if (_messages.isEmpty) return;
    try {
      final raw = await _storage.read(key: 'chat_history_sessions');
      List<dynamic> list = [];
      if (raw != null && raw.isNotEmpty) {
        list = jsonDecode(raw) as List;
      }

      final sessionData = {
        'id': _sessionId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'date': DateTime.now().toIso8601String(),
        'avatarName': _currentAvatar.name,
        'messages': _messages.map((m) => m.toJson()).toList(),
      };

      // Check if session exists and update, or prepend
      final existingIdx = list.indexWhere((s) => s is Map && s['id'] == sessionData['id']);
      if (existingIdx >= 0) {
        list[existingIdx] = sessionData;
      } else {
        list.insert(0, sessionData);
      }

      // Limit to 20 past sessions
      if (list.length > 20) list = list.sublist(0, 20);

      await _storage.write(key: 'chat_history_sessions', value: jsonEncode(list));
    } catch (_) {}
  }

  void _startNewChat() {
    setState(() {
      _sessionId = null;
      _messages.clear();
      _showMenu = false;
    });
  }

  void _openChatHistory() {
    setState(() => _showMenu = false);
    Navigator.of(context).push(
      slideRoute(
        ChatHistoryScreen(
          onResumeSession: (pastMessages) {
            setState(() {
              _messages.clear();
              for (final m in pastMessages) {
                _messages.add(_ChatMessage.fromJson(m));
              }
            });
            _scrollToBottom();
          },
        ),
      ),
    );
  }

  // ── Message Dispatch & Dynamic Engine ─────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        _sendMessage('', imagePath: image.path, imageBytes: bytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage(String text, {String? imagePath, Uint8List? imageBytes}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty && imagePath == null && imageBytes == null) return;

    _inputController.clear();
    setState(() {
      _messages.add(_ChatMessage(role: 'user', content: trimmed, imagePath: imagePath, imageBytes: imageBytes));
      _isTyping = true;
    });
    _scrollToBottom();

    // Check crisis detection locally first
    final bool isCrisis = _checkIsCrisis(trimmed);

    try {
      final sessionId = await _ensureSession();
      final endpoint = '${ApiConfig.chatSessions}/$sessionId/messages';
      final data = await ApiClient().post(endpoint, body: {'content': trimmed});
      final aiContent = data['content'] as String? ?? '…';

      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(role: 'assistant', content: aiContent, isCrisis: isCrisis));
        _isTyping = false;
      });
      _saveSessionToHistory();
      _scrollToBottom();
    } catch (_) {
      // Dynamic Cognitive Fallback Engine
      final fallbackResponse = _generateEmpatheticFallback(trimmed, isCrisis: isCrisis);
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(
          role: 'assistant',
          content: fallbackResponse,
          isCrisis: isCrisis,
        ));
        _isTyping = false;
      });
      _saveSessionToHistory();
      _scrollToBottom();
    }
  }

  bool _checkIsCrisis(String input) {
    final lower = input.toLowerCase();
    final crisisKeywords = [
      'suicide',
      'kill myself',
      'want to die',
      'end it all',
      'end my life',
      'hurt myself',
      'giving up',
      'give up',
      'hopeless',
      'ayoko na mabuhay',
      'tapusin na',
      'no reason to live',
      'better off dead',
      'cut myself',
    ];
    for (final k in crisisKeywords) {
      if (lower.contains(k)) return true;
    }
    return false;
  }

  String _generateEmpatheticFallback(String input, {bool isCrisis = false}) {
    final lower = input.toLowerCase();

    if (isCrisis) {
      return "I hear how heavy things feel right now, and I want you to know you don't have to carry this alone. Your life has immense value, and there is caring support available 24/7. Please connect with someone who can help right now:";
    }

    // Family and Relationship Struggles
    if (lower.contains('family') ||
        lower.contains('parents') ||
        lower.contains('mom') ||
        lower.contains('dad') ||
        lower.contains('magulang') ||
        lower.contains('kapatid') ||
        lower.contains('away') ||
        lower.contains('toxic') ||
        lower.contains('breakup') ||
        lower.contains('relationship')) {
      return "Family and relationship struggles can feel especially draining because they touch the people closest to us. It is completely okay to feel hurt, frustrated, or misunderstood. Remember that your feelings are valid, and it is healthy to protect your emotional boundaries. Would you like to talk through what happened, or explore ways to express your feelings safely?";
    }

    // Depression, Sadness, Feeling Down
    if (lower.contains('depre') || // matches deprees, depressed, depression
        lower.contains('sad') ||
        lower.contains('down') ||
        lower.contains('lungkot') ||
        lower.contains('crying') ||
        lower.contains('empty') ||
        lower.contains('heavy') ||
        lower.contains('miserable')) {
      return "Thank you for trusting me and sharing that. When you're carrying a heavy sadness, even small tasks can feel overwhelming. Please remember you don't have to solve everything today—just taking it moment by moment is enough. What is weighing on your heart the most right now?";
    }

    // Academic & School / Exam Stress
    if (lower.contains('exam') ||
        lower.contains('midterm') ||
        lower.contains('finals') ||
        lower.contains('thesis') ||
        lower.contains('grade') ||
        lower.contains('bagsak') ||
        lower.contains('fail') ||
        lower.contains('school') ||
        lower.contains('study') ||
        lower.contains('deadline') ||
        lower.contains('prof') ||
        lower.contains('pressure')) {
      return "Academic pressure can feel so suffocating, especially when expectations are high. But remember: your grades do not define your worth or your future as a person. Let's take a quick reset. Have you taken a break or had water recently? We can break down what you need to study into tiny, manageable 15-minute steps.";
    }

    // Anxiety & Panic
    if (lower.contains('anxious') ||
        lower.contains('anxiety') ||
        lower.contains('panic') ||
        lower.contains('kaba') ||
        lower.contains('takot') ||
        lower.contains('nervous') ||
        lower.contains('overwhelm')) {
      return "I'm right here with you. Anxiety is your body's alarm system reacting, but you are in a safe space. Let's do a quick grounding check: name 3 things you can see around you, and take a slow breath in for 4 seconds... and out for 6. How is your body feeling right now?";
    }

    // Sleep & Insomnia
    if (lower.contains('sleep') ||
        lower.contains('insomnia') ||
        lower.contains('puyat') ||
        lower.contains('gising') ||
        lower.contains('night') ||
        lower.contains('tired') ||
        lower.contains('pagod')) {
      return "Struggling to sleep when your thoughts are racing is so frustrating. When your mind won't quiet down, try not forcing sleep. Instead, let's do a gentle body scan or write down your thoughts so your brain knows they're safe for tomorrow. Would you like a calming breathing tip?";
    }

    // Loneliness
    if (lower.contains('lonely') ||
        lower.contains('alone') ||
        lower.contains('isolated') ||
        lower.contains('walang kausap') ||
        lower.contains('nobody')) {
      return "Feeling alone can make everything seem darker, but I want you to know I'm right here listening. You are worthy of genuine connection and kindness. Even in quiet moments, you are never truly as alone as it feels. What's been on your mind today?";
    }

    // Positive / Gratitude
    if (lower.contains('happy') ||
        lower.contains('good') ||
        lower.contains('better') ||
        lower.contains('salamat') ||
        lower.contains('thank') ||
        lower.contains('masaya') ||
        lower.contains('passed')) {
      return "I'm so glad to hear that! 🌟 Celebrating these positive moments and giving yourself credit is a huge part of your mental wellness journey. Keep that momentum going—what made you smile today?";
    }

    // Greetings
    if (lower.contains('hello') ||
        lower.contains('hi') ||
        lower.contains('kamusta') ||
        lower.contains('kumusta') ||
        lower.contains('hey')) {
      return "Kumusta! 👋 I'm ${_currentAvatar.name}. I'm here as your mental health companion to listen, support, and chat about whatever is on your mind today. How are you feeling right now?";
    }

    // Context-sensitive default reflection
    return "I hear you. Thank you for expressing that with me. It takes real honesty to put our thoughts into words. Tell me more about what you're experiencing with this—I'm here to listen.";
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _openSelectAvatar() async {
    setState(() => _showMenu = false);
    final result = await Navigator.of(context).push<AvatarModel>(
      slideRoute(SelectAvatarScreen(currentAvatar: _currentAvatar))
    );
    if (result != null && mounted) {
      setState(() {
        _currentAvatar = result;
        _sessionId = null;
        _messages.clear();
      });
    }
  }

  // ── UI Builders ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bool isEmpty = _messages.isEmpty && !_isTyping;

    return GestureDetector(
      onTap: () {
        if (_showMenu) setState(() => _showMenu = false);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F2FF),
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: isEmpty ? _buildWelcomeView() : _buildChatView(),
                  ),
                  _buildInputArea(isEmpty),
                ],
              ),
              if (_showMenu) _buildDropdownMenu(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // Left: Brand name + tier
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kausap AI',
                style: AppTextStyles.heading2.copyWith(
                  color: AppColors.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                _currentAvatar.isPremium ? 'Premium' : 'Basic',
                style: AppTextStyles.body.copyWith(
                  fontSize: 12,
                  color: _currentAvatar.isPremium
                      ? const Color(0xFFFFC107)
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          // History Button
          _HeaderIconBtn(
            icon: Icons.history_rounded,
            onTap: _openChatHistory,
          ),
          const SizedBox(width: 8),
          // Phone call icon
          _HeaderIconBtn(
            icon: Icons.phone_outlined,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Voice call coming in Phase 2!')),
              );
            },
          ),
          const SizedBox(width: 8),
          // Video call icon
          _HeaderIconBtn(
            icon: Icons.videocam_outlined,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Video call coming in Phase 2!')),
              );
            },
          ),
          const SizedBox(width: 8),
          // Avatar profile circle → opens menu
          GestureDetector(
            onTap: () => setState(() => _showMenu = !_showMenu),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  _currentAvatar.imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: const Color(0xFFEEF2FF),
                    child: Icon(Icons.person, color: AppColors.primary, size: 22),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            height: 340,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFDDE6FF), Color(0xFFF0E6FF)],
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                _currentAvatar.imagePath,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Center(
                  child: Icon(Icons.smart_toy_rounded,
                      color: AppColors.primary, size: 80),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: AppTextStyles.heading2.copyWith(
                  fontSize: 22,
                  height: 1.4,
                  color: const Color(0xFF191C21),
                ),
                children: const [
                  TextSpan(
                    text: 'Meet Kausap AI',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: AppColors.primary,
                    ),
                  ),
                  TextSpan(text: ', your\ncompanion'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildChatView() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isTyping) {
          return _buildTypingIndicator();
        }
        final msg = _messages[index];
        return msg.role == 'user'
            ? _buildUserBubble(msg)
            : _buildAiBubble(msg);
      },
    );
  }

  Widget _buildAiBubble(_ChatMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4, right: 10),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  _currentAvatar.imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: const Color(0xFFE4F9FF),
                    child: const Icon(Icons.smart_toy_rounded,
                        color: AppColors.primary, size: 18),
                  ),
                ),
              ),
            ),
          ),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: const BoxConstraints(maxWidth: 265),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(2),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0D000000),
                        blurRadius: 1,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    msg.content,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 14,
                      color: const Color(0xFF191C21),
                      height: 1.43,
                    ),
                  ),
                ),
                if (msg.isCrisis) _buildCrisisCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCrisisCard() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCA5A5)),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withAlpha(15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.emergency_rounded, color: Color(0xFFDC2626), size: 20),
              SizedBox(width: 8),
              Text(
                'Philippine Crisis Hotlines (24/7)',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Color(0xFF991B1B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildHotlineRow('📞 NCMH Crisis Helpline', '1553 (Toll-free 24/7) / 0917-899-8727'),
          const SizedBox(height: 6),
          _buildHotlineRow('🤝 Hopeline Philippines', '(02) 8804-4673 / 0917-558-4673'),
          const SizedBox(height: 6),
          _buildHotlineRow('🚑 In Touch Community', '0917-800-1123 / 0922-893-8944'),
          const SizedBox(height: 6),
          _buildHotlineRow('🚨 Emergency Hotline', '911'),
        ],
      ),
    );
  }

  Widget _buildHotlineRow(String title, String number) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF7F1D1D),
            ),
          ),
          Text(
            number,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFFDC2626),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserBubble(_ChatMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 260),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(2),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 1,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (msg.imageBytes != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(
                      msg.imageBytes!,
                      fit: BoxFit.cover,
                      width: 200,
                      height: 140,
                    ),
                  ),
                )
              else if (msg.imagePath != null && !kIsWeb)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      File(msg.imagePath!),
                      fit: BoxFit.cover,
                      width: 200,
                      height: 140,
                    ),
                  ),
                ),
              if (msg.content.isNotEmpty)
                Text(
                  msg.content,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: Colors.white,
                    height: 1.43,
                    fontWeight: FontWeight.w400,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4, right: 10),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  _currentAvatar.imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: const Color(0xFFE4F9FF),
                    child: const Icon(Icons.smart_toy_rounded,
                        color: AppColors.primary, size: 18),
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(2),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 1,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: _dotAnimation,
              builder: (context, _) {
                final double v = _dotAnimation.value;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Dot(opacity: (v < 0.33) ? 1.0 : 0.3),
                    const SizedBox(width: 4),
                    _Dot(opacity: (v >= 0.33 && v < 0.66) ? 1.0 : 0.3),
                    const SizedBox(width: 4),
                    _Dot(opacity: (v >= 0.66) ? 1.0 : 0.3),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(bool isEmpty) {
    return Container(
      color: const Color(0xFFF0F2FF),
      child: Column(
        children: [
          if (isEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _quickReplies.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  return GestureDetector(
                    onTap: () => _sendMessage(_quickReplies[i]),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 17, vertical: 9),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                            color: const Color(0xFFC1C7D3).withAlpha(128)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0D000000),
                            blurRadius: 1,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        _quickReplies[i],
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: const Color(0xFFC1C7D3).withAlpha(100)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _showAttachmentMenu,
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.add_circle_outline,
                          color: AppColors.textSecondary, size: 22),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _sendMessage,
                      style: AppTextStyles.body.copyWith(
                          fontSize: 14, color: const Color(0xFF191C21)),
                      decoration: InputDecoration(
                        hintText: 'Start conversation...',
                        hintStyle: AppTextStyles.body.copyWith(
                          fontSize: 14,
                          color: const Color(0xFF9BA4B4),
                        ),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => _sendMessage(_inputController.text),
                    child: Container(
                      width: 34,
                      height: 34,
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(100),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.send_rounded,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownMenu() {
    return Positioned(
      top: 62,
      right: 20,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        shadowColor: Colors.black.withAlpha(50),
        child: Container(
          width: 210,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MenuItem(
                icon: Icons.add_comment_rounded,
                label: 'New Chat',
                iconColor: AppColors.primary,
                labelColor: AppColors.primary,
                onTap: _startNewChat,
              ),
              _MenuDivider(),
              _MenuItem(
                icon: Icons.history_rounded,
                label: 'Chat History',
                onTap: _openChatHistory,
              ),
              _MenuDivider(),
              _MenuItem(
                icon: Icons.person_outline,
                label: 'Account',
                onTap: () {
                  setState(() => _showMenu = false);
                  Navigator.of(context).push(slideRoute(const AccountSettingsScreen()));
                },
              ),
              _MenuDivider(),
              _MenuItem(
                icon: Icons.swap_horiz_rounded,
                label: 'Switch Avatar',
                onTap: _openSelectAvatar,
              ),
              _MenuDivider(),
              _MenuItem(
                icon: Icons.article_outlined,
                label: 'Articles',
                iconColor: const Color(0xFF6E6EFF),
                onTap: () {
                  setState(() => _showMenu = false);
                  Navigator.of(context).push(slideRoute(const ArticlesScreen()));
                },
              ),
              _MenuDivider(),
              _MenuItem(
                icon: Icons.credit_card_outlined,
                label: 'Upgrade Plan',
                iconColor: const Color(0xFF6E6EFF),
                labelColor: const Color(0xFF6E6EFF),
                onTap: () {
                  setState(() => _showMenu = false);
                  Navigator.of(context).push(slideRoute(const UpgradePlanScreen()));
                },
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helper widgets ─────────────────────────────────────────────────────────────

class _HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(200),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? labelColor;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            Icon(icon, size: 18, color: iconColor ?? AppColors.textPrimary),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: labelColor ?? AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, color: Color(0xFFF0F2FF));
  }
}

class _Dot extends StatelessWidget {
  final double opacity;
  const _Dot({required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
