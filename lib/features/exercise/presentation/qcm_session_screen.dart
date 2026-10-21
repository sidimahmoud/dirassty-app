import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../core/gamification/gamification.dart';
import '../../../core/models/exercise_body.dart';
import '../../../core/models/student.dart';
import '../../../core/text/dirassty_dates.dart';
import '../../../core/text/math_format.dart';
import '../../../core/theme/dirassty_theme.dart';
import '../../../core/widgets/diagram_view.dart';
import '../../../core/widgets/dirassty/dirassty_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../courses/application/courses_providers.dart';
import '../../home/presentation/student_home_screen.dart';
import '../../lesson/presentation/widgets/concept_check_card.dart';
import '../../student/application/student_providers.dart';
import '../application/qcm_session_controller.dart';
import '../application/qcm_session_state.dart';

/// A lesson's QCM: one question per screen — pick an option (teal
/// border), "Vérifier", feedback card (teal-tint + "+XP", or red-tint
/// with the right answer highlighted), "Continuer". Closing mid-session
/// asks first. Ends on the result screen (streak celebration only when
/// the streak went up today, score / duration / XP, level bar, mistakes).
///
/// Scoring and XP are unchanged — [QcmSessionController.selectChoice]
/// still records the answer; the screen just holds the pick until
/// "Vérifier".
///
/// design_handoff QcmSession / QcmAR / QcmResult · DESIGN_SPEC §4 "QCM".
class QcmSessionScreen extends ConsumerStatefulWidget {
  const QcmSessionScreen({required this.lessonId, super.key});

  static const String path = '/exercise/:lessonId';
  static const String name = 'qcmSession';

  final String lessonId;

  @override
  ConsumerState<QcmSessionScreen> createState() => _QcmSessionScreenState();
}

class _QcmSessionScreenState extends ConsumerState<QcmSessionScreen> {
  /// Option picked but not yet checked, for [_pendingFor] question index.
  int? _pending;
  int _pendingFor = -1;

