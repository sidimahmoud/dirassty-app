import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/exam.dart';
import '../../../core/models/student.dart';
import '../../../core/text/math_format.dart';
import '../../../core/theme/dirassty_theme.dart';
import '../../../core/widgets/diagram_view.dart';
import '../../../core/widgets/dirassty/dirassty_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../student/application/student_providers.dart';
import '../application/exam_providers.dart';
import '../application/exam_session_state.dart';
import 'exams_list_screen.dart';

/// A weekly exam: timer chip, question navigator (answered / current /
/// open), one question per screen with radio options and no feedback,
/// Précédente / Suivante, "Terminer l'examen" (warns about unanswered
/// questions). Re-opening a finished exam shows its results.
///
/// Timer: counts down with the gold (< 5 min) / red (< 1 min) states and
/// auto-submits at 0 when the exam has a time limit
/// ([Exam.durationMinutes]); exams don't store one yet, so for now it
/// shows elapsed time.
///
/// design_handoff ExamSession.dc.html + ExamResults.dc.html.
class ExamSessionScreen extends ConsumerWidget {
  const ExamSessionScreen({required this.examId, super.key});

  static const String path = '/exam/:examId';
  static const String name = 'examSession';

  static String pathFor(String examId) => '/exam/$examId';

  final String examId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ExamSessionState state =
        ref.watch(examSessionControllerProvider(examId));

    return Scaffold(
      backgroundColor: DirasstyColors.background,
      body: SafeArea(
        child: switch (state) {
          ExamSessionLoading() =>
            const Center(child: CircularProgressIndicator()),
          ExamSessionError() => Center(
              child: ErrorState(
                title: l10n.examLoadError,
                onRetry: () =>
                    ref.invalidate(examSessionControllerProvider(examId)),
              ),
            ),
          ExamSessionActive() => _ActiveView(state: state, examId: examId),
          ExamSessionComplete() => _ResultsView(state: state),
        },
      ),
    );
  }
}

class _ActiveView extends ConsumerStatefulWidget {
  const _ActiveView({required this.state, required this.examId});

  final ExamSessionActive state;
  final String examId;

  @override
  ConsumerState<_ActiveView> createState() => _ActiveViewState();
}

class _ActiveViewState extends ConsumerState<_ActiveView> {
  late final Timer _ticker;

  ExamSessionController get _controller =>
      ref.read(examSessionControllerProvider(widget.examId).notifier);

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  Duration? get _remaining {
    final int? minutes = widget.state.exam.durationMinutes;
    if (minutes == null) return null;
    return Duration(minutes: minutes) -
        DateTime.now().difference(widget.state.startedAt);
  }

  void _tick() {
    if (!mounted) return;
    final Duration? left = _remaining;
    if (left != null && left <= Duration.zero && !widget.state.finishing) {
      _submit();
      return;
    }
    setState(() {});
  }

  Future<void> _submit() async {
    try {
      await _controller.finish();
    } catch (_) {
      if (mounted)
        showDirasstySnackBar(context, AppLocalizations.of(context).submitError);
    }
  }

