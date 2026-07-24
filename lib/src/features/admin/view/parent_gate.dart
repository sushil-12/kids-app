import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/clay_decor.dart';
import '../../../l10n/app_localizations.dart';

/// Shows the parent gate (a simple math question) and resolves to `true` only
/// when answered correctly. Used to guard grown-up-only areas (CLAUDE.md §7).
///
/// Returns `false` if dismissed/cancelled.
Future<bool> showParentGate(BuildContext context) async {
  final bool? ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext _) => const _ParentGateDialog(),
  );
  return ok ?? false;
}

class _ParentGateDialog extends StatefulWidget {
  const _ParentGateDialog();

  @override
  State<_ParentGateDialog> createState() => _ParentGateDialogState();
}

class _ParentGateDialogState extends State<_ParentGateDialog> {
  final TextEditingController _controller = TextEditingController();
  final Random _random = Random();
  late int _a;
  late int _b;
  bool _wrong = false;

  @override
  void initState() {
    super.initState();
    _newQuestion();
  }

  void _newQuestion() {
    // Single-digit sums keep it adult-trivial but child-resistant.
    _a = 2 + _random.nextInt(7);
    _b = 2 + _random.nextInt(7);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final int? answer = int.tryParse(_controller.text.trim());
    if (answer == _a + _b) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _wrong = true;
      _controller.clear();
      _newQuestion();
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    // Clay dialog: white panel with an indigo tinted shadow (grown-up accent).
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: const BorderSide(color: Colors.white, width: 2.5),
      ),
      title: Text(l10n.parentGateTitle, style: clayTitle(fontSize: 20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.parentGateInstruction(_a, _b),
            style: clayBody(fontSize: 15, color: AppColors.ink),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              errorText: _wrong ? l10n.parentGateWrong : null,
              filled: true,
              fillColor: pastelOf(AppColors.indigo, 0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: AppColors.indigo.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: AppColors.indigo.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.indigo, width: 2),
              ),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            l10n.cancel,
            style: clayBody(fontSize: 14),
          ),
        ),
        ClayButton(
          label: l10n.parentGateContinue,
          onTap: _submit,
        ),
      ],
    );
  }
}
