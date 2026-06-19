import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../games/shared/games_catalog.dart';
import '../../profile/data/buddy.dart';
import '../../profile/data/child_profile.dart';
import '../../profile/view_model/profile_view_model.dart';
import '../../rewards/view_model/rewards_view_model.dart';
import '../../streak/view_model/streak_view_model.dart';

/// S3 · Home (Kid Hub).
///
/// A lively dashboard: an animated buddy greeting, a daily-streak tracker,
/// a rotating "Today's Adventure" pick, the two big activity tiles, and a
/// sticker-collection progress strip. Soft shapes drift in the background.
///
/// Name, age band and buddy come from the saved profile ([profileProvider]);
/// the streak and sticker figures are persisted too ([streakProvider] /
/// [rewardsProvider]). The daily pick and play count respect the age band.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ambient;

  @override
  void initState() {
    super.initState();
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    // Count today's open toward the streak, after the first frame so we never
    // mutate provider state during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(streakProvider.notifier).recordVisit();
    });
  }

  @override
  void dispose() {
    _ambient.dispose();
    super.dispose();
  }

  /// Maps the profile's age band to the games-catalog band.
  static GameBand _gameBand(AgeBand band) =>
      band == AgeBand.junior ? GameBand.junior : GameBand.senior;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final RewardsState rewards = ref.watch(rewardsProvider);
    final StreakState streak = ref.watch(streakProvider);
    final ChildProfile? profile = ref.watch(profileProvider);
    final Buddy buddy = ref.watch(buddyProvider);
    // Surface the games that match the child's age band (fall back to all).
    final List<GameInfo> ageGames = profile == null
        ? kGames
        : gamesForBand(_gameBand(profile.ageBand));
    // A different adventure surfaces each calendar day, from age-fit games.
    final GameInfo daily = ageGames[DateTime.now().day % ageGames.length];

    return Scaffold(
      body: Stack(
        children: <Widget>[
          _FloatingShapes(animation: _ambient),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _Header(name: profile?.name ?? '', buddy: buddy, bounce: _ambient),
                  const SizedBox(height: 20),
                  _StreakCard(streakDays: streak.streak),
                  const SizedBox(height: 16),
                  _DailyAdventureCard(
                    title: daily.title(l10n),
                    icon: daily.icon,
                    color: daily.color,
                    onTap: () => context.push(daily.route),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 168,
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: _ActivityTile(
                            label: l10n.tileColor,
                            subtitle: l10n.tileColorSubtitle(60),
                            color: AppColors.coral,
                            icon: Icons.brush_rounded,
                            onTap: () => context.push(Routes.gallery),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _ActivityTile(
                            label: l10n.tilePlay,
                            subtitle: l10n.tilePlaySubtitle(ageGames.length),
                            color: AppColors.purple,
                            icon: Icons.extension_rounded,
                            onTap: () => context.push(Routes.games),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 96,
                    child: _ActivityTile(
                      label: l10n.tileLearn,
                      subtitle: l10n.tileLearnSubtitle,
                      color: AppColors.green,
                      icon: Icons.menu_book_rounded,
                      onTap: () => context.push(Routes.learn),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _StickerProgress(
                    earned: rewards.earned,
                    total: rewards.total,
                    onTap: () => context.push(Routes.stickers),
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

/// Buddy avatar + greeting + settings cog.
class _Header extends StatelessWidget {
  const _Header({required this.name, required this.buddy, required this.bounce});

  final String name;
  final Buddy buddy;
  final Animation<double> bounce;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final String greeting =
        name.trim().isEmpty ? l10n.homeGreetingNoName : l10n.homeGreeting(name);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Gentle vertical bob makes the buddy feel alive.
        AnimatedBuilder(
          animation: bounce,
          builder: (BuildContext context, Widget? child) {
            final double dy = math.sin(bounce.value * 2 * math.pi) * 5;
            return Transform.translate(offset: Offset(0, dy), child: child);
          },
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: buddy.color.withValues(alpha: 0.15),
              border: Border.all(color: buddy.color, width: 3),
            ),
            alignment: Alignment.center,
            child: Text(buddy.emoji, style: const TextStyle(fontSize: 32)),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                greeting,
                style: theme.textTheme.headlineMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                l10n.homeQuestion,
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: AppColors.dark.withValues(alpha: 0.6)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          onPressed: () => _parentGate(context, Routes.settings),
          icon: const Icon(Icons.settings_rounded),
        ),
      ],
    );
  }

  void _parentGate(BuildContext context, String destination) {
    // Real parent gate is a math-question modal; routed here for the walkthrough.
    context.push(destination);
  }
}

/// "{n}-day streak!" with a Mon–Sun week tracker of filled flames.
class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.streakDays});

  final int streakDays;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final MaterialLocalizations material = MaterialLocalizations.of(context);
    final int firstDay = material.firstDayOfWeekIndex;
    // 0-based position of today within the displayed week.
    final int todayPos = (DateTime.now().weekday % 7 - firstDay + 7) % 7;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.orange.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.orange.withValues(alpha: 0.15),
                child: const Text('🔥', style: TextStyle(fontSize: 26)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l10n.homeStreakTitle(streakDays),
                      style: theme.textTheme.titleLarge,
                    ),
                    Text(
                      l10n.homeStreakSubtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.dark.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List<Widget>.generate(7, (int i) {
              final int weekday = (firstDay + i) % 7;
              final bool done = i <= todayPos && i > todayPos - streakDays;
              final bool isToday = i == todayPos;
              return Column(
                children: <Widget>[
                  Text(
                    material.narrowWeekdays[weekday],
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.dark.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done ? AppColors.orange : AppColors.grey,
                      border: isToday
                          ? Border.all(color: AppColors.dark, width: 2)
                          : null,
                    ),
                    child: done
                        ? const Icon(
                            Icons.check_rounded,
                            size: 18,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// Big gradient hero card featuring a rotating daily activity.
class _DailyAdventureCard extends StatelessWidget {
  const _DailyAdventureCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    return Material(
      borderRadius: BorderRadius.circular(32),
      child: InkWell(
        borderRadius: BorderRadius.circular(32),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: LinearGradient(
              colors: <Color>[color, color.withValues(alpha: 0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      l10n.homeDailyTitle,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            l10n.homeStart,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.play_arrow_rounded,
                            color: color,
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white24,
                child: Icon(icon, size: 44, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A compact square activity tile (Color / Play).
class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.label,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white,
                child: Icon(icon, size: 30, color: color),
              ),
              const Spacer(),
              Text(
                label,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(color: Colors.white),
              ),
              Text(
                subtitle,
                style:
                    theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sticker-collection progress strip → My Sticker Room.
class _StickerProgress extends StatelessWidget {
  const _StickerProgress({
    required this.earned,
    required this.total,
    required this.onTap,
  });

  final int earned;
  final int total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final double fraction = total == 0 ? 0 : (earned / total).clamp(0.0, 1.0);
    return Material(
      color: AppColors.yellow,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: <Widget>[
              const Text('⭐', style: TextStyle(fontSize: 30)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l10n.stickerRoom,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(color: AppColors.dark),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: fraction,
                        minHeight: 10,
                        backgroundColor: Colors.white,
                        color: AppColors.coral,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.stickersCollected(earned, total),
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: AppColors.dark),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.dark.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Soft, slowly drifting blobs behind the dashboard. Decorative only.
class _FloatingShapes extends StatelessWidget {
  const _FloatingShapes({required this.animation});

  final Animation<double> animation;

  static const List<_Blob> _blobs = <_Blob>[
    _Blob(color: AppColors.teal, size: 150, left: -40, top: 80, phase: 0),
    _Blob(color: AppColors.pink, size: 110, right: -30, top: 220, phase: 0.4),
    _Blob(
      color: AppColors.purple,
      size: 130,
      left: -30,
      bottom: 60,
      phase: 0.7,
    ),
    _Blob(
      color: AppColors.yellow,
      size: 90,
      right: -10,
      bottom: 160,
      phase: 0.2,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: animation,
          builder: (BuildContext context, _) {
            return Stack(
              children: _blobs.map((_Blob b) {
                final double t = (animation.value + b.phase) * 2 * math.pi;
                return Positioned(
                  left: b.left,
                  right: b.right,
                  top: b.top == null ? null : b.top! + math.sin(t) * 12,
                  bottom:
                      b.bottom == null ? null : b.bottom! + math.cos(t) * 12,
                  child: Container(
                    width: b.size,
                    height: b.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: b.color.withValues(alpha: 0.12),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}

@immutable
class _Blob {
  const _Blob({
    required this.color,
    required this.size,
    required this.phase,
    this.left,
    this.right,
    this.top,
    this.bottom,
  });

  final Color color;
  final double size;
  final double phase;
  final double? left;
  final double? right;
  final double? top;
  final double? bottom;
}
