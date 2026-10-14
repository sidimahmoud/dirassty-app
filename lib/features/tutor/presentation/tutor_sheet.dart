import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/tutor_reply.dart';
import '../../../core/network/api_client.dart';
import '../../../core/text/math_format.dart';
import '../../../core/theme/dirassty_theme.dart';
import '../../../core/widgets/dirassty/dirassty_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../ai_report/presentation/report_ai_button.dart';
import '../../exercise/application/exercise_providers.dart';

/// Opens Rafiq, the AI tutor — for an exercise ([exerciseRef]: hint, guide,
/// check my step, explain a step, full solution) or a lesson ([lessonId]:
/// explain, step by step, example, another example, summary, question).
/// One sheet, one endpoint (`/api/tutor`); the server builds the
/// curriculum context and enforces the student's AI budget.
Future<void> showTutorSheet(
  BuildContext context, {
  Map<String, String>? exerciseRef,
  String? lessonId,
  required String lang,
}) {
  assert((exerciseRef == null) != (lessonId == null));
  return showDirasstyBottomSheet<void>(
    context,
    builder: (_) => SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.78,
      child:
          _TutorSheet(exerciseRef: exerciseRef, lessonId: lessonId, lang: lang),
    ),
  );
}

class _Msg {
  _Msg.student(this.text)
      : fromStudent = true,
        reply = null;
  _Msg.tutor(TutorReply this.reply)
      : fromStudent = false,
        text = reply.reply;

  final bool fromStudent;
  final String text;
  final TutorReply? reply;
}

class _TutorSheet extends ConsumerStatefulWidget {
  const _TutorSheet({this.exerciseRef, this.lessonId, required this.lang});

  final Map<String, String>? exerciseRef;
  final String? lessonId;
  final String lang;

  @override
  ConsumerState<_TutorSheet> createState() => _TutorSheetState();
}

class _TutorSheetState extends ConsumerState<_TutorSheet> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<_Msg> _messages = [];
  bool _busy = false;
  String? _error;
  bool _blocked = false; // AI budget used up / rate-limited
  int? _budgetPct;

  bool get _isExercise => widget.exerciseRef != null;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  List<(String action, String label, bool needsText)> _actions(
          AppLocalizations l10n) =>
      _isExercise
          ? [
              ('hint', l10n.tutorHint, false),
              ('guide', l10n.tutorGuide, false),
              ('check_step', l10n.tutorCheckStep, true),
              ('explain_step', l10n.tutorExplainStep, true),
              ('solution', l10n.tutorSolution, false),
            ]
          : [
              ('explain', l10n.tutorExplain, false),
              ('step_by_step', l10n.tutorStepByStep, false),
              ('example', l10n.tutorExample, false),
              ('another_example', l10n.tutorAnotherExample, false),
              ('summary', l10n.tutorSummary, false),
            ];

  Future<void> _ask(String action, {bool needsText = false}) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String text = _input.text.trim();
    if (needsText && text.isEmpty) {
      setState(() => _error = l10n.tutorNeedsText);
      return;
    }
    // Free text: tutor the next step (exercise) / answer it (lesson).
    final String effective =
        action == 'free' ? (_isExercise ? 'guide' : 'question') : action;
    final List<TutorTurn> history = [
      for (final _Msg m in _messages)
        TutorTurn(
            fromStudent: m.fromStudent,
            text: m.text,
            isHint: m.reply?.isHint ?? false),
    ];
    setState(() {
      _busy = true;
      _error = null;
      if (text.isNotEmpty) _messages.add(_Msg.student(text));
    });
    _input.clear();
    _scrollToEnd();
    try {
      final TutorReply reply =
          await ref.read(exerciseRepositoryProvider).askTutor(
                mode: _isExercise ? 'exercise' : 'lesson',
                action: effective,
                exerciseRef: widget.exerciseRef,
                lessonId: widget.lessonId,
                message: text,
                history: history,
                lang: widget.lang,
              );
      if (!mounted) return;
      setState(() {
        _messages.add(_Msg.tutor(reply));
        _budgetPct = reply.budgetLeftPct ?? _budgetPct;
      });
      _scrollToEnd();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _blocked = e.isLimit;
      });
    } catch (_) {
      if (mounted) setState(() => _error = l10n.errGeneric);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: DirasstyMotion.fast, curve: DirasstyMotion.curve);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    final bool canAsk = !_busy && !_blocked;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome_rounded, color: DirasstyColors.teal),
            const SizedBox(width: DirasstySpace.sm),
            Expanded(child: Text(l10n.tutorTitle, style: type.titleSmall)),
          ],
        ),
        const SizedBox(height: DirasstySpace.md),
        Expanded(
          child: ListView(
            controller: _scroll,
            children: [
              _Bubble(
                fromStudent: false,
                child: Text(
                  _isExercise ? l10n.tutorIntroExercise : l10n.tutorIntroLesson,
                  style: type.bodySmall.copyWith(color: DirasstyColors.text),
                ),
              ),
              for (final _Msg m in _messages)
                m.fromStudent
                    ? _Bubble(
                        fromStudent: true,
                        child: Text(m.text,
                            style:
                                type.bodySmall.copyWith(color: Colors.white)))
                    : _Bubble(
                        fromStudent: false,
                        child: _ReplyView(
                          reply: m.reply!,
                          reportContext: {
                            if (widget.exerciseRef != null)
                              'exercise': widget.exerciseRef,
                            if (widget.lessonId != null)
                              'lesson_id': widget.lessonId,
                          },
                        )),
              if (_busy)
                _Bubble(
                  fromStudent: false,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: DirasstyColors.teal),
                      ),
                      const SizedBox(width: DirasstySpace.sm),
                      Text(l10n.tutorThinking, style: type.label),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(top: DirasstySpace.sm),
            child: Text(_error!,
                style: type.label.copyWith(color: DirasstyColors.error)),
          ),
        const SizedBox(height: DirasstySpace.sm),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final (String action, String label, bool needsText)
                  in _actions(l10n)) ...[
                DirasstyChip(
                  label: label,
                  variant: action == 'solution'
                      ? DirasstyChipVariant.gold
                      : DirasstyChipVariant.teal,
                  onTap:
                      canAsk ? () => _ask(action, needsText: needsText) : null,
                ),
                const SizedBox(width: DirasstySpace.xs),
              ],
            ],
          ),
        ),
        const SizedBox(height: DirasstySpace.sm),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _input,
                enabled: canAsk,
                minLines: 1,
                maxLines: 3,
                maxLength: 600,
                textInputAction: TextInputAction.send,
                onSubmitted:
                    canAsk ? (_) => _ask('free', needsText: true) : null,
                decoration: InputDecoration(
                  hintText: _isExercise
                      ? l10n.tutorInputHintExercise
                      : l10n.tutorInputHintLesson,
                  counterText: '',
                ),
              ),
            ),
            const SizedBox(width: DirasstySpace.sm),
            IconButton.filled(
              onPressed: canAsk ? () => _ask('free', needsText: true) : null,
              tooltip: MaterialLocalizations.of(context).continueButtonLabel,
              style: IconButton.styleFrom(backgroundColor: DirasstyColors.teal),
              icon: const Icon(Icons.send_rounded, color: Colors.white),
            ),
          ],
        ),
        if (_budgetPct != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(top: DirasstySpace.xs),
            child: Text(
              l10n.aiBudgetLeft(_budgetPct!.toString()),
              style: type.label
                  .copyWith(fontWeight: FontWeight.w400, fontSize: 11),
            ),
          ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.fromStudent, required this.child});

  final bool fromStudent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: fromStudent
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsetsDirectional.only(bottom: DirasstySpace.sm),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
        padding: const EdgeInsetsDirectional.all(DirasstySpace.md),
        decoration: BoxDecoration(
          color: fromStudent ? DirasstyColors.teal : DirasstyColors.surface,
          borderRadius: DirasstyRadius.cardR,
          border: fromStudent ? null : Border.all(color: DirasstyColors.line),
        ),
        child: child,
      ),
    );
  }
}

