import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../admin/view/parent_gate.dart';
import '../data/creative_artwork.dart';
import '../view_model/my_art_view_model.dart';

/// S · My Art. A grid of the child's saved drawings. Tap to view large; delete
/// is destructive, so it is guarded by the parent gate (CLAUDE.md §7).
class MyArtScreen extends ConsumerWidget {
  const MyArtScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<CreativeArtwork> art = ref.watch(myArtProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(l10n.creativeMyArt),
      ),
      body: art.isEmpty
          ? _Empty(message: l10n.creativeEmptyArt)
          : GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.all(16),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: <Widget>[
                for (final CreativeArtwork a in art)
                  _ArtTile(
                    artwork: a,
                    onView: () => _view(context, ref, a),
                  ),
              ],
            ),
    );
  }

  void _view(BuildContext context, WidgetRef ref, CreativeArtwork artwork) {
    final Uint8List bytes = base64Decode(artwork.pngBase64);
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        final AppLocalizations l10n = AppLocalizations.of(ctx);
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                child: Image.memory(bytes, fit: BoxFit.contain),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    TextButton.icon(
                      onPressed: () => _confirmDelete(ctx, ref, artwork.id),
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.coral,
                      ),
                      label: Text(
                        l10n.deleteConfirm,
                        style: const TextStyle(color: AppColors.coral),
                      ),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.teal,
                      ),
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text(l10n.cancel),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Deleting erases the drawing for good, so a grown-up has to confirm.
  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    final bool ok = await showParentGate(context);
    if (!ok || !context.mounted) return;
    ref.read(myArtProvider.notifier).remove(id);
    if (context.mounted) Navigator.of(context).pop();
  }
}

class _ArtTile extends StatelessWidget {
  const _ArtTile({required this.artwork, required this.onView});

  final CreativeArtwork artwork;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final Uint8List bytes = base64Decode(artwork.pngBase64);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onView,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.memory(bytes, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text('🎨', style: TextStyle(fontSize: 72)),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.dark.withValues(alpha: 0.6),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
