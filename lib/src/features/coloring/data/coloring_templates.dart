import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'coloring_template.dart';

/// All bundled coloring pictures. Authored in a 100x100 viewBox.
/// Original vector art — no third-party/copyrighted assets.
final List<ColoringTemplate> kColoringTemplates = <ColoringTemplate>[
  _sun(),
  _fish(),
  _flower(),
  _house(),
];

ColoringTemplate? templateById(String id) {
  for (final ColoringTemplate t in kColoringTemplates) {
    if (t.id == id) return t;
  }
  return kColoringTemplates.isEmpty ? null : kColoringTemplates.first;
}

// ---------- helpers ----------

Path _circle(double cx, double cy, double r) =>
    Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));

Path _triangle(Offset a, Offset b, Offset c) => Path()
  ..moveTo(a.dx, a.dy)
  ..lineTo(b.dx, b.dy)
  ..lineTo(c.dx, c.dy)
  ..close();

Path _rect(double l, double t, double w, double h) =>
    Path()..addRect(Rect.fromLTWH(l, t, w, h));

Path _fullBackground() => _rect(0, 0, 100, 100);

// ---------- SUN ----------

ColoringTemplate _sun() {
  const double cx = 50, cy = 47;
  final Path rays = Path();
  const int n = 12;
  for (int i = 0; i < n; i++) {
    final double a = (i / n) * 2 * math.pi;
    final Offset tip = Offset(cx + 42 * math.cos(a), cy + 42 * math.sin(a));
    final Offset b1 = Offset(cx + 26 * math.cos(a - 0.14), cy + 26 * math.sin(a - 0.14));
    final Offset b2 = Offset(cx + 26 * math.cos(a + 0.14), cy + 26 * math.sin(a + 0.14));
    rays
      ..moveTo(b1.dx, b1.dy)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo(b2.dx, b2.dy)
      ..close();
  }
  final Path body = _circle(cx, cy, 24);
  final Path smile = Path()
    ..addArc(Rect.fromCircle(center: const Offset(cx, cy + 2), radius: 12),
        0.25 * math.pi, 0.5 * math.pi);

  return ColoringTemplate(
    id: 'sun',
    title: 'Happy Sun',
    viewBox: 100,
    stickerRewardId: 'sun',
    regions: <ColorRegion>[
      ColorRegion(id: 'sky', path: _fullBackground()),
      ColorRegion(id: 'rays', path: rays),
      ColorRegion(id: 'body', path: body),
    ],
    outlines: <Path>[body, rays, smile],
    details: <Path>[
      _circle(cx - 8, cy - 3, 2.4),
      _circle(cx + 8, cy - 3, 2.4),
    ],
    byNumber: <String, int>{'sky': 5, 'rays': 2, 'body': 1},
  );
}

// ---------- FISH ----------

ColoringTemplate _fish() {
  final Path body = Path()
    ..addOval(Rect.fromCenter(center: const Offset(54, 52), width: 50, height: 32));
  final Path tail = _triangle(const Offset(34, 52), const Offset(14, 38), const Offset(14, 66));
  final Path fin = _triangle(const Offset(54, 38), const Offset(44, 24), const Offset(66, 32));
  final Path eyeWhite = _circle(68, 46, 5);
  final Path mouth = Path()
    ..addArc(Rect.fromCircle(center: const Offset(76, 54), radius: 5),
        1.1 * math.pi, 0.8 * math.pi);
  final Path bubbles = Path()
    ..addOval(Rect.fromCircle(center: const Offset(84, 36), radius: 3))
    ..addOval(Rect.fromCircle(center: const Offset(90, 28), radius: 2));

  return ColoringTemplate(
    id: 'fish',
    title: 'Splashy Fish',
    viewBox: 100,
    stickerRewardId: 'fish',
    regions: <ColorRegion>[
      ColorRegion(id: 'water', path: _fullBackground()),
      ColorRegion(id: 'tail', path: tail),
      ColorRegion(id: 'fin', path: fin),
      ColorRegion(id: 'body', path: body),
      ColorRegion(id: 'eye', path: eyeWhite),
    ],
    outlines: <Path>[body, tail, fin, eyeWhite, mouth, bubbles],
    details: <Path>[_circle(69, 46, 2.2)],
    byNumber: <String, int>{
      'water': 5,
      'tail': 2,
      'fin': 1,
      'body': 3,
      'eye': 6,
    },
  );
}

// ---------- FLOWER ----------

ColoringTemplate _flower() {
  const double cx = 50, cy = 38;
  final Path petals = Path();
  for (int i = 0; i < 6; i++) {
    final double a = (i / 6) * 2 * math.pi;
    petals.addOval(
      Rect.fromCircle(center: Offset(cx + 15 * math.cos(a), cy + 15 * math.sin(a)), radius: 9),
    );
  }
  final Path center = _circle(cx, cy, 10);
  final Path stem = Path()
    ..moveTo(47, 48)
    ..lineTo(47, 92)
    ..lineTo(53, 92)
    ..lineTo(53, 48)
    ..close();
  final Path leftLeaf = Path()
    ..addOval(Rect.fromCenter(center: const Offset(36, 70), width: 22, height: 12));
  final Path rightLeaf = Path()
    ..addOval(Rect.fromCenter(center: const Offset(64, 78), width: 22, height: 12));

  return ColoringTemplate(
    id: 'flower',
    title: 'Sunny Flower',
    viewBox: 100,
    isPremium: true,
    stickerRewardId: 'flower',
    regions: <ColorRegion>[
      ColorRegion(id: 'sky', path: _fullBackground()),
      ColorRegion(id: 'stem', path: stem),
      ColorRegion(id: 'leftLeaf', path: leftLeaf),
      ColorRegion(id: 'rightLeaf', path: rightLeaf),
      ColorRegion(id: 'petals', path: petals),
      ColorRegion(id: 'center', path: center),
    ],
    outlines: <Path>[petals, center, stem, leftLeaf, rightLeaf],
    byNumber: <String, int>{
      'sky': 5,
      'stem': 4,
      'leftLeaf': 4,
      'rightLeaf': 4,
      'petals': 2,
      'center': 1,
    },
  );
}

// ---------- HOUSE ----------

ColoringTemplate _house() {
  final Path wall = _rect(28, 48, 44, 40);
  final Path roof = _triangle(const Offset(22, 48), const Offset(78, 48), const Offset(50, 22));
  final Path door = _rect(44, 68, 12, 20);
  final Path win1 = _rect(33, 54, 10, 10);
  final Path win2 = _rect(57, 54, 10, 10);
  final Path sun = _circle(84, 18, 9);

  return ColoringTemplate(
    id: 'house',
    title: 'Cozy House',
    viewBox: 100,
    isPremium: true,
    stickerRewardId: 'house',
    regions: <ColorRegion>[
      ColorRegion(id: 'sky', path: _fullBackground()),
      ColorRegion(id: 'sun', path: sun),
      ColorRegion(id: 'wall', path: wall),
      ColorRegion(id: 'roof', path: roof),
      ColorRegion(id: 'door', path: door),
      ColorRegion(id: 'win1', path: win1),
      ColorRegion(id: 'win2', path: win2),
    ],
    outlines: <Path>[wall, roof, door, win1, win2, sun],
    details: <Path>[_circle(54, 79, 1.4)],
    byNumber: <String, int>{
      'sky': 5,
      'sun': 1,
      'wall': 4,
      'roof': 2,
      'door': 3,
      'win1': 6,
      'win2': 6,
    },
  );
}
