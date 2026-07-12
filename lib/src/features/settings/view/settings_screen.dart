import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/router/locale_controller.dart';
import '../../../core/services/sound_settings_store.dart';
import '../../../l10n/app_localizations.dart';
import '../../admin/view/parent_gate.dart';
import '../../profile/data/child_profile.dart';
import '../../profile/view_model/profile_view_model.dart';

/// S12 · Settings (Parent Area). Language override, age band, and profile
/// deletion. Reached only through the parent gate (House Rule §7).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ChildProfile? profile = ref.watch(profileProvider);
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
          // Voice + sound-effects master switch (House Rule §5: sound is core
          // to how young children learn). Flips the whole AudioService silent.
          SwitchListTile(
            secondary: const Icon(Icons.volume_up),
            title: Text(l10n.soundsAndMusic),
            value: ref.watch(
              soundSettingsProvider.select((SoundSettings s) => s.soundEnabled),
            ),
            onChanged: (bool value) =>
                ref.read(soundSettingsProvider.notifier).setSoundEnabled(value),
          ),
          // Developer tool to audition every SFX + voice line on-device.
          ListTile(
            leading: const Icon(Icons.graphic_eq),
            title: const Text('Sound Lab'),
            onTap: () => context.push(Routes.soundLab),
          ),
          // Age band only appears once a profile exists (i.e. post-onboarding).
          if (profile != null)
            ListTile(
              leading: const Icon(Icons.cake_outlined),
              title: Text(l10n.ageBandSetting),
              trailing: DropdownButton<AgeBand>(
                value: profile.ageBand,
                items: <DropdownMenuItem<AgeBand>>[
                  DropdownMenuItem<AgeBand>(
                    value: AgeBand.junior,
                    child: Text(l10n.ageBand24),
                  ),
                  DropdownMenuItem<AgeBand>(
                    value: AgeBand.senior,
                    child: Text(l10n.ageBand56),
                  ),
                ],
                onChanged: (AgeBand? value) {
                  if (value != null) {
                    ref.read(profileProvider.notifier).setAgeBand(value);
                  }
                },
              ),
            ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: Text(l10n.privacyPolicy),
          ),
          // Grown-up-only content tools — guarded by the parent gate (§7).
          ListTile(
            leading: const Icon(Icons.admin_panel_settings_outlined),
            title: Text(l10n.adminTitle),
            onTap: () async {
              final bool ok = await showParentGate(context);
              if (ok && context.mounted) context.push(Routes.admin);
            },
          ),
          if (profile != null)
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(l10n.deleteProfile),
              textColor: Colors.red,
              iconColor: Colors.red,
              onTap: () => _confirmDelete(context, ref),
            ),
        ],
      ),
    );
  }

  /// Confirms before wiping the profile, then deletes it and returns to the
  /// first-run setup so a new profile can be created.
  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(l10n.deleteProfile),
        content: Text(l10n.deleteProfileMessage),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.deleteConfirm),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    ref.read(profileProvider.notifier).deleteProfile();
    context.go(Routes.onboarding);
  }
}
