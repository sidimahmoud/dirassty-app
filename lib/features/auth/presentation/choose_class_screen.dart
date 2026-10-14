import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/grade.dart';
import '../../../core/theme/dirassty_theme.dart';
import '../../../core/widgets/dirassty/dirassty_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../courses/application/courses_providers.dart';
import 'register_screen.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/open_grade_picker.dart';

/// Student sign-up, step 1: "Tu es en quelle classe ?" — the class cards
/// on their own screen (admin-saved names, C2 and up), so the form that
/// follows ([RegisterScreen], step 2) stays short. The chosen class goes
/// to the form as `?grade=`.
class ChooseClassScreen extends ConsumerStatefulWidget {
  const ChooseClassScreen({super.key});

  static const String path = '/signup/class';
  static const String name = 'chooseClass';

  @override
  ConsumerState<ChooseClassScreen> createState() => _ChooseClassScreenState();
}

class _ChooseClassScreenState extends ConsumerState<ChooseClassScreen> {
  /// Starts on the exam year of collège (the likeliest sign-up); snapped to
  /// the nearest open class once the list is known.
  int _grade = 10;

  int? get _openGrade => openGradeOrNearest(
      _grade,
      selectableGrades(ref.watch(activeGradeIdsProvider).valueOrNull,
          minGrade: kMinSelfSignupGrade));

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    final int? grade = _openGrade;
    final bool loaded = ref.watch(openGradesProvider).hasValue;

    return AuthScaffold(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.stepOf(1, 3), style: type.label),
            const SizedBox(height: 10),
            const DirasstyProgressBar(value: 1 / 3),
          ],
        ),
        AuthHeading(title: l10n.chooseClassTitle, body: l10n.chooseClassBody),
        OpenGradePicker(
          label: l10n.myGrade,
          grade: grade,
          minGrade: kMinSelfSignupGrade,
          note: l10n.selfSignupFromC2,
          lastOfCycleByDefault: true,
          onChanged: (g) => setState(() => _grade = g),
        ),
      ],
      bottom: [
        DirasstyButton(
          label: l10n.continueAction,
          onPressed: grade == null || !loaded
              ? null
              : () => context
                  .push('${RegisterScreen.pathFor('student')}?grade=$grade'),
        ),
      ],
    );
  }
}