class _ReplyView extends StatelessWidget {
  const _ReplyView({required this.reply, required this.reportContext});

  final TutorReply reply;
  final Map<String, Object?> reportContext;

  /// The reply as plain text, for a report.
  String get _asText => [
        reply.reply,
        for (final ({String work, String why}) s in reply.steps)
          '${s.work}${s.why.isEmpty ? '' : ' — ${s.why}'}',
        ...reply.formulas,
        if (reply.finalAnswer.isNotEmpty) '= ${reply.finalAnswer}',
      ].where((t) => t.isNotEmpty).join('\n');

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    final (String, DirasstyChipVariant)? status = switch (reply.stepStatus) {
      'correct' => (l10n.tutorStepCorrect, DirasstyChipVariant.teal),
      'partially_correct' => (l10n.tutorStepPartial, DirasstyChipVariant.gold),
      'incorrect' => (l10n.tutorStepIncorrect, DirasstyChipVariant.red),
      _ => null,
    };
    final TextStyle body =
        type.bodySmall.copyWith(color: DirasstyColors.text, height: 1.5);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (status != null) ...[
          DirasstyChip(label: status.$1, variant: status.$2, dense: true),
          const SizedBox(height: DirasstySpace.xs),
        ],
        if (reply.reply.isNotEmpty)
          Text(
              '${reply.isHint ? '💡 ' : ''}${cleanMathForDisplay(reply.reply)}',
              style: body),
        for (final (int i, ({String work, String why}) s)
            in reply.steps.indexed) ...[
          const SizedBox(height: DirasstySpace.sm),
          Text('${i + 1}. ${cleanMathForDisplay(s.work)}',
              style: body.copyWith(fontWeight: FontWeight.w700)),
          if (s.why.isNotEmpty)
            Text('${l10n.tutorWhy} ${cleanMathForDisplay(s.why)}',
                style: type.label.copyWith(fontWeight: FontWeight.w400)),
        ],
        if (reply.formulas.isNotEmpty) ...[
          const SizedBox(height: DirasstySpace.sm),
          Text(l10n.tutorFormulas, style: type.label),
          for (final String f in reply.formulas)
            Text('• ${cleanMathForDisplay(f)}', style: body),
        ],
        if (reply.finalAnswer.isNotEmpty) ...[
          const SizedBox(height: DirasstySpace.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsetsDirectional.all(DirasstySpace.sm),
            decoration: const BoxDecoration(
                color: DirasstyColors.tealTint,
                borderRadius: DirasstyRadius.smallR),
            child: Text(
                '${l10n.tutorFinalAnswer} : ${cleanMathForDisplay(reply.finalAnswer)}',
                style: body.copyWith(
                    fontWeight: FontWeight.w800,
                    color: DirasstyColors.tealDark)),
          ),
        ],
        const SizedBox(height: DirasstySpace.xs),
        ReportAiButton(
            feature: 'tutor', aiText: _asText, reportContext: reportContext),
      ],
    );
  }
}