  Future<void> _confirmFinish() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final int unanswered =
        widget.state.questions.length - widget.state.answeredCount;
    final bool? finish = await showDirasstyDialog<bool>(
      context,
      icon: Icons.flag_rounded,
      title: l10n.finishExamTitle,
      message: unanswered > 0
          ? l10n.finishExamUnanswered(unanswered)
          : l10n.finishExamAll,
      actions: [
        DirasstyDialogAction(label: l10n.finishNow, value: true),
        DirasstyDialogAction(
            label: l10n.keepGoing,
            value: false,
            variant: DirasstyButtonVariant.quiet),
      ],
    );
    if (finish == true) await _submit();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    final ExamSessionActive state = widget.state;
    final ExamQuestion q = state.current;
    final int skipped = state.questions.indexWhere((x) => !x.answered);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
              DirasstySpace.sm, DirasstySpace.xs, DirasstySpace.screen, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const BackButtonIcon(),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                color: DirasstyColors.ink,
              ),
              Expanded(
                child: Text(
                  l10n.questionOf(
                      state.currentIndex + 1, state.questions.length),
                  style: type.subheading.copyWith(fontSize: 14),
                ),
              ),
              _TimerChip(
                  remaining: _remaining,
                  elapsed: DateTime.now().difference(state.startedAt)),
            ],
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsetsDirectional.symmetric(
                horizontal: DirasstySpace.screen),
            itemCount: state.questions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (context, i) => _NavBox(
              number: i + 1,
              answered: state.questions[i].answered,
              current: i == state.currentIndex,
              onTap: () => _controller.goTo(i),
            ),
          ),
        ),
        if (skipped != -1 && skipped < state.currentIndex)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
                DirasstySpace.screen, DirasstySpace.xs, DirasstySpace.screen, 0),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(l10n.skippedHint(skipped + 1),
                  style: type.label.copyWith(fontWeight: FontWeight.w400)),
            ),
          ),
        Expanded(
          child: ListView(
            key: ValueKey(state.currentIndex),
            padding: const EdgeInsetsDirectional.fromSTEB(DirasstySpace.screen,
                DirasstySpace.lg, DirasstySpace.screen, DirasstySpace.lg),
            children: [
              DirasstyCard(
                variant: DirasstyCardVariant.shadow,
                padding: const EdgeInsetsDirectional.all(DirasstySpace.screen),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (q.lessonTitle.isNotEmpty) ...[
                      Text(q.lessonTitle.toUpperCase(), style: type.label),
                      const SizedBox(height: DirasstySpace.sm),
                    ],
                    Text(cleanMathForDisplay(q.body.question),
                        style: type.titleSmall
                            .copyWith(fontSize: 22, height: 1.3)),
                    if (q.body.diagram != null) ...[
                      const SizedBox(height: DirasstySpace.md),
                      DiagramView(
                          spec: q.body.diagram!, color: DirasstyColors.teal),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: DirasstySpace.lg),
              for (int i = 0; i < q.body.choices.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                _RadioOption(
                  label: q.body.choices[i],
                  selected: q.selectedChoice == i,
                  onTap: state.finishing
                      ? null
                      : () => _controller.selectChoice(i),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
              DirasstySpace.screen, 0, DirasstySpace.screen, DirasstySpace.md),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DirasstyButton(
                      label: l10n.previous,
                      variant: DirasstyButtonVariant.quiet,
                      onPressed: state.isFirst ? null : _controller.previous,
                    ),
                  ),
                  const SizedBox(width: DirasstySpace.md),
                  Expanded(
                    child: state.isLast
                        ? DirasstyButton(
                            label: l10n.finishExam,
                            loading: state.finishing,
                            onPressed: _confirmFinish)
                        : DirasstyButton(
                            label: l10n.next,
                            variant: DirasstyButtonVariant.ink,
                            onPressed: _controller.next),
                  ),
                ],
              ),
              if (!state.isLast)
                TextButton(
                    onPressed: state.finishing ? null : _confirmFinish,
                    child: Text(l10n.finishExam)),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimerChip extends StatelessWidget {
  const _TimerChip({required this.remaining, required this.elapsed});

  final Duration? remaining;
  final Duration elapsed;

  @override
  Widget build(BuildContext context) {
    final Duration shown = remaining == null
        ? elapsed
        : (remaining!.isNegative ? Duration.zero : remaining!);
    final (Color bg, Color fg) =
        remaining == null || remaining! > const Duration(minutes: 5)
            ? (DirasstyColors.tealTint, DirasstyColors.tealDark)
            : remaining! > const Duration(minutes: 1)
                ? (DirasstyColors.goldTint, DirasstyColors.ink)
                : (DirasstyColors.errorTint, DirasstyColors.errorDark);
    final int m = shown.inMinutes;
    final int s = shown.inSeconds % 60;
    return Container(
      height: 36,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: DirasstySpace.md),
      decoration: BoxDecoration(color: bg, borderRadius: DirasstyRadius.pillR),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(
            '$m:${s.toString().padLeft(2, '0')}',
            textDirection: TextDirection.ltr,
            style: context.dirasstyType.subheading
                .copyWith(fontSize: 14, color: fg, fontFamily: 'Inter'),
          ),
        ],
      ),
    );
  }
}

