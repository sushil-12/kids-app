import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/clay_decor.dart';
import '../../../core/widgets/clay_icons.dart';
import '../../../l10n/app_localizations.dart';
import '../data/creative_guide.dart';

/// S · Creative Canvas hub. Pick a blank page, a shape to trace, or a fruit to
/// trace — or visit the saved-art gallery. Tapping a tile opens the draw screen.
class CreativeHubScreen extends StatelessWidget {
  const CreativeHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<TraceGuide> shapes = kCreativeGuides
        .where((TraceGuide g) => g.mode == CreativeMode.traceShape)
        .toList(growable: false);
    final List<TraceGuide> fruits = kCreativeGuides
        .where((TraceGuide g) => g.mode == CreativeMode.traceFruit)
        .toList(growable: false);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const ClayBackground(tint: AppColors.pinkDeep),
          SafeArea(
            child: CustomScrollView(
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: ClayHeader(
                      title: l10n.creativeHubTitle,
                      tint: AppColors.pinkDeep,
                      trailing: ClayIconButton(
                        icon: Icons.collections_rounded,
                        tint: AppColors.pinkDeep,
                        onTap: () => context.push(Routes.creativeArt),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(<Widget>[
                      _FreeDrawCard(
                        label: l10n.creativeFreeDraw,
                        onTap: () => _open(context, kFreeDrawId),
                      ),
                      const SizedBox(height: 24),
                      _SectionTitle(l10n.creativeShapes),
                      const SizedBox(height: 12),
                      _GuideGrid(
                        guides: shapes,
                        onTap: (String id) => _open(context, id),
                      ),
                      const SizedBox(height: 24),
                      _SectionTitle(l10n.creativeFruits),
                      const SizedBox(height: 12),
                      _GuideGrid(
                        guides: fruits,
                        onTap: (String id) => _open(context, id),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _open(BuildContext context, String guideId) =>
      context.push('${Routes.creativeDraw}?guide=$guideId');
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: clayTitle(fontSize: 18));
  }
}

class _FreeDrawCard extends StatelessWidget {
  const _FreeDrawCard({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClayTile(
      color: AppColors.pinkDeep,
      padding: const EdgeInsets.all(20),
      onTap: onTap,
      child: Row(
        children: <Widget>[
          const ClayIcon(
            kind: ClayIconKind.pencil,
            tint: AppColors.pinkDeep,
            size: 60,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(label, style: clayTitle(fontSize: 19)),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.pinkDeep),
        ],
      ),
    );
  }
}

class _GuideGrid extends StatelessWidget {
  const _GuideGrid({required this.guides, required this.onTap});

  final List<TraceGuide> guides;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      children: <Widget>[
        for (final TraceGuide g in guides)
          _GuideTile(guide: g, onTap: () => onTap(g.id)),
      ],
    );
  }
}

class _GuideTile extends StatelessWidget {
  const _GuideTile({required this.guide, required this.onTap});

  final TraceGuide guide;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClayTile(
      color: AppColors.pinkDeep,
      fill: Colors.white,
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Center(
        child: Text(guide.emoji, style: const TextStyle(fontSize: 44)),
      ),
    );
  }
}
