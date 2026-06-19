import 'package:go_router/go_router.dart';

import '../../features/learn/view/abc_tutorial_screen.dart';
import '../../features/learn/view/daily_story_screen.dart';
import '../../features/learn/view/learn_hub_screen.dart';
import '../../features/learn/view/poem_screen.dart';
import '../../features/coloring/view/color_by_number_screen.dart';
import '../../features/coloring/view/coloring_canvas_screen.dart';
import '../../features/coloring/view/coloring_gallery_screen.dart';
import '../../features/games/color_match/view/color_match_screen.dart';
import '../../features/games/count_tap/view/count_tap_screen.dart';
import '../../features/games/letter_trace/view/letter_trace_screen.dart';
import '../../features/games/memory_flip/view/memory_flip_screen.dart';
import '../../features/games/odd_one_out/view/odd_one_out_screen.dart';
import '../../features/games/pattern/view/pattern_screen.dart';
import '../../features/games/shape_sorter/view/shape_sorter_screen.dart';
import '../../features/games/shared/games_hub_screen.dart';
import '../../features/home/view/home_screen.dart';
import '../../features/onboarding/view/onboarding_screen.dart';
import '../../features/onboarding/view/splash_screen.dart';
import '../../features/paywall/view/paywall_screen.dart';
import '../../features/settings/view/settings_screen.dart';
import '../../features/stickers/view/sticker_room_screen.dart';

/// Type-safe route names. Use these instead of raw strings.
abstract final class Routes {
  const Routes._();
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String gallery = '/coloring';
  static const String canvas = '/coloring/canvas';
  static const String colorByNumber = '/coloring/numbers';
  static const String games = '/games';
  static const String gameShapeSorter = '/games/shapes';
  static const String gameColorMatch = '/games/colors';
  static const String gameMemoryFlip = '/games/memory';
  static const String gameLetterTrace = '/games/letters';
  static const String gameCountTap = '/games/count';
  static const String gamePattern = '/games/pattern';
  static const String gameOddOneOut = '/games/odd';
  static const String learn = '/learn';
  static const String learnStory = '/learn/story';
  static const String learnAbc = '/learn/abc';
  static const String learnPoems = '/learn/poems';
  static const String stickers = '/stickers';
  static const String paywall = '/paywall';
  static const String settings = '/settings';
}

/// Single source of truth for navigation. Declarative + deep-link ready.
final GoRouter appRouter = GoRouter(
  initialLocation: Routes.splash,
  routes: <RouteBase>[
    GoRoute(path: Routes.splash, builder: (_, __) => const SplashScreen()),
    GoRoute(path: Routes.onboarding, builder: (_, __) => const OnboardingScreen()),
    GoRoute(path: Routes.home, builder: (_, __) => const HomeScreen()),
    GoRoute(
      path: Routes.gallery,
      builder: (_, __) => const ColoringGalleryScreen(),
      routes: <RouteBase>[
        GoRoute(
          path: 'canvas',
          builder: (_, GoRouterState state) =>
              ColoringCanvasScreen(pageId: state.uri.queryParameters['page'] ?? 'lion'),
        ),
        GoRoute(
          path: 'numbers',
          builder: (_, GoRouterState state) =>
              ColorByNumberScreen(pageId: state.uri.queryParameters['page'] ?? 'sun'),
        ),
      ],
    ),
    GoRoute(
      path: Routes.games,
      builder: (_, __) => const GamesHubScreen(),
      routes: <RouteBase>[
        GoRoute(path: 'shapes', builder: (_, __) => const ShapeSorterScreen()),
        GoRoute(path: 'colors', builder: (_, __) => const ColorMatchScreen()),
        GoRoute(path: 'memory', builder: (_, __) => const MemoryFlipScreen()),
        GoRoute(path: 'letters', builder: (_, __) => const LetterTraceScreen()),
        GoRoute(path: 'count', builder: (_, __) => const CountTapScreen()),
        GoRoute(path: 'pattern', builder: (_, __) => const PatternScreen()),
        GoRoute(path: 'odd', builder: (_, __) => const OddOneOutScreen()),
      ],
    ),
    GoRoute(
      path: Routes.learn,
      builder: (_, __) => const LearnHubScreen(),
      routes: <RouteBase>[
        GoRoute(path: 'story', builder: (_, __) => const DailyStoryScreen()),
        GoRoute(path: 'abc', builder: (_, __) => const AbcTutorialScreen()),
        GoRoute(path: 'poems', builder: (_, __) => const PoemScreen()),
      ],
    ),
    GoRoute(path: Routes.stickers, builder: (_, __) => const StickerRoomScreen()),
    GoRoute(path: Routes.paywall, builder: (_, __) => const PaywallScreen()),
    GoRoute(path: Routes.settings, builder: (_, __) => const SettingsScreen()),
  ],
);
