import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../profile/data/buddy.dart';
import '../../profile/data/child_profile.dart';
import '../../profile/view_model/profile_view_model.dart';
import 'onboarding_decor.dart';

/// S2 · Profile Setup. Final onboarding step — name, age band, and buddy
/// (shown here as a Boy/Girl avatar picker) — then routes to Home.
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
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
          name: _nameController.text.trim(),
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
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const OnboardingBackground(tint: AppColors.purple),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text.rich(
                    TextSpan(
                      children: <InlineSpan>[
                        TextSpan(text: l10n.profileSetupTitlePrefix),
                        const TextSpan(text: ' '),
                        TextSpan(
                          text: l10n.profileSetupTitleAccent,
                          style: const TextStyle(color: AppColors.crimson),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 30,
                      height: 1.15,
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      l10n.profileSetupSubtitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lexendDeca(
                        fontSize: 14.5,
                        color: AppColors.slate,
                        height: 1.45,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        _SectionLabel(l10n.profileSetupNameLabel),
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
                              color: AppColors.dark.withValues(alpha: 0.3),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: AppColors.crimson,
                                width: 1.5,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: AppColors.crimson.withValues(alpha: 0.4),
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: AppColors.crimson,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _SectionLabel(l10n.profileSetupAgeLabel),
                        const SizedBox(height: 10),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: _AgeChip(
                                label: l10n.ageBand24,
                                color: AppColors.indigo,
                                selected: _ageBand == AgeBand.junior,
                                onTap: () =>
                                    setState(() => _ageBand = AgeBand.junior),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _AgeChip(
                                label: l10n.ageBand56,
                                color: AppColors.pinkDeep,
                                selected: _ageBand == AgeBand.senior,
                                onTap: () =>
                                    setState(() => _ageBand = AgeBand.senior),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        _SectionLabel(l10n.profileSetupBuddyLabel),
                        const SizedBox(height: 12),
                        Row(
                          children: kBuddies.map((Buddy buddy) {
                            final bool isFirst = buddy == kBuddies.first;
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  left: isFirst ? 0 : 8,
                                  right: isFirst ? 8 : 0,
                                ),
                                child: _AvatarCard(
                                  buddy: buddy,
                                  label: buddy.id == 'girl'
                                      ? l10n.buddyGirl
                                      : l10n.buddyBoy,
                                  selected: _buddyId == buddy.id,
                                  onTap: () =>
                                      setState(() => _buddyId = buddy.id),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  ClayButton(
                    label: l10n.profileSetupContinue,
                    trailingIcon: Icons.arrow_forward_rounded,
                    onTap: _finish,
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

/// White rounded panel that lifts each form section off the pastel background.
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.14),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _AgeChip extends StatelessWidget {
  const _AgeChip({
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
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withValues(alpha: selected ? 0 : 0.5),
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: selected ? Colors.white : color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ),
    );
  }
}

class _AvatarCard extends StatelessWidget {
  const _AvatarCard({
    required this.buddy,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Buddy buddy;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: buddy.color.withValues(alpha: selected ? 0.08 : 0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  selected ? buddy.color : buddy.color.withValues(alpha: 0.3),
              width: selected ? 2.5 : 1.5,
            ),
          ),
          child: Column(
            children: <Widget>[
              Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      buddy.assetPath,
                      height: 112,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      alignment: const Alignment(0, -0.2),
                    ),
                  ),
                  if (selected)
                    Positioned(
                      top: -6,
                      right: -6,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: buddy.color,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: buddy.color,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
