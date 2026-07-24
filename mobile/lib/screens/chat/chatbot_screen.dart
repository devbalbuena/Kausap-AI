import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../services/api_client.dart';
import '../../config/api_config.dart';
import '../../models/avatar_model.dart';
import 'select_avatar_screen.dart';

/// A single message in the chat (either user or assistant).
class _ChatMessage {
  final String role; // 'user' | 'assistant'
  final String content;
  final String? imagePath;

  const _ChatMessage({required this.role, required this.content, this.imagePath});
}

/// Phase 12/21 — Client Chatbot Screen
/// Figma: "Basic" and "Premium" chat frames (node 395:8846, 477:172313)
///
/// Features:
///   - Large avatar portrait fills the screen in the empty/welcome state
///   - Header: "Kausap AI" + tier label left, phone/video icons + profile menu right
///   - Profile dropdown: Account, Switch Avatar, Article, Upgrade Plan, Logout
///   - Scrollable chat history with AI/user bubbles + typing indicator
///   - Input bar with + attachment and send button
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: source);
      if (image != null) {
        _sendMessage('', imagePath: image.path);
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

  // Animated dots for typing indicator
  late AnimationController _dotController;
  late Animation<double> _dotAnimation;

  // Quick-reply chips shown in the empty state
  static const List<String> _quickReplies = [
    'Academic Stress',
    'Anxiety',
    "Can't Sleep",
    'Feeling Lonely',
    'Work Stress',
  ];

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
    _dotAnimation = Tween<double>(begin: 0, end: 1).animate(_dotController);
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _dotController.dispose();
    super.dispose();
  }

  // ── API helpers ─────────────────────────────────────────────────────────────

  Future<String> _ensureSession() async {
    if (_sessionId != null) return _sessionId!;
    final data = await ApiClient().post(ApiConfig.chatSessions);
    _sessionId = data['id'] as String;
    return _sessionId!;
  }

  Future<void> _sendMessage(String text, {String? imagePath}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty && imagePath == null) return;

    _inputController.clear();
    setState(() {
      _messages.add(_ChatMessage(role: 'user', content: trimmed, imagePath: imagePath));
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      final sessionId = await _ensureSession();
      final endpoint = '${ApiConfig.chatSessions}/$sessionId/messages';
      final data = await ApiClient().post(endpoint, body: {'content': trimmed});
      final aiContent = data['content'] as String? ?? '…';

      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(role: 'assistant', content: aiContent));
        _isTyping = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(const _ChatMessage(
          role: 'assistant',
          content: 'Sorry, I couldn\'t reach the server. Please try again.',
        ));
        _isTyping = false;
      });
      _scrollToBottom();
    }
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
      MaterialPageRoute(
        builder: (_) => SelectAvatarScreen(currentAvatar: _currentAvatar),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _currentAvatar = result;
        // Start a new session when avatar changes
        _sessionId = null;
        _messages.clear();
      });
    }
  }

  // ── UI builders ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bool isEmpty = _messages.isEmpty && !_isTyping;

    return GestureDetector(
      // Dismiss menu when tapping outside
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
              // Dropdown menu overlay
              if (_showMenu) _buildDropdownMenu(),
            ],
          ),
        ),
      ),
    );
  }

  // Header — Figma: "Kausap AI" + tier label left, phone/video + avatar right
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
          // Phone call icon
          _HeaderIconBtn(
            icon: Icons.phone_outlined,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Voice call coming soon!')),
              );
            },
          ),
          const SizedBox(width: 8),
          // Video call icon
          _HeaderIconBtn(
            icon: Icons.videocam_outlined,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Video call coming soon!')),
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
                    color: Colors.black.withValues(alpha: 0.15),
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

  // Welcome state — large avatar portrait + text
  Widget _buildWelcomeView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Large avatar image
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
          // "Meet Kausap AI, your companion" text
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

  // Chat history view (messages)
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
            : _buildAiBubble(msg.content);
      },
    );
  }

  // AI message bubble
  Widget _buildAiBubble(String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Small avatar circle
          Padding(
            padding: const EdgeInsets.only(top: 4, right: 10),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
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
          // Bubble
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 258),
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
                content,
                style: AppTextStyles.body.copyWith(
                  fontSize: 14,
                  color: const Color(0xFF191C21),
                  height: 1.43,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // User message bubble
  Widget _buildUserBubble(_ChatMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 240),
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
              if (msg.imagePath != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(msg.imagePath!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              if (msg.content.isNotEmpty)
                Text(
                  msg.content,
                  style: const TextStyle(
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

  // Typing indicator
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
                    color: Colors.black.withValues(alpha: 0.1),
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
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final phase =
                        ((_dotAnimation.value * 3) - i).clamp(0.0, 1.0);
                    final bounce = (phase < 0.5 ? phase : 1 - phase) * 2;
                    return Padding(
                      padding: EdgeInsets.only(right: i < 2 ? 4 : 0),
                      child: Transform.translate(
                        offset: Offset(0, -4 * bounce),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: const Color(0xFFC1C7D3),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Bottom input area
  Widget _buildInputArea(bool isEmpty) {
    return Container(
      color: const Color(0xFFF0F2FF),
      child: Column(
        children: [
          // Quick reply chips (shown only in empty state)
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
                            color: const Color(0xFFC1C7D3)
                                .withValues(alpha: 0.5)),
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
                        style: TextStyle(
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
                    color: const Color(0xFFC1C7D3).withValues(alpha: 0.4)),
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
                  // Attachment button
                  GestureDetector(
                    onTap: _showAttachmentMenu,
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.add_circle_outline,
                          color: AppColors.textSecondary, size: 22),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Text input
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
                  // Send button
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
                            color: AppColors.primary.withValues(alpha: 0.4),
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

  // Profile dropdown menu — Figma: Account, Switch Avatar, Article, Upgrade Plan, Logout
  Widget _buildDropdownMenu() {
    return Positioned(
      top: 62,
      right: 20,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        shadowColor: Colors.black.withValues(alpha: 0.2),
        child: Container(
          width: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MenuItem(
                icon: Icons.person_outline,
                label: 'Account',
                onTap: () {
                  setState(() => _showMenu = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Account settings coming soon!')),
                  );
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
                label: 'Article',
                iconColor: const Color(0xFF6E6EFF),
                onTap: () {
                  setState(() => _showMenu = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Articles coming soon!')),
                  );
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Upgrade plan coming soon!')),
                  );
                },
              ),
              _MenuDivider(),
              _MenuItem(
                icon: Icons.logout_rounded,
                label: 'Logout',
                iconColor: AppColors.error,
                labelColor: AppColors.error,
                onTap: () {
                  setState(() => _showMenu = false);
                  // Navigate back to the parent which handles logout
                  Navigator.of(context).pop();
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
          color: Colors.white.withValues(alpha: 0.8),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF191C21)),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color labelColor;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor = const Color(0xFF191C21),
    this.labelColor = const Color(0xFF191C21),
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 12),
            Text(
              label,
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w500,
                color: labelColor,
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
    return Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: const Color(0xFFE5E7EB),
    );
  }
}
