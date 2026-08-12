import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../config/theme.dart';
import '../utils/haptics.dart';
import '../widgets/cards.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _header(context)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _introCard(),
                    const SizedBox(height: AppSpacing.lg),
                    ..._sections.map((s) => _section(s)),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Last updated: August 12, 2026',
                      style: AppText.caption,
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Haptics.tap();
              Navigator.of(context).pop();
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: AppColors.textPrimary, size: 22),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text('Privacy Policy', style: AppText.heading.copyWith(fontSize: 22)),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.02);
  }

  Widget _introCard() {
    return SurfaceCard(
      glow: true,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              gradient: AppColors.accentGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.privacy_tip_outlined,
                color: Colors.white, size: 32),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Your privacy matters',
            style: AppText.heading.copyWith(fontSize: 20),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'We are committed to protecting your personal information and being transparent about how we use it.',
            textAlign: TextAlign.center,
            style: AppText.bodySecondary,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.02);
  }

  List<({String title, String body})> get _sections => [
        (
          title: '1. Information We Collect',
          body: 'We collect information you provide directly, such as your name and email '
              'address when you create an account. We also collect usage data including the '
              'prompts you enter, videos you generate, and device information to improve our service.',
        ),
        (
          title: '2. How We Use Your Information',
          body: 'We use your information to provide and improve our services, communicate with '
              'you about your account, process payments, prevent abuse, and comply with legal '
              'obligations. We do not sell your personal data to third parties.',
        ),
        (
          title: '3. Data Storage & Security',
          body: 'Your data is stored securely using industry-standard encryption. Authentication '
              'tokens are stored locally on your device. We use Supabase for secure data storage '
              'with row-level security policies to ensure your data is only accessible to you.',
        ),
        (
          title: '4. Video Generation Data',
          body: 'The prompts you submit and videos generated are associated with your account. '
              'We may use anonymized prompt data to improve our AI models. Your generated videos '
              'are private to your account unless you choose to share them.',
        ),
        (
          title: '5. Third-Party Services',
          body: 'We use third-party services for authentication, payment processing, and AI video '
              'generation. These providers have their own privacy policies governing the use of '
              'your data on their platforms.',
        ),
        (
          title: '6. Your Rights',
          body: 'You have the right to access, correct, or delete your personal data. You can '
              'request data deletion by contacting our support team. You may also close your '
              'account at any time, which will remove access to your stored data.',
        ),
        (
          title: '7. Cookies & Tracking',
          body: 'We do not use advertising cookies. We use minimal local storage to maintain '
              'your session and preferences. No third-party tracking pixels are used.',
        ),
        (
          title: '8. Children\'s Privacy',
          body: 'Our service is not directed to children under 13. We do not knowingly collect '
              'personal information from children under 13. If you believe a child has provided '
              'us with personal data, please contact us so we can delete it.',
        ),
        (
          title: '9. Changes to This Policy',
          body: 'We may update this privacy policy from time to time. We will notify you of '
              'significant changes through the app or via email. Continued use of the service '
              'after changes constitutes acceptance of the updated policy.',
        ),
        (
          title: '10. Contact Us',
          body: 'If you have questions about this privacy policy or your data, please contact '
              'us at privacy@aivideogenerator.app. We will respond to your inquiry within '
              '5 business days.',
        ),
      ];

  Widget _section(({String title, String body}) section) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              section.title,
              style: AppText.body.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              section.body,
              style: AppText.bodySecondary.copyWith(fontSize: 13, height: 1.6),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.02);
  }
}
