import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/audio_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/clay_decor.dart';
import '../../../l10n/app_localizations.dart';
import '../data/learn_content.dart';
import '../view_model/learn_providers.dart';

const List<String> _kLetters = <String>[
  'A',
  'B',
  'C',
  'D',
  'E',
  'F',
  'G',
  'H',
  'I',
  'J',
  'K',
  'L',
  'M',
  'N',
  'O',
  'P',
  'Q',
  'R',
  'S',
  'T',
  'U',
  'V',
  'W',
  'X',
  'Y',
  'Z',
];

/// S· ABC Tutorial — swipe or tap through A–Z lessons.
class AbcTutorialScreen extends ConsumerStatefulWidget {
  const AbcTutorialScreen({super.key});

  @override
  ConsumerState<AbcTutorialScreen> createState() => _AbcTutorialScreenState();
}

class _AbcTutorialScreenState extends ConsumerState<AbcTutorialScreen> {
  late final PageController _controller;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const ClayBackground(tint: AppColors.teal),
          SafeArea(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: ClayHeader(title: l10n.abcTitle, tint: AppColors.teal),
                ),
                // Letter strip navigator
                SizedBox(
                  height: 44,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _kLetters.length,
                    itemBuilder: (BuildContext context, int i) {
                      final bool active = i == _currentIndex;
                      return GestureDetector(
                        onTap: () => _goTo(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 36,
                          height: 36,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 2,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                active ? AppColors.coral : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _kLetters[i],
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: active
                                  ? Colors.white
                                  : AppColors.dark.withValues(alpha: 0.5),
                              fontWeight:
                                  active ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _kLetters.length,
                    onPageChanged: (int i) => setState(() => _currentIndex = i),
                    itemBuilder: (BuildContext context, int i) {
                      final String letter = _kLetters[i];
                      final AsyncValue<AbcLesson> async =
                          ref.watch(abcLessonProvider(letter));
                      return async.when(
                        loading: () => const Center(
                          child:
                              CircularProgressIndicator(color: AppColors.teal),
                        ),
                        error: (_, __) => const Center(
                          child:
                              CircularProgressIndicator(color: AppColors.teal),
                        ),
                        data: (AbcLesson lesson) => _LessonPage(
                          lesson: lesson,
                          isActive: i == _currentIndex,
                        ),
                      );
                    },
                  ),
                ),
                // Prev / Next navigation
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      _NavButton(
                        label: l10n.prevLetter,
                        icon: Icons.arrow_back_rounded,
                        onTap: _currentIndex > 0
                            ? () => _goTo(_currentIndex - 1)
                            : null,
                        color: AppColors.coral,
                      ),
                      Text(
                        '${_currentIndex + 1} / ${_kLetters.length}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.dark.withValues(alpha: 0.5),
                        ),
                      ),
                      _NavButton(
                        label: l10n.nextLetter,
                        icon: Icons.arrow_forward_rounded,
                        trailingIcon: true,
                        onTap: _currentIndex < _kLetters.length - 1
                            ? () => _goTo(_currentIndex + 1)
                            : null,
                        color: AppColors.teal,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonPage extends ConsumerStatefulWidget {
  const _LessonPage({required this.lesson, required this.isActive});

  final AbcLesson lesson;

  /// True when this is the visible page, so we only speak the active letter.
  final bool isActive;

  @override
  ConsumerState<_LessonPage> createState() => _LessonPageState();
}

class _LessonPageState extends ConsumerState<_LessonPage> {
  @override
  void initState() {
    super.initState();
    if (widget.isActive) _speak();
  }

  @override
  void didUpdateWidget(_LessonPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Speak when this page slides into view (or its letter changes).
    if (widget.isActive &&
        (!oldWidget.isActive ||
            oldWidget.lesson.letter != widget.lesson.letter)) {
      _speak();
    }
  }

  void _speak() => ref.read(audioServiceProvider).speakLetter(widget.lesson);

  @override
  Widget build(BuildContext context) {
    final AbcLesson lesson = widget.lesson;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
      child: Column(
        children: <Widget>[
          // Giant letter
          Text(
            lesson.letter,
            style: const TextStyle(
              fontSize: 120,
              fontWeight: FontWeight.bold,
              color: AppColors.coral,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          // Word + emoji
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(lesson.emoji, style: const TextStyle(fontSize: 40)),
              const SizedBox(width: 12),
              Text(
                lesson.word,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.dark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Tap to hear "A for Apple" / "A — सेब" again.
          FilledButton.tonalIcon(
            onPressed: _speak,
            icon: const Icon(Icons.volume_up_rounded),
            label: Text(l10n.tapToHear),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.teal.withValues(alpha: 0.15),
              foregroundColor: AppColors.teal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Phonics chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.yellow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.yellow.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Text(
              lesson.phonics,
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.dark,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          // Mini story card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.teal.withValues(alpha: 0.16),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Text(
              lesson.miniStory,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.7),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.color,
    this.trailingIcon = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;
  final bool trailingIcon;

  @override
  Widget build(BuildContext context) {
    final Widget iconWidget = Icon(icon, size: 18);
    return FilledButton.tonal(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor:
            onTap != null ? color.withValues(alpha: 0.15) : AppColors.grey,
        foregroundColor:
            onTap != null ? color : AppColors.dark.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: trailingIcon
            ? <Widget>[
                Text(label),
                const SizedBox(width: 6),
                iconWidget,
              ]
            : <Widget>[
                iconWidget,
                const SizedBox(width: 6),
                Text(label),
              ],
      ),
    );
  }
}
