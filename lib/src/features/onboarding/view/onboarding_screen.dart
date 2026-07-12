import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../profile/data/buddy.dart';
import '../../profile/data/child_profile.dart';
import '../../profile/view_model/profile_view_model.dart';

/// S2 · First-run Setup.
///
/// Compact single-screen form — name, age band, buddy — sized to fit without
/// scrolling on common phone heights. Material rounded icons render reliably
/// on every platform.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();

  AgeBand _ageBand = AgeBand.junior;
  String _buddyId = kBuddies.first.id;

  late final AnimationController _ambient;

  @override
  void initState() {
    super.initState();
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _ambient.dispose();
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  void _finish() {
    _nameFocusNode.unfocus();
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
        children: <Widget>[
          const _GradientCanvas(),
          _FloatingShapes(animation: _ambient),
          SafeArea(
            child: Column(
              children: <Widget>[
                _Header(theme: theme, l10n: l10n),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: Column(
                      children: <Widget>[
                        Expanded(
                          flex: 2, // Reduced flex for the simple input
                          child: _StepSection(
                            icon: Icons.badge_rounded,
                            iconColor: AppColors.teal,
                            title: l10n.childNameHint,
                            child: _NameInput(
                              controller: _nameController,
                              focusNode: _nameFocusNode,
                              l10n: l10n,
                              theme: theme,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          flex: 3, // Balanced flex for age cards
                          child: _StepSection(
                            icon: Icons.cake_rounded,
                            iconColor: AppColors.coral,
                            title: l10n.ageQuestion,
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: _AgeCard(
                                    label: l10n.ageBand24,
                                    ageLabel: '2–4',
                                    icon: Icons.child_care_rounded,
                                    color: AppColors.coral,
                                    selected: _ageBand == AgeBand.junior,
                                    onTap: () {
                                      _nameFocusNode.unfocus();
                                      setState(
                                        () => _ageBand = AgeBand.junior,
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _AgeCard(
                                    label: l10n.ageBand56,
                                    ageLabel: '5–6',
                                    icon: Icons.auto_awesome_rounded,
                                    color: AppColors.purple,
                                    selected: _ageBand == AgeBand.senior,
                                    onTap: () {
                                      _nameFocusNode.unfocus();
                                      setState(
                                        () => _ageBand = AgeBand.senior,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          flex: 4, // Larger flex for big avatars
                          child: _StepSection(
                            icon: Icons.favorite_rounded,
                            iconColor: AppColors.pink,
                            title: l10n.pickBuddy,
                            subtitle: l10n.pickBuddyHint,
                            child: Row(
                              children: kBuddies.map((Buddy buddy) {
                                final bool isFirst = buddy == kBuddies.first;
                                return Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      left: isFirst ? 0 : 8,
                                      right: isFirst ? 8 : 0,
                                    ),
                                    child: _BuddyCard(
                                      buddy: buddy,
                                      label: buddy.id == 'girl'
                                          ? l10n.buddyGirl
                                          : l10n.buddyBoy,
                                      selected: _buddyId == buddy.id,
                                      onTap: () {
                                        _nameFocusNode.unfocus();
                                        setState(() => _buddyId = buddy.id);
                                      },
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _BottomCTA(onTap: _finish, l10n: l10n, theme: theme),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Background
// ─────────────────────────────────────────────────────────────────────────────

class _GradientCanvas extends StatelessWidget {
  const _GradientCanvas();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFFDFBF7),
            Color(0xFFF9F5EC),
            Color(0xFFF4ECE1),
          ],
          stops: <double>[0, 0.5, 1],
        ),
      ),
      child: SizedBox.expand(),
    );
  }
}

class _FloatingShapes extends StatelessWidget {
  const _FloatingShapes({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        final double t = animation.value;
        return IgnorePointer(
          child: Stack(
            children: <Widget>[
              Positioned(
                top: -50 + math.sin(t * math.pi * 2) * 15,
                right: -60,
                child: _shape(AppColors.yellow, 180, 0.06),
              ),
              Positioned(
                bottom: 100 + math.cos(t * math.pi * 2) * 15,
                left: -80,
                child: _shape(AppColors.teal, 160, 0.05),
              ),
              Positioned(
                top: 250 + math.sin(t * math.pi * 2) * 10,
                right: -40,
                child: _shape(AppColors.pink, 100, 0.04),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _shape(Color color, double size, double alpha) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: alpha),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.theme, required this.l10n});

  final ThemeData theme;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.teal.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/logos/app-logo.png',
                width: 48,
                height: 48,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.onboardingGreeting,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppColors.dark,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.onboardingSubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.dark.withValues(alpha: 0.5),
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step section (Glassmorphism & Clean UI)
// ─────────────────────────────────────────────────────────────────────────────

class _StepSection extends StatelessWidget {
  const _StepSection({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
    this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.dark.withValues(alpha: 0.03),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.9),
                width: 1.5,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Container(
                    width: 5,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.8),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        bottomLeft: Radius.circular(24),
                      ),
                    )),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            _IconChip(icon: icon, color: iconColor),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      color: AppColors.dark,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (subtitle != null)
                                    Text(
                                      subtitle!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          theme.textTheme.labelMedium?.copyWith(
                                        color: AppColors.dark
                                            .withValues(alpha: 0.45),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Expanded(child: child),
                      ],
                    ),
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

class _IconChip extends StatelessWidget {
  const _IconChip({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: color, size: 20),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Name input
// ─────────────────────────────────────────────────────────────────────────────

class _NameInput extends StatelessWidget {
  const _NameInput({
    required this.controller,
    required this.focusNode,
    required this.l10n,
    required this.theme,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final AppLocalizations l10n;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textCapitalization: TextCapitalization.words,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: AppColors.dark,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: l10n.childNameHint,
          hintStyle: theme.textTheme.bodyLarge?.copyWith(
            color: AppColors.dark.withValues(alpha: 0.25),
          ),
          prefixIcon: Icon(
            Icons.person_rounded,
            color: AppColors.teal.withValues(alpha: 0.8),
            size: 22,
          ),
          filled: true,
          fillColor: Colors.black.withValues(alpha: 0.02),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: AppColors.dark.withValues(alpha: 0.04),
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.teal, width: 2),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Age card
// ─────────────────────────────────────────────────────────────────────────────

class _AgeCard extends StatelessWidget {
  const _AgeCard({
    required this.label,
    required this.ageLabel,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String ageLabel;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          // Reduced padding to help prevent overflow
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[color, color.withValues(alpha: 0.85)],
                  )
                : null,
            color: selected ? null : Colors.black.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? color : Colors.transparent,
              width: selected ? 0 : 1.5,
            ),
            boxShadow: selected
                ? <BoxShadow>[
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          // FittedBox guarantees the content scales down instead of overflowing
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  icon,
                  size: 26,
                  color: selected ? Colors.white : color,
                ),
                const SizedBox(height: 6),
                Text(
                  ageLabel,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: selected ? Colors.white : color,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.95)
                        : AppColors.dark.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
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

// ─────────────────────────────────────────────────────────────────────────────
// Buddy card (Enlarged Avatars)
// ─────────────────────────────────────────────────────────────────────────────

class _BuddyCard extends StatelessWidget {
  const _BuddyCard({
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
    final ThemeData theme = Theme.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color:
                selected ? Colors.white : Colors.black.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? buddy.color : Colors.transparent,
              width: selected ? 2.5 : 1.5,
            ),
            boxShadow: selected
                ? <BoxShadow>[
                    BoxShadow(
                      color: buddy.color.withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      // Kept very large, but slightly bounded to fit flexible constraints
                      width: selected ? 105 : 90,
                      height: selected ? 105 : 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: buddy.color.withValues(
                          alpha: selected ? 0.15 : 0.08,
                        ),
                        border: Border.all(
                          color: selected
                              ? buddy.color
                              : buddy.color.withValues(alpha: 0.3),
                          width: selected ? 3 : 2,
                        ),
                        boxShadow: selected
                            ? <BoxShadow>[
                                BoxShadow(
                                  color: buddy.color.withValues(alpha: 0.2),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ]
                            : null,
                      ),
                      padding: const EdgeInsets.all(6),
                      child: ClipOval(
                        child: Image.asset(
                          buddy.assetPath,
                          fit: BoxFit.cover,
                          alignment: const Alignment(0, -0.10),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: AnimatedScale(
                        scale: selected ? 1 : 0,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutBack,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: buddy.color,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: buddy.color.withValues(alpha: 0.4),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: selected ? buddy.color : AppColors.dark,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom CTA
// ─────────────────────────────────────────────────────────────────────────────

class _BottomCTA extends StatelessWidget {
  const _BottomCTA({
    required this.onTap,
    required this.l10n,
    required this.theme,
  });

  final VoidCallback onTap;
  final AppLocalizations l10n;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: <Color>[AppColors.teal, Color(0xFF209E96)],
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.teal.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(28),
            splashColor: Colors.white.withValues(alpha: 0.2),
            highlightColor: Colors.white.withValues(alpha: 0.1),
            child: SizedBox(
              height: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    l10n.letsGo,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
