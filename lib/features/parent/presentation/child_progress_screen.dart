import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/grade.dart';
import '../../../core/models/student.dart';
import '../../../core/models/student_stats.dart';
import '../../../core/models/subject.dart';
import '../../../core/text/study_time.dart';
import '../../../core/theme/dirassty_theme.dart';
import '../../../core/validation/validators.dart';
import '../../../core/widgets/dirassty/dirassty_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/widgets/pin_entry.dart';
import '../../courses/application/courses_providers.dart';
import '../../focus/application/focus_providers.dart';
// import '../../focus/presentation/focus_settings_screen.dart'; // next version
import '../../exams/application/exam_providers.dart';
import '../../progress/application/progress_providers.dart';
import '../application/parent_providers.dart';
import 'child_exam_history_screen.dart';
import 'parent_subject_detail_screen.dart';
import 'widgets/child_card.dart';
import 'widgets/week_exams_card.dart';
import 'widgets/weekly_insight_card.dart';

/// One child's progress for the parent: identity header, exam countdown
/// (P6 Concours / C4 Brevet / L3 Bac), the AI weekly analysis, 4 stats,
/// mastery per subject, and links — exam history, lesson-by-lesson,
/// focus mode (with its status) and the child's login credentials.
///
/// Deviation from ChildProgress.dc.html: no "Examen blanc prévu le …"
/// line under the countdown (no mock-exam schedule in the API yet).
///
/// design_handoff ChildProgress.dc.html · DESIGN_SPEC §4 "Child progress".
class ChildProgressScreen extends ConsumerWidget {
  const ChildProgressScreen({super.key, required this.studentId});

  static const String path = '/parent/child/:studentId';
  static const String name = 'childProgress';

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<List<Student>> students =
        ref.watch(studentsByParentProvider);

    return Scaffold(
      backgroundColor: DirasstyColors.background,
      appBar: AppBar(),
      body: students.when(
        loading: () => const _ProgressSkeleton(),
        error: (_, __) => ErrorState(
          title: l10n.errGeneric,
          onRetry: () => ref.invalidate(studentsByParentProvider),
        ),
        data: (list) {
          final Student? student =
              list.where((s) => s.id == studentId).firstOrNull;
          if (student == null) {
            return EmptyState(
                icon: Icons.person_off_outlined, title: l10n.childNotFound);
          }
          return _ChildProgressBody(student: student);
        },
      ),
    );
  }
}

class _ChildProgressBody extends ConsumerWidget {
  const _ChildProgressBody({required this.student});

