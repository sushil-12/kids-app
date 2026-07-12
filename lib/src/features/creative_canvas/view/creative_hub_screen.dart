import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
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
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: CustomScrollView(
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Row(
                  children: <Widget>[
                    IconButton.filledTonal(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    Expanded(
                      child: Text(
                        l10n.creativeHubTitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: () => context.push(Routes.creativeArt),
                      icon: const Icon(Icons.collections_rounded),
                    ),
                  ],
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
                  _GuideGrid(guides: shapes, onTap: (String id) => _open(context, id)),
                  const SizedBox(height: 24),
                  _SectionTitle(l10n.creativeFruits),
                  const SizedBox(height: 12),
                  _GuideGrid(guides: fruits, onTap: (String id) => _open(context, id)),
                ]),
              ),
            ),
          ],
        ),
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
    return Text(text, style: Theme.of(context).textTheme.titleLarge);
  }
}

class _FreeDrawCard extends StatelessWidget {
  const _FreeDrawCard({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.pink,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: <Widget>[
              const CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                child: Icon(Icons.edit_rounded, size: 32, color: AppColors.pink),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(color: Colors.white),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white),
            ],
          ),
        ),
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
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Center(
          child: Text(guide.emoji, style: const TextStyle(fontSize: 44)),
        ),
      ),
    );
  }
}
