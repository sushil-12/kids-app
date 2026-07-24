import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import 'src/app/app.dart';
import 'src/core/services/feature_flags.dart';
import 'src/core/services/sound_settings_store.dart';
import 'src/features/admin/data/admin_key_store.dart';
import 'src/features/admin/view_model/admin_view_model.dart';
import 'src/features/creative_canvas/data/creative_store.dart';
import 'src/features/creative_canvas/view_model/my_art_view_model.dart';
import 'src/features/learn/data/content_cache.dart';
import 'src/features/adaptive/data/adaptive_repository.dart';
import 'src/features/adaptive/view_model/adaptive_view_model.dart';
import 'src/features/profile/data/profile_repository.dart';
import 'src/features/profile/view_model/profile_view_model.dart';
import 'src/features/rewards/data/reward_repository.dart';
import 'src/features/rewards/view_model/rewards_view_model.dart';
import 'src/features/streak/data/streak_repository.dart';
import 'src/features/streak/view_model/streak_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Local persistence (profiles, progress, stickers, in-progress art).
  await Hive.initFlutter();
  final Box<dynamic> rewardsBox =
      await Hive.openBox<dynamic>(HiveRewardStore.boxName);
  final Box<dynamic> streakBox =
      await Hive.openBox<dynamic>(HiveStreakStore.boxName);
  final Box<dynamic> profileBox =
      await Hive.openBox<dynamic>(HiveProfileStore.boxName);
  // On-device intelligence: feature flags + per-game adaptive difficulty.
  final Box<dynamic> flagsBox =
      await Hive.openBox<dynamic>(HiveFeatureFlagStore.boxName);
  final Box<dynamic> adaptiveBox =
      await Hive.openBox<dynamic>(HiveAdaptiveStore.boxName);
  final Box<String> learnBox = await Hive.openBox<String>('learn_content');
  // Parent-gated admin panel: stores the backend admin key on-device only.
  final Box<dynamic> adminBox =
      await Hive.openBox<dynamic>(HiveAdminKeyStore.boxName);
  // Parent sound preferences (master Sounds & Music switch).
  final Box<dynamic> settingsBox =
      await Hive.openBox<dynamic>(HiveSoundSettingsStore.boxName);
  // Creative Canvas: the child's saved drawings (base64 PNGs), on-device only.
  final Box<dynamic> creativeBox =
      await Hive.openBox<dynamic>(HiveCreativeStore.boxName);

  // Kids' app: lock to portrait for a predictable, simple layout.
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);

  // Edge-to-edge: let every screen's background paint behind the status bar
  // and the bottom system inset instead of leaving opaque OS-drawn bars.
  // Screens still use SafeArea to keep interactive content clear of both.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
      // Android draws a dark contrast scrim behind a transparent nav bar by
      // default; disable it so the screen's own background shows through.
      systemNavigationBarContrastEnforced: false,
    ),
  );

  runApp(
    ProviderScope(
      overrides: <Override>[
        // Inject the Hive-backed stores now that their boxes are open.
        rewardStoreProvider.overrideWithValue(HiveRewardStore(rewardsBox)),
        streakStoreProvider.overrideWithValue(HiveStreakStore(streakBox)),
        profileStoreProvider.overrideWithValue(HiveProfileStore(profileBox)),
        featureFlagStoreProvider
            .overrideWithValue(HiveFeatureFlagStore(flagsBox)),
        adaptiveStoreProvider
            .overrideWithValue(HiveAdaptiveStore(adaptiveBox)),
        contentCacheProvider
            .overrideWithValue(HiveContentCache(learnBox)),
        adminKeyStoreProvider
            .overrideWithValue(HiveAdminKeyStore(adminBox)),
        soundSettingsStoreProvider
            .overrideWithValue(HiveSoundSettingsStore(settingsBox)),
        creativeStoreProvider
            .overrideWithValue(HiveCreativeStore(creativeBox)),
      ],
      child: const BrightMindApp(),
    ),
  );
}
