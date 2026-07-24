import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/clay_decor.dart';
import '../../../l10n/app_localizations.dart';

/// S11 · Paywall, in the pastel-clay design language (crimson accent).
/// RevenueCat purchase/restore wiring is still pending (CLAUDE.md §6).
class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const ClayBackground(tint: AppColors.crimson),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  ClayHeader(
                    title: l10n.paywallTitle,
                    tint: AppColors.crimson,
                    onBack: () => context.pop(),
                  ),
                  const SizedBox(height: 24),
                  ClayCard(
                    color: AppColors.crimson,
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      l10n.paywallSubtitle,
                      textAlign: TextAlign.center,
                      style: clayBody(fontSize: 16, color: AppColors.ink),
                    ),
                  ),
                  const Spacer(),
                  ClayButton(
                    label: l10n.startFreeTrial,
                    color: AppColors.crimson,
                    trailingIcon: Icons.arrow_forward_rounded,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
