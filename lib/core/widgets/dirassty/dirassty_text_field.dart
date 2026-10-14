import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/dirassty_theme.dart';
import 'dirassty_context.dart';

/// Label (14/600) above a 52 px field with a 1.5 px line border — teal on
/// focus, red on error with a red 12/600 hint below; [successText] shows
/// a teal hint instead (e.g. "✓ Disponible").
///
/// [phonePrefix] adds the fixed "+222" prefix on ivory, and a phone field
/// is always laid out LTR (digits never mirror).
///
/// DESIGN_SPEC.md §2 "DirasstyTextField".
class DirasstyTextField extends StatelessWidget {
  const DirasstyTextField({
    required this.label,
    super.key,
    this.controller,
    this.hint,
    this.errorText,
    this.successText,
    this.helperText,
    this.phonePrefix = false,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.obscureText = false,
    this.maxLength,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.enabled = true,
    this.forceLtr = false,
    this.suffix,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? errorText;
  final String? successText;

  /// Plain muted hint under the field, shown when there's no error or
  /// success hint (e.g. "Pour recevoir ton code de vérification").
  final String? helperText;
  final bool phonePrefix;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final bool enabled;

  /// Lay the field out LTR even in Arabic — usernames, codes, math.
  final bool forceLtr;
  final Widget? suffix;

  static const String _countryCode = '+222';

  @override
  Widget build(BuildContext context) {
    final DirasstyType type = context.dirasstyType;
    final bool hasError = errorText != null && errorText!.isNotEmpty;
    final bool hasSuccess =
        !hasError && successText != null && successText!.isNotEmpty;
    final bool hasHelper = !hasError &&
        !hasSuccess &&
        helperText != null &&
        helperText!.isNotEmpty;

    Widget field = TextField(
      controller: controller,
      keyboardType: phonePrefix ? TextInputType.phone : keyboardType,
      textInputAction: textInputAction,
      inputFormatters: phonePrefix
          ? [FilteringTextInputFormatter.digitsOnly, ...?inputFormatters]
          : inputFormatters,
      obscureText: obscureText,
      maxLength: maxLength,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      autofocus: autofocus,
      enabled: enabled,
      style: type.body,
      decoration: InputDecoration(
        hintText: hint,
        counterText: '',
        // Error text is drawn below by this widget (so success can share
        // the same slot) — only flip the border here.
        errorText: hasError ? '' : null,
        errorStyle: const TextStyle(height: 0, fontSize: 0),
        suffixIcon: suffix,
        prefixIcon: phonePrefix ? const _PhonePrefix() : null,
        prefixIconConstraints: const BoxConstraints(minHeight: DirasstySize.input),
        constraints: const BoxConstraints(minHeight: DirasstySize.input),
      ),
    );
    if (phonePrefix || forceLtr) {
      field = Directionality(textDirection: TextDirection.ltr, child: field);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: type.label.copyWith(fontSize: 14, color: DirasstyColors.text),
        ),
        const SizedBox(height: DirasstySpace.sm),
        field,
        if (hasError || hasSuccess) ...[
          const SizedBox(height: 6),
          Text(
            hasError ? errorText! : successText!,
            style: type.label.copyWith(
              color: hasError ? DirasstyColors.error : DirasstyColors.teal,
            ),
          ),
        ],
        if (hasHelper) ...[
          const SizedBox(height: 6),
          Text(helperText!, style: type.label),
        ],
      ],
    );
  }
}

class _PhonePrefix extends StatelessWidget {
  const _PhonePrefix();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsetsDirectional.only(
          start: 1.5, top: 1.5, bottom: 1.5, end: DirasstySpace.md),
      padding: const EdgeInsetsDirectional.symmetric(horizontal: DirasstySpace.md),
      decoration: const BoxDecoration(
        color: DirasstyColors.ivory,
        borderRadius: BorderRadiusDirectional.horizontal(
          start: Radius.circular(DirasstyRadius.card - 1.5),
        ),
        border: BorderDirectional(
            end: BorderSide(color: DirasstyColors.line, width: 1.5)),
      ),
      // widthFactor: 1 — size to the "+222" text. A plain `alignment`
      // here made the box expand to the field's full width, leaving the
      // input itself zero-wide (nothing typed was visible).
      child: Center(
        widthFactor: 1,
        child: Text(
          DirasstyTextField._countryCode,
          style: context.dirasstyType.subheading,
        ),
      ),
    );
  }
}
