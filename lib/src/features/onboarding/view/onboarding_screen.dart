import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../profile/data/buddy.dart';
import '../../profile/data/child_profile.dart';
import '../../profile/view_model/profile_view_model.dart';

/// S2 · First-run Setup. Collects the child's (optional) name, age band, and
/// buddy character, then persists them via [profileProvider] and enters Home.
/// Age band and buddy then drive personalization across the app.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final TextEditingController _nameController = TextEditingController();
  AgeBand _ageBand = AgeBand.junior;
  String _buddyId = kBuddies.first.id;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _finish() {
    ref.read(profileProvider.notifier).completeOnboarding(
          name: _nameController.text,
          ageBand: _ageBand,
          buddyId: _buddyId,
        );
    context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Center(
                      child: Text(
                        l10n.onboardingGreeting,
                        style: theme.textTheme.displaySmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        l10n.onboardingSubtitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.dark.withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 28),
                    TextField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        hintText: l10n.childNameHint,
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 20,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28),
                          borderSide:
                              const BorderSide(color: AppColors.teal, width: 2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28),
                          borderSide:
                              const BorderSide(color: AppColors.teal, width: 2.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(l10n.ageQuestion, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _AgeCard(
                            label: l10n.ageBand24,
                            color: AppColors.coral,
                            selected: _ageBand == AgeBand.junior,
                            onTap: () =>
                                setState(() => _ageBand = AgeBand.junior),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _AgeCard(
                            label: l10n.ageBand56,
                            color: AppColors.purple,
                            selected: _ageBand == AgeBand.senior,
                            onTap: () =>
                                setState(() => _ageBand = AgeBand.senior),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Text(l10n.pickBuddy, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      l10n.pickBuddyHint,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.dark.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: <Widget>[
                        for (final Buddy buddy in kBuddies)
                          _BuddyOption(
                            buddy: buddy,
                            selected: _buddyId == buddy.id,
                            onTap: () => setState(() => _buddyId = buddy.id),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  minimumSize: const Size.fromHeight(68),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(34),
                  ),
                ),
                onPressed: _finish,
                child: Text(
                  l10n.letsGo,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One of the two age-band choices. Selected fills with [color]; unselected is
/// a white card outlined in [color].
class _AgeCard extends StatelessWidget {
  const _AgeCard({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Material(
      color: selected ? color : Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          height: 132,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color, width: selected ? 0 : 2.5),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: selected ? Colors.white : color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

/// A single selectable buddy avatar. The chosen one gets a colored ring.
class _BuddyOption extends StatelessWidget {
  const _BuddyOption({
    required this.buddy,
    required this.selected,
    required this.onTap,
  });

  final Buddy buddy;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: buddy.color.withValues(alpha: selected ? 0.25 : 0.12),
            border: Border.all(
              color: selected ? buddy.color : Colors.transparent,
              width: 4,
            ),
          ),
          alignment: Alignment.center,
          child: Text(buddy.emoji, style: const TextStyle(fontSize: 44)),
        ),
      ),
    );
  }
}
