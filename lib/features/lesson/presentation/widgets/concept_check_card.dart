import 'package:flutter/material.dart';

import '../../../../core/models/explanation_body.dart';
import '../../../../core/text/math_format.dart';
import '../../../../core/theme/dirassty_theme.dart';
import '../../../../core/widgets/dirassty/dirassty_widgets.dart';
import '../../../../l10n/app_localizations.dart';
import 'lesson_blocks.dart';

/// The comprehension-gate question at the end of a concept ("Vérifie ta
/// compréhension"). Same rule as the web app: continuing requires a
/// correct answer, OR two wrong attempts (the right choice is then
/// revealed and the student may move on) — never an indefinite block,
/// never a free skip.
///
/// design_handoff LessonConcept.dc.html (mini-quiz card).
class ConceptCheckCard extends StatefulWidget {
  const ConceptCheckCard({
    required this.check,
    required this.canContinue,
    required this.onCanContinueChanged,
    super.key,
  });

  final ConceptCheck check;
  final bool canContinue;
  final ValueChanged<bool> onCanContinueChanged;

  @override
  State<ConceptCheckCard> createState() => _ConceptCheckCardState();
}

class _ConceptCheckCardState extends State<ConceptCheckCard> {
  int? _selected;
  int _attempts = 0;
  bool _passed = false;
  bool _revealed = false;

  /// First wrong answer, waiting for "Réessayer".
  bool get _locked => _selected != null && !_passed && !_revealed;

  void _select(int index) {
    if (_selected != null) return;
    setState(() {
      _selected = index;
      if (index == widget.check.correct) {
        _passed = true;
      } else {
        _attempts++;
        if (_attempts >= 2) _revealed = true;
      }
    });
    if (_passed || _revealed) widget.onCanContinueChanged(true);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;

    return LessonCard(
      icon: Icons.quiz_rounded,
      label: l10n.checkUnderstanding,
      labelColor: DirasstyColors.tealDark,
      children: [
        Text(
          cleanMathForDisplay(widget.check.question),
          style: type.subheading,
        ),
        const SizedBox(height: DirasstySpace.md),
        for (int i = 0; i < widget.check.choices.length; i++) ...[
          if (i > 0) const SizedBox(height: DirasstySpace.sm),
          AnswerOption(
            letter: String.fromCharCode(65 + i),
            label: widget.check.choices[i],
            state: _stateOf(i),
            picked: i == _selected,
            onTap: () => _select(i),
          ),
        ],
        if (_locked) ...[
          const SizedBox(height: DirasstySpace.md),
          Text(
            l10n.wrongTryAgain,
            style: type.label.copyWith(color: DirasstyColors.error),
          ),
          const SizedBox(height: DirasstySpace.sm),
          DirasstyButton(
            label: l10n.retry,
            variant: DirasstyButtonVariant.quiet,
            compact: true,
            onPressed: () => setState(() => _selected = null),
          ),
        ],
        if (_passed) ...[
          const SizedBox(height: DirasstySpace.md),
          Text(
            l10n.correctUnlocked,
            style: type.label.copyWith(color: DirasstyColors.teal),
          ),
        ],
        if (_passed || _revealed) ...[
          if (_revealed) ...[
            const SizedBox(height: DirasstySpace.md),
            Text(
              l10n.revealedAnswer,
              style: type.label.copyWith(color: DirasstyColors.text),
            ),
          ],
          const SizedBox(height: DirasstySpace.xs),
          LessonText(widget.check.explanation, muted: true, small: true),
        ],
      ],
    );
  }

  AnswerState _stateOf(int i) {
    if (_selected == null) return AnswerState.idle;
    if (_locked) {
      return i == _selected ? AnswerState.wrong : AnswerState.disabled;
    }
    if (i == widget.check.correct) return AnswerState.correct;
    if (i == _selected) return AnswerState.wrong;
    return AnswerState.disabled;
  }
}

enum AnswerState { idle, selected, correct, wrong, disabled }

/// One multiple-choice option: 28 px letter badge + label, min 52 high,
/// 2 px border. Shared with the QCM / exam screens.
class AnswerOption extends StatelessWidget {
  const AnswerOption({
    required this.letter,
    required this.label,
    required this.state,
    required this.onTap,
    this.picked = false,
    super.key,
  });

  final String letter;
  final String label;
  final AnswerState state;
  final VoidCallback? onTap;

  /// Whether this is the option the student chose — only that one plays
  /// the correct-pulse / wrong-shake feedback (a correct answer revealed
  /// after a mistake stays still).
  final bool picked;

  @override
  Widget build(BuildContext context) {
    final DirasstyType type = context.dirasstyType;
    final (
      Color bg,
      Color border,
      Color badgeBg,
      Color badgeFg,
      IconData? trailing
    ) = switch (state) {
      AnswerState.idle => (
          DirasstyColors.surface,
          DirasstyColors.line,
          DirasstyColors.track,
          DirasstyColors.ink,
          null
        ),
      AnswerState.selected => (
          DirasstyColors.tealTint,
          DirasstyColors.teal,
          DirasstyColors.teal,
          Colors.white,
          null
        ),
      AnswerState.correct => (
          DirasstyColors.tealTint,
          DirasstyColors.teal,
          DirasstyColors.teal,
          Colors.white,
          Icons.check_circle_rounded
        ),
      AnswerState.wrong => (
          DirasstyColors.errorTint,
          DirasstyColors.error,
          DirasstyColors.error,
          Colors.white,
          Icons.cancel_rounded
        ),
      AnswerState.disabled => (
          DirasstyColors.surface,
          DirasstyColors.line,
          DirasstyColors.track,
          DirasstyColors.textMuted,
          null
        ),
    };
    final bool tappable =
        state == AnswerState.idle || state == AnswerState.selected;

    final AnswerFeedback feedback = !picked
        ? AnswerFeedback.none
        : switch (state) {
            AnswerState.correct => AnswerFeedback.correct,
            AnswerState.wrong => AnswerFeedback.wrong,
            _ => AnswerFeedback.none,
          };

    return FeedbackMotion(
      feedback: feedback,
      child: Semantics(
        button: true,
        selected: state == AnswerState.selected,
        child: Material(
          color: bg,
          shape: RoundedRectangleBorder(
            borderRadius: DirasstyRadius.cardR,
            side: BorderSide(color: border, width: 2),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: tappable ? onTap : null,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: DirasstyRadius.smallR,
                      ),
                      child: Text(
                        letter,
                        style: type.label.copyWith(
                          color: badgeFg,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                    const SizedBox(width: DirasstySpace.md),
                    Expanded(
                      child: Text(
                        cleanMathForDisplay(label),
                        style: type.body.copyWith(
                          color: state == AnswerState.disabled
                              ? DirasstyColors.textMuted
                              : DirasstyColors.text,
                          fontWeight: state == AnswerState.idle
                              ? FontWeight.w400
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                    if (trailing != null) Icon(trailing, color: border),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
