import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../engine/mascot_painter.dart';

/// S1.5 · Welcome flow. Three pillar slides (Coloring, Games, Rewards) shown
/// once before the name/age/buddy setup screen, introducing the app with the
/// original flat-vector mascot instead of a wall of text.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToSetup() => context.go(Routes.onboarding);

  void _next(int slideCount) {
    if (_index == slideCount - 1) {
      _goToSetup();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<_Slide> slides = <_Slide>[
      _Slide(
        pose: WelcomePose.coloring,
        accent: AppColors.coral,
        badge: l10n.welcomeBadgeColoring,
        title: l10n.welcomeColoringTitle,
        subtitle: l10n.welcomeColoringSubtitle,
      ),
      _Slide(
        pose: WelcomePose.games,
        accent: AppColors.purple,
        badge: l10n.welcomeBadgeGames,
        title: l10n.welcomeGamesTitle,
        subtitle: l10n.welcomeGamesSubtitle,
      ),
      _Slide(
        pose: WelcomePose.rewards,
        accent: AppColors.teal,
        badge: l10n.welcomeBadgeRewards,
        title: l10n.welcomeRewardsTitle,
        subtitle: l10n.welcomeRewardsSubtitle,
      ),
    ];
    final bool isLast = _index == slides.length - 1;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _TopBar(
              onSkip: _goToSetup,
              skipLabel: l10n.welcomeSkip,
              wordmark: l10n.appName.toLowerCase(),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: slides.length,
                onPageChanged: (int i) => setState(() => _index = i),
                itemBuilder: (BuildContext context, int i) => _SlideView(slide: slides[i]),
              ),
            ),
            _BottomBar(
              count: slides.length,
              index: _index,
              accent: slides[_index].accent,
              ctaLabel: isLast ? l10n.letsGo : l10n.welcomeNext,
              onTap: () => _next(slides.length),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide {
  const _Slide({
    required this.pose,
    required this.accent,
    required this.badge,
    required this.title,
    required this.subtitle,
  });

  final WelcomePose pose;
  final Color accent;
  final String badge;
  final String title;
  final String subtitle;
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onSkip, required this.skipLabel, required this.wordmark});

  final VoidCallback onSkip;
  final String skipLabel;
  final String wordmark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                wordmark,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.dark,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          TextButton(
            onPressed: onSkip,
            style: TextButton.styleFrom(foregroundColor: AppColors.dark.withValues(alpha: 0.4)),
            child: Text(skipLabel),
          ),
        ],
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});

  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            flex: 5,
            child: RepaintBoundary(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: slide.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    Positioned(
                      top: 18,
                      left: 20,
                      child: _floatDot(slide.accent.withValues(alpha: 0.22), 46),
                    ),
                    Positioned(
                      bottom: 22,
                      right: 26,
                      child: _floatDot(AppColors.yellow.withValues(alpha: 0.22), 30),
                    ),
                    FractionallySizedBox(
                      widthFactor: 0.62,
                      heightFactor: 0.72,
                      child: CustomPaint(painter: MascotPainter(pose: slide.pose)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: slide.accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              slide.badge.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: slide.accent,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            slide.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: AppColors.dark,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            slide.subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.dark.withValues(alpha: 0.55),
              height: 1.4,
            ),
          ),
          const Expanded(flex: 2, child: SizedBox.shrink()),
        ],
      ),
    );
  }

  Widget _floatDot(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.count,
    required this.index,
    required this.accent,
    required this.ctaLabel,
    required this.onTap,
  });

  final int count;
  final int index;
  final Color accent;
  final String ctaLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List<Widget>.generate(count, (int i) {
              final bool active = i == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 20 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: active ? accent : AppColors.dark.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              color: accent,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: accent.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(28),
                splashColor: Colors.white.withValues(alpha: 0.2),
                highlightColor: Colors.white.withValues(alpha: 0.1),
                child: SizedBox(
                  height: 60,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        ctaLabel,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
