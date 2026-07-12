import 'package:brightmind_kids/src/core/services/sound_settings_store.dart';
import 'package:brightmind_kids/src/features/creative_canvas/data/creative_guide.dart';
import 'package:brightmind_kids/src/features/creative_canvas/view_model/creative_canvas_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sound off so the view-model's fire-and-forget audio calls are no-ops in
/// tests.
class _SilentSoundStore implements SoundSettingsStore {
  @override
  SoundSettings read() => const SoundSettings(soundEnabled: false);

  @override
  void save(SoundSettings settings) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The real AudioService builds audioplayers/flutter_tts on construction,
  // which hit platform channels that don't exist under flutter_test. Stub them
  // so the view-model's audio dependency is harmless.
  setUpAll(() {
    final TestDefaultBinaryMessenger messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final String channel in <String>[
      'flutter_tts',
      'xyz.luan/audioplayers.global',
      'xyz.luan/audioplayers',
    ]) {
      messenger.setMockMethodCallHandler(
        MethodChannel(channel),
        (MethodCall call) async => null,
      );
    }
  });

  late ProviderContainer container;

  CreativeState read(String id) =>
      container.read(creativeCanvasViewModelProvider(id));
  CreativeCanvasViewModel vm(String id) =>
      container.read(creativeCanvasViewModelProvider(id).notifier);

  setUp(() {
    container = ProviderContainer(
      overrides: <Override>[
        soundSettingsStoreProvider.overrideWithValue(_SilentSoundStore()),
      ],
    );
  });
  tearDown(() => container.dispose());

  test('free-draw builds with no guide and free-draw mode', () {
    final CreativeState s = read(kFreeDrawId);
    expect(s.guide, isNull);
    expect(s.mode, CreativeMode.freeDraw);
    expect(s.guidePaths, isEmpty);
    expect(s.hasDrawn, isFalse);
    expect(s.canUndo, isFalse);
  });

  test('a guide id builds with that guide and its mode', () {
    final CreativeState s = read('fruit_apple');
    expect(s.guide?.id, 'fruit_apple');
    expect(s.mode, CreativeMode.traceFruit);
    expect(s.guidePaths, isNotEmpty);
  });

  test('a full stroke is captured on end', () {
    vm(kFreeDrawId)
      ..startStroke(const Offset(10, 10))
      ..extendStroke(const Offset(20, 20))
      ..endStroke();

    final CreativeState s = read(kFreeDrawId);
    expect(s.strokes, hasLength(1));
    expect(s.activeStroke, isNull);
    expect(s.strokes.first.points, hasLength(2));
    expect(s.hasDrawn, isTrue);
    expect(s.canUndo, isTrue);
  });

  test('undo removes the most recent stroke', () {
    final CreativeCanvasViewModel v = vm(kFreeDrawId);
    for (int i = 0; i < 3; i++) {
      v
        ..startStroke(Offset(i.toDouble(), i.toDouble()))
        ..endStroke();
    }
    expect(read(kFreeDrawId).strokes, hasLength(3));

    v.undo();
    expect(read(kFreeDrawId).strokes, hasLength(2));
  });

  test('clear wipes all strokes', () {
    vm(kFreeDrawId)
      ..startStroke(const Offset(5, 5))
      ..endStroke()
      ..clear();
    expect(read(kFreeDrawId).strokes, isEmpty);
    expect(read(kFreeDrawId).hasDrawn, isFalse);
  });

  test('selecting a color switches back to the brush tool', () {
    final CreativeCanvasViewModel v = vm(kFreeDrawId);
    v.selectTool(CreativeTool.eraser);
    expect(read(kFreeDrawId).tool, CreativeTool.eraser);

    v.selectColor(Colors.red);
    expect(read(kFreeDrawId).selectedColor, Colors.red);
    expect(read(kFreeDrawId).tool, CreativeTool.brush);
  });

  test('the eraser draws a white stroke', () {
    vm(kFreeDrawId)
      ..selectTool(CreativeTool.eraser)
      ..startStroke(const Offset(1, 1))
      ..extendStroke(const Offset(2, 2))
      ..endStroke();
    expect(read(kFreeDrawId).strokes.single.color, Colors.white);
  });

  test('brush size selection changes the captured stroke width', () {
    final CreativeCanvasViewModel v = vm(kFreeDrawId);
    v
      ..selectBrush(CreativeBrush.thick)
      ..startStroke(const Offset(0, 0))
      ..endStroke();
    expect(
      read(kFreeDrawId).strokes.single.width,
      CreativeBrush.thick.width,
    );
  });

  test('every bundled guide has at least one path and a sticker id', () {
    for (final TraceGuide g in kCreativeGuides) {
      expect(g.guidePaths, isNotEmpty, reason: 'guide "${g.id}" has no paths');
      expect(g.stickerRewardId, isNotEmpty);
    }
  });
}
