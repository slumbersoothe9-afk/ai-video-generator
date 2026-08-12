import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../models/city_model.dart';
import '../models/video_model.dart';
import '../services/api_exception.dart';
import '../services/auth_service.dart';
import '../services/credits_service.dart';
import '../services/video_service.dart';
import '../utils/haptics.dart';
import '../utils/prompt_engine.dart';
import '../utils/prediction_engine.dart';
import '../widgets/buttons.dart';
import '../widgets/cards.dart';
import '../widgets/feedback.dart';
import 'about_us_screen.dart';
import 'contact_us_screen.dart';
import 'privacy_policy_screen.dart';
import 'referral_screen.dart';
import 'result_screen.dart';
import 'subscription_screen.dart';
import 'ugc_templates_screen.dart';
import 'viral_hooks_screen.dart';

/// Available generation styles shown in the selector.
const List<String> kVideoStyles = [
  'Cinematic',
  '3D Animation',
  'Anime',
  'Realistic',
  'Cyberpunk',
  'Watercolor',
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final _promptController = TextEditingController();
  final _titleController = TextEditingController();
  String _selectedStyle = kVideoStyles.first;
  bool _generating = false;
  VideoModel? _current;
  String? _error;
  List<PromptSuggestion> _suggestions = [];
  List<IntentPrediction> _predictions = [];
  late final AnimationController _glowController;
  final PredictionEngine _predictionEngine = PredictionEngine.instance;

  @override
  void initState() {
    super.initState();
    _refreshSuggestions();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CreditsService>().fetchAccount();
      _predictionEngine.load().then((_) {
        if (mounted) {
          setState(() {
            _predictions = _predictionEngine.predict();
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _promptController.dispose();
    _titleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _refreshSuggestions() {
    setState(() {
      _suggestions = PromptEngine.suggestions(style: _selectedStyle);
    });
  }

  void _applySuggestion(PromptSuggestion suggestion) {
    Haptics.select();
    _promptController.text = suggestion.text;
    _promptController.selection = TextSelection.fromPosition(
      TextPosition(offset: suggestion.text.length),
    );
    setState(() {});
  }

  void _applyPrediction(IntentPrediction prediction) {
    Haptics.heavy();
    _promptController.text = prediction.prompt;
    _promptController.selection = TextSelection.fromPosition(
      TextPosition(offset: prediction.prompt.length),
    );
    setState(() {
      _selectedStyle = prediction.style;
    });
  }

  void _surpriseMe() {
    Haptics.heavy();
    final s = PromptEngine.surprise(style: _selectedStyle);
    _promptController.text = s.text;
    setState(() {});
  }

  Future<void> _generate() async {
    final prompt = _promptController.text.trim();
    final title = _titleController.text.trim().isEmpty
        ? _defaultTitle(prompt)
        : _titleController.text.trim();
    if (prompt.isEmpty) {
      Haptics.warning();
      setState(() => _error = 'Please enter a prompt to describe your video.');
      return;
    }
    final credits = context.read<CreditsService>();
    if (credits.balance < 1) {
      Haptics.warning();
      _showInsufficientCredits();
      return;
    }
    Haptics.heavy();
    setState(() {
      _generating = true;
      _error = null;
      _current = null;
    });
    try {
      final videoService = context.read<VideoService>();
      final initial = await videoService.generate(
        title: title,
        prompt: prompt,
        style: _selectedStyle,
      );
      setState(() => _current = initial);
      await videoService.pollUntilDone(
        initial.id,
        onUpdate: (v) {
          if (mounted) setState(() => _current = v);
        },
      );
      if (_current?.status == VideoStatus.completed && mounted) {
        Haptics.success();
        credits.fetchAccount();
        await _predictionEngine.record(prompt: prompt, style: _selectedStyle);
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ResultScreen(videoId: _current!.id),
          ),
        );
      } else if (_current?.status == VideoStatus.failed && mounted) {
        Haptics.error();
        setState(() => _error =
            _current?.errorMessage ?? 'Generation failed. Please try again.');
      }
    } on ApiException catch (e) {
      Haptics.error();
      setState(() => _error = e.message);
    } catch (_) {
      Haptics.error();
      setState(() => _error = 'Generation failed. Please try again.');
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  void _showInsufficientCredits() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                gradient: AppColors.accentGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bolt, color: Colors.white, size: 28),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Out of credits',
              style: AppText.heading.copyWith(fontSize: 20),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'You\'ve used all your free credits. Upgrade to keep creating stunning videos.',
              textAlign: TextAlign.center,
              style: AppText.bodySecondary,
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: 'View plans',
              icon: Icons.rocket_launch,
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
                );
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            TextLink(
              label: 'Earn free credits with referrals',
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ReferralScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _defaultTitle(String prompt) {
    if (prompt.length <= 40) return prompt;
    return '${prompt.substring(0, 40)}…';
  }

  Future<void> _logout() async {
    Haptics.tap();
    await context.read<AuthService>().logout();
  }

  void _showMenu() {
    Haptics.tap();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('More', style: AppText.heading.copyWith(fontSize: 20)),
            const SizedBox(height: AppSpacing.lg),
            _menuTile(Icons.info_outline, 'About Us', () => _push(const AboutUsScreen())),
            _menuTile(Icons.privacy_tip_outlined, 'Privacy Policy', () => _push(const PrivacyPolicyScreen())),
            _menuTile(Icons.mail_outline, 'Contact Us', () => _push(const ContactUsScreen())),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  Widget _menuTile(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.accent),
      title: Text(label, style: AppText.body),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
      onTap: () {
        Navigator.of(context).pop();
        onTap();
      },
    );
  }

  void _push(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  void _goToReferrals() {
    Haptics.tap();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ReferralScreen()),
    );
  }

  void _goToSubscription() {
    Haptics.tap();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
    );
  }

  void _goToViralHooks() {
    Haptics.tap();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ViralHooksScreen()),
    );
  }

  void _goToUgcTemplates() async {
    Haptics.tap();
    final result = await Navigator.of(context).push<UgcTemplate>(
      MaterialPageRoute(builder: (_) => const UgcTemplatesScreen()),
    );
    if (result != null && mounted) {
      final prompt = '${result.name}: ${result.description}';
      _promptController.text = prompt;
      _promptController.selection = TextSelection.fromPosition(
        TextPosition(offset: prompt.length),
      );
      if (kVideoStyles.contains(result.subtitleStyle)) {
        setState(() => _selectedStyle = result.subtitleStyle);
      }
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthService, String?>((a) => a.currentUser?.name);
    final balance = context.select<CreditsService, int>((c) => c.balance);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _header(user, balance)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _cityMap(),
                    const SizedBox(height: AppSpacing.lg),
                    _composer(),
                    const SizedBox(height: AppSpacing.lg),
                    if (_predictions.isNotEmpty) ...[
                      _mindReadingSection(),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    _smartSuggestions(),
                    const SizedBox(height: AppSpacing.lg),
                    if (_error != null) _errorBanner(),
                    if (_generating || _current != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _progressCard(),
                    ],
                    const SizedBox(height: AppSpacing.xxl),
                    _referralCta(),
                    const SizedBox(height: AppSpacing.lg),
                    _tips(),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(String? name, int balance) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm,
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, _) {
              final t = _glowController.value;
              return Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.3 + 0.2 * t),
                      blurRadius: 12 + 8 * t,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 26),
              );
            },
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${name?.split(' ').first ?? 'creator'}',
                  style: AppText.heading.copyWith(fontSize: 18),
                ),
                Text(
                  'Welcome to Smart Creator City',
                  style: AppText.bodySecondary.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
          CreditPill(balance: balance, onTap: _goToSubscription),
          const SizedBox(width: AppSpacing.sm),
          GlassIconButton(
            icon: Icons.menu_rounded,
            onPressed: _showMenu,
          ),
          const SizedBox(width: AppSpacing.sm),
          GlassIconButton(
            icon: Icons.logout_rounded,
            onPressed: _logout,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.02);
  }

  /// The Smart Creator City interactive map — a grid of districts.
  Widget _cityMap() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.location_city, color: AppColors.accent, size: 18),
            const SizedBox(width: 6),
            Text(
              'SMART CREATOR CITY',
              style: AppText.label.copyWith(
                color: AppColors.accent,
                fontSize: 12,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Choose your district',
          style: AppText.heading.copyWith(fontSize: 18),
        ),
        const SizedBox(height: AppSpacing.md),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.1,
          ),
          itemCount: kCityDistricts.length,
          itemBuilder: (context, index) {
            final district = kCityDistricts[index];
            return _districtCard(district)
                .animate()
                .fadeIn(delay: (index * 80).ms)
                .scale(
                  begin: const Offset(0.95, 0.95),
                  duration: 400.ms,
                );
          },
        ),
      ],
    ).animate().fadeIn(duration: 500.ms, delay: 100.ms).slideY(begin: 0.02);
  }

  Widget _districtCard(CityDistrict district) {
    final gradientColors = district.gradient
        .map((c) => Color(c))
        .toList();
    return GestureDetector(
      onTap: () => _enterDistrict(district),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              gradientColors[0].withValues(alpha: 0.15),
              gradientColors[1].withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: gradientColors[0].withValues(alpha: 0.3),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradientColors),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors[0].withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Icon(
                  _iconForName(district.icon),
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const Spacer(),
              Text(
                district.name,
                style: AppText.heading.copyWith(fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                district.description,
                style: AppText.bodySecondary.copyWith(fontSize: 11),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _enterDistrict(CityDistrict district) {
    Haptics.heavy();
    switch (district.id) {
      case 'viral_studio':
        _goToViralHooks();
        break;
      case 'ecommerce_hub':
        _goToUgcTemplates();
        break;
      case 'creator_lab':
        _scrollToComposer();
        break;
      case 'growth_garden':
        _goToReferrals();
        break;
      case 'trend_tower':
        _goToUgcTemplates();
        break;
      case 'polyglot_plaza':
        _goToViralHooks();
        break;
    }
  }

  void _scrollToComposer() {
    // Just trigger a state update — the composer is already visible.
    setState(() {});
  }

  /// The mind-reading prediction section.
  Widget _mindReadingSection() {
    return SurfaceCard(
      glow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Mind-Reading Predictions',
                style: AppText.heading.copyWith(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Based on your history, we think you\'ll want these:',
            style: AppText.bodySecondary.copyWith(fontSize: 12),
          ),
          const SizedBox(height: AppSpacing.md),
          ..._predictions.take(3).toList().asMap().entries.map((entry) {
            final index = entry.key;
            final prediction = entry.value;
            return _predictionItem(prediction, index);
          }),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.02);
  }

  Widget _predictionItem(IntentPrediction prediction, int index) {
    final confidencePercent = (prediction.confidence * 100).round();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GestureDetector(
        onTap: () => _applyPrediction(prediction),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prediction.prompt,
                      style: AppText.body.copyWith(fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$confidencePercent% match',
                            style: AppText.label.copyWith(
                              fontSize: 10,
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            prediction.reason,
                            style: AppText.label.copyWith(
                              fontSize: 10,
                              color: AppColors.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: AppColors.accent,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: (index * 100).ms)
        .slideX(begin: 0.05);
  }

  Widget _composer() {
    return SurfaceCard(
      glow: true,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Creator Lab',
            subtitle: 'Describe your scene and pick a visual style.',
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title (optional)',
              prefixIcon: Icon(Icons.title_outlined, size: 20),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _promptController,
            minLines: 4,
            maxLines: 8,
            decoration: InputDecoration(
              labelText: 'Prompt',
              alignLabelWithHint: true,
              hintText: 'A lone astronaut walking across a neon-lit alien desert at dusk…',
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 120),
                child: Icon(Icons.edit_outlined, size: 20),
              ),
              suffixIcon: _promptController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        Haptics.tap();
                        _promptController.clear();
                        setState(() {});
                      },
                    )
                  : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Text(
                'Style',
                style: AppText.label,
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _surpriseMe,
                icon: const Icon(Icons.shuffle, size: 16),
                label: const Text('Surprise me'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  textStyle: AppText.label.copyWith(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _styleSelector(),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: _generating ? 'Generating…' : 'Generate Video',
            icon: Icons.auto_awesome,
            isLoading: _generating,
            onPressed: _generating ? null : _generate,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.03);
  }

  Widget _styleSelector() {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: kVideoStyles.map((style) {
        final selected = style == _selectedStyle;
        return StyleChip(
          label: style,
          selected: selected,
          onSelected: () {
            setState(() => _selectedStyle = style);
            _refreshSuggestions();
          },
        );
      }).toList(),
    );
  }

  Widget _smartSuggestions() {
    if (_suggestions.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome, color: AppColors.accent, size: 16),
            const SizedBox(width: 6),
            Text(
              'Smart suggestions',
              style: AppText.label.copyWith(
                color: AppColors.accent,
                fontSize: 13,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _suggestions.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final s = _suggestions[index];
              return PromptChip(
                label: s.label,
                icon: _iconForName(s.icon),
                onTap: () => _applySuggestion(s),
              ).animate().fadeIn(delay: (index * 60).ms).slideX(begin: 0.05);
            },
          ),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(begin: 0.02);
  }

  IconData _iconForName(String name) {
    const map = {
      'wb_sunny': Icons.wb_sunny,
      'local_cafe': Icons.local_cafe,
      'eco': Icons.eco,
      'location_city': Icons.location_city,
      'waves': Icons.waves,
      'restaurant': Icons.restaurant,
      'nights_stay': Icons.nights_stay,
      'local_fire_department': Icons.local_fire_department,
      'directions_car': Icons.directions_car,
      'auto_awesome': Icons.auto_awesome,
      'forest': Icons.forest,
      'ac_unit': Icons.ac_unit,
      'movie': Icons.movie,
      'rocket_launch': Icons.rocket_launch,
      'smart_toy': Icons.smart_toy,
      'terrain': Icons.terrain,
      'person': Icons.person,
      'auto_fix_high': Icons.auto_fix_high,
      'flutter_dash': Icons.flutter_dash,
      'coffee': Icons.coffee,
      'code': Icons.code,
      'apartment': Icons.apartment,
      'water': Icons.water,
      'pets': Icons.pets,
      'local_florist': Icons.local_florist,
      'public': Icons.public,
      'waterfall_chart': Icons.waterfall_chart,
      'shopping_bag': Icons.shopping_bag,
      'trending_up': Icons.trending_up,
      'language': Icons.language,
      'card_giftcard': Icons.card_giftcard,
      'inventory_2': Icons.inventory_2_outlined,
      'compare': Icons.compare,
      'format_quote': Icons.format_quote,
      'play_circle': Icons.play_circle_outline,
      'auto_stories': Icons.auto_stories,
    };
    return map[name] ?? Icons.auto_awesome;
  }

  Widget _errorBanner() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              _error!,
              style: AppText.bodySecondary,
            ),
          ),
        ],
      ),
    ).animate().shake(duration: 400.ms).fadeIn(duration: 200.ms);
  }

  Widget _progressCard() {
    final video = _current;
    if (video == null) {
      return SurfaceCard(
        child: Row(
          children: [
            const PremiumLoader(size: 40),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'Submitting your request…',
                style: AppText.bodySecondary,
              ),
            ),
          ],
        ),
      );
    }
    return SurfaceCard(
      glow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  video.title,
                  style: AppText.heading.copyWith(fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _statusPill(video.status),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: LinearProgressIndicator(
              value: video.progress / 100,
              minHeight: 10,
              backgroundColor: AppColors.surfaceElevated,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                video.status.label,
                style: AppText.label.copyWith(fontSize: 12),
              ),
              Text(
                '${video.progress}%',
                style: AppText.label.copyWith(
                  fontSize: 12,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          if (video.thumbnailUrl != null) ...[
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: CachedNetworkImage(
                imageUrl: video.thumbnailUrl!,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    const ShimmerBox(height: 160),
                errorWidget: (_, __, ___) => Container(
                  height: 160,
                  color: AppColors.surfaceElevated,
                  child: const Icon(Icons.broken_image,
                      color: AppColors.textMuted),
                ),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 350.ms);
  }

  Widget _referralCta() {
    return GradientBannerCard(
      icon: Icons.card_giftcard,
      title: 'Refer friends, earn credits',
      subtitle: 'Give 5, get 5 for every friend who joins.',
      onTap: _goToReferrals,
    );
  }

  Widget _statusPill(VideoStatus status) {
    switch (status) {
      case VideoStatus.queued:
        return StatusPill(
          label: status.label,
          color: AppColors.warning,
          icon: Icons.queue,
        );
      case VideoStatus.processing:
        return StatusPill(
          label: status.label,
          color: AppColors.accent,
          icon: Icons.autorenew,
        );
      case VideoStatus.completed:
        return StatusPill(
          label: status.label,
          color: AppColors.success,
          icon: Icons.check_circle,
        );
      case VideoStatus.failed:
        return StatusPill(
          label: status.label,
          color: AppColors.error,
          icon: Icons.error_outline,
        );
      case VideoStatus.unknown:
        return StatusPill(label: status.label, color: AppColors.textMuted);
    }
  }

  Widget _tips() {
    final tips = [
      ('Be specific', 'Describe lighting, camera, mood, and motion.'),
      ('Keep it short', 'One focused scene works best for AI video.'),
      ('Pick a style', 'Styles strongly affect the final look.'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tips for great results',
          style: AppText.heading.copyWith(fontSize: 16),
        ),
        const SizedBox(height: AppSpacing.md),
        ...tips.map((t) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.bolt_rounded,
                      color: AppColors.accent, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: AppText.bodySecondary,
                        children: [
                          TextSpan(
                            text: '${t.$1} — ',
                            style: AppText.body.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(text: t.$2),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    ).animate().fadeIn(duration: 500.ms, delay: 300.ms);
  }
}