  final Student student;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    final AsyncValue<StudentStats> stats =
        ref.watch(studentStatsProvider(student.id));
    final AsyncValue<List<Subject>> subjects = ref.watch(
      subjectsWithMasteryForStudentProvider((
        studentId: student.id,
        country: student.country,
        grade: student.grade,
      )),
    );
    // Parental control (focus mode) — next version; uncomment with the
    // link row below.
    // final bool? focusEnabled = ref
    //     .watch(focusSettingsForStudentProvider(student.id))
    //     .valueOrNull
    //     ?.enabled;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(studentStatsProvider(student.id));
        ref.invalidate(examsByStudentProvider(student.id));
        ref.invalidate(focusSettingsForStudentProvider(student.id));
        ref.invalidate(studentsByParentProvider);
        await ref.read(studentsByParentProvider.future);
      },
      child: ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(
            DirasstySpace.screen, 0, DirasstySpace.screen, DirasstySpace.xxl),
        children: [
          Row(
            children: [
              ChildAvatar(name: student.name, size: 56),
              const SizedBox(width: DirasstySpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(student.name, style: type.titleSmall),
                    const SizedBox(height: 2),
                    Text(childGradeLine(l10n, ref, student),
                        style:
                            type.label.copyWith(fontWeight: FontWeight.w400)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: DirasstySpace.xl),
          _ExamCountdown(grade: student.grade),
          WeekExamsCard(studentId: student.id),
          WeeklyInsightCard(studentId: student.id),
          const SizedBox(height: DirasstySpace.xl),
          stats.when(
            loading: () => const _StatsSkeleton(),
            error: (_, __) => const SizedBox.shrink(),
            data: (s) => _StatsGrid(stats: s),
          ),
          const SizedBox(height: DirasstySpace.xl),
          Text(l10n.masteryBySubject, style: type.subheading),
          const SizedBox(height: DirasstySpace.md),
          subjects.when(
            loading: () =>
                const Skeleton(height: 180, radius: DirasstyRadius.card),
            error: (_, __) => ErrorState(
              title: l10n.errGeneric,
              onRetry: () =>
                  ref.invalidate(subjectsWithMasteryForStudentProvider),
            ),
            data: (list) => list.isEmpty
                ? EmptyState(
                    icon: Icons.menu_book_outlined,
                    title: l10n.noSubjectsForChild)
                : _MasteryList(studentId: student.id, subjects: list),
          ),
          const SizedBox(height: DirasstySpace.xl),
          _LinkGroup(
            rows: [
              _LinkRow(
                icon: Icons.fact_check_outlined,
                title: l10n.examHistory,
                onTap: () => context.pushNamed(
                  ChildExamHistoryScreen.name,
                  pathParameters: {'studentId': student.id},
                ),
              ),
              _LinkRow(
                icon: Icons.format_list_bulleted_rounded,
                title: l10n.lessonDetail,
                onTap: () => _pickSubject(
                    context, l10n, subjects.valueOrNull ?? const []),
              ),
              // Parental control (focus mode) — not ready, back in the next
              // version.
              // _LinkRow(
              //   icon: Icons.track_changes_rounded,
              //   title: l10n.focusMode,
              //   trailing: focusEnabled == null
              //       ? null
              //       : DirasstyChip(
              //           label: focusEnabled ? l10n.focusOn : l10n.focusOff,
              //           variant: focusEnabled
              //               ? DirasstyChipVariant.teal
              //               : DirasstyChipVariant.neutral,
              //           dense: true,
              //         ),
              //   onTap: () => context.pushNamed(
              //     FocusSettingsScreen.name,
              //     pathParameters: {'studentId': student.id},
              //   ),
              // ),
              _LinkRow(
                icon: Icons.key_outlined,
                title: l10n.loginCredentials,
                subtitle:
                    student.username == null ? null : '@${student.username}',
                trailing: Text(
                  student.username == null ? l10n.setLogin : l10n.edit,
                  style: type.label.copyWith(
                      color: DirasstyColors.teal, fontWeight: FontWeight.w700),
                ),
                onTap: () => _editCredentials(context, l10n),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openSubject(BuildContext context, Subject subject) {
    context.pushNamed(
      ParentSubjectDetailScreen.name,
      pathParameters: {'studentId': student.id, 'subjectKey': subject.key},
    );
  }

  Future<void> _pickSubject(
      BuildContext context, AppLocalizations l10n, List<Subject> list) async {
    if (list.length == 1) return _openSubject(context, list.first);
    final Subject? picked = await showDirasstyBottomSheet<Subject>(
      context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: DirasstySpace.md),
              child: Text(l10n.chooseSubject,
                  style: sheetContext.dirasstyType.titleSmall),
            ),
            for (final Subject s in list)
              ListTile(
                leading: Text(s.icon, style: const TextStyle(fontSize: 22)),
                title: Text(s.label),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(sheetContext).pop(s),
              ),
            const SizedBox(height: DirasstySpace.md),
          ],
        ),
      ),
    );
    if (picked != null && context.mounted) _openSubject(context, picked);
  }

  Future<void> _editCredentials(
      BuildContext context, AppLocalizations l10n) async {
    final String? username = await showDirasstyBottomSheet<String>(
      context,
      builder: (_) => _EditCredentialsSheet(student: student),
    );
    if (username != null && context.mounted) {
      showDirasstySnackBar(context, l10n.credentialsUpdated(username));
    }
  }
}

/// Ink card, gold day count: "45 jours avant le Brevet". Only for exam
/// grades (P6, C4, L3).
class _ExamCountdown extends StatelessWidget {
  const _ExamCountdown({required this.grade});

  final int grade;

  @override
  Widget build(BuildContext context) {
    final int? days = daysUntilExam(grade);
    if (days == null) return const SizedBox.shrink();
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    final String exam = switch (kGradeExams[grade]) {
      'Concours' => l10n.examConcours,
      'Brevet' => l10n.examBrevet,
      _ => l10n.examBac,
    };
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: DirasstySpace.lg),
      child: Container(
        padding: const EdgeInsetsDirectional.all(DirasstySpace.lg),
        decoration: const BoxDecoration(
            color: DirasstyColors.ink, borderRadius: DirasstyRadius.cardR),
        child: Row(
          children: [
            const Icon(Icons.event_rounded, color: DirasstyColors.gold),
            const SizedBox(width: DirasstySpace.md),
            Text(
              '$days',
              style: type.title.copyWith(
                  color: DirasstyColors.gold,
                  fontSize: 32,
                  fontFamily: 'Inter',
                  height: 1),
            ),
            const SizedBox(width: DirasstySpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.daysUnit,
                      style: type.subheading
                          .copyWith(color: Colors.white, fontSize: 14)),
                  Text(l10n.beforeExam(exam),
                      style: type.label
                          .copyWith(color: DirasstyColors.textOnDarkMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final StudentStats stats;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<(String, String)> tiles = [
      (formatStudyTime(l10n, stats.week.minutesOnApp), l10n.studyTime),
      ('${(stats.week.correctRate * 100).round()} %', l10n.correctAnswers),
      ('${stats.week.exercisesDone}', l10n.exercisesDone),
      (l10n.daysShortN(stats.streak), l10n.currentStreak),
    ];
    if (context.useSingleColumn) {
      return Column(
        children: [
          for (final (int i, (String, String) t) in tiles.indexed) ...[
            if (i > 0) const SizedBox(height: DirasstySpace.md),
            StatTile(value: t.$1, label: t.$2),
          ],
        ],
      );
    }
    return Column(
      children: [
        for (int row = 0; row < 2; row++) ...[
          if (row > 0) const SizedBox(height: DirasstySpace.md),
          Row(
            children: [
              for (int col = 0; col < 2; col++) ...[
                if (col > 0) const SizedBox(width: DirasstySpace.md),
                Expanded(
                  child: StatTile(
                    value: tiles[row * 2 + col].$1,
                    label: tiles[row * 2 + col].$2,
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _MasteryList extends StatelessWidget {
  const _MasteryList({required this.studentId, required this.subjects});

  final String studentId;
  final List<Subject> subjects;

  @override
  Widget build(BuildContext context) {
    final DirasstyType type = context.dirasstyType;
    return DirasstyCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final (int i, Subject s) in subjects.indexed) ...[
            if (i > 0) const Divider(height: 1),
            InkWell(
              onTap: () => context.pushNamed(
                ParentSubjectDetailScreen.name,
                pathParameters: {'studentId': studentId, 'subjectKey': s.key},
              ),
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: DirasstySpace.lg, vertical: DirasstySpace.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(s.label,
                              style: type.subheading.copyWith(fontSize: 14)),
                        ),
                        Text(
                          '${((s.mastery ?? 0) * 100).round()} %',
                          style: type.label.copyWith(
                              color: DirasstyColors.text,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: DirasstySpace.sm),
                    DirasstyProgressBar(value: s.mastery ?? 0),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LinkGroup extends StatelessWidget {
  const _LinkGroup({required this.rows});

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return DirasstyCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final (int i, Widget row) in rows.indexed) ...[
            if (i > 0) const Divider(height: 1),
            row,
          ],
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final DirasstyType type = context.dirasstyType;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
              DirasstySpace.lg, DirasstySpace.md, DirasstySpace.md, DirasstySpace.md),
          child: Row(
            children: [
              Icon(icon, size: 22, color: DirasstyColors.text),
              const SizedBox(width: DirasstySpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: type.subheading.copyWith(fontSize: 14)),
                    if (subtitle != null)
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(subtitle!,
                            style: type.label
                                .copyWith(fontWeight: FontWeight.w400)),
                      ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                trailing!,
                const SizedBox(width: DirasstySpace.xs),
              ],
              const Icon(Icons.chevron_right_rounded,
                  color: DirasstyColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Change the child's username and/or PIN. A legacy child created before
/// logins existed has no username yet, so a PIN is required then.
class _EditCredentialsSheet extends ConsumerStatefulWidget {
  const _EditCredentialsSheet({required this.student});

  final Student student;

  @override
  ConsumerState<_EditCredentialsSheet> createState() =>
      _EditCredentialsSheetState();
}

class _EditCredentialsSheetState extends ConsumerState<_EditCredentialsSheet> {
  late final TextEditingController _usernameController =
      TextEditingController(text: widget.student.username ?? '');
  String _pin = '';
  String? _usernameError;
  String? _pinError;
  String? _serverError;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String username = _usernameController.text.trim();
    final bool changingPin = _pin.isNotEmpty;
    setState(() {
      _serverError = null;
      _usernameError =
          isValidUsername(username) ? null : l10n.errUsernameFormat;
      _pinError = changingPin
          ? (isValidPin(_pin) ? null : l10n.errPinFormat)
          : (widget.student.username == null
              ? l10n.errPinRequiredNewLogin
              : null);
    });
    if (_usernameError != null || _pinError != null) return;

    final String result = await ref
        .read(updateStudentCredentialsControllerProvider.notifier)
        .updateCredentials(
          studentId: widget.student.id,
          username: username,
          pin: changingPin ? _pin : null,
        );
    if (!mounted) return;
    final AsyncValue<void> state =
        ref.read(updateStudentCredentialsControllerProvider);
    if (state.hasError) {
      final String message = state.error.toString();
      setState(() {
        if (message.contains('username_taken')) {
          _usernameError = l10n.errUsernameTaken;
        } else if (message.contains('invalid_username')) {
          _usernameError = l10n.errUsernameFormat;
        } else {
          _serverError = l10n.errGeneric;
        }
      });
      return;
    }
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    final bool loading =
        ref.watch(updateStudentCredentialsControllerProvider).isLoading;

    // showDirasstyBottomSheet already pads for the screen edges and keyboard.
    return Padding(
      padding: EdgeInsetsDirectional.zero,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.editCredentials, style: type.titleSmall),
            const SizedBox(height: DirasstySpace.lg),
            DirasstyTextField(
              label: l10n.username,
              controller: _usernameController,
              forceLtr: true,
              errorText: _usernameError,
            ),
            const SizedBox(height: DirasstySpace.lg),
            PinField(
              label: l10n.newPinOptional,
              value: _pin,
              hint: widget.student.username == null
                  ? l10n.childPinHint
                  : l10n.newPinOptionalHint,
              errorText: _pinError,
              onChanged: (pin) => setState(() {
                _pin = pin;
                _pinError = null;
              }),
            ),
            if (_serverError != null) ...[
              const SizedBox(height: DirasstySpace.sm),
              Text(_serverError!,
                  style: type.label.copyWith(color: DirasstyColors.error)),
            ],
            const SizedBox(height: DirasstySpace.xl),
            DirasstyButton(label: l10n.save, loading: loading, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}

class _StatsSkeleton extends StatelessWidget {
  const _StatsSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Row(children: [
          Expanded(child: Skeleton(height: 84, radius: DirasstyRadius.card)),
          SizedBox(width: DirasstySpace.md),
          Expanded(child: Skeleton(height: 84, radius: DirasstyRadius.card)),
        ]),
        SizedBox(height: DirasstySpace.md),
        Row(children: [
          Expanded(child: Skeleton(height: 84, radius: DirasstyRadius.card)),
          SizedBox(width: DirasstySpace.md),
          Expanded(child: Skeleton(height: 84, radius: DirasstyRadius.card)),
        ]),
      ],
    );
  }
}

class _ProgressSkeleton extends StatelessWidget {
  const _ProgressSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsetsDirectional.all(DirasstySpace.screen),
      children: const [
        Skeleton(height: 56, radius: DirasstyRadius.card),
        SizedBox(height: DirasstySpace.xl),
        Skeleton(height: 80, radius: DirasstyRadius.card),
        SizedBox(height: DirasstySpace.lg),
        Skeleton(height: 150, radius: DirasstyRadius.card),
        SizedBox(height: DirasstySpace.xl),
        _StatsSkeleton(),
      ],
    );
  }
}
