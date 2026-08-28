import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../services/api_client.dart';
import '../../services/ambient_audio_service.dart';
import '../../utils/haptic_service.dart';
import '../../config/api_config.dart';
import '../../models/avatar_model.dart';
import 'select_avatar_screen.dart';
import 'chat_history_screen.dart';
import 'voice_call_screen.dart';
import '../articles/articles_screen.dart';
import '../profile/profile_screen.dart';
import '../../services/voice_audio_service.dart';
import '../../services/offline_mood_queue.dart';

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
  final String? initialMessage;
  final int? contextualMoodLevel;
  final String? userName;

  const ChatbotScreen({
    super.key,
    this.initialMessage,
    this.contextualMoodLevel,
    this.userName,
  });

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

  // Voice recording & TTS states
  bool _isRecordingVoice = false;
  String? _currentlySpeakingContent;
  int? _activeMoodContext;

  AvatarModel _currentAvatar = AvatarData.defaultAvatar;
  final ImagePicker _imagePicker = ImagePicker();

  static const _storage = FlutterSecureStorage();

  // Animated dots for typing indicator
  late AnimationController _dotController;
  late Animation<double> _dotAnimation;

  // Quick-Start conversation prompt cards
  static const List<Map<String, String>> _quickPromptCards = [
    {
      'title': "I'm anxious about exams & deadlines 📚",
      'desc': 'Unpack study stress, manage time, and regain focus',
      'prompt': "I'm feeling overwhelmed and anxious about my upcoming exams and school deadlines.",
    },
    {
      'title': 'Guide me through a calming breath 🌿',
      'desc': '2-minute box breathing to reset your nervous system',
      'prompt': 'Can you guide me through a 2-minute calming breathing exercise right now?',
    },
    {
      'title': 'I just need someone to vent to 💭',
      'desc': 'Safe, confidential space without any judgment',
      'prompt': 'I had a really difficult day and I just need a safe space to vent and talk through things.',
    },
    {
      'title': "I can't sleep, my thoughts are racing 😴",
      'desc': 'Quiet bedtime meditation and nighttime relaxation',
      'prompt': "I'm having trouble falling asleep because my mind won't stop racing.",
    },
    {
      'title': 'Help me reframe a stressful thought 💡',
      'desc': 'Positive thought reframing for emotional balance',
      'prompt': 'Can you help me reframe a stressful thought I keep having and find a more balanced perspective?',
    },
  ];

  static const List<String> _quickChips = [
    '📚 Exam Stress',
    '🌿 Calming Breath',
    '💭 Just Venting',
    '😴 Insomnia',
    '💡 Positive Reframe',
    '🛡️ 5-4-3-2-1 Grounding',
  ];

  bool _showQuickPrompts = true;

  @override
  void initState() {
    super.initState();
    _activeMoodContext = widget.contextualMoodLevel;
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
    _dotAnimation = Tween<double>(begin: 0, end: 1).animate(_dotController);
    _loadSavedAvatar().then((_) async {
      // 1. Pre-fill initial message from article discussion button if present
      if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _sendMessage(widget.initialMessage!);
        });
        return;
      }

      // 2. Feature A: Contextual Mood-to-Chat Bridge
      // If student has a logged mood today and no active chat messages yet, greet them contextually
      int? effectiveMood = _activeMoodContext;
      effectiveMood ??= await OfflineMoodQueue().getTodayOfflineMood();

      if (effectiveMood != null && _messages.isEmpty && mounted) {
        final name = widget.userName != null && widget.userName!.isNotEmpty
            ? (widget.userName![0].toUpperCase() + widget.userName!.substring(1))
            : 'Friend';
        String greeting;
        if (effectiveMood <= 2) {
          greeting = "I noticed you're having a low day today, $name. 💙 You don't have to carry it alone. Would you like to talk about what's weighing on you, or would you prefer a quick grounding exercise?";
        } else if (effectiveMood == 3) {
          greeting = "Kumusta $name! 🌿 I see you're feeling okay today. How is everything going so far? I'm right here whenever you need a listening ear.";
        } else {
          greeting = "Magandang araw $name! ✨ Glad to hear you're feeling ${effectiveMood == 5 ? 'great' : 'good'} today! What's something that made you smile?";
        }

        setState(() {
          _messages.add(_ChatMessage(role: 'assistant', content: greeting));
        });
      }
    });
    AmbientAudioService.instance.addListener(_onAmbientAudioChanged);
  }

  void _onAmbientAudioChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _openAmbientSoundscapeSheet() async {
    HapticService.lightTap();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AmbientSoundscapeSheet(),
    );
  }

  Future<void> _loadSavedAvatar() async {
    final avatarId = await _storage.read(key: 'selected_chatbot_avatar_id');
    final showPrompts = await _storage.read(key: 'show_chatbot_quick_prompts');

    if (showPrompts != null && mounted) {
      setState(() => _showQuickPrompts = showPrompts == 'true');
    }

    if (avatarId != null) {
      // 1. Check built-in & premium avatar roster
      final found = AvatarData.findById(avatarId);
      if (found != null && mounted) {
        setState(() => _currentAvatar = found);
        return;
      }

      // 2. Check multi-custom avatar storage
      try {
        final jsonStr = await _storage.read(key: 'custom_avatars_list_json');
        if (jsonStr != null && jsonStr.isNotEmpty) {
          final List<dynamic> list = jsonDecode(jsonStr);
          final customList = list.map((item) => AvatarModel.fromJson(item as Map<String, dynamic>)).toList();
          final customMatch = customList.where((a) => a.id == avatarId).firstOrNull;
          if (customMatch != null && mounted) {
            setState(() => _currentAvatar = customMatch);
            return;
          }
        }
      } catch (_) {}

      // 3. Fallback to legacy custom companion
      final customName = await _storage.read(key: 'custom_avatar_name');
      final customPrompt = await _storage.read(key: 'custom_avatar_prompt');
      if (customName != null && customName.isNotEmpty && mounted) {
        setState(() {
          _currentAvatar = AvatarModel(
            id: 'custom_user_avatar',
            name: customName,
            roleTitle: 'Custom Companion',
            tier: 'basic',
            imagePath: 'assets/avatars/avatar_basic_kim.png',
            systemPrompt: customPrompt ?? 'You are $customName, a personalized mental wellness companion.',
          );
        });
      }
    }
  }

  Future<void> _toggleQuickPrompts() async {
    HapticService.lightTap();
    setState(() => _showQuickPrompts = !_showQuickPrompts);
    await _storage.write(key: 'show_chatbot_quick_prompts', value: _showQuickPrompts.toString());
  }

  void _toggleVoiceRecording() {
    if (!_isRecordingVoice) {
      HapticService.heavyTap();
      setState(() {
        _isRecordingVoice = true;
      });
      VoiceAudioService().startListening(
        onResult: (transcript) {
          if (mounted) {
            setState(() {
              _inputController.text = transcript;
            });
          }
        },
      );
    } else {
      HapticService.mediumTap();
      VoiceAudioService().stopListening();
      setState(() {
        _isRecordingVoice = false;
      });
      final textToSend = _inputController.text.trim();
      if (textToSend.isNotEmpty) {
        _sendMessage(textToSend);
      }
    }
  }

  void _toggleTts(String text) {
    if (_currentlySpeakingContent == text && VoiceAudioService().isSpeaking) {
      VoiceAudioService().stopSpeaking();
      setState(() => _currentlySpeakingContent = null);
    } else {
      HapticService.lightTap();
      setState(() => _currentlySpeakingContent = text);
      VoiceAudioService().speak(
        text,
        onDone: () {
          if (mounted) setState(() => _currentlySpeakingContent = null);
        },
      );
    }
  }

  @override
  void dispose() {
    VoiceAudioService().stopSpeaking();
    VoiceAudioService().stopListening();
    AmbientAudioService.instance.removeListener(_onAmbientAudioChanged);
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
      String personaKey = 'buddy';
      if (_currentAvatar.id.contains('maya')) {
        personaKey = 'maya';
      } else if (_currentAvatar.id.contains('ben')) {
        personaKey = 'ben';
      } else if (_currentAvatar.id.contains('santos')) {
        personaKey = 'santos';
      }

      final data = await ApiClient().post(
        endpoint,
        body: {
          'content': trimmed.isEmpty ? '[Photo attachment]' : trimmed,
          'persona': personaKey,
        },
      );
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
      final fallbackResponse = _generateEmpatheticFallback(
        trimmed,
        isCrisis: isCrisis,
        hasImage: imageBytes != null || imagePath != null,
      );
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

  String _generateEmpatheticFallback(String input, {bool isCrisis = false, bool hasImage = false}) {
    final lower = input.toLowerCase();

    if (isCrisis) {
      return "I hear how heavy things feel right now, and I want you to know you don't have to carry this alone. Your life has immense value, and there is caring support available 24/7. Please connect with someone who can help right now:";
    }

    if (hasImage && input.trim().isEmpty) {
      return "I received your photo! 📸 Whether it's your student ID, school documents, study notes, or something personal you wanted to share, I'm right here with you. What would you like to discuss about it, or how are you feeling right now?";
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
      await _storage.write(key: 'selected_chatbot_avatar_id', value: result.id);
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
    final audio = AmbientAudioService.instance;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Living Expressive Chat Mascot Avatar (Reacts to isTyping!) or Specialist Avatar Photo
          if (_currentAvatar.isMascot)
            _ChatCompanionAvatar(
              isTyping: _isTyping,
              avatar: _currentAvatar,
              size: 38,
              onAvatarTap: () => setState(() => _showMenu = !_showMenu),
            )
          else
            GestureDetector(
              onTap: () => setState(() => _showMenu = !_showMenu),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipOval(
                      child: Image.asset(
                        _currentAvatar.imagePath,
                        width: 38,
                        height: 38,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: const Color(0xFFEEF2FF),
                          child: const Icon(Icons.person, color: AppColors.primary, size: 22),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(width: 10),

          // Left: Brand name + tier
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _currentAvatar.name,
                        style: AppTextStyles.heading2.copyWith(
                          color: AppColors.primary,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (_isTyping)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'thinking… ✨',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0284C7),
                          ),
                        ),
                      ),
                  ],
                ),
                Text(
                  _isTyping
                      ? 'Composing a caring response'
                      : (_currentAvatar.isPremium
                          ? '👑 Premium Specialist'
                          : (_currentAvatar.isMascot ? '🌱 Active Mascot Shield' : '🌱 Basic Companion')),
                  style: AppTextStyles.body.copyWith(
                    fontSize: 11,
                    color: _currentAvatar.isPremium
                        ? const Color(0xFFD97706)
                        : (_isTyping ? const Color(0xFF0284C7) : AppColors.textSecondary),
                    fontWeight: _currentAvatar.isPremium ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Ambient Audio / Soundscape Control Button
          if (audio.isPlaying)
            GestureDetector(
              onTap: _openAmbientSoundscapeSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF7DD3FC)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x140284C7), blurRadius: 6, offset: Offset(0, 2)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      audio.currentType == SoundscapeType.rain
                          ? '🌧️'
                          : audio.currentType == SoundscapeType.ocean
                              ? '🌊'
                              : audio.currentType == SoundscapeType.forest
                                  ? '🍃'
                                  : '🧘',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 4),
                    const _SoundwaveBars(),
                  ],
                ),
              ),
            )
          else
            _HeaderIconBtn(
              icon: Icons.headphones_rounded,
              onTap: _openAmbientSoundscapeSheet,
            ),
          const SizedBox(width: 6),

          // Phone call icon
          _HeaderIconBtn(
            icon: Icons.phone_outlined,
            onTap: () {
              Navigator.of(context).push(slideUpRoute(VoiceCallScreen(avatar: _currentAvatar)));
            },
          ),
          const SizedBox(width: 6),

          // Avatar profile circle → opens dropdown menu
          GestureDetector(
            onTap: () => setState(() => _showMenu = !_showMenu),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _currentAvatar.isMascot
                  ? ClipOval(
                      child: Container(
                        color: const Color(0xFFE0F2FE),
                        child: const Icon(Icons.menu_rounded, color: AppColors.primary, size: 20),
                      ),
                    )
                  : ClipOval(
                      child: Image.asset(
                        _currentAvatar.imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: const Color(0xFFEEF2FF),
                          child: const Icon(Icons.person, color: AppColors.primary, size: 22),
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
    final bool isSpacious = !_showQuickPrompts;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: isSpacious ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar Hero Card with Soft Ambient Glow
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: isSpacious ? 24 : 20, vertical: isSpacious ? 32 : 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE0F2FE), Color(0xFFEDE9FE)],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFBAE6FD)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x120077B6),
                  blurRadius: 22,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                if (_currentAvatar.isMascot)
                  _ChatCompanionAvatar(
                    isTyping: false,
                    size: isSpacious ? 104 : 68,
                    avatar: _currentAvatar,
                    onAvatarTap: () {
                      HapticService.mediumTap();
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text("I'm right here listening, take your time! 💬✨"),
                          backgroundColor: const Color(0xFF0F172A),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  )
                else
                  Container(
                    width: isSpacious ? 104 : 72,
                    height: isSpacious ? 104 : 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(isSpacious ? 35 : 25),
                          blurRadius: isSpacious ? 16 : 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        _currentAvatar.imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: const Color(0xFFEEF2FF),
                          child: Icon(Icons.person, color: AppColors.primary, size: isSpacious ? 52 : 36),
                        ),
                      ),
                    ),
                  ),
                SizedBox(height: isSpacious ? 16 : 12),
                Text(
                  'Magandang araw! I\'m ${_currentAvatar.name} ✨',
                  style: AppTextStyles.heading2.copyWith(
                    fontSize: isSpacious ? 20 : 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  _currentAvatar.isMascot
                      ? 'Your 24/7 confidential companion for student wellness. How can I help support you today?'
                      : 'Your ${_currentAvatar.isPremium ? 'Specialist' : 'Companion'} for student mental wellness. How can I support you today?',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: isSpacious ? 13.5 : 12.5,
                    color: const Color(0xFF475569),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (isSpacious) ...[
                  const SizedBox(height: 20),
                  InkWell(
                    onTap: _toggleQuickPrompts,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(220),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFBAE6FD)),
                        boxShadow: const [
                          BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2)),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bolt_rounded, size: 16, color: Color(0xFF0284C7)),
                          SizedBox(width: 6),
                          Text(
                            'Show Conversation Prompts 💡',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0284C7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          if (_showQuickPrompts) ...[
            const SizedBox(height: 20),

            // Quick-Start Conversation Prompts Header with Hide Button
            Align(
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.bolt_rounded, size: 16, color: Color(0xFF0284C7)),
                      SizedBox(width: 4),
                      Text(
                        'Quick-Start Prompts',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: _toggleQuickPrompts,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Text(
                            'Hide',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          SizedBox(width: 2),
                          Icon(Icons.keyboard_arrow_up_rounded, size: 14, color: Color(0xFF64748B)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Prompt Cards
            ..._quickPromptCards.map((item) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () {
                      HapticService.lightTap();
                      _sendMessage(item['prompt']!);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x06000000),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title']!,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  item['desc']!,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11.5,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 12,
                              color: Color(0xFF0284C7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
          const SizedBox(height: 12),
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
            child: _currentAvatar.isMascot
                ? _ChatCompanionAvatar(
                    isTyping: false,
                    size: 32,
                    avatar: _currentAvatar,
                  )
                : Container(
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
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _toggleTts(msg.content),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _currentlySpeakingContent == msg.content ? const Color(0xFFE0F2FE) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: _currentlySpeakingContent == msg.content
                          ? Border.all(color: const Color(0xFFBAE6FD))
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _currentlySpeakingContent == msg.content ? Icons.stop_circle_rounded : Icons.volume_up_rounded,
                          size: 13,
                          color: _currentlySpeakingContent == msg.content ? const Color(0xFF0284C7) : const Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _currentlySpeakingContent == msg.content ? 'Speaking • Tap to stop' : 'Listen 🔊',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: _currentlySpeakingContent == msg.content ? const Color(0xFF0284C7) : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
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
            child: _currentAvatar.isMascot
                ? _ChatCompanionAvatar(
                    isTyping: true,
                    size: 32,
                    avatar: _currentAvatar,
                  )
                : Container(
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
          if (!isEmpty) ...[
            const SizedBox(height: 6),
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _quickChips.length,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (context, i) {
                  return GestureDetector(
                    onTap: () {
                      HapticService.lightTap();
                      _sendMessage(_quickPromptCards[i % _quickPromptCards.length]['prompt']!);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFFBAE6FD)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x08000000),
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        _quickChips[i],
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          if (_isRecordingVoice)
            Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.mic_rounded, color: Color(0xFFDC2626), size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Listening... Speak freely 🎙️',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF991B1B),
                      ),
                    ),
                  ),
                  const _SoundwaveBars(),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _toggleVoiceRecording,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Send Voice',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 6),
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
                        hintText: _isRecordingVoice ? 'Listening to your voice...' : 'Start conversation...',
                        hintStyle: AppTextStyles.body.copyWith(
                          fontSize: 14,
                          color: _isRecordingVoice ? const Color(0xFFDC2626) : const Color(0xFF9BA4B4),
                        ),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  // Mic Button (Hold / Tap to record voice note)
                  Semantics(
                    label: _isRecordingVoice ? 'Stop voice recording and send' : 'Record voice message',
                    button: true,
                    child: GestureDetector(
                      onTap: _toggleVoiceRecording,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _isRecordingVoice ? const Color(0xFFFEF2F2) : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isRecordingVoice ? Icons.stop_circle_rounded : Icons.mic_none_rounded,
                          color: _isRecordingVoice ? const Color(0xFFDC2626) : AppColors.primary,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Send Text Button
                  Semantics(
                    label: 'Send text message',
                    button: true,
                    child: GestureDetector(
                      onTap: () => _sendMessage(_inputController.text),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x330077B6),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.send_rounded,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
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
          width: 235,
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
                icon: Icons.swap_horiz_rounded,
                label: 'Switch Avatar',
                onTap: _openSelectAvatar,
              ),
              _MenuDivider(),
              _MenuItem(
                icon: Icons.emergency_rounded,
                label: 'Crisis & Hotlines (24/7)',
                iconColor: const Color(0xFFDC2626),
                labelColor: const Color(0xFFDC2626),
                onTap: _showHotlinesSheet,
              ),
              _MenuDivider(),
              _MenuItem(
                icon: Icons.article_outlined,
                label: 'Wellness Articles',
                iconColor: const Color(0xFF6E6EFF),
                onTap: () {
                  setState(() => _showMenu = false);
                  Navigator.of(context).push(slideRoute(const ArticlesScreen()));
                },
              ),
              _MenuDivider(),
              _MenuItem(
                icon: Icons.person_outline_rounded,
                label: 'My Profile',
                iconColor: const Color(0xFF0F172A),
                onTap: () {
                  setState(() => _showMenu = false);
                  Navigator.of(context).push(slideRoute(const ProfileScreen()));
                },
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }

  void _showHotlinesSheet() {
    setState(() => _showMenu = false);
    HapticService.mediumTap();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.support_agent_rounded, color: Color(0xFFDC2626), size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '24/7 Student Support Hotlines',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Free, confidential mental health assistance',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildHotlineRow('📞 NCMH Crisis Helpline', '1553 (Toll-Free 24/7) / 0917-899-8727'),
              const SizedBox(height: 8),
              _buildHotlineRow('🤝 Hopeline Philippines', '(02) 8804-4673 / 0917-558-4673'),
              const SizedBox(height: 8),
              _buildHotlineRow('🏫 FSUU Guidance Office', '(085) 342-1830 • guidance@urios.edu.ph'),
              const SizedBox(height: 8),
              _buildHotlineRow('🚨 Emergency Services', '911'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: const Color(0xFFF1F5F9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                  ),
                ),
              ),
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
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: labelColor ?? AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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

// ── Living Chat Companion Avatar (Reacts to Typing & States) ─────────────────
class _ChatCompanionAvatar extends StatefulWidget {
  final bool isTyping;
  final double size;
  final AvatarModel avatar;
  final VoidCallback? onAvatarTap;

  const _ChatCompanionAvatar({
    required this.isTyping,
    this.size = 38,
    required this.avatar,
    this.onAvatarTap,
  });

  @override
  State<_ChatCompanionAvatar> createState() => _ChatCompanionAvatarState();
}

class _ChatCompanionAvatarState extends State<_ChatCompanionAvatar> with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _wiggleController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _wiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    if (widget.isTyping) {
      _wiggleController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _ChatCompanionAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isTyping != oldWidget.isTyping) {
      if (widget.isTyping) {
        _wiggleController.repeat(reverse: true);
      } else {
        _wiggleController.stop();
        _wiggleController.reset();
      }
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    _wiggleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onAvatarTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: Listenable.merge([_floatController, _wiggleController]),
        builder: (context, _) {
          final floatOffset = math.sin(_floatController.value * math.pi * 2) * 2.0;
          final wiggleAngle = widget.isTyping ? (math.sin(_wiggleController.value * math.pi * 2) * 0.08) : 0.0;

          return Transform.translate(
            offset: Offset(0, floatOffset),
            child: Transform.rotate(
              angle: wiggleAngle,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: widget.isTyping
                        ? [const Color(0xFF06B6D4), const Color(0xFF8B5CF6)]
                        : [const Color(0xFF0077B6), const Color(0xFF00B4D8)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.isTyping
                          ? const Color(0x668B5CF6)
                          : const Color(0x330077B6),
                      blurRadius: widget.isTyping ? 12 : 8,
                      spreadRadius: widget.isTyping ? 2 : 0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Headset Arc
                    Positioned(
                      top: widget.size * 0.12,
                      child: Container(
                        width: widget.size * 0.65,
                        height: widget.size * 0.25,
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.white.withAlpha(220), width: widget.size * 0.05),
                          ),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(widget.size * 0.3)),
                        ),
                      ),
                    ),
                    // Headset Ear Cushions
                    Positioned(
                      left: widget.size * 0.16,
                      top: widget.size * 0.44,
                      child: CircleAvatar(radius: widget.size * 0.09, backgroundColor: Colors.white),
                    ),
                    Positioned(
                      right: widget.size * 0.16,
                      top: widget.size * 0.44,
                      child: CircleAvatar(radius: widget.size * 0.09, backgroundColor: Colors.white),
                    ),
                    // Expressive Face Painter
                    CustomPaint(
                      size: Size(widget.size, widget.size),
                      painter: _ChatMascotFacePainter(
                        isTyping: widget.isTyping,
                        progress: _floatController.value,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ChatMascotFacePainter extends CustomPainter {
  final bool isTyping;
  final double progress;

  _ChatMascotFacePainter({
    required this.isTyping,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final eyePaint = Paint()..color = Colors.white;
    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.05
      ..strokeCap = StrokeCap.round;
    final blushPaint = Paint()..color = const Color(0xFFFFB4A2).withAlpha(180);

    final isBlinking = !isTyping && progress > 0.48 && progress < 0.52;

    if (isTyping) {
      // Winking star eye ( ★ ‿ ◕ )
      final starPath = Path();
      final cx = size.width * 0.35;
      final cy = size.height * 0.43;
      final r = size.width * 0.09;
      starPath.moveTo(cx, cy - r);
      starPath.lineTo(cx + r * 0.3, cy - r * 0.3);
      starPath.lineTo(cx + r, cy);
      starPath.lineTo(cx + r * 0.3, cy + r * 0.3);
      starPath.lineTo(cx, cy + r);
      starPath.lineTo(cx - r * 0.3, cy + r * 0.3);
      starPath.lineTo(cx - r, cy);
      starPath.lineTo(cx - r * 0.3, cy - r * 0.3);
      starPath.close();
      canvas.drawPath(starPath, eyePaint);

      // Right eye: round open eye
      canvas.drawCircle(Offset(size.width * 0.65, size.height * 0.43), size.width * 0.08, eyePaint);
      canvas.drawCircle(Offset(size.width * 0.63, size.height * 0.40), size.width * 0.03, Paint()..color = Colors.white);
    } else if (isBlinking) {
      // Peaceful closed smiling eyes
      final leftArc = Path()
        ..moveTo(size.width * 0.24, size.height * 0.44)
        ..quadraticBezierTo(size.width * 0.35, size.height * 0.36, size.width * 0.46, size.height * 0.44);
      final rightArc = Path()
        ..moveTo(size.width * 0.54, size.height * 0.44)
        ..quadraticBezierTo(size.width * 0.65, size.height * 0.36, size.width * 0.76, size.height * 0.44);
      canvas.drawPath(leftArc, strokePaint);
      canvas.drawPath(rightArc, strokePaint);
    } else {
      // Round sparkling eyes
      canvas.drawCircle(Offset(size.width * 0.35, size.height * 0.42), size.width * 0.08, eyePaint);
      canvas.drawCircle(Offset(size.width * 0.65, size.height * 0.42), size.width * 0.08, eyePaint);

      final glintPaint = Paint()..color = Colors.white;
      canvas.drawCircle(Offset(size.width * 0.33, size.height * 0.39), size.width * 0.03, glintPaint);
      canvas.drawCircle(Offset(size.width * 0.63, size.height * 0.39), size.width * 0.03, glintPaint);
    }

    // Rosy Cheeks
    canvas.drawCircle(Offset(size.width * 0.20, size.height * 0.56), size.width * 0.07, blushPaint);
    canvas.drawCircle(Offset(size.width * 0.80, size.height * 0.56), size.width * 0.07, blushPaint);

    // Warm Upbeat Smile
    final mouth = Path()
      ..moveTo(size.width * 0.38, size.height * 0.58)
      ..quadraticBezierTo(size.width * 0.50, size.height * 0.72, size.width * 0.62, size.height * 0.58);
    canvas.drawPath(mouth, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _ChatMascotFacePainter oldDelegate) =>
      oldDelegate.isTyping != isTyping || oldDelegate.progress != progress;
}

// ── Animated Equalizer Bars for Active Audio ──────────────────────────────────
class _SoundwaveBars extends StatefulWidget {
  const _SoundwaveBars();

  @override
  State<_SoundwaveBars> createState() => _SoundwaveBarsState();
}

class _SoundwaveBarsState extends State<_SoundwaveBars> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final h1 = 4.0 + (math.sin(t * math.pi * 2) * 4.0).abs();
        final h2 = 4.0 + (math.sin((t + 0.33) * math.pi * 2) * 6.0).abs();
        final h3 = 4.0 + (math.sin((t + 0.66) * math.pi * 2) * 5.0).abs();

        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildBar(h1),
            const SizedBox(width: 2),
            _buildBar(h2),
            const SizedBox(width: 2),
            _buildBar(h3),
          ],
        );
      },
    );
  }

  Widget _buildBar(double height) {
    return Container(
      width: 2.5,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF0284C7),
        borderRadius: BorderRadius.circular(1.5),
      ),
    );
  }
}

// ── Ambient Soundscapes Bottom Modal Sheet ────────────────────────────────────
class _AmbientSoundscapeSheet extends StatefulWidget {
  const _AmbientSoundscapeSheet();

  @override
  State<_AmbientSoundscapeSheet> createState() => _AmbientSoundscapeSheetState();
}

class _AmbientSoundscapeSheetState extends State<_AmbientSoundscapeSheet> {
  final AmbientAudioService _audio = AmbientAudioService.instance;

  @override
  Widget build(BuildContext context) {
    final soundscapes = AmbientAudioService.availableSoundscapes;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: const [
          BoxShadow(color: Color(0x22000000), blurRadius: 24, offset: Offset(0, -6)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 18),

              // Title & Subtitle
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text('🎧', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 8),
                  Text(
                    'Calming Ambient Soundscapes',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Play soothing background soundscapes while chatting to ease anxiety and focus your mind.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  height: 1.35,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),

              // Soundscape Selection Cards
              ...soundscapes.map((s) {
                final isSelected = _audio.currentType == s.type;
                final isPlayingThis = isSelected && _audio.isPlaying;

                return GestureDetector(
                  onTap: () {
                    HapticService.lightTap();
                    setState(() {
                      if (isSelected && _audio.isPlaying) {
                        _audio.stop();
                      } else {
                        _audio.play(s.type);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFF0F9FF) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? const [BoxShadow(color: Color(0x140284C7), blurRadius: 8, offset: Offset(0, 2))]
                          : [],
                    ),
                    child: Row(
                      children: [
                        Text(s.emoji, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.title,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13.5,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                  color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                s.description,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isPlayingThis ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isPlayingThis ? Icons.stop_rounded : Icons.play_arrow_rounded,
                            size: 18,
                            color: isPlayingThis ? Colors.white : const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 14),

              // Volume Slider
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Icon(
                      _audio.volume > 0.5
                          ? Icons.volume_up_rounded
                          : _audio.volume > 0
                              ? Icons.volume_down_rounded
                              : Icons.volume_mute_rounded,
                      color: const Color(0xFF0284C7),
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                          activeTrackColor: const Color(0xFF0284C7),
                          inactiveTrackColor: const Color(0xFFCBD5E1),
                          thumbColor: const Color(0xFF0284C7),
                        ),
                        child: Slider(
                          value: _audio.volume,
                          min: 0.0,
                          max: 1.0,
                          onChanged: (val) {
                            setState(() => _audio.setVolume(val));
                          },
                        ),
                      ),
                    ),
                    Text(
                      '${(_audio.volume * 100).toInt()}%',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Bottom Play/Pause & Dismiss Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        HapticService.mediumTap();
                        setState(() {
                          _audio.togglePlay();
                        });
                      },
                      icon: Icon(_audio.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                      label: Text(_audio.isPlaying ? 'Pause Soundscape' : 'Play Soundscape'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _audio.isPlaying ? const Color(0xFFEF4444) : const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

