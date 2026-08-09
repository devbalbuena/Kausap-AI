import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../theme/app_theme.dart';
import '../../services/message_service.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/skeleton_widgets.dart';
import 'widgets/attachment_menu_sheet.dart';
import 'widgets/typing_indicator.dart';
import 'widgets/therapist_profile_sheet.dart';

class DirectMessageScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final String? otherUserRole;
  final String? otherUserSpecialty;
  final bool? otherUserOnline;

  const DirectMessageScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserRole,
    this.otherUserSpecialty,
    this.otherUserOnline,
  });

  @override
  State<DirectMessageScreen> createState() => _DirectMessageScreenState();
}

class _DirectMessageScreenState extends State<DirectMessageScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final MessageService _messageService = MessageService();
  final FocusNode _inputFocusNode = FocusNode();

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isTyping = false;
  bool _otherUserTyping = false;
  Timer? _pollingTimer;
  Timer? _typingTimer;

  // Dynamic online status
  late bool _isOnline;

  @override
  void initState() {
    super.initState();
    _isOnline = widget.otherUserOnline ?? false;
    _fetchMessages();
    // Poll every 3 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _fetchMessages(isBackground: true);
    });
    _inputController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _typingTimer?.cancel();
    _inputController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (_inputController.text.isNotEmpty && !_isTyping) {
      setState(() => _isTyping = true);
      // Simulate the other user typing after a small delay
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) setState(() => _otherUserTyping = true);
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _otherUserTyping = false);
        });
      });
    }
    if (_inputController.text.isEmpty) {
      setState(() => _isTyping = false);
    }
    // Reset typing debounce
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isTyping = false);
    });
  }

  Future<void> _fetchMessages({bool isBackground = false}) async {
    try {
      final messages = await _messageService.getMessages(widget.otherUserId);
      if (mounted) {
        setState(() {
          _messages = messages;
          if (!isBackground) _isLoading = false;
        });
        if (!isBackground) _scrollToBottom();
      }
    } catch (e) {
      if (mounted && !isBackground) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading messages: $e')),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isSending = true;
      _isTyping = false;
      _otherUserTyping = false;
    });
    _inputController.clear();

    final tempMsg = {
      'sender_id': 'me',
      'receiver_id': widget.otherUserId,
      'content': text,
      'created_at': DateTime.now().toIso8601String(),
    };
    setState(() {
      _messages.add(tempMsg);
    });
    _scrollToBottom();

    try {
      await _messageService.sendMessage(widget.otherUserId, text);
      await _fetchMessages(isBackground: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(String? isoString) {
    if (isoString == null) return '';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return DateFormat('h:mm a').format(dt);
    } catch (_) {
      return '';
    }
  }

  bool _shouldShowDateDivider(int index) {
    if (index == 0) return true;
    final curr = _messages[index]['created_at'];
    final prev = _messages[index - 1]['created_at'];
    if (curr == null || prev == null) return false;
    try {
      final currDate = DateTime.parse(curr).toLocal();
      final prevDate = DateTime.parse(prev).toLocal();
      return !DateUtils.isSameDay(currDate, prevDate);
    } catch (_) {
      return false;
    }
  }

  String _formatDateDivider(String? isoString) {
    if (isoString == null) return '';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final now = DateTime.now();
      if (DateUtils.isSameDay(dt, now)) return 'Today';
      if (DateUtils.isSameDay(dt, now.subtract(const Duration(days: 1)))) return 'Yesterday';
      return DateFormat('MMMM d, yyyy').format(dt);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _isLoading
                    ? const SkeletonChatList()
                    : _buildChatList(),
                ),
                if (_otherUserTyping) const TypingIndicator(),
                _buildInputArea(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
          Stack(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withAlpha(30),
                child: Text(
                  widget.otherUserName.isNotEmpty ? widget.otherUserName[0].toUpperCase() : '?',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              Positioned(
                bottom: 1,
                right: 1,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _isOnline ? const Color(0xFF22C55E) : const Color(0xFF9CA3AF),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUserName,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _isOnline ? const Color(0xFF22C55E) : const Color(0xFF9CA3AF),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: _isOnline ? const Color(0xFF22C55E) : const Color(0xFF9CA3AF),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (widget.otherUserSpecialty != null) ...[
                      const Text(' · ', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      Text(
                        widget.otherUserSpecialty!,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: AppColors.textSecondary),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => TherapistProfileSheet(
                  name: widget.otherUserName,
                  role: widget.otherUserRole,
                  specialty: widget.otherUserSpecialty ?? 'Licensed Therapist',
                  isOnline: _isOnline,
                  bio: 'Helping individuals navigate life\'s challenges with compassion and evidence-based therapy.',
                  languages: const ['English', 'Filipino'],
                  sessionCount: 128,
                  rating: 4.9,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    if (_messages.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.chat_bubble_outline_rounded,
        title: 'No messages yet',
        description: 'Start the conversation by sending a message below.',
      );
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final bool isMe = msg['sender_id'] == 'me' || msg['receiver_id'] == widget.otherUserId;
        return Column(
          children: [
            if (_shouldShowDateDivider(index))
              _buildDateDivider(_formatDateDivider(msg['created_at'])),
            _buildBubble(msg['content'] ?? '', isMe, _formatTime(msg['created_at'])),
          ],
        );
      },
    );
  }

  Widget _buildDateDivider(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
        ],
      ),
    );
  }

  Widget _buildBubble(String text, bool isMe, String time) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            constraints: const BoxConstraints(maxWidth: 280),
            decoration: BoxDecoration(
              color: isMe ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isMe ? 20 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 20),
              ),
              boxShadow: const [
                BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
              ],
            ),
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
                fontSize: 14,
                height: 1.4,
                color: isMe ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
            child: Text(
              time,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 10 : 16,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 28),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (_) => const AttachmentMenuSheet(),
              );
            },
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _inputController,
                focusNode: _inputFocusNode,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                maxLines: 4,
                minLines: 1,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: _isSending ? null : _sendMessage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isSending ? const Color(0xFFCBD5E1) : AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
