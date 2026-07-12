import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

/// Parent-controlled sound preferences. Immutable; replaced on every change so
/// Riverpod detects updates by identity (House Rule §4).
@immutable
class SoundSettings {
  const SoundSettings({this.soundEnabled = true});

  /// Master switch for all voice + sound effects (Settings → Sounds & Music).
  final bool soundEnabled;

  SoundSettings copyWith({bool? soundEnabled}) =>
      SoundSettings(soundEnabled: soundEnabled ?? this.soundEnabled);
}

/// Persistence boundary for [SoundSettings]. Behind an interface so the
/// controller can be unit-tested with an in-memory store, with no Hive setup.
abstract interface class SoundSettingsStore {
  SoundSettings read();
  void save(SoundSettings settings);
}

/// Hive-backed [SoundSettingsStore]. The box is opened once at app start
/// (see `main.dart`).
class HiveSoundSettingsStore implements SoundSettingsStore {
  HiveSoundSettingsStore(this._box);

  /// Name of the Hive box that holds parent settings.
  static const String boxName = 'settings';
  static const String _soundEnabledKey = 'soundEnabled';

  final Box<dynamic> _box;

  @override
  SoundSettings read() {
    final dynamic enabled = _box.get(_soundEnabledKey);
    return SoundSettings(soundEnabled: enabled is bool ? enabled : true);
  }

  @override
  void save(SoundSettings settings) =>
      _box.put(_soundEnabledKey, settings.soundEnabled);
}

/// Injected persistence. Overridden in `main()` with the Hive-backed store once
/// its box is open; overridden again with an in-memory fake in tests.
final soundSettingsStoreProvider = Provider<SoundSettingsStore>(
  (Ref ref) => throw UnimplementedError(
    'soundSettingsStoreProvider must be overridden in main() with a store',
  ),
);

/// Owns the sound preferences. Loads from the [SoundSettingsStore] on build and
/// persists every change, so the master sound switch survives restarts.
class SoundSettingsController extends Notifier<SoundSettings> {
  SoundSettingsStore get _store => ref.read(soundSettingsStoreProvider);

  @override
  SoundSettings build() => _store.read();

  void setSoundEnabled(bool enabled) {
    final SoundSettings next = state.copyWith(soundEnabled: enabled);
    _store.save(next);
    state = next;
  }

  void toggleSound() => setSoundEnabled(!state.soundEnabled);
}

final soundSettingsProvider =
    NotifierProvider<SoundSettingsController, SoundSettings>(
  SoundSettingsController.new,
);
