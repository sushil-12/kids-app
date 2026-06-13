import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/coloring/view/coloring_canvas_screen.dart';
import '../../features/coloring/view/coloring_gallery_screen.dart';
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
  static const String games = '/games';
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
      ],
    ),
    GoRoute(path: Routes.games, builder: (_, __) => const GamesHubScreen()),
    GoRoute(path: Routes.stickers, builder: (_, __) => const StickerRoomScreen()),
    GoRoute(path: Routes.paywall, builder: (_, __) => const PaywallScreen()),
    GoRoute(path: Routes.settings, builder: (_, __) => const SettingsScreen()),
  ],
);
