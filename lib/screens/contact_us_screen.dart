import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/theme.dart';
import '../utils/haptics.dart';
import '../widgets/buttons.dart';
import '../widgets/cards.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

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
                    _contactTile(
                      context,
                      icon: Icons.email_outlined,
                      title: 'Email',
                      subtitle: 'support@aivideogenerator.app',
                      onTap: () {
                        Haptics.tap();
                        _launch('mailto:support@aivideogenerator.app');
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _contactTile(
                      context,
                      icon: Icons.language_outlined,
                      title: 'Website',
                      subtitle: 'www.aivideogenerator.app',
                      onTap: () {
                        Haptics.tap();
                        _launch('https://aivideogenerator.app');
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _contactTile(
                      context,
                      icon: Icons.chat_outlined,
                      title: 'Live Chat',
                      subtitle: 'Available 9am–6pm, Mon–Fri',
                      onTap: () {
                        Haptics.tap();
                        _launch('https://aivideogenerator.app/chat');
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'FAQ',
                      style: AppText.heading.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ..._faqs.map((f) => _faqTile(f)),
                    const SizedBox(height: AppSpacing.xl),
                    PrimaryButton(
                      label: 'Send Feedback',
                      icon: Icons.feedback_outlined,
                      onPressed: () {
                        Haptics.tap();
                        _launch('mailto:feedback@aivideogenerator.app');
                      },
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
          Text('Contact Us', style: AppText.heading.copyWith(fontSize: 22)),
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
            child: const Icon(Icons.support_agent_rounded,
                color: Colors.white, size: 32),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'We are here to help',
            style: AppText.heading.copyWith(fontSize: 20),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Questions, feedback, or need a hand? Reach out any time.',
            textAlign: TextAlign.center,
            style: AppText.bodySecondary,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.02);
  }

  Widget _contactTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SurfaceCard(
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: AppColors.accent, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppText.bodySecondary.copyWith(fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.03);
  }

  List<({String question, String answer})> get _faqs => [
        (
          question: 'How do credits work?',
          answer: 'Each video generation costs 1 credit. Free accounts get 3 credits. '
              'You can earn more through referrals or upgrade to a subscription.',
        ),
        (
          question: 'How long does generation take?',
          answer: 'Most videos are ready in 30–60 seconds. Complex prompts may take longer.',
        ),
        (
          question: 'Can I use my videos commercially?',
          answer: 'Yes, videos you create are yours to use however you like, including commercially.',
        ),
        (
          question: 'What if my video fails?',
          answer: 'Failed generations do not consume credits. Simply try again or adjust your prompt.',
        ),
      ];

  Widget _faqTile(({String question, String answer}) faq) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      iconColor: AppColors.accent,
      collapsedIconColor: AppColors.textMuted,
      title: Text(
        faq.question,
        style: AppText.body.copyWith(fontWeight: FontWeight.w600),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Text(faq.answer, style: AppText.bodySecondary.copyWith(fontSize: 13)),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }
}
