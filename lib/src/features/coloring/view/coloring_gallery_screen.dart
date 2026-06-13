import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../data/coloring_page.dart';
import '../data/coloring_template.dart';
import '../data/coloring_templates.dart';
import '../engine/coloring_painter.dart';

/// S4 · Coloring Gallery. Shows each picture's line art as a preview so kids
/// recognize what they're about to color.
class ColoringGalleryScreen extends StatelessWidget {
  const ColoringGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.galleryTitle),
        backgroundColor: Colors.transparent,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.82,
        ),
        itemCount: kColoringTemplates.length,
        itemBuilder: (BuildContext context, int i) {
          final ColoringTemplate template = kColoringTemplates[i];
          return _PictureCard(
            template: template,
            onTap: () => context.push('${Routes.canvas}?page=${template.id}'),
          );
        },
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
