import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../config/theme.dart';
import '../utils/haptics.dart';
import '../widgets/cards.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _header(context),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _heroCard(),
                    const SizedBox(height: AppSpacing.lg),
                    _sectionTitle('Our Mission'),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'We believe everyone has a story worth telling. Our AI video generator '
                      'empowers creators, marketers, and dreamers to turn simple text prompts '
                      'into stunning cinematic videos — no editing skills required.',
                      style: AppText.bodySecondary,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _sectionTitle('What We Do'),
                    const SizedBox(height: AppSpacing.sm),
                    ..._features.map((f) => _featureTile(f)),
                    const SizedBox(height: AppSpacing.lg),
                    _sectionTitle('The Team'),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'A small, passionate team of engineers, designers, and AI researchers '
                      'building the future of creative tools. We are committed to making '
                      'professional-quality video creation accessible to everyone.',
                      style: AppText.bodySecondary,
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
          Text('About Us', style: AppText.heading.copyWith(fontSize: 22)),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.02);
  }

  Widget _heroCard() {
    return SurfaceCard(
      glow: true,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              gradient: AppColors.accentGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_arrow_rounded,
                color: Colors.white, size: 36),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'AI Video Generator',
            style: AppText.heading.copyWith(fontSize: 22),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Version 1.0.0',
            style: AppText.bodySecondary.copyWith(fontSize: 13),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.02);
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: AppText.heading.copyWith(fontSize: 18),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.02);
  }

  List<({IconData icon, String title, String description})> get _features => [
        (
          icon: Icons.auto_awesome,
          title: 'AI-Powered Generation',
          description: 'Transform text prompts into cinematic videos in seconds.',
        ),
        (
          icon: Icons.palette_outlined,
          title: 'Multiple Styles',
          description: 'Cinematic, anime, 3D, realistic, and more visual styles.',
        ),
        (
          icon: Icons.bolt_rounded,
          title: 'Fast & Simple',
          description: 'No editing skills needed — just describe and generate.',
        ),
        (
          icon: Icons.share_outlined,
          title: 'Share Anywhere',
          description: 'Export and share your creations to any platform.',
        ),
      ];

  Widget _featureTile(
      ({IconData icon, String title, String description}) feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(feature.icon, color: AppColors.accent, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  feature.description,
                  style: AppText.bodySecondary.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.03);
  }
}
