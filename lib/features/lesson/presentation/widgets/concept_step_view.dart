import 'package:flutter/material.dart';

import '../../../../core/models/explanation_body.dart';
import '../../../../core/text/math_format.dart';
import '../../../../core/theme/dirassty_theme.dart';
import '../../../../core/widgets/diagram_view.dart';
import '../../../../core/widgets/dirassty/dirassty_widgets.dart';
import '../../../../l10n/app_localizations.dart';
import 'concept_check_card.dart';
import 'lesson_blocks.dart';

/// One taught concept ("Notion n sur N"): explanation, key formula,
/// worked examples the student steps through (or the "Dans la vraie vie"
/// card), then the gating mini-quiz — "Notion suivante" stays disabled
/// until [ConceptCheckCard] lets the student through.
///
/// Give this a fresh `key` per concept at the call site so no state
/// (example position, quiz attempts) leaks between concepts.
///
/// design_handoff LessonConcept.dc.html · DESIGN_SPEC §4 "Concept".
class ConceptStepView extends StatefulWidget {
  const ConceptStepView({
    required this.section,
    required this.index,
    required this.total,
    required this.onContinue,
    super.key,
    this.continueLabel,
  });

  final ConceptSection section;

  /// 0-based position among the lesson's concepts, and their count.
  final int index;
  final int total;
  final VoidCallback onContinue;

  /// Overrides "Notion suivante" — e.g. "Commencer le QCM" on the last
  /// step.
  final String? continueLabel;

  @override
  State<ConceptStepView> createState() => _ConceptStepViewState();
}

class _ConceptStepViewState extends State<ConceptStepView> {
  int _exampleIndex = 0;
  bool _examplesDone = false;
  bool _canContinue = false;

  bool get _hasExamples => widget.section.hasExamples;
  bool get _showCheck => !_hasExamples || _examplesDone;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    final ConceptSection section = widget.section;
    final String? coreIdea = section.coreIdea;

    return _StepScaffold(
      children: [
        Text(l10n.conceptOf(widget.index + 1, widget.total), style: type.label),
        Text(section.title, style: type.titleSmall.copyWith(fontSize: 22)),
        if (section.explanation != null) LessonText(section.explanation!),
        if (coreIdea != null)
          // Short core ideas are formulas/rules — shown as the design's
          // formula box; longer ones read better as a text callout.
          coreIdea.length <= 70
              ? FormulaBox(text: coreIdea)
              : Container(
                  padding: const EdgeInsetsDirectional.all(DirasstySpace.lg),
                  decoration: const BoxDecoration(
                      color: DirasstyColors.ivory,
                      borderRadius: DirasstyRadius.cardR),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_rounded,
                          size: 20, color: DirasstyColors.goldStroke),
                      const SizedBox(width: DirasstySpace.md),
                      Expanded(
                        child: Text(
                          cleanMathForDisplay(coreIdea),
                          style: type.subheading.copyWith(height: 1.45),
                        ),
                      ),
                    ],
                  ),
                ),
        if (_hasExamples)
          _ExampleCard(
            example: section.examples[_exampleIndex],
            index: _exampleIndex,
            total: section.examples.length,
            done: _examplesDone,
            onNext: () => setState(() {
              if (_exampleIndex < section.examples.length - 1) {
                _exampleIndex++;
              } else {
                _examplesDone = true;
              }
            }),
          )
        else if (section.realLifeExample != null)
          LessonCard(
            icon: Icons.public_rounded,
            label: l10n.realLife,
            children: [LessonText(section.realLifeExample!, small: true)],
          ),
        if (_showCheck)
          ConceptCheckCard(
            check: section.check,
            canContinue: _canContinue,
            onCanContinueChanged: (v) => setState(() => _canContinue = v),
          )
        else
          Text(l10n.finishExamplesFirst, style: type.label),
      ],
      bottom: [
        DirasstyButton(
          label: widget.continueLabel ?? l10n.nextConcept,
          icon: Directionality.of(context) == TextDirection.rtl
              ? Icons.arrow_back_rounded
              : Icons.arrow_forward_rounded,
          onPressed: _canContinue ? widget.onContinue : null,
        ),
        if (!_canContinue)
          Text(l10n.answerToContinue,
              textAlign: TextAlign.center, style: type.label),
      ],
    );
  }
}

/// One worked example of the concept, stepped through one at a time:
/// scenario, optional diagram, numbered steps, result.
class _ExampleCard extends StatelessWidget {
  const _ExampleCard({
    required this.example,
    required this.index,
    required this.total,
    required this.done,
    required this.onNext,
  });

  final WorkedExample example;
  final int index;
  final int total;
  final bool done;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    return DirasstyCard(
      variant: DirasstyCardVariant.shadow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.exampleOf(index + 1, total).toUpperCase(),
              style: type.label),
          const SizedBox(height: DirasstySpace.sm),
          LessonText(example.scenario),
          if (example.diagram != null) ...[
            const SizedBox(height: DirasstySpace.md),
            DiagramView(spec: example.diagram!, color: DirasstyColors.teal),
          ],
          for (final (int i, String step) in example.steps.indexed) ...[
            const SizedBox(height: DirasstySpace.md),
            NumberedStep(number: i + 1, child: LessonText(step, small: true)),
          ],
          const SizedBox(height: DirasstySpace.md),
          FormulaBox(text: example.result, compact: true),
          if (!done) ...[
            const SizedBox(height: DirasstySpace.lg),
            DirasstyButton(
              label: index < total - 1 ? l10n.nextExample : l10n.continueAction,
              variant: DirasstyButtonVariant.quiet,
              compact: true,
              onPressed: onNext,
            ),
          ],
        ],
      ),
    );
  }
}

/// Scrolling step body (20 px padding, 18 gap) with its actions under the
/// content.
class _StepScaffold extends StatelessWidget {
  const _StepScaffold({required this.children, required this.bottom});

  final List<Widget> children;
  final List<Widget> bottom;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(
          DirasstySpace.screen, DirasstySpace.lg, DirasstySpace.screen, DirasstySpace.xxl),
      children: [
        for (int i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(height: i == 1 ? DirasstySpace.sm : 18),
          children[i],
        ],
        const SizedBox(height: DirasstySpace.xl),
        for (int i = 0; i < bottom.length; i++) ...[
          if (i > 0) const SizedBox(height: DirasstySpace.sm),
          bottom[i],
        ],
      ],
    );
  }
}