class _NavBox extends StatelessWidget {
  const _NavBox(
      {required this.number,
      required this.answered,
      required this.current,
      required this.onTap});

  final int number;
  final bool answered;
  final bool current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        button: true,
        selected: current,
        child: InkWell(
          onTap: onTap,
          borderRadius: DirasstyRadius.smallR,
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: answered ? DirasstyColors.ink : DirasstyColors.surface,
              borderRadius: DirasstyRadius.smallR,
              border: Border.all(
                color: current
                    ? DirasstyColors.teal
                    : (answered ? DirasstyColors.ink : DirasstyColors.line),
                width: current ? 2 : 1,
              ),
            ),
            child: Text(
              '$number',
              style: context.dirasstyType.label.copyWith(
                color: answered ? Colors.white : DirasstyColors.ink,
                fontWeight: FontWeight.w700,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Exam option: radio circle + label, 56 high, ink border when selected
/// (no right/wrong colors during an exam).
class _RadioOption extends StatelessWidget {
  const _RadioOption(
      {required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      child: Material(
        color: DirasstyColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: DirasstyRadius.cardR,
          side: BorderSide(
              color: selected ? DirasstyColors.ink : DirasstyColors.line, width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: DirasstySpace.lg, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: selected ? DirasstyColors.ink : DirasstyColors.idle,
                          width: 2),
                    ),
                    child: selected
                        ? Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                                color: DirasstyColors.ink, shape: BoxShape.circle),
                          )
                        : null,
                  ),
                  const SizedBox(width: DirasstySpace.md),
                  Expanded(
                    child: Text(
                      cleanMathForDisplay(label),
                      style: context.dirasstyType.body.copyWith(
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w400),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultsView extends ConsumerWidget {
  const _ResultsView({required this.state});

  final ExamSessionComplete state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    final Student? student = ref.watch(currentStudentProvider).valueOrNull;
    final String firstName =
        (student?.name ?? '').trim().split(RegExp(r'\s+')).first;
    final double ratio =
        state.total == 0 ? 0 : state.correctCount / state.total;
    final String title = ratio >= 0.75
        ? l10n.resultsGreat(firstName)
        : ratio >= 0.5
            ? l10n.resultsGood(firstName)
            : l10n.resultsKeepGoing(firstName);

    // Per-lesson breakdown, in question order — by concept for AI-written
    // exam questions, which have no lesson of their own.
    final Map<String, ({int right, int total})> byLesson = {};
    for (final ExamQuestion q in state.questions) {
      final String key =
          q.lessonTitle.isNotEmpty ? q.lessonTitle : q.body.concept.trim();
      if (key.isEmpty) continue;
      final ({int right, int total}) prev =
          byLesson[key] ?? (right: 0, total: 0);
      byLesson[key] = (
        right: prev.right + (q.isCorrect == true ? 1 : 0),
        total: prev.total + 1
      );
    }
    final List<ExamQuestion> mistakes =
        state.questions.where((q) => q.isCorrect != true).toList();

    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(
          DirasstySpace.screen, DirasstySpace.lg, DirasstySpace.screen, DirasstySpace.xl),
      children: [
        Center(
          child: SizedBox.square(
            dimension: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                MasteryRing(
                    value: ratio, size: 140, stroke: 10, showLabel: false),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${state.correctCount}/${state.total}',
                      textDirection: TextDirection.ltr,
                      style: type.display.copyWith(fontFamily: 'Inter'),
                    ),
                    Text('${(ratio * 100).round()} %', style: type.label),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: DirasstySpace.md),
        Text(title, textAlign: TextAlign.center, style: type.title),
        const SizedBox(height: DirasstySpace.md),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: DirasstySpace.sm,
          runSpacing: DirasstySpace.sm,
          children: [
            Container(
              height: 32,
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 10),
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                  color: DirasstyColors.gold, borderRadius: DirasstyRadius.pillR),
              child: Text(
                l10n.xpGain(state.totalXp),
                style: type.label.copyWith(
                    color: DirasstyColors.ink,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Inter'),
              ),
            ),
            DirasstyChip(
              label: state.duration == null
                  ? state.exam.subject.label
                  : '${state.exam.subject.label} · ${l10n.minutesShort(state.duration!.inMinutes)}',
            ),
          ],
        ),
        if (byLesson.isNotEmpty) ...[
          const SizedBox(height: 18),
          DirasstyCard(
            padding: const EdgeInsetsDirectional.all(DirasstySpace.screen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.byLesson, style: type.subheading),
                for (final (int i, MapEntry<String, ({int right, int total})> e)
                    in byLesson.entries.indexed) ...[
                  const SizedBox(height: DirasstySpace.md),
                  Row(
                    children: [
                      Expanded(
                          child: Text(e.key,
                              style: type.label.copyWith(
                                  fontSize: 14, color: DirasstyColors.text))),
                      Text(
                        '${e.value.right}/${e.value.total}',
                        style: type.subheading.copyWith(
                            fontSize: 14,
                            color:
                                i.isEven ? DirasstyColors.teal : DirasstyColors.ink),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  DirasstyProgressBar(
                    value:
                        e.value.total == 0 ? 0 : e.value.right / e.value.total,
                    color: i.isEven ? DirasstyColors.teal : DirasstyColors.ink,
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 18),
        Text(l10n.yourAnswers, style: type.subheading),
        const SizedBox(height: DirasstySpace.md),
        Container(
          decoration: BoxDecoration(
            color: DirasstyColors.surface,
            borderRadius: DirasstyRadius.cardR,
            border: Border.all(color: DirasstyColors.line),
          ),
          child: Column(
            children: [
              for (final (int i, ExamQuestion q)
                  in state.questions.indexed) ...[
                if (i > 0) const Divider(height: 1),
                Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: DirasstySpace.lg, vertical: DirasstySpace.md),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: q.isCorrect == true
                              ? DirasstyColors.teal
                              : DirasstyColors.errorTint,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          q.isCorrect == true
                              ? Icons.check_rounded
                              : Icons.close_rounded,
                          size: 16,
                          color: q.isCorrect == true
                              ? Colors.white
                              : DirasstyColors.error,
                        ),
                      ),
                      const SizedBox(width: DirasstySpace.md),
                      Expanded(
                        child: Text(
                          '${i + 1}. ${cleanMathForDisplay(q.body.question)}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              type.bodySmall.copyWith(color: DirasstyColors.text),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: DirasstySpace.xl),
        Row(
          children: [
            if (mistakes.isNotEmpty) ...[
              Expanded(
                child: DirasstyButton(
                  label: l10n.reviewMistakes(mistakes.length),
                  variant: DirasstyButtonVariant.secondary,
                  onPressed: () => _showMistakes(context, mistakes),
                ),
              ),
              const SizedBox(width: DirasstySpace.md),
            ],
            Expanded(
                child: DirasstyButton(
                    label: l10n.done,
                    onPressed: () => context.go(ExamsListScreen.path))),
          ],
        ),
      ],
    );
  }

  void _showMistakes(BuildContext context, List<ExamQuestion> mistakes) {
    showDirasstyBottomSheet<void>(
      context,
      builder: (sheetContext) {
        final AppLocalizations l10n = AppLocalizations.of(sheetContext);
        final DirasstyType type = sheetContext.dirasstyType;
        return ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.75),
          child: ListView(
            shrinkWrap: true,
            children: [
              Text(l10n.mistakesTitle, style: type.heading),
              for (final ExamQuestion q in mistakes) ...[
                const SizedBox(height: DirasstySpace.lg),
                DirasstyCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(cleanMathForDisplay(q.body.question),
                          style: type.subheading),
                      const SizedBox(height: DirasstySpace.sm),
                      if (q.selectedChoice != null)
                        Text(
                          l10n.yourAnswerWas(cleanMathForDisplay(
                              q.body.choices[q.selectedChoice!])),
                          style: type.label.copyWith(color: DirasstyColors.error),
                        ),
                      Text(
                        l10n.correctAnswerWas(cleanMathForDisplay(
                            q.body.choices[q.body.correct])),
                        style: type.label.copyWith(color: DirasstyColors.teal),
                      ),
                      if (q.body.explanation.isNotEmpty) ...[
                        const SizedBox(height: DirasstySpace.sm),
                        Text(cleanMathForDisplay(q.body.explanation),
                            style: type.bodySmall),
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
