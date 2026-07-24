import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import 'onboarding_decor.dart';

/// Welcome screen — hero illustration in a pastel clay card over a warm
/// gradient, two-line Poppins title, and a full-width tactile CTA.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const OnboardingBackground(tint: AppColors.yellow),
          SafeArea(
            child: Column(
              children: <Widget>[
                const SizedBox(height: 32),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ClayCard(
                      color: AppColors.yellow,
                      child: RepaintBoundary(
                        child: Image.asset(
                          'assets/images/onboarding/welcome_hero.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  l10n.welcomeTitleLine1,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                    height: 1.2,
                  ),
                ),
                Text(
                  l10n.welcomeTitleLine2,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                    color: AppColors.crimson,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36),
                  child: Text(
                    l10n.welcomeSubtitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lexendDeca(
                      fontSize: 16,
                      color: AppColors.slate,
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ClayButton(
                      label: l10n.welcomeCta,
                      trailingIcon: Icons.arrow_forward_rounded,
                      onTap: () => context.go(Routes.onboarding),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
