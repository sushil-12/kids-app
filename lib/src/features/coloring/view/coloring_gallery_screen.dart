import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../l10n/app_localizations.dart';

/// S4 · Coloring Gallery. Tap a page to open the canvas.
class ColoringGalleryScreen extends StatelessWidget {
  const ColoringGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.galleryTitle)),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: <Widget>[
          for (final String id in <String>['lion', 'puppy', 'rocket'])
            Card(
              child: InkWell(
                onTap: () => context.push('${Routes.canvas}?page=$id'),
                child: Center(
                  child: Text(id, style: Theme.of(context).textTheme.titleLarge),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
