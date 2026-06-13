import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// S11 · Paywall.
class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.paywallTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: <Widget>[
            Text(l10n.paywallSubtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(64)),
              onPressed: () {},
              child: Text(l10n.startFreeTrial),
            ),
          ],
        ),
      ),
    );
  }
}
