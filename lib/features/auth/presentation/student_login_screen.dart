import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/validation/validators.dart';
import '../../../core/widgets/dirassty/dirassty_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../application/auth_providers.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/pin_login_form.dart';

/// Student login: WhatsApp number + 4-digit PIN on the custom keypad
/// (migration 082, one number = one student). "J'ai un nom d'utilisateur"
/// switches to the username + PIN login — for accounts that have no number
/// yet (and the only login of app versions already in the stores). On
/// success the router's auth-redirect gate takes over — no explicit
/// navigation.
///
/// design_handoff StudentLogin.dc.html · DESIGN_SPEC §4 "Student login".
class StudentLoginScreen extends ConsumerStatefulWidget {
  const StudentLoginScreen({super.key});

  static const String path = '/login/student';
  static const String name = 'studentLogin';

  @override
  ConsumerState<StudentLoginScreen> createState() => _StudentLoginScreenState();
}

class _StudentLoginScreenState extends ConsumerState<StudentLoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _usePhone = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return PinLoginForm(
      limiterScope: 'student',
      heading: AuthHeading(
        title: l10n.studentLoginTitle,
        body: _usePhone ? l10n.studentPhoneLoginBody : l10n.studentLoginBody,
      ),
      identityField: _usePhone
          ? DirasstyTextField(
              key: const ValueKey<String>('phone'),
              label: l10n.whatsappNumber,
              controller: _phoneController,
              phonePrefix: true,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() {}),
            )
          : DirasstyTextField(
              key: const ValueKey<String>('username'),
              label: l10n.username,
              controller: _usernameController,
              forceLtr: true,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() {}),
            ),
      identityFilled: _usePhone
          ? isValidPhone(_phoneController.text)
          : _usernameController.text.trim().isNotEmpty,
      submitLabel: l10n.signIn,
      wrongCredentialsMessage: _usePhone
          ? l10n.wrongStudentPhoneCredentials
          : l10n.wrongStudentCredentials,
      errorMessage: (Object error) {
        final String m = error.toString();
        if (m.contains('phone_not_found')) return l10n.errStudentPhoneNotFound;
        if (m.contains('too_many_attempts')) {
          return l10n.errLoginTooManyAttempts;
        }
        return null;
      },
      lockedHint: l10n.askParentForPin,
      onSubmit: (pin) => _usePhone
          ? ref.read(authControllerProvider.notifier).signInStudentWithPhone(
                phone: _phoneController.text.trim(),
                pin: pin,
              )
          : ref.read(authControllerProvider.notifier).signInStudent(
                username: _usernameController.text.trim(),
                pin: pin,
              ),
      onForgotPin: () => showDirasstyDialog<void>(
        context,
        icon: Icons.lock_reset_rounded,
        title: l10n.forgotPinStudentTitle,
        message: l10n.forgotPinStudentBody,
        actions: [DirasstyDialogAction(label: l10n.ok)],
      ),
      footer: Center(
        child: TextButton(
          onPressed: () => setState(() => _usePhone = !_usePhone),
          child: Text(_usePhone ? l10n.loginWithUsername : l10n.loginWithPhone),
        ),
      ),
    );
  }
}
