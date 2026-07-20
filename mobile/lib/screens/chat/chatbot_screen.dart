import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_client.dart';
import '../../config/api_config.dart';

/// A single message in the chat (either user or assistant).
class _ChatMessage {
  final String role; // 'user' | 'assistant'
  final String content;

  const _ChatMessage({required this.role, required this.content});
}

/// Phase 12 — Client Chatbot Screen
/// Figma: "Client/Chatbot Empty" and "Client/Chatbot Convo"
///
/// States:
///   - Empty  : Disclaimer banner + quick-reply chips (no messages yet)
///   - Convo  : Scrollable chat history with AI/user bubbles + typing indicator
///
/// API flow:
///   1. On first message → POST /chat/sessions  (creates a session)
///   2. Each message     → POST /chat/sessions/{id}/messages
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

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    _inputController.clear();
    setState(() {
      _messages.add(_ChatMessage(role: 'user', content: trimmed));
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

  // ── UI builders ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildDisclaimerBanner(),
            Expanded(
              child: _messages.isEmpty && !_isTyping
                  ? const SizedBox() // Empty state — nothing in the scroll area
                  : _buildChatHistory(),
            ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  // Header — Figma: "Kausap AI" title centered
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 27,
            height: 27,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.chat_bubble_rounded,
                color: Colors.white, size: 15),
          ),
          const SizedBox(width: 8),
          Text(
            'Kausap AI',
            style: AppTextStyles.heading2.copyWith(
              color: AppColors.primary,
              fontSize: 20,
              letterSpacing: -0.55,
            ),
          ),
        ],
      ),
    );
  }

  // Disclaimer banner — Figma: green bg, info icon, text
  Widget _buildDisclaimerBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
        decoration: BoxDecoration(
          color: const Color(0xFFE7FEEE),
          border: Border.all(color: const Color(0xFF98F5CE)),
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 1,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline,
                color: Color(0xFF006C4F), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "I'm an AI assistant here to listen and support you, but I can't replace a professional counselor. If you're in crisis, please use the emergency resources.",
                style: AppTextStyles.body.copyWith(
                  fontSize: 12,
                  color: const Color(0xFF006C4F),
                  height: 1.75,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Scrollable chat history (shown once messages exist)
  Widget _buildChatHistory() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isTyping) {
          return _buildTypingIndicator();
        }
        final msg = _messages[index];
        return msg.role == 'user'
            ? _buildUserBubble(msg.content)
            : _buildAiBubble(msg.content);
      },
    );
  }

  // AI message bubble — Figma: white bg, light-blue robot avatar, tl=2px radius
  Widget _buildAiBubble(String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Robot avatar
          Padding(
            padding: const EdgeInsets.only(top: 4, right: 12),
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFE4F9FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_rounded,
                  color: AppColors.primary, size: 18),
            ),
          ),
          // Bubble
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 258),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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

  // User message bubble — Figma: primary blue bg, white text, tr=2px radius
  Widget _buildUserBubble(String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 240),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
          child: Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              height: 1.43,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  // Typing indicator — Figma: 3 grey dots in a white bubble
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4, right: 12),
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFE4F9FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_rounded,
                  color: AppColors.primary, size: 18),
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                    final phase = ((_dotAnimation.value * 3) - i).clamp(0.0, 1.0);
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

  // Bottom input area — Figma: Quick reply chips + message input form
  Widget _buildInputArea() {
    final bool isEmpty = _messages.isEmpty && !_isTyping;

    return Container(
      color: const Color(0xFFF8F9FF),
      child: Column(
        children: [
          // Quick reply chips (shown only in empty state)
          if (isEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _quickReplies.length,
                separatorBuilder: (_, index) => const SizedBox(width: 8),
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
                            color: const Color(0xFFC1C7D3).withValues(alpha: 0.5)),
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
          // Message input form
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: const Color(0xFFC1C7D3).withValues(alpha: 0.4)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 1,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 9),
                  // Attachment button (UI only per Figma)
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Icon(Icons.add_circle_outline,
                          color: AppColors.textSecondary, size: 22),
                    ),
                  ),
                  const SizedBox(width: 6),
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
                        hintText: 'Type your message...',
                        hintStyle: AppTextStyles.body.copyWith(
                          fontSize: 14,
                          color: const Color(0xFF6B7280),
                        ),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Send button
                  GestureDetector(
                    onTap: () => _sendMessage(_inputController.text),
                    child: Container(
                      width: 30,
                      height: 30,
                      margin: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0D000000),
                            blurRadius: 1,
                            offset: Offset(0, 1),
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
}
