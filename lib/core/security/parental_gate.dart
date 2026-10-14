import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/app_auth_state.dart';
import '../../features/auth/application/auth_providers.dart';
import '../../l10n/app_localizations.dart';
import '../theme/dirassty_theme.dart';
import '../widgets/dirassty/dirassty_widgets.dart';

/// Parental gate (App Store 1.3 / Play Families): before a student leaves
/// the app (WhatsApp, store, share) or starts a payment, an adult answers
/// a multiplication. Parents pass straight through. Returns true when the
/// action may go ahead.
Future<bool> passParentalGate(BuildContext context) async {
  final AppAuthState? auth = ProviderScope.containerOf(context, listen: false)
      .read(appAuthStateProvider)
      .valueOrNull;
  if (auth is! AppAuthStudent) return true;
  final bool? ok = await showDialog<bool>(
    context: context,
    builder: (_) => const _ParentalGateDialog(),
  );
  return ok ?? false;
}

class _ParentalGateDialog extends StatefulWidget {
  const _ParentalGateDialog();

  @override
  State<_ParentalGateDialog> createState() => _ParentalGateDialogState();
}

class _ParentalGateDialogState extends State<_ParentalGateDialog> {
  final Random _random = Random();
  final TextEditingController _answer = TextEditingController();
  late int _a = 6 + _random.nextInt(4);
  late int _b = 6 + _random.nextInt(4);
  bool _wrong = false;

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  void _check() {
    if (int.tryParse(_answer.text.trim()) == _a * _b) {
      Navigator.of(context).pop(true);
      return;
    }
    // A new question after each miss, so guessing doesn't work.
    setState(() {
      _wrong = true;
      _a = 6 + _random.nextInt(4);
      _b = 6 + _random.nextInt(4);
      _answer.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    return AlertDialog(
      title: Text(l10n.parentGateTitle, style: type.titleSmall),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.parentGateBody(_a, _b), style: type.bodySmall),
          const SizedBox(height: DirasstySpace.md),
          TextField(
            controller: _answer,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 3,
            onSubmitted: (_) => _check(),
            decoration: InputDecoration(
              counterText: '',
              errorText: _wrong ? l10n.parentGateWrong : null,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _check,
          style: FilledButton.styleFrom(backgroundColor: DirasstyColors.teal),
          child: Text(l10n.parentGateConfirm),
        ),
      ],
    );
  }
}
