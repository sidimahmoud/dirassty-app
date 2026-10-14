import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/actions/app_promotion_actions.dart';
import '../../../core/analytics/app_analytics.dart';
import '../../../core/i18n/app_language_provider.dart';
import '../../../core/models/grade.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/dirassty_theme.dart';
import '../../../core/validation/validators.dart';
import '../../../core/widgets/dirassty/dirassty_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../parent/presentation/add_child_screen.dart';
import '../../subscription/application/subscription_providers.dart';
import '../../courses/application/courses_providers.dart';
import '../../marketing/presentation/promo_code_field.dart';
import '../application/auth_providers.dart';
import 'choose_class_screen.dart';
import 'trial_offer_screen.dart';
import 'widgets/auth_errors.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/open_grade_picker.dart';
import 'widgets/pin_entry.dart';

/// Self-registration for a parent or a student (role switchable on the
/// screen, [role] is only the initial selection).
///
/// WhatsApp OTP is switched OFF for now ([_otpVerificationEnabled]) —
/// until a paid Twilio WhatsApp sender exists, every registration goes
/// straight through `register-direct` (parent and student). The OTP flow
/// below is kept intact; flip the flag back to `true` to restore it.
///
/// Flow when OTP is enabled, restyled to the design:
/// - A parent's phone IS their login identity, so it's always verified
///   by WhatsApp OTP (`request-otp` → `verify-otp`), then they land on
///   Add child (DESIGN_SPEC §4 "Register › Parent").
/// - A student's phone is optional (notifications only; they log in with
///   username + PIN). With a phone it's verified the same way; without
///   one, registration goes straight through `register-direct`. Either
///   way they then see the trial offer.
///
/// Deviations from Register.dc.html (backend gaps):
/// - No live "✓ Disponible" username check — there's no endpoint for it
///   yet (TODO(api)); the format is checked as you type and a taken name
///   is reported by the server on submit.
/// - The checkbox accepts the privacy policy (no separate terms page);
///   the link opens dirassty.vercel.app/confidentialite.
///
/// design_handoff Register.dc.html + VerifyCode.dc.html.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({required this.role, this.initialGrade, super.key});

  /// 'parent' | 'student'.
  final String role;

  /// The class picked on [ChooseClassScreen] (step 1 of a student sign-up).
  final int? initialGrade;

  static const String path = '/register/:role';
  static const String name = 'register';

  static String pathFor(String role) => '/register/$role';

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _promoController = TextEditingController();

  late final bool _isStudent = widget.role != 'parent';
  late int _grade = widget.initialGrade ?? 10;
  bool _showPromo = false;
  String _pin = '';
  bool _termsAccepted = false;

  String? _nameError;
  String? _usernameError;
  String? _phoneError;
  String? _pinError;
  String? _termsError;
  String? _serverError;

  /// True once `request-otp` has sent a code — the screen switches to
  /// the code step. Never set for a student who left the phone blank.
  bool _codeRequested = false;
  String? _codeError;
  Timer? _resendTimer;
  int _resendSecondsLeft = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _promoController.dispose();
    _phoneController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  AppLocalizations get _l10n => AppLocalizations.of(context);

  /// The chosen grade if it's open for registration, else the nearest open
  /// one (see [OpenGradePicker]); null when no grade is open.
  int? get _openGrade => openGradeOrNearest(
      _grade,
      selectableGrades(ref.read(activeGradeIdsProvider).valueOrNull,
          minGrade: kMinSelfSignupGrade));

  /// WhatsApp phone verification at registration. Off until the Twilio
  /// WhatsApp sender is a paid (non-sandbox) number.
  static const bool _otpVerificationEnabled = false;

  /// A parent always verifies (phone required); a student only when they
  /// typed a phone in. Never while [_otpVerificationEnabled] is off.
  bool get _needsOtp =>
      _otpVerificationEnabled &&
      (!_isStudent || _phoneController.text.trim().isNotEmpty);

  /// Mirrors the backend's 60 s RESEND_COOLDOWN_MS (request-otp) — a UX
  /// countdown only, enforcement is server-side.
  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(() => _resendSecondsLeft = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _resendSecondsLeft--);
      if (_resendSecondsLeft <= 0) timer.cancel();
    });
  }

  bool _validate() {
    final AppLocalizations l10n = _l10n;
    setState(() {
      _nameError =
          _nameController.text.trim().isEmpty ? l10n.errNameRequired : null;
      _usernameError =
          _isStudent && !isValidUsername(_usernameController.text.trim())
              ? l10n.errUsernameFormat
              : null;
      _phoneError = !_isStudent && _phoneController.text.trim().isEmpty
          ? l10n.errPhoneRequired
          : null;
      _pinError = isValidPin(_pin) ? null : l10n.errPinFormat;
      _termsError = _termsAccepted ? null : l10n.errTermsRequired;
      _serverError = null;
    });
    return [_nameError, _usernameError, _phoneError, _pinError, _termsError]
            .every((e) => e == null) &&
        (!_isStudent || _openGrade != null);
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    if (_needsOtp) {
      await _requestCode();
    } else {
      await _registerDirect();
    }
  }

  Map<String, dynamic> get _metadata => {
        'name': _nameController.text.trim(),
        'lang': ref.read(appLanguageProvider).dbValue,
        if (_isStudent) 'grade': _openGrade,
        if (_isStudent)
          'username': _usernameController.text.trim().toLowerCase(),
      };

  Future<void> _requestCode() async {
    await ref.read(authControllerProvider.notifier).requestOtp(
          phone: _phoneController.text.trim(),
          role: _isStudent ? 'student' : 'parent',
          metadata: _metadata,
        );
    if (!mounted) return;
    final AsyncValue<void> result = ref.read(authControllerProvider);
    if (result.hasError) {
      setState(() => _serverError = authErrorMessage(_l10n, result.error!));
      return;
    }
    setState(() {
      _codeRequested = true;
      _codeError = null;
    });
    _startResendCooldown();
  }

  Future<void> _verifyCode(String code) async {
    await ref.read(authControllerProvider.notifier).verifyOtpAndRegister(
          phone: _phoneController.text.trim(),
          role: _isStudent ? 'student' : 'parent',
          code: code,
          pin: _pin,
        );
    if (!mounted) return;
    final AsyncValue<void> result = ref.read(authControllerProvider);
    if (result.hasError) {
      setState(() => _codeError = authErrorMessage(_l10n, result.error!));
      return;
    }
    await _afterRegistered();
  }

  Future<void> _registerDirect() async {
    await ref.read(authControllerProvider.notifier).registerDirect(
          role: _isStudent ? 'student' : 'parent',
          name: _nameController.text.trim(),
          lang: ref.read(appLanguageProvider).dbValue,
          pin: _pin,
          phone: _phoneController.text.trim(),
          grade: _isStudent ? _openGrade : null,
          username: _isStudent ? _usernameController.text.trim() : null,
        );
    if (!mounted) return;
    final AsyncValue<void> result = ref.read(authControllerProvider);
    if (result.hasError) {
      // A grade closed while the form was open: reload the open grades.
      if (result.error.toString().contains('grade_inactive')) {
        ref.invalidate(activeGradeIdsProvider);
      }
      setState(() => _serverError = authErrorMessage(_l10n, result.error!));
      return;
    }
    await _afterRegistered();
  }

  /// Signed in by now. Navigates through the router instance, not this
  /// screen's context: the auth-state change can redirect away (and
  /// unmount this screen) before these awaits finish.
  Future<void> _afterRegistered() async {
    final router = ref.read(goRouterProvider);
    // Optional influencer / promo code — attribution only, never blocks.
    unawaited(ref
        .read(appAnalyticsProvider)
        .applyPromoCode(_promoController.text, context: 'signup'));
    if (!_isStudent) {
      router.go(AddChildScreen.path);
      return;
    }
    await ref
        .read(postRegistrationTrialControllerProvider.notifier)
        .grantTrialIfEnabled();
    router.go(TrialOfferScreen.path);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool loading = ref.watch(authControllerProvider).isLoading;

    if (_codeRequested) {
      return VerifyCodeView(
        phoneDisplay: formatMauritanianPhone(_phoneController.text),
        loading: loading,
        errorText: _codeError,
        resendSecondsLeft: _resendSecondsLeft,
        onVerify: _verifyCode,
        onResend: _requestCode,
        onChangeNumber: () => setState(() => _codeRequested = false),
      );
    }

    final DirasstyType type = context.dirasstyType;
    return AuthScaffold(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.stepOf(_isStudent ? 2 : 1, 3), style: type.label),
            const SizedBox(height: 10),
            DirasstyProgressBar(value: (_isStudent ? 2 : 1) / 3),
          ],
        ),
        AuthHeading(
          title: l10n.registerTitle,
          body: _isStudent ? l10n.registerBody : l10n.registerParentBody,
        ),
        DirasstyTextField(
          label: l10n.fullName,
          controller: _nameController,
          errorText: _nameError,
          textInputAction: TextInputAction.next,
        ),
        if (_isStudent) _buildGradePicker(l10n, type),
        DirasstyTextField(
          label: l10n.whatsappNumber,
          controller: _phoneController,
          phonePrefix: true,
          errorText: _phoneError,
          helperText:
              _isStudent ? l10n.phoneHintOptional : l10n.phoneHintVerify,
          onChanged: (_) => setState(() {}),
        ),
        if (_isStudent)
          DirasstyTextField(
            label: l10n.username,
            controller: _usernameController,
            forceLtr: true,
            errorText: _usernameError,
            hint: 'amina.b',
            onChanged: (value) {
              if (_usernameError != null && isValidUsername(value.trim())) {
                setState(() => _usernameError = null);
              }
            },
          ),
        PinField(
          label: l10n.choosePin,
          value: _pin,
          hint: l10n.pinHint,
          errorText: _pinError,
          onChanged: (pin) => setState(() {
            _pin = pin;
            _pinError = null;
          }),
        ),
        // Optional, so folded away to keep the form short.
        if (_showPromo)
          DirasstyTextField(
            label: l10n.promoCodeOptional,
            controller: _promoController,
            hint: 'AMINA10',
            forceLtr: true,
            inputFormatters: promoCodeFormatters,
          )
        else
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () => setState(() => _showPromo = true),
              icon: const Icon(Icons.local_offer_outlined, size: 18),
              label: Text(l10n.havePromoCode),
              style: TextButton.styleFrom(
                  foregroundColor: DirasstyColors.teal,
                  visualDensity: VisualDensity.compact),
            ),
          ),
        _TermsCheckbox(
          accepted: _termsAccepted,
          label: l10n.acceptTerms,
          linkLabel: l10n.privacyPolicy,
          onOpenLink: () => openPrivacyPolicy(context),
          errorText: _termsError,
          onChanged: (v) => setState(() {
            _termsAccepted = v;
            _termsError = null;
          }),
        ),
        if (_serverError != null)
          Text(_serverError!,
              style: type.label.copyWith(color: DirasstyColors.error)),
      ],
      bottom: [
        DirasstyButton(
          label: _needsOtp ? l10n.getWhatsappCode : l10n.createMyAccount,
          icon: _needsOtp ? Icons.chat_rounded : null,
          loading: loading,
          onPressed: _submit,
        ),
      ],
    );
  }

  /// The class chosen on step 1, as one line with "Modifier" (back to
  /// [ChooseClassScreen]) — the cards themselves live on that screen.
  Widget _buildGradePicker(AppLocalizations l10n, DirasstyType type) {
    final int? grade = _openGrade;
    return Material(
      color: DirasstyColors.tealTint,
      shape: const RoundedRectangleBorder(borderRadius: DirasstyRadius.cardR),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.canPop()
            ? context.pop()
            : context.go(ChooseClassScreen.path),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
              horizontal: DirasstySpace.lg, vertical: DirasstySpace.md),
          child: Row(
            children: [
              const Icon(Icons.school_rounded, color: DirasstyColors.teal),
              const SizedBox(width: DirasstySpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.myGrade, style: type.label),
                    Text(
                      grade == null ? '—' : gradeName(ref, grade),
                      style: type.subheading.copyWith(
                          fontSize: 15, color: DirasstyColors.tealDark),
                    ),
                  ],
                ),
              ),
              Text(l10n.changeClass,
                  style: type.label.copyWith(color: DirasstyColors.teal)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({
    required this.accepted,
    required this.linkLabel,
    required this.onOpenLink,
    required this.label,
    required this.onChanged,
    this.errorText,
  });

  final bool accepted;
  final String label;

  /// "Read the privacy policy" link under the checkbox.
  final String linkLabel;
  final VoidCallback onOpenLink;
  final ValueChanged<bool> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final DirasstyType type = context.dirasstyType;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          checked: accepted,
          child: InkWell(
            onTap: () => onChanged(!accepted),
            borderRadius: DirasstyRadius.smallR,
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(minHeight: DirasstySize.minTouch),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: context.reduceMotion
                        ? Duration.zero
                        : DirasstyMotion.fast,
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: accepted
                          ? DirasstyColors.teal
                          : DirasstyColors.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: accepted
                          ? null
                          : Border.all(
                              color: errorText != null
                                  ? DirasstyColors.error
                                  : DirasstyColors.line,
                              width: 1.5),
                    ),
                    child: accepted
                        ? const Icon(Icons.check_rounded,
                            size: 18, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: DirasstySpace.md),
                  Expanded(
                      child: Text(label,
                          style: type.bodySmall
                              .copyWith(color: DirasstyColors.text))),
                ],
              ),
            ),
          ),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: onOpenLink,
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: Text(linkLabel),
            style: TextButton.styleFrom(
                foregroundColor: DirasstyColors.teal,
                visualDensity: VisualDensity.compact),
          ),
        ),
        if (errorText != null)
          Text(errorText!,
              style: type.label.copyWith(color: DirasstyColors.error)),
      ],
    );
  }
}
