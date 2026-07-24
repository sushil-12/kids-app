import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/clay_decor.dart';
import '../../../core/widgets/clay_icons.dart';
import '../../../l10n/app_localizations.dart';
import '../../games/shared/games_catalog.dart';
import '../../profile/data/buddy.dart';
import '../../profile/data/child_profile.dart';
import '../../profile/view_model/profile_view_model.dart';
import '../../rewards/view_model/rewards_view_model.dart';
import '../../streak/view_model/streak_view_model.dart';

/// S3 · Home (Kid Hub), in the shared "pastel clay" design language.
///
/// Sits on a blue [OnboardingBackground]; every panel is a clay card
/// (pastel fill, white border, soft tinted drop shadow): buddy greeting,
/// daily-streak tracker, "Today's Adventure" pick, the activity tiles, and
/// the sticker-collection progress strip.
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
    final List<GameInfo> ageGames =
        profile == null ? kGames : gamesForBand(_gameBand(profile.ageBand));
    // A different adventure surfaces each calendar day, from age-fit games.
    final GameInfo daily = ageGames[DateTime.now().day % ageGames.length];

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const ClayBackground(tint: AppColors.blue),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _Header(
                    name: profile?.name ?? '',
                    buddy: buddy,
                    bounce: _ambient,
                  ),
                  const SizedBox(height: 20),
                  _StreakCard(streakDays: streak.streak),
                  const SizedBox(height: 16),
                  _DailyAdventureCard(
                    title: daily.title(l10n),
                    glyph: daily.glyph,
                    color: daily.color,
                    onTap: () => context.push(daily.route),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 172,
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: _ActivityTile(
                            label: l10n.tileColor,
                            subtitle: l10n.tileColorSubtitle(60),
                            color: AppColors.coral,
                            glyph: ClayIconKind.brush,
                            onTap: () => context.push(Routes.gallery),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _ActivityTile(
                            label: l10n.tilePlay,
                            subtitle: l10n.tilePlaySubtitle(ageGames.length),
                            color: AppColors.purple,
                            glyph: ClayIconKind.puzzle,
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
                      glyph: ClayIconKind.book,
                      onTap: () => context.push(Routes.learn),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 96,
                    child: _ActivityTile(
                      label: l10n.tileCreate,
                      subtitle: l10n.tileCreateSubtitle,
                      color: AppColors.pinkDeep,
                      glyph: ClayIconKind.palette,
                      onTap: () => context.push(Routes.creative),
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
  const _Header({
    required this.name,
    required this.buddy,
    required this.bounce,
  });

  final String name;
  final Buddy buddy;
  final Animation<double> bounce;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String greeting =
        name.trim().isEmpty ? l10n.homeGreetingNoName : l10n.homeGreeting(name);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        // Gentle vertical bob makes the buddy feel alive.
        RepaintBoundary(
          child: AnimatedBuilder(
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
                color: pastelOf(buddy.color, 0.35),
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: buddy.color.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              alignment: Alignment.center,
              padding: const EdgeInsets.all(4),
              child: ClipOval(
                child: Image.asset(
                  buddy.assetPath,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                greeting,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  height: 1.15,
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                l10n.homeQuestion,
                style: GoogleFonts.lexendDeca(
                  fontSize: 14,
                  color: AppColors.slate,
                  height: 1.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        ClayIconButton(
          icon: Icons.settings_rounded,
          onTap: () => _parentGate(context, Routes.settings),
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
    final MaterialLocalizations material = MaterialLocalizations.of(context);
    final int firstDay = material.firstDayOfWeekIndex;
    // 0-based position of today within the displayed week.
    final int todayPos = (DateTime.now().weekday % 7 - firstDay + 7) % 7;

    return ClayTile(
      color: AppColors.orange,
      fill: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const ClayIcon(
                kind: ClayIconKind.flame,
                tint: AppColors.orange,
                size: 48,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l10n.homeStreakTitle(streakDays),
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      l10n.homeStreakSubtitle,
                      style: GoogleFonts.lexendDeca(
                        fontSize: 13,
                        color: AppColors.slate,
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
                    style: GoogleFonts.lexendDeca(
                      fontSize: 11,
                      color: AppColors.slate,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done
                          ? AppColors.orange
                          : pastelOf(AppColors.slate, 0.14),
                      border: isToday
                          ? Border.all(color: AppColors.ink, width: 2)
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

/// Clay hero card featuring a rotating daily activity with a "Start" pill.
class _DailyAdventureCard extends StatelessWidget {
  const _DailyAdventureCard({
    required this.title,
    required this.glyph,
    required this.color,
    required this.onTap,
  });

  final String title;
  final ClayIconKind glyph;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final Color edge =
        Color.alphaBlend(AppColors.ink.withValues(alpha: 0.3), color);
    return ClayTile(
      color: color,
      onTap: onTap,
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
                  style: GoogleFonts.lexendDeca(
                    fontSize: 13,
                    color: AppColors.slate,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 21,
                    height: 1.2,
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),
                // Mini clay CTA: solid fill + hard darker bottom edge.
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: <BoxShadow>[
                      BoxShadow(color: edge, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 9,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          l10n.homeStart,
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ClayIcon(kind: glyph, tint: color, size: 80),
        ],
      ),
    );
  }
}

/// A compact clay activity tile (Color / Play / Learn / Create).
class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.label,
    required this.subtitle,
    required this.color,
    required this.glyph,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final Color color;
  final ClayIconKind glyph;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClayTile(
      color: color,
      onTap: onTap,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          // Short, wide slots (e.g. the full-width Learn tile) lay the icon
          // out beside the text; tall square tiles stack it on top.
          final bool horizontal = constraints.maxHeight < 120;
          final Widget avatar = ClayIcon(kind: glyph, tint: color);
          final Widget labels = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  height: 1.2,
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitle,
                style: GoogleFonts.lexendDeca(
                  fontSize: 12.5,
                  color: AppColors.slate,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          );
          if (horizontal) {
            return Row(
              children: <Widget>[
                avatar,
                const SizedBox(width: 16),
                Expanded(child: labels),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              avatar,
              const Spacer(),
              labels,
            ],
          );
        },
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
    final double fraction = total == 0 ? 0 : (earned / total).clamp(0.0, 1.0);
    return ClayTile(
      color: AppColors.yellow,
      onTap: onTap,
      child: Row(
        children: <Widget>[
          const ClayIcon(
            kind: ClayIconKind.star,
            tint: AppColors.yellow,
            size: 48,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.stickerRoom,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
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
                  style: GoogleFonts.lexendDeca(
                    fontSize: 13,
                    color: AppColors.slate,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: AppColors.slate),
        ],
      ),
    );
  }
}
