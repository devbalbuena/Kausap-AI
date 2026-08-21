import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../theme/app_theme.dart';

class UpgradePlanScreen extends StatefulWidget {
  const UpgradePlanScreen({super.key});

  @override
  State<UpgradePlanScreen> createState() => _UpgradePlanScreenState();
}

class _UpgradePlanScreenState extends State<UpgradePlanScreen> {
  static const _storage = FlutterSecureStorage();
  bool _isAnnual = false; // Default to monthly view
  bool _isUpgrading = false;
  String _activePlanTier = 'none'; // 'none' | 'monthly' | 'annual'

  final List<Map<String, String>> _faqs = [
    {
      'question': 'Can I cancel my subscription anytime?',
      'answer':
          'Yes, you can cancel or switch your plan anytime with a single tap in your Account Settings. You will retain access until the end of your billing cycle.',
    },
    {
      'question': 'Is my mental health conversation data private?',
      'answer':
          'Absolutely. All messages with Kausap AI and therapists are protected with end-to-end encryption and strict medical-grade privacy standards.',
    },
    {
      'question': 'What payment methods are supported in the Philippines?',
      'answer':
          'We support GCash, Maya, Debit/Credit Cards (Visa, Mastercard), and Google Play / Apple In-App Purchases.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _checkProStatus();
  }

  Future<void> _checkProStatus() async {
    final tier = await _storage.read(key: 'pro_plan_tier');
    final isPro = await _storage.read(key: 'is_pro_member');

    if (mounted) {
      setState(() {
        if (tier == 'annual' || tier == 'monthly') {
          _activePlanTier = tier!;
          _isAnnual = (tier == 'annual');
        } else if (isPro == 'true') {
          _activePlanTier = 'monthly';
        } else {
          _activePlanTier = 'none';
        }
      });
    }
  }

  Future<void> _handleUpgrade(String targetTier) async {
    setState(() => _isUpgrading = true);
    await Future.delayed(const Duration(milliseconds: 900));

    await _storage.write(key: 'is_pro_member', value: 'true');
    await _storage.write(key: 'pro_plan_tier', value: targetTier);

    if (!mounted) return;
    setState(() {
      _isUpgrading = false;
      _activePlanTier = targetTier;
    });

    _showCelebrationSheet(targetTier);
  }

  void _showManageSubscriptionSheet(String planTier) {
    final bool isAnnualPlan = planTier == 'annual';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text('👑', style: TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAnnualPlan ? 'Kausap AI Pro (Annual)' : 'Kausap AI Pro (Monthly)',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const Text(
                      '🟢 Active Subscription',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildSubRow('Billing Cycle', isAnnualPlan ? 'Annual (₱1,899/year)' : 'Monthly (₱199/month)'),
                  const Divider(height: 18, color: Color(0xFFE2E8F0)),
                  _buildSubRow('Access Tier', 'All 4 Specialist Avatars & Features'),
                  const Divider(height: 18, color: Color(0xFFE2E8F0)),
                  _buildSubRow('Renewal Date', isAnnualPlan ? 'August 2027 (Renews Yearly)' : 'Next Month (Renews Monthly)'),
                ],
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Keep Active Plan', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  _confirmCancelSubscription();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  side: const BorderSide(color: Color(0xFFFCA5A5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Cancel Subscription / Revert to Free', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 12.5, color: Color(0xFF64748B))),
        Text(value, style: const TextStyle(fontFamily: 'Inter', fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
      ],
    );
  }

