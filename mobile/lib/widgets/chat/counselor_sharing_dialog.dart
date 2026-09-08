import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/haptic_service.dart';

/// Interactive modal dialog implementing two-step verification for granting
/// or revoking university counselor access to AI chat transcripts.
/// Enforces student autonomy, informed consent, and confidential-by-default rules.
class CounselorSharingDialog {
  static Future<void> show(
    BuildContext context, {
    ValueChanged<bool>? onStatusChanged,
  }) async {
    final auth = context.read<AuthProvider>();
    final bool currentStatus = auth.currentUser?['share_chat_with_counselor'] == true;

    if (currentStatus) {
      // Flow: Revoke consent (Turn OFF)
      await _showRevokeDialog(context, onStatusChanged);
    } else {
      // Flow: Grant consent (Turn ON) with Step 1 Explanatory Sheet & Step 2 Confirmation
      await _showGrantFlow(context, onStatusChanged);
    }
  }

  /// Step 1: Explanatory Modal Bottom Sheet
  static Future<void> _showGrantFlow(
    BuildContext context,
    ValueChanged<bool>? onStatusChanged,
  ) async {
    HapticService.lightTap();
    final bool? proceedToStep2 = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SharingExplanationSheet(),
    );

    if (proceedToStep2 == true && context.mounted) {
      // Step 2: Secondary Confirmation Dialog ("Are you sure?")
      await _showSecondaryConfirmationDialog(context, onStatusChanged);
    }
  }

  /// Step 2: Secondary Verification Dialog
  static Future<void> _showSecondaryConfirmationDialog(
    BuildContext context,
    ValueChanged<bool>? onStatusChanged,
  ) async {
    HapticService.mediumTap();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.verified_user_rounded, color: Color(0xFF0284C7), size: 22),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Are you sure?',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your conversation transcripts with Kausap AI will become visible in the counselor clinical review portal.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: Color(0xFF334155),
                height: 1.45,
              ),
            ),
            SizedBox(height: 12),
            Text(
              '🔒 You can revoke this permission anytime from the chat menu or Privacy Settings with a single tap.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticService.lightTap();
              Navigator.pop(ctx, false);
            },
            child: const Text(
              'Keep Private',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              HapticService.mediumTap();
              Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: const Text(
              'Yes, Share with Counselors',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final auth = context.read<AuthProvider>();
      await auth.updateProfile({'share_chat_with_counselor': true});
      onStatusChanged?.call(true);

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Color(0xFF4ADE80), size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Counselor chat sharing enabled. You can revoke this anytime.',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 12.5),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF0F172A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Revocation Dialog (Turn OFF)
  static Future<void> _showRevokeDialog(
    BuildContext context,
    ValueChanged<bool>? onStatusChanged,
  ) async {
    HapticService.lightTap();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.lock_rounded, color: Color(0xFFDC2626), size: 22),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Disable Chat Sharing?',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Your conversation transcripts will immediately become confidential and hidden from university counselors.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: Color(0xFF475569),
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: const Text(
              'Disable Sharing',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final auth = context.read<AuthProvider>();
      await auth.updateProfile({'share_chat_with_counselor': false});
      onStatusChanged?.call(false);

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.lock_rounded, color: Color(0xFFBAE6FD), size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '🔒 Counselor sharing disabled. Your AI chats are now completely private.',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 12.5),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF0F172A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

/// Step 1: Bottom Sheet Explaining Counselor Sharing
class _SharingExplanationSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).padding.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Row
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE0F2FE), Color(0xFFBAE6FD)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.shield_outlined, color: Color(0xFF0284C7), size: 26),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Share AI Chats with Counselors?',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Private by default • Student choice first',
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

            // Introductory Callout
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Text(
                'By default, your conversations with Kausap AI are 100% confidential and cannot be viewed by counselors or administrators. You may voluntarily choose to share them to assist in clinical guidance.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  color: Color(0xFF334155),
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Detail Cards
            _buildDetailCard(
              icon: Icons.person_search_rounded,
              color: const Color(0xFF7C3AED),
              title: 'Who has access?',
              description: 'Only licensed university guidance counselors at Father Saturnino Urios University (FSUU). System administrators cannot view private messages.',
            ),
            const SizedBox(height: 10),
            _buildDetailCard(
              icon: Icons.psychology_outlined,
              color: const Color(0xFF0284C7),
              title: 'How does this help you?',
              description: 'Counselors can review your emotional journey and conversation context to prepare personalized advice during 1-on-1 counseling appointments.',
            ),
            const SizedBox(height: 10),
            _buildDetailCard(
              icon: Icons.lock_clock_rounded,
              color: const Color(0xFF059669),
              title: 'Revoke anytime instantly',
              description: 'You are in complete control. Turning this OFF immediately revokes counselor visibility with zero delay.',
            ),
            const SizedBox(height: 12),

            // Duty of care disclaimer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Emergency Protocol: In accordance with student safety ethics, acute crisis triggers (imminent danger/self-harm) trigger campus emergency triage regardless of this setting.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: Color(0xFF92400E),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      HapticService.lightTap();
                      Navigator.pop(context, false);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: const Text(
                      'Keep Private',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      HapticService.mediumTap();
                      Navigator.pop(context, true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: const Text(
                      'Proceed to Verify',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildDetailCard({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
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
    );
  }
}
