import 'package:brightmind_kids/src/features/coloring/data/coloring_templates.dart';
import 'package:brightmind_kids/src/features/rewards/data/sticker_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every coloring template awards a sticker that exists in the catalog',
      () {
    for (final dynamic t in kColoringTemplates) {
      // Guards against a page referencing a sticker id that was renamed/removed.
      expect(
        stickerById(t.stickerRewardId as String),
        isNotNull,
        reason: 'template "${t.id}" → unknown sticker "${t.stickerRewardId}"',
      );
    }
  });
}
