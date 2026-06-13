import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../l10n/app_localizations.dart';

/// S2 · First-run Setup. Name + age band + buddy.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(l10n.onboardingGreeting,
                  style: Theme.of(context).textTheme.displaySmall),
              Text(l10n.onboardingSubtitle,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 24),
              TextField(
                decoration: InputDecoration(
                  hintText: l10n.childNameHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              const Spacer(),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(68)),
                onPressed: () => context.go(Routes.home),
                child: Text(l10n.letsGo),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
