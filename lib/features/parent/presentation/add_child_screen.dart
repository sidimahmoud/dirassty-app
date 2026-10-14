import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/grade.dart';
import '../../../core/theme/dirassty_theme.dart';
import '../../../core/validation/validators.dart';
import '../../../core/widgets/dirassty/dirassty_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/widgets/auth_scaffold.dart';
import '../../auth/presentation/widgets/open_grade_picker.dart';
import '../../auth/presentation/widgets/pin_entry.dart';
import '../../courses/application/courses_providers.dart';
import '../application/parent_providers.dart';
import 'child_created_screen.dart';

/// "Ajouter un enfant" (step 1 of 2): first name, the class picker
/// (admin-saved class names, exam years marked), username and the child's
/// 4-digit PIN. Step 2 is [ChildCreatedScreen].
///
/// Deviations from AddChild.dc.html: no live "✓ Disponible" username
/// check (TODO(api): availability endpoint) — a taken name is reported
/// on submit; no avatar picker (the redesign uses initials everywhere).
///
/// design_handoff AddChild.dc.html · DESIGN_SPEC §4 "Parent space".
class AddChildScreen extends ConsumerStatefulWidget {
  const AddChildScreen({super.key});

  static const String path = '/parent/add-child';
  static const String name = 'addChild';

  @override
  ConsumerState<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends ConsumerState<AddChildScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  int _grade = 7;
  String _pin = '';
  String? _nameError;
  String? _usernameError;
  String? _pinError;
  String? _serverError;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String name = _nameController.text.trim();
    final String username = _usernameController.text.trim();
    setState(() {
      _nameError = name.isEmpty ? l10n.errChildNameRequired : null;
      _usernameError =
          isValidUsername(username) ? null : l10n.errUsernameFormat;
      _pinError = isValidPin(_pin) ? null : l10n.errPinFormat;
      _serverError = null;
    });
    final int? grade = openGradeOrNearest(
        _grade, selectableGrades(ref.read(activeGradeIdsProvider).valueOrNull));
    if (_nameError != null ||
        _usernameError != null ||
        _pinError != null ||
        grade == null) {
      return;
    }

    final ({String username, String studentId}) result =
        await ref.read(addChildControllerProvider.notifier).createChild(
              name: name,
              grade: grade,
              avatarId: 'avatar_1',
              username: username,
              pin: _pin,
            );
    if (!mounted) return;
    final AsyncValue<void> state = ref.read(addChildControllerProvider);
    if (state.hasError) {
      final String message = state.error.toString();
      setState(() {
        if (message.contains('username_taken')) {
          _usernameError = l10n.errUsernameTaken;
        } else if (message.contains('invalid_username')) {
          _usernameError = l10n.errUsernameFormat;
        } else if (message.contains("n'est pas active") ||
            message.contains('grade_inactive')) {
          ref.invalidate(activeGradeIdsProvider);
          _serverError = l10n.errGradeClosed;
        } else {
          _serverError = l10n.addChildError;
        }
      });
      return;
    }

    context.pushReplacement(
      ChildCreatedScreen.path,
      extra: ChildCreatedArgs(
        studentId: result.studentId,
        name: name,
        username: result.username,
        pin: _pin,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    final bool loading = ref.watch(addChildControllerProvider).isLoading;

    return AuthScaffold(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.stepOf(1, 2), style: type.label),
            const SizedBox(height: 10),
            const DirasstyProgressBar(value: 1 / 2),
          ],
        ),
        Text(l10n.addChild, style: type.title),
        DirasstyTextField(
          label: l10n.childFirstName,
          controller: _nameController,
          errorText: _nameError,
          textInputAction: TextInputAction.next,
        ),
        _buildGradePicker(l10n, type),
        DirasstyTextField(
          label: l10n.username,
          controller: _usernameController,
          forceLtr: true,
          errorText: _usernameError,
          hint: 'sidi.sow',
          onChanged: (value) {
            if (_usernameError != null && isValidUsername(value.trim())) {
              setState(() => _usernameError = null);
            }
          },
        ),
        PinField(
          label: l10n.childPinLabel,
          value: _pin,
          hint: l10n.childPinHint,
          errorText: _pinError,
          onChanged: (pin) => setState(() {
            _pin = pin;
            _pinError = null;
          }),
        ),
        if (_serverError != null)
          Text(_serverError!,
              style: type.label.copyWith(color: DirasstyColors.error)),
      ],
      bottom: [
        DirasstyButton(
          label: l10n.createChildAccount,
          loading: loading,
          onPressed: _submit,
        ),
      ],
    );
  }

  Widget _buildGradePicker(AppLocalizations l10n, DirasstyType type) {
    // Only classes an admin has opened, with their saved names (the card
    // marks the exam year); the server still rejects a closed one.
    return OpenGradePicker(
      label: l10n.childClass,
      grade: openGradeOrNearest(_grade,
          selectableGrades(ref.watch(activeGradeIdsProvider).valueOrNull)),
      onChanged: (g) => setState(() => _grade = g),
    );
  }
}
