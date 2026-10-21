import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/app_analytics.dart';
import '../../../core/theme/dirassty_theme.dart';
import '../../../core/widgets/dirassty/dirassty_widgets.dart';
import '../../../l10n/app_localizations.dart';

/// Upper-case letters, digits, - and _ only (what promo codes are made of).
final List<TextInputFormatter> promoCodeFormatters = [
  FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9_-]')),
  LengthLimitingTextInputFormatter(30),
  TextInputFormatter.withFunction(
    (_, v) => v.copyWith(text: v.text.toUpperCase()),
  ),
];

/// "J'ai un code promo" at payment: collapsed link → field + Valider,
/// checked right away (`apply_promo_code`, context "payment"). Tracking
/// only — it attributes the account to an influencer, no discount.
class PromoCodeField extends ConsumerStatefulWidget {
  const PromoCodeField({super.key});

  @override
  ConsumerState<PromoCodeField> createState() => _PromoCodeFieldState();
}

class _PromoCodeFieldState extends ConsumerState<PromoCodeField> {
  final TextEditingController _controller = TextEditingController();
  bool _open = false;
  bool _busy = false;
  String? _success;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
      _success = null;
    });
    final String? influencer = await ref
        .read(appAnalyticsProvider)
        .applyPromoCode(_controller.text, context: 'payment');
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (influencer == null) {
        _error = l10n.promoUnknown;
      } else {
        _success = l10n.promoApplied(influencer);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    if (!_open) {
      return Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton.icon(
          onPressed: () => setState(() => _open = true),
          icon: const Icon(Icons.local_offer_outlined, size: 18),
          label: Text(l10n.promoHaveCode),
          style: TextButton.styleFrom(foregroundColor: DirasstyColors.tealDark),
        ),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: DirasstyTextField(
            label: l10n.promoCodeOptional,
            controller: _controller,
            hint: 'AMINA10',
            forceLtr: true,
            inputFormatters: promoCodeFormatters,
            errorText: _error,
            successText: _success,
            enabled: _success == null,
            onSubmitted: (_) => _apply(),
          ),
        ),
        const SizedBox(width: DirasstySpace.sm),
        Padding(
          padding: const EdgeInsetsDirectional.only(top: 24),
          child: DirasstyButton(
            label: l10n.promoApply,
            compact: true,
            expand: false,
            loading: _busy,
            onPressed: _success != null ? null : _apply,
          ),
        ),
      ],
    );
  }
}
