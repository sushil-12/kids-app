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
    final double screenWidth = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // ── Header ──────────────────────────────────────────────
                    _Header(theme: theme, l10n: l10n),
                    const SizedBox(height: 32),

                    // ── Name field ──────────────────────────────────────────
                    _SectionLabel(
                      emoji: '✏️',
                      text: l10n.childNameHint,
                      theme: theme,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppColors.dark,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText: l10n.childNameHint,
                        hintStyle: theme.textTheme.bodyLarge?.copyWith(
                          color: AppColors.dark.withValues(alpha: 0.4),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 18,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28),
                          borderSide: const BorderSide(
                            color: AppColors.teal,
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28),
                          borderSide: const BorderSide(
                            color: AppColors.teal,
                            width: 2.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Age band ────────────────────────────────────────────
                    _SectionLabel(
                      emoji: '🎂',
                      text: l10n.ageQuestion,
                      theme: theme,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _AgeCard(
                            label: l10n.ageBand24,
                            emoji: '🐣',
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
                            emoji: '🚀',
                            color: AppColors.purple,
                            selected: _ageBand == AgeBand.senior,
                            onTap: () =>
                                setState(() => _ageBand = AgeBand.senior),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // ── Buddy picker ────────────────────────────────────────
                    _SectionLabel(
                      emoji: '🐾',
                      text: l10n.pickBuddy,
                      theme: theme,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.pickBuddyHint,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.dark.withValues(alpha: 0.55),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _BuddyGrid(
                      buddies: kBuddies,
                      selectedId: _buddyId,
                      availableWidth: screenWidth - 48,
                      onSelect: (String id) => setState(() => _buddyId = id),
                    ),
                  ],
                ),
              ),
            ),

            // ── CTA button ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  minimumSize: const Size.fromHeight(64),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                  elevation: 4,
                  shadowColor: AppColors.teal.withValues(alpha: 0.4),
                ),
                onPressed: _finish,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      l10n.letsGo,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('🚀', style: TextStyle(fontSize: 22)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.theme, required this.l10n});

  final ThemeData theme;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        // Coloured decoration strip behind the title.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: <Color>[Color(0xFFFFEBE8), Color(0xFFE8F7F6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppColors.teal.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Column(
            children: <Widget>[
              const Text('👋', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 8),
              Text(
                l10n.onboardingGreeting,
                style: theme.textTheme.displaySmall?.copyWith(
                  color: AppColors.dark,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                l10n.onboardingSubtitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.dark.withValues(alpha: 0.65),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.emoji,
    required this.text,
    required this.theme,
  });

  final String emoji;
  final String text;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Text(
          text,
          style: theme.textTheme.titleLarge?.copyWith(
            color: AppColors.dark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// Age-band selection card. Selected state fills with [color]; unselected is
/// a white card outlined in [color].
class _AgeCard extends StatelessWidget {
  const _AgeCard({
    required this.label,
    required this.emoji,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String emoji;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: selected ? color : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color, width: selected ? 0 : 2.5),
        boxShadow: selected
            ? <BoxShadow>[
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : const <BoxShadow>[],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: SizedBox(
            height: 120,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: selected ? Colors.white : color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Buddy grid — centered and evenly spaced. Each buddy gets a coloured circle
/// with a selection ring when chosen.
class _BuddyGrid extends StatelessWidget {
  const _BuddyGrid({
    required this.buddies,
    required this.selectedId,
    required this.availableWidth,
    required this.onSelect,
  });

  final List<Buddy> buddies;
  final String selectedId;
  final double availableWidth;
  final ValueChanged<String> onSelect;

  static const int _columns = 3;
  static const double _spacing = 16;

  @override
  Widget build(BuildContext context) {
    final double itemSize =
        (availableWidth - (_columns - 1) * _spacing) / _columns;

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: _spacing,
      runSpacing: _spacing,
      children: <Widget>[
        for (final Buddy buddy in buddies)
          _BuddyOption(
            buddy: buddy,
            size: itemSize,
            selected: selectedId == buddy.id,
            onTap: () => onSelect(buddy.id),
          ),
      ],
    );
  }
}

class _BuddyOption extends StatelessWidget {
  const _BuddyOption({
    required this.buddy,
    required this.size,
    required this.selected,
    required this.onTap,
  });

  final Buddy buddy;
  final double size;
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
          duration: const Duration(milliseconds: 200),
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: buddy.color.withValues(alpha: selected ? 0.22 : 0.10),
            border: Border.all(
              color: selected ? buddy.color : Colors.transparent,
              width: 4,
            ),
            boxShadow: selected
                ? <BoxShadow>[
                    BoxShadow(
                      color: buddy.color.withValues(alpha: 0.35),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : const <BoxShadow>[],
          ),
          alignment: Alignment.center,
          child: Text(
            buddy.emoji,
            style: TextStyle(fontSize: size * 0.48),
          ),
        ),
      ),
    );
  }
}
