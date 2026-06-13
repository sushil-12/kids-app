import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// S9 · My Sticker Room.
class StickerRoomScreen extends StatelessWidget {
  const StickerRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.stickerRoom)),
      body: Center(child: Text(l10n.stickersCollected(7, 65))),
    );
  }
}