  Future<void> _confirmLeave() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool? leave = await showDirasstyDialog<bool>(
      context,
      icon: Icons.logout_rounded,
      iconBackground: DirasstyColors.errorTint,
      iconColor: DirasstyColors.error,
      title: l10n.leaveSessionTitle,
      message: l10n.leaveSessionBody,
      actions: [
        DirasstyDialogAction(
          label: l10n.leave,
          value: true,
          variant: DirasstyButtonVariant.danger,
        ),
        DirasstyDialogAction(
          label: l10n.stayInSession,
          value: false,
          variant: DirasstyButtonVariant.quiet,
        ),
      ],
    );
    if (leave == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final QcmSessionState state =
        ref.watch(qcmSessionControllerProvider(widget.lessonId));
    final QcmSessionController controller =
        ref.read(qcmSessionControllerProvider(widget.lessonId).notifier);
    final String lessonTitle = ref
            .watch(lessonByIdProvider(widget.lessonId))
            .valueOrNull
            ?.lessonTitle ??
        '';
    final bool midSession = state is QcmExercising &&
        (state.answers.isNotEmpty || _pending != null);

    return PopScope(
      canPop: !midSession,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        backgroundColor: DirasstyColors.background,
        body: SafeArea(
          child: switch (state) {
            QcmLoading() => const Center(child: CircularProgressIndicator()),
            QcmError() => _Centered(
                child: ErrorState(
                  title: l10n.qcmLoadError,
                  onRetry: controller.retry,
                ),
              ),
            QcmEmpty() => _Centered(
                child: EmptyState(
                  icon: Icons.quiz_outlined,
                  title: l10n.noQcmTitle,
                  message: l10n.noQcmBody,
                  actionLabel: l10n.backToLesson,
                  onAction: () => Navigator.of(context).maybePop(),
                ),
              ),
            QcmExercising() =>
              _buildExercising(context, l10n, state, controller, lessonTitle),
            QcmComplete() => _ResultView(
                state: state,
                lessonId: widget.lessonId,
                lessonTitle: lessonTitle,
                onRetry: controller.retry,
              ),
          },
        ),
      ),
    );
  }

  Widget _buildExercising(
    BuildContext context,
    AppLocalizations l10n,
    QcmExercising state,
    QcmSessionController controller,
    String lessonTitle,
  ) {
    final DirasstyType type = context.dirasstyType;
    final ExerciseBody body = state.current.body;
    if (_pendingFor != state.currentIndex) {
      _pending = null;
      _pendingFor = state.currentIndex;
    }
    final bool answered = state.answered;
    final bool correct = answered && state.answers.last.correct;

    AnswerState optionState(int i) {
      if (!answered) {
        return i == _pending ? AnswerState.selected : AnswerState.idle;
      }
      if (i == body.correct) return AnswerState.correct;
      if (i == state.selectedChoice) return AnswerState.wrong;
      return AnswerState.disabled;
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            DirasstySpace.sm,
            DirasstySpace.xs,
            DirasstySpace.screen,
            0,
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close_rounded),
                color: DirasstyColors.ink,
                tooltip: l10n.close,
              ),
              Expanded(
                child: DirasstyProgressBar(
                  value: (state.currentIndex + (answered ? 1 : 0)) /
                      state.exercises.length,
                ),
              ),
              const SizedBox(width: DirasstySpace.md),
              Text(
                '${state.currentIndex + 1}/${state.exercises.length}',
                style:
                    type.subheading.copyWith(fontSize: 14, fontFamily: 'Inter'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            key: ValueKey(state.currentIndex),
            padding: const EdgeInsetsDirectional.fromSTEB(
              DirasstySpace.screen,
              DirasstySpace.lg,
              DirasstySpace.screen,
              DirasstySpace.lg,
            ),
            children: [
              Text(
                lessonTitle.isEmpty
                    ? l10n.questionOf(
                        state.currentIndex + 1,
                        state.exercises.length,
                      )
                    : l10n.questionTopic(lessonTitle, state.currentIndex + 1),
                style: type.label,
              ),
              const SizedBox(height: DirasstySpace.sm),
              Text(
                cleanMathForDisplay(body.question),
                style: type.title.copyWith(height: 1.3),
              ),
              if (body.diagram != null) ...[
                const SizedBox(height: DirasstySpace.md),
                DiagramView(spec: body.diagram!, color: DirasstyColors.teal),
              ],
              if (!answered && body.hint.isNotEmpty) ...[
                const SizedBox(height: DirasstySpace.xs),
                if (state.hintRevealed)
                  Container(
                    padding: const EdgeInsetsDirectional.all(DirasstySpace.md),
                    decoration: const BoxDecoration(
                      color: DirasstyColors.goldTint,
                      borderRadius: DirasstyRadius.cardR,
                    ),
                    child: Text(
                      cleanMathForDisplay(body.hint),
                      style:
                          type.bodySmall.copyWith(color: DirasstyColors.text),
                    ),
                  )
                else
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      onPressed: controller.toggleHint,
                      icon:
                          const Icon(Icons.lightbulb_outline_rounded, size: 18),
                      label: Text(l10n.hint),
                    ),
                  ),
              ],
              const SizedBox(height: DirasstySpace.lg),
              for (int i = 0; i < body.choices.length; i++) ...[
                if (i > 0) const SizedBox(height: DirasstySpace.md),
                AnswerOption(
                  letter: String.fromCharCode(65 + i),
                  label: body.choices[i],
                  state: optionState(i),
                  picked: i == (answered ? state.selectedChoice : _pending),
                  onTap: () => setState(() => _pending = i),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            DirasstySpace.screen,
            0,
            DirasstySpace.screen,
            DirasstySpace.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (answered) ...[
                _FeedbackCard(
                  correct: correct,
                  explanation: body.explanation,
                  xp: correct
                      ? xpForCorrectAnswer(state.current.difficulty)
                      : 0,
                ),
                const SizedBox(height: DirasstySpace.md),
                DirasstyButton(
                  label: state.isLast ? l10n.seeResults : l10n.continueAction,
                  variant: DirasstyButtonVariant.ink,
                  onPressed: controller.next,
                ),
              ] else
                DirasstyButton(
                  label: l10n.check,
                  onPressed: _pending == null
                      ? null
                      : () => controller.selectChoice(_pending!),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({
    required this.correct,
    required this.explanation,
    required this.xp,
  });

  final bool correct;
  final String explanation;
  final int xp;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsetsDirectional.all(DirasstySpace.lg),
        decoration: BoxDecoration(
          color: correct ? DirasstyColors.tealTint : DirasstyColors.errorTint,
          borderRadius: DirasstyRadius.cardR,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    correct ? l10n.correctFeedback : l10n.wrongFeedback,
                    style: type.subheading.copyWith(
                      fontWeight: FontWeight.w800,
                      color: correct
                          ? DirasstyColors.tealDark
                          : DirasstyColors.errorDark,
                    ),
                  ),
                ),
                if (xp > 0)
                  RiseIn(
                    child: Container(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: 10,
                        vertical: DirasstySpace.xs,
                      ),
                      decoration: const BoxDecoration(
                        color: DirasstyColors.gold,
                        borderRadius: DirasstyRadius.pillR,
                      ),
                      child: Text(
                        l10n.xpGain(xp),
                        style: type.label.copyWith(
                          color: DirasstyColors.ink,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (explanation.isNotEmpty) ...[
              const SizedBox(height: DirasstySpace.sm),
              Text(
                cleanMathForDisplay(explanation),
                style: type.bodySmall.copyWith(color: DirasstyColors.text),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResultView extends ConsumerWidget {
  const _ResultView({
    required this.state,
    required this.lessonId,
    required this.lessonTitle,
    required this.onRetry,
  });

  final QcmComplete state;
  final String lessonId;
  final String lessonTitle;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    final Student? student = ref.watch(currentStudentProvider).valueOrNull;
    final int xpTotal = student?.xpTotal ?? 0;
    final List<QcmAnswerRecord> mistakes =
        state.answers.where((a) => !a.correct).toList();
    final int seconds = state.duration.inSeconds;

    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(
        DirasstySpace.xl,
        DirasstySpace.xl,
        DirasstySpace.xl,
        DirasstySpace.xl,
      ),
      children: [
        if (state.streakIncreased) ...[
          _StreakCelebration(streak: state.newStreak),
          const SizedBox(height: DirasstySpace.xl),
        ],
        DirasstyCard(
          variant: DirasstyCardVariant.shadow,
          padding: const EdgeInsetsDirectional.all(DirasstySpace.screen),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                lessonTitle.isEmpty
                    ? l10n.qcmTitle
                    : l10n.qcmScoreTitle(lessonTitle),
                style: type.label.copyWith(fontSize: 14),
              ),
              const SizedBox(height: DirasstySpace.lg),
              Row(
                children: [
                  _ResultStat(
                    value: '${state.correctCount}/${state.total}',
                    label: l10n.score,
                    emphasize: true,
                  ),
                  _ResultStat(
                    value:
                        '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}',
                    label: l10n.duration,
                  ),
                  _ResultStat(value: '+${state.totalXp}', label: l10n.xpEarned),
                ],
              ),
              const SizedBox(height: DirasstySpace.lg),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.level(levelFromXp(xpTotal)),
                      style: type.label.copyWith(color: DirasstyColors.text),
                    ),
                  ),
                  Text(
                    l10n.xpOfTotal(xpTotal, nextLevelXp(xpTotal)),
                    style: type.label,
                    textDirection: TextDirection.ltr,
                  ),
                ],
              ),
              const SizedBox(height: DirasstySpace.sm),
              XpBar(value: levelProgress(xpTotal)),
              const SizedBox(height: DirasstySpace.md),
              Text(
                state.passed
                    ? l10n.lessonValidated
                    : l10n.notMasteredYet((state.lessonMastery * 100).round()),
                style: type.label.copyWith(
                  color: state.passed
                      ? DirasstyColors.teal
                      : DirasstyColors.goldStroke,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: DirasstySpace.xl),
        if (mistakes.isNotEmpty) ...[
          DirasstyButton(
            label: l10n.reviewMistakes(mistakes.length),
            variant: DirasstyButtonVariant.secondary,
            onPressed: () => _showMistakes(context, mistakes),
          ),
          const SizedBox(height: DirasstySpace.md),
        ],
        DirasstyButton(
          label: l10n.guidedExercises,
          icon: Icons.edit_note_rounded,
          variant: DirasstyButtonVariant.quiet,
          onPressed: () => context.push('/open-practice/$lessonId'),
        ),
        const SizedBox(height: DirasstySpace.md),
        DirasstyButton(
          label: l10n.backHome,
          onPressed: () => context.go(StudentHomeScreen.path),
        ),
        const SizedBox(height: DirasstySpace.sm),
        TextButton(onPressed: onRetry, child: Text(l10n.retryQcm)),
      ],
    );
  }

  void _showMistakes(BuildContext context, List<QcmAnswerRecord> mistakes) {
    showDirasstyBottomSheet<void>(
      context,
      builder: (sheetContext) {
        final AppLocalizations l10n = AppLocalizations.of(sheetContext);
        final DirasstyType type = sheetContext.dirasstyType;
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.75,
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              Text(l10n.mistakesTitle, style: type.heading),
              for (final QcmAnswerRecord m in mistakes) ...[
                const SizedBox(height: DirasstySpace.lg),
                DirasstyCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        cleanMathForDisplay(m.exercise.body.question),
                        style: type.subheading,
                      ),
                      const SizedBox(height: DirasstySpace.sm),
                      Text(
                        l10n.yourAnswerWas(
                          cleanMathForDisplay(
                            m.exercise.body.choices[m.chosen],
                          ),
                        ),
                        style: type.label.copyWith(color: DirasstyColors.error),
                      ),
                      Text(
                        l10n.correctAnswerWas(
                          cleanMathForDisplay(
                            m.exercise.body.choices[m.exercise.body.correct],
                          ),
                        ),
                        style: type.label.copyWith(color: DirasstyColors.teal),
                      ),
                      if (m.exercise.body.explanation.isNotEmpty) ...[
                        const SizedBox(height: DirasstySpace.sm),
                        Text(
                          cleanMathForDisplay(m.exercise.body.explanation),
                          style: type.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ResultStat extends StatelessWidget {
  const _ResultStat({
    required this.value,
    required this.label,
    this.emphasize = false,
  });

  final String value;
  final String label;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final DirasstyType type = context.dirasstyType;
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            textDirection: TextDirection.ltr,
            style: type.statValue.copyWith(
              color: emphasize ? DirasstyColors.teal : DirasstyColors.text,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: type.label, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

/// Gold flame burst, "{n} jours de suite", and the week strip — the last
/// min(streak, 7) days filled (a streak is consecutive days ending today),
/// today outlined in ink.
class _StreakCelebration extends StatelessWidget {
  const _StreakCelebration({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    final String locale =
        Localizations.localeOf(context).languageCode == 'ar' ? 'ar' : 'fr';
    DirasstyDates.ensureWesternDigits();
    final DateTime today = DateTime.now();

    return Column(
      children: [
        SizedBox.square(
          dimension: 132,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: DirasstyColors.goldTint,
                  shape: BoxShape.circle,
                ),
              ),
              // Sparks burst outward from the flame once it has landed.
              const PositionedDirectional(
                top: 6,
                start: 18,
                child: ScaleIn(
                  begin: 0,
                  delay: Duration(milliseconds: 180),
                  burst: Offset(30, 40),
                  child: _Spark(size: 8),
                ),
              ),
              const PositionedDirectional(
                top: 22,
                end: 8,
                child: ScaleIn(
                  begin: 0,
                  delay: Duration(milliseconds: 180),
                  burst: Offset(-40, 30),
                  child: _Spark(size: 6),
                ),
              ),
              const PositionedDirectional(
                bottom: 14,
                start: 4,
                child: ScaleIn(
                  begin: 0,
                  delay: Duration(milliseconds: 180),
                  burst: Offset(44, -34),
                  child: _Spark(size: 6),
                ),
              ),
              const ScaleIn(
                child: Icon(
                  Icons.local_fire_department_rounded,
                  size: 68,
                  color: DirasstyColors.gold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: DirasstySpace.lg),
        Text(
          l10n.streakDays(streak),
          textAlign: TextAlign.center,
          style: type.display,
        ),
        const SizedBox(height: 6),
        Text(
          l10n.streakBody,
          textAlign: TextAlign.center,
          style: type.body.copyWith(color: DirasstyColors.textMuted),
        ),
        const SizedBox(height: DirasstySpace.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int back = 6; back >= 0; back--) ...[
              if (back < 6) const SizedBox(width: 6),
              // Today's circle fills last, after the flame lands.
              if (back == 0)
                ScaleIn(
                  delay: DirasstyMotion.celebrate,
                  child: _DayDot(
                    label: _dayInitial(locale, today),
                    active: streak > 0,
                    today: true,
                  ),
                )
              else
                _DayDot(
                  label:
                      _dayInitial(locale, today.subtract(Duration(days: back))),
                  active: back < streak,
                  today: false,
                ),
            ],
          ],
        ),
      ],
    );
  }
}

String _dayInitial(String locale, DateTime day) =>
    DateFormat.E(locale).format(day).characters.first.toUpperCase();

class _Spark extends StatelessWidget {
  const _Spark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: DirasstyColors.gold,
          shape: BoxShape.circle,
        ),
      );
}

class _DayDot extends StatelessWidget {
  const _DayDot({
    required this.label,
    required this.active,
    required this.today,
  });

  final String label;
  final bool active;
  final bool today;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? DirasstyColors.gold : DirasstyColors.track,
            border:
                today ? Border.all(color: DirasstyColors.ink, width: 2) : null,
          ),
          child: active
              ? const Icon(
                  Icons.local_fire_department_rounded,
                  size: 18,
                  color: DirasstyColors.ink,
                )
              : null,
        ),
        const SizedBox(height: 6),
        Text(label, style: context.dirasstyType.label),
      ],
    );
  }
}

class _Centered extends StatelessWidget {
  const _Centered({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const BackButtonIcon(),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            color: DirasstyColors.ink,
          ),
        ),
        Expanded(child: Center(child: child)),
      ],
    );
  }
}
