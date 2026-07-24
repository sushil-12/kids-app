import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import 'onboarding_decor.dart';

/// S1.75 · Onboarding carousel. Each slide has its own pastel theme color;
/// the background, progress pills, and CTA cross-fade as the child swipes.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next(int slideCount) {
    if (_index == slideCount - 1) {
      context.go(Routes.profileSetup);
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve:
            Curves.easeOutBack, // Playful, bouncy transition suitable for kids
      );
    }
  }

  /// Continuous scroll position, so the theme color lerps while dragging.
  double get _page {
    if (_controller.hasClients && _controller.position.haveDimensions) {
      return _controller.page ?? _index.toDouble();
    }
    return _index.toDouble();
  }

  Color _themeColor(List<_Slide> slides) {
    final double page = _page.clamp(0, (slides.length - 1).toDouble());
    final int from = page.floor();
    final int to = (from + 1).clamp(0, slides.length - 1);
    return Color.lerp(slides[from].color, slides[to].color, page - from)!;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    final List<_Slide> slides = <_Slide>[
      _Slide(
        image: 'assets/images/onboarding/onboarding_1_hero.png',
        title: l10n.onboarding1Title,
        subtitle: l10n.onboarding1Subtitle,
        color: AppColors.teal,
      ),
      _Slide(
        image: 'assets/images/onboarding/onboarding_2_hero.png',
        title: l10n.onboarding2Title,
        subtitle: l10n.onboarding2Subtitle,
        color: AppColors.purple,
      ),
      _Slide(
        image: 'assets/images/onboarding/onboarding_3_hero.png',
        title: l10n.onboarding3Title,
        subtitle: l10n.onboarding3Subtitle,
        color: AppColors.coral,
      ),
    ];

    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) {
          final Color theme = _themeColor(slides);

          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              OnboardingBackground(tint: theme),
              SafeArea(
                child: Column(
                  children: <Widget>[
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4, right: 12),
                        child: TextButton(
                          onPressed: () => context.go(Routes.profileSetup),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(64, 44),
                            foregroundColor: AppColors.slate,
                          ),
                          child: Text(
                            l10n.onboardingSkip,
                            style: GoogleFonts.lexendDeca(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: PageView.builder(
                        controller: _controller,
                        itemCount: slides.length,
                        onPageChanged: (int i) => setState(() => _index = i),
                        itemBuilder: (BuildContext context, int i) =>
                            _SlideView(slide: slides[i]),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List<Widget>.generate(slides.length, (int i) {
                        final bool active = i == _index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutBack,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: active ? 28 : 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: active
                                ? theme
                                : AppColors.dark.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: 32,
                        left: 24,
                        right: 24,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: ClayButton(
                          label: _index == slides.length - 1
                              ? l10n.onboardingStart
                              : l10n.onboardingNext,
                          trailingIcon: _index == slides.length - 1
                              ? Icons.celebration_rounded
                              : Icons.arrow_forward_rounded,
                          color: theme,
                          onTap: () => _next(slides.length),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Slide {
  const _Slide({
    required this.image,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final String image;
  final String title;
  final String subtitle;
  final Color color;
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});

  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Column(
        children: <Widget>[
          Expanded(
            child: ClayCard(
              color: slide.color,
              child: RepaintBoundary(
                child: Center(
                  child: Image.asset(
                    slide.image,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            slide.subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.lexendDeca(
              fontSize: 16,
              color: AppColors.slate,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