  Future<void> _confirmCancelSubscription() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Cancel Pro Membership?'),
        content: const Text('You will be reverted to the Free Basic tier and will lose access to specialist avatars.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Keep Pro')),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Yes, Downgrade', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _storage.write(key: 'is_pro_member', value: 'false');
      await _storage.write(key: 'pro_plan_tier', value: 'none');
      if (mounted) {
        setState(() => _activePlanTier = 'none');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription downgraded to Free Basic tier.'),
            backgroundColor: Color(0xFF475569),
          ),
        );
      }
    }
  }

  void _showCelebrationSheet(String tier) {
    final isAnnual = tier == 'annual';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text('👑', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 12),
            Text(
              isAnnual ? 'Welcome to Kausap Pro Annual!' : 'Welcome to Kausap Pro Monthly!',
              style: AppTextStyles.heading1.copyWith(fontSize: 22),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isAnnual
                  ? 'You unlocked the complete Annual plan with 20% savings, unlimited AI sessions, and all specialist avatars!'
                  : 'You now have full Pro access with all specialist avatars unlocked.',
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Start Exploring Pro', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(15),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xFF191C21)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text('Upgrade Plan', style: AppTextStyles.heading2.copyWith(fontSize: 18)),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                children: [
                  // Hero Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0284C7), Color(0xFF0EA5E9)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0284C7).withAlpha(60),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(45),
                                shape: BoxShape.circle,
                              ),
                              child: const Text('👑', style: TextStyle(fontSize: 22)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Kausap AI Pro',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    _activePlanTier != 'none'
                                        ? 'You are currently a ${_activePlanTier.toUpperCase()} Pro Member'
                                        : 'Unlock full mental wellness companion',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      color: Colors.white.withAlpha(220),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Unlock unlimited conversations with specialist personas, deep analytics, and personalized guided recovery.',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: Colors.white.withAlpha(235),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Billing Cycle Toggle (Monthly vs Annual)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isAnnual = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !_isAnnual ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: !_isAnnual
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withAlpha(15),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  'Monthly (₱199/mo)',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12.5,
                                    fontWeight: !_isAnnual ? FontWeight.w700 : FontWeight.w500,
                                    color: !_isAnnual ? const Color(0xFF1E293B) : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isAnnual = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _isAnnual ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: _isAnnual
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withAlpha(15),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Annual (₱158/mo)',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12.5,
                                      fontWeight: _isAnnual ? FontWeight.w700 : FontWeight.w500,
                                      color: _isAnnual ? const Color(0xFF1E293B) : const Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      '-20%',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 9.5,
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
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Included Features List
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0x1AC0C9C2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(8),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Included with Pro', style: AppTextStyles.heading2.copyWith(fontSize: 15)),
                        const SizedBox(height: 16),
                        _buildFeatureRow('Unlimited AI Companion Chat', 'No daily message limits or slowdowns'),
                        _buildFeatureRow('Unlock All Specialist Avatars', 'Dr. Kim, Dr. Min, Coach Jeon & custom personas'),
                        _buildFeatureRow('Full Wellness Activity Library', 'Access to all guided meditations, breathwork, and journaling'),
                        _buildFeatureRow('Comprehensive Mood Analytics', 'Monthly PDF summary reports of your emotional wellness'),
                        _buildFeatureRow('Ad-Free & Privacy Shield', 'Zero ads and prioritized server response speed'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Upgrade / Manage CTA Button based on exact tier state
                  _buildActionButton(),

                  const SizedBox(height: 24),

                  // FAQ Section
                  Text('Frequently Asked Questions', style: AppTextStyles.heading2.copyWith(fontSize: 16)),
                  const SizedBox(height: 10),
                  ..._faqs.map((faq) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0x1AC0C9C2)),
                      ),
                      child: ExpansionTile(
                        shape: const Border(),
                        title: Text(
                          faq['question']!,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Text(
                              faq['answer']!,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    if (_isUpgrading) {
      return Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
        ),
      );
    }

    // Tab is Monthly
    if (!_isAnnual) {
      if (_activePlanTier == 'monthly') {
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => _showManageSubscriptionSheet('monthly'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: const Text('Manage Monthly Pro Plan', style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        );
      } else if (_activePlanTier == 'annual') {
        return Container(
          width: double.infinity,
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: const Center(
            child: Text(
              'Included in Active Annual Plan 👑',
              style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
            ),
          ),
        );
      } else {
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => _handleUpgrade('monthly'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: const Text('Upgrade to Monthly — ₱199/month', style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        );
      }
    }

    // Tab is Annual
    if (_activePlanTier == 'annual') {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: () => _showManageSubscriptionSheet('annual'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: const Text('Manage Annual Pro Plan', style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700)),
        ),
      );
    } else if (_activePlanTier == 'monthly') {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: () => _handleUpgrade('annual'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: const Text('Switch to Annual — ₱1,899/year (Save 20%)', style: TextStyle(fontFamily: 'Inter', fontSize: 14.5, fontWeight: FontWeight.w700)),
        ),
      );
    } else {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: () => _handleUpgrade('annual'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: const Text('Upgrade to Annual — ₱1,899/year', style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700)),
        ),
      );
    }
  }

  Widget _buildFeatureRow(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Color(0xFFDCFCE7),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, size: 14, color: Color(0xFF16A34A)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textSecondary,
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
