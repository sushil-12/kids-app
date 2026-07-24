import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

/// The app-wide "pastel clay" design kit (CLAUDE.md §9): pastel gradient
/// backgrounds with soft decor, claymorphism cards/tiles/buttons, and the
/// Poppins/Lexend Deca/Nunito type helpers. Originally built for the
/// onboarding flow, now shared by every screen.

/// Blends [tint] over white to make the soft pastels used across the app,
/// so every background/card shade derives from the `AppColors` palette.
Color pastelOf(Color tint, [double strength = 0.16]) =>
    Color.alphaBlend(tint.withValues(alpha: strength), Colors.white);

/// Poppins title style (screen + card headings).
TextStyle clayTitle({
  double fontSize = 22,
  Color color = AppColors.ink,
}) =>
    GoogleFonts.poppins(
      fontSize: fontSize,
      height: 1.2,
      color: color,
      fontWeight: FontWeight.w700,
    );

/// Lexend Deca body style (subtitles, captions).
TextStyle clayBody({
  double fontSize = 14,
  Color color = AppColors.slate,
}) =>
    GoogleFonts.lexendDeca(fontSize: fontSize, color: color, height: 1.35);

/// Full-screen pastel gradient + floating sparkles/bubbles/cloud decoration.
/// One palette tint per screen; neighbors in a flow stay visually distinct.
class ClayBackground extends StatelessWidget {
  const ClayBackground({required this.tint, super.key});

  /// Base palette color; rendered as a pastel fading into warm cream.
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                pastelOf(tint, 0.3),
                pastelOf(tint, 0.12),
                AppColors.cream,
              ],
              stops: const <double>[0, 0.55, 1],
            ),
          ),
          child: CustomPaint(
            painter: _DecorPainter(tint: tint),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

/// Legacy name from the onboarding flow, kept so existing call sites read
/// naturally; the widget is app-wide now.
typedef OnboardingBackground = ClayBackground;

/// Scattered soft decor: four-point sparkles, bubbles, and one cloud blob.
class _DecorPainter extends CustomPainter {
  const _DecorPainter({required this.tint});

  final Color tint;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    _sparkle(
      canvas,
      Offset(w * 0.12, h * 0.09),
      14,
      tint.withValues(alpha: 0.3),
    );
    _sparkle(
      canvas,
      Offset(w * 0.88, h * 0.16),
      10,
      AppColors.yellow.withValues(alpha: 0.5),
    );
    _sparkle(
      canvas,
      Offset(w * 0.8, h * 0.55),
      8,
      tint.withValues(alpha: 0.22),
    );
    _sparkle(
      canvas,
      Offset(w * 0.16, h * 0.62),
      9,
      AppColors.coral.withValues(alpha: 0.2),
    );

    final Paint bubble = Paint()..color = tint.withValues(alpha: 0.1);
    canvas.drawCircle(Offset(w * 0.94, h * 0.36), 26, bubble);
    canvas.drawCircle(Offset(w * 0.06, h * 0.3), 16, bubble);
    canvas.drawCircle(Offset(w * 0.9, h * 0.78), 20, bubble);

    _cloud(
      canvas,
      Offset(w * 0.2, h * 0.2),
      26,
      Colors.white.withValues(alpha: 0.55),
    );
    _cloud(
      canvas,
      Offset(w * 0.78, h * 0.68),
      20,
      Colors.white.withValues(alpha: 0.4),
    );
  }

  void _sparkle(Canvas canvas, Offset c, double r, Color color) {
    final double waist = r * 0.22;
    final Path path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx + waist, c.dy - waist, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx + waist, c.dy + waist, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx - waist, c.dy + waist, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx - waist, c.dy - waist, c.dx, c.dy - r)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _cloud(Canvas canvas, Offset c, double r, Color color) {
    final Paint paint = Paint()..color = color;
    canvas.drawCircle(c, r, paint);
    canvas.drawCircle(c.translate(-r * 0.9, r * 0.25), r * 0.7, paint);
    canvas.drawCircle(c.translate(r * 0.9, r * 0.25), r * 0.75, paint);
  }

  @override
  bool shouldRepaint(_DecorPainter oldDelegate) => oldDelegate.tint != tint;
}

/// Rounded pastel "clay" panel that frames hero art and static content.
/// For a tappable version use [ClayTile].
class ClayCard extends StatelessWidget {
  const ClayCard({
    required this.color,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    super.key,
  });

  final Color color;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: pastelOf(color, 0.22),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: color.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// [ClayCard] recipe with a Material ripple, for tappable panels and tiles.
class ClayTile extends StatelessWidget {
  const ClayTile({
    required this.color,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(18),
    this.fill,
    super.key,
  });

  final Color color;
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  /// Overrides the default pastel fill (e.g. `Colors.white` form sections).
  final Color? fill;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill ?? pastelOf(color, 0.22),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: color.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          splashColor: color.withValues(alpha: 0.15),
          highlightColor: color.withValues(alpha: 0.08),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// White clay circle housing a single icon (back arrows, settings cogs...).
class ClayIconButton extends StatelessWidget {
  const ClayIconButton({
    required this.icon,
    required this.onTap,
    this.tint = AppColors.blue,
    this.iconColor = AppColors.slate,
    super.key,
  });

  final IconData icon;
  final VoidCallback onTap;

  /// Shadow tint; match the screen's background tint.
  final Color tint;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: tint.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: iconColor),
          ),
        ),
      ),
    );
  }
}

/// Sub-screen header row: clay back button + Poppins title (+ optional
/// trailing widget). Replaces `AppBar` on pastel screens.
class ClayHeader extends StatelessWidget {
  const ClayHeader({
    required this.title,
    required this.tint,
    this.onBack,
    this.trailing,
    super.key,
  });

  final String title;
  final Color tint;

  /// Defaults to popping the current route.
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        ClayIconButton(
          icon: Icons.arrow_back_rounded,
          tint: tint,
          onTap: onBack ?? () => Navigator.of(context).maybePop(),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            title,
            style: clayTitle(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (trailing != null) ...<Widget>[
          const SizedBox(width: 8),
          trailing!,
        ],
      ],
    );
  }
}

/// Shared tactile call-to-action with a claymorphic bottom edge.
class ClayButton extends StatelessWidget {
  const ClayButton({
    required this.label,
    required this.onTap,
    this.color = AppColors.indigo,
    this.trailingIcon,
    super.key,
  });

  final String label;
  final VoidCallback onTap;
  final Color color;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final Color edge =
        Color.alphaBlend(AppColors.ink.withValues(alpha: 0.3), color);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: <BoxShadow>[
          BoxShadow(color: edge, offset: const Offset(0, 5)),
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          splashColor: Colors.white.withValues(alpha: 0.25),
          highlightColor: Colors.white.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 17),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  label,
                  style: GoogleFonts.nunito(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: Colors.white,
                  ),
                ),
                if (trailingIcon != null) ...<Widget>[
                  const SizedBox(width: 10),
                  Icon(trailingIcon, color: Colors.white, size: 22),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
