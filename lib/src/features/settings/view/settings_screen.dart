import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/locale_controller.dart';
import '../../../l10n/app_localizations.dart';

/// S12 · Settings (Parent Area). Includes a language override.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.workspace_premium),
            title: Text(l10n.manageSubscription),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language / भाषा'),
            trailing: DropdownButton<Locale?>(
              value: ref.watch(localeControllerProvider),
              hint: const Text('Auto'),
              items: const <DropdownMenuItem<Locale?>>[
                DropdownMenuItem<Locale?>(value: null, child: Text('Auto')),
                DropdownMenuItem<Locale?>(value: Locale('en'), child: Text('English')),
                DropdownMenuItem<Locale?>(value: Locale('hi'), child: Text('हिन्दी')),
              ],
              onChanged: (Locale? value) =>
                  ref.read(localeControllerProvider.notifier).setLocale(value),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: Text(l10n.privacyPolicy),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: Text(l10n.deleteProfile),
            textColor: Colors.red,
          ),
        ],
      ),
    );
  }
}
