import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/dirassty/dirassty_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../application/auth_providers.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/pin_login_form.dart';

/// Student login: username + 4-digit PIN on the custom keypad (the
/// username/PIN a parent created, or the student's own). On success the
/// router's auth-redirect gate takes over — no explicit navigation.
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

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return PinLoginForm(
      limiterScope: 'student',
      heading: AuthHeading(
        title: l10n.studentLoginTitle,
        body: l10n.studentLoginBody,
      ),
      identityField: DirasstyTextField(
        label: l10n.username,
        controller: _usernameController,
        forceLtr: true,
        textInputAction: TextInputAction.done,
        onChanged: (_) => setState(() {}),
      ),
      identityFilled: _usernameController.text.trim().isNotEmpty,
      submitLabel: l10n.signIn,
      wrongCredentialsMessage: l10n.wrongStudentCredentials,
      lockedHint: l10n.askParentForPin,
      onSubmit: (pin) => ref
          .read(authControllerProvider.notifier)
          .signInStudent(username: _usernameController.text.trim(), pin: pin),
      onForgotPin: () => showDirasstyDialog<void>(
        context,
        icon: Icons.lock_reset_rounded,
        title: l10n.forgotPinStudentTitle,
        message: l10n.forgotPinStudentBody,
        actions: [DirasstyDialogAction(label: l10n.ok)],
      ),
    );
  }
}
