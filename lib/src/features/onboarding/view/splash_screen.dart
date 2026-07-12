import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../profile/view_model/profile_view_model.dart';

/// S1 · Splash. Brand moment, then routes to the welcome flow on first run,
/// or straight to Home once a profile has been saved.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  late final AnimationController _controller;
  late final Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    // Gentle, looping up-and-down bounce for the logo.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _bounce = Tween<double>(begin: 0, end: -28).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _timer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      // Returning children skip setup and land on Home. First-run children
      // see the welcome flow before the name/age/buddy setup screen.
      final bool onboarded = ref.read(profileProvider) != null;
      context.go(onboarded ? Routes.home : Routes.welcome);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AnimatedBuilder(
              animation: _bounce,
              builder: (BuildContext context, Widget? child) =>
                  Transform.translate(
                offset: Offset(0, _bounce.value),
                child: child,
              ),
              child: Image.asset(
                'assets/logos/splash-logo.png',
                width: 320,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
