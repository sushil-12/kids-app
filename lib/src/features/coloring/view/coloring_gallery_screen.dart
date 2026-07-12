import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../data/coloring_page.dart';
import '../data/coloring_repository.dart';
import '../data/coloring_template.dart';
import '../data/coloring_templates.dart';
import '../engine/coloring_painter.dart';

/// S4 · Coloring Gallery. Shows each picture's line art as a preview so kids
/// recognize what they're about to color. A mode toggle switches between free
/// coloring and the guided Color-by-Number variation.
class ColoringGalleryScreen extends ConsumerStatefulWidget {
  const ColoringGalleryScreen({super.key});

  @override
  ConsumerState<ColoringGalleryScreen> createState() =>
      _ColoringGalleryScreenState();
}

class _ColoringGalleryScreenState extends ConsumerState<ColoringGalleryScreen> {
  bool _byNumber = false;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    // Watch the catalog so the grid rebuilds once backend pages merge in.
    // Bundled pages render immediately; this just adds fresh ones when ready.
    ref.watch(coloringCatalogProvider);
    // In by-number mode, only pictures that define a number map are offered.
    final List<ColoringTemplate> templates = _byNumber
        ? kColoringTemplates
            .where((ColoringTemplate t) => t.supportsByNumber)
            .toList()
        : kColoringTemplates;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.galleryTitle),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: SegmentedButton<bool>(
              segments: <ButtonSegment<bool>>[
                ButtonSegment<bool>(
                  value: false,
                  label: Text(l10n.coloringModeFree),
                  icon: const Icon(Icons.brush_rounded),
                ),
                ButtonSegment<bool>(
                  value: true,
                  label: Text(l10n.coloringModeByNumber),
                  icon: const Icon(Icons.format_list_numbered_rounded),
                ),
              ],
              selected: <bool>{_byNumber},
              onSelectionChanged: (Set<bool> s) =>
                  setState(() => _byNumber = s.first),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.82,
              ),
              itemCount: templates.length,
              itemBuilder: (BuildContext context, int i) {
                final ColoringTemplate template = templates[i];
                final String route = _byNumber
                    ? '${Routes.colorByNumber}?page=${template.id}'
                    : '${Routes.canvas}?page=${template.id}';
                return _PictureCard(
                  template: template,
                  onTap: () => context.push(route),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PictureCard extends StatelessWidget {
  const _PictureCard({required this.template, required this.onTap});

  final ColoringTemplate template;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: <Widget>[
              Expanded(
                child: Stack(
                  children: <Widget>[
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.cream,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: CustomPaint(
                            painter: ColoringPainter(
                              template: template,
                              fills: const <String, Color>{},
                              strokes: const <ColorStroke>[],
                            ),
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ),
                    ),
                    if (template.isPremium)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.yellow,
                          child: const Icon(Icons.lock_rounded,
                              size: 16, color: AppColors.dark),
                        ),
                      )
                    else
                      const Positioned(
                        top: 4,
                        right: 4,
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.green,
                          child: Icon(Icons.check_rounded, size: 18, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                template.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
