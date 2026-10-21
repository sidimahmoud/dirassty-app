import 'package:flutter/material.dart';

import '../../../../core/models/open_exercise_correction.dart';
import '../../../../core/text/math_format.dart';
import '../../../../core/theme/dirassty_theme.dart';
import '../../../../core/widgets/dirassty/dirassty_widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../ai_report/presentation/report_ai_button.dart';

/// The AI check of an open exercise, laid out to be scanned, not read:
/// verdict banner (+ one-line encouragement) → three ✓/✗ checks
/// (reasoning, calculations, final answer) → what was right → what to fix
/// → the full solution and "what I read", both folded by default.
class CorrectionResult extends StatelessWidget {
  const CorrectionResult({
    required this.correction,
    required this.lang,
    super.key,
  });

  final OpenExerciseCorrection correction;

  /// The subject's language ('ar' / 'fr'): the AI writes in it, so its text
  /// is laid out RTL for Arabic subjects whatever the app's own language.
  final String lang;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final OpenExerciseCorrection c = correction;
    final TextDirection dir =
        lang == 'ar' ? TextDirection.rtl : TextDirection.ltr;
    final List<String> steps = _solutionSteps(c.correctSolution);
    final bool hasChecks = c.reasoningCorrect != null ||
        c.calculationCorrect != null ||
        c.finalAnswerCorrect != null;
    final String wellDone = c.whatWasRight.isNotEmpty
        ? c.whatWasRight
        : c.correctSteps.take(2).join('\n');
    final bool hasFixes = c.score != CorrectionScore.correct &&
        (c.mistakes.isNotEmpty || c.whatWasWrong.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _VerdictBanner(correction: c, dir: dir),
        if (hasChecks) ...[
          const SizedBox(height: DirasstySpace.md),
          Row(
            children: [
              _CheckPill(label: l10n.resultReasoning, ok: c.reasoningCorrect),
              const SizedBox(width: DirasstySpace.sm),
              _CheckPill(
                label: l10n.resultCalculation,
                ok: c.calculationCorrect,
              ),
              const SizedBox(width: DirasstySpace.sm),
              _CheckPill(
                label: l10n.resultFinalAnswer,
                ok: c.finalAnswerCorrect,
              ),
            ],
          ),
        ],
        if (c.method == 'alternative_valid') ...[
          const SizedBox(height: DirasstySpace.sm),
          Text(
            l10n.alternativeMethod,
            textAlign: TextAlign.center,
            style: context.dirasstyType.label
                .copyWith(color: DirasstyColors.tealDark),
          ),
        ],
        if (wellDone.isNotEmpty) ...[
          const SizedBox(height: DirasstySpace.lg),
          _Section(
            icon: Icons.thumb_up_alt_rounded,
            color: DirasstyColors.teal,
            title: l10n.correctionWellDone,
            child: _Body(wellDone, dir: dir),
          ),
        ],
        if (hasFixes) ...[
          const SizedBox(height: DirasstySpace.md),
          _Section(
            icon: Icons.edit_note_rounded,
            color: DirasstyColors.error,
            title: l10n.correctionToFix,
            child: c.mistakes.isEmpty
                ? _Body(c.whatWasWrong, dir: dir)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (int i, CorrectionMistake m)
                          in c.mistakes.indexed)
                        _MistakeRow(index: i + 1, mistake: m, dir: dir),
                    ],
                  ),
          ),
        ],
        if (steps.isNotEmpty) ...[
          const SizedBox(height: DirasstySpace.md),
          _Foldable(
            icon: Icons.menu_book_rounded,
            closedLabel: l10n.correctionSeeSolution,
            openLabel: l10n.correctionHideSolution,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (int i, String s) in steps.indexed)
                  _SolutionStep(
                    index: i + 1,
                    text: s,
                    last: i == steps.length - 1,
                    dir: dir,
                  ),
              ],
            ),
          ),
        ],
        if (c.transcription.isNotEmpty) ...[
          const SizedBox(height: DirasstySpace.sm),
          _Foldable(
            icon: Icons.document_scanner_outlined,
            closedLabel: l10n.whatIRead,
            openLabel: l10n.whatIRead,
            quiet: true,
            child: _Body(c.transcription, dir: dir),
          ),
        ],
        const SizedBox(height: DirasstySpace.sm),
        ReportAiButton(
          feature: 'correction',
          aiText: [
            c.whatWasRight,
            c.whatWasWrong,
            c.correctSolution,
          ].where((t) => t.isNotEmpty).join('\n'),
          reportContext: {'transcription': c.transcription, 'lang': lang},
        ),
      ],
    );
  }

  /// "One step per line" from the API → clean steps, without the AI's own
  /// numbering ("1.", "Étape 2 :", "- ").
  static List<String> _solutionSteps(String raw) {
    final RegExp numbering = RegExp(
      r'^\s*(?:[-•*]\s*|\d+\s*[.):-]\s*|(?:étape|etape|step)\s*\d+\s*[:.)-]?\s*)',
      caseSensitive: false,
    );
    return raw
        .split('\n')
        .map((String l) => l.replaceFirst(numbering, '').trim())
        .where((String l) => l.isNotEmpty)
        .toList();
  }
}

class _VerdictBanner extends StatelessWidget {
  const _VerdictBanner({required this.correction, required this.dir});

  final OpenExerciseCorrection correction;
  final TextDirection dir;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    final (String label, Color color, Color tint, IconData icon) =
        switch (correction.score) {
      CorrectionScore.correct => (
          l10n.verdictCorrect,
          DirasstyColors.teal,
          DirasstyColors.tealTint,
          Icons.check_rounded
        ),
      CorrectionScore.partial => (
          l10n.almost,
          DirasstyColors.goldStroke,
          DirasstyColors.goldTint,
          Icons.trending_up_rounded
        ),
      CorrectionScore.incorrect => (
          l10n.verdictReview,
          DirasstyColors.error,
          DirasstyColors.errorTint,
          Icons.replay_rounded
        ),
      CorrectionScore.undetermined => (
          l10n.verdictUndetermined,
          DirasstyColors.textMuted,
          DirasstyColors.track,
          Icons.help_outline_rounded
        ),
    };
    return Container(
      padding: const EdgeInsetsDirectional.all(DirasstySpace.lg),
      decoration:
          BoxDecoration(color: tint, borderRadius: DirasstyRadius.cardR),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: DirasstySpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.aiCorrection.toUpperCase(),
                  style: type.label.copyWith(fontSize: 11, color: color),
                ),
                const SizedBox(height: 2),
                Text(label, style: type.titleSmall.copyWith(color: color)),
                if (correction.encouragement.isNotEmpty) ...[
                  const SizedBox(height: DirasstySpace.xs),
                  Text(
                    correction.encouragement,
                    textDirection: dir,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: type.bodySmall.copyWith(color: DirasstyColors.text),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckPill extends StatelessWidget {
  const _CheckPill({required this.label, required this.ok});

  final String label;
  final bool? ok;

  @override
  Widget build(BuildContext context) {
    final (Color color, IconData icon) = switch (ok) {
      true => (DirasstyColors.teal, Icons.check_circle_rounded),
      false => (DirasstyColors.error, Icons.cancel_rounded),
      null => (DirasstyColors.idle, Icons.remove_circle_outline_rounded),
    };
    return Expanded(
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(
          vertical: DirasstySpace.sm,
          horizontal: DirasstySpace.xs,
        ),
        decoration: BoxDecoration(
          color: DirasstyColors.surface,
          borderRadius: DirasstyRadius.cardR,
          border: Border.all(color: DirasstyColors.line),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: DirasstySpace.xs),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: context.dirasstyType.label
                  .copyWith(color: DirasstyColors.text),
            ),
          ],
        ),
      ),
    );
  }
}

/// A titled block with a colored accent bar on the leading edge.
class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.color,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final Color color;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DirasstyColors.surface,
        borderRadius: DirasstyRadius.cardR,
        border: BorderDirectional(start: BorderSide(color: color, width: 3)),
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(
        DirasstySpace.md,
        DirasstySpace.md,
        DirasstySpace.md,
        DirasstySpace.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: DirasstySpace.sm),
              Text(
                title,
                style: context.dirasstyType.subheading
                    .copyWith(fontSize: 14, color: color),
              ),
            ],
          ),
          const SizedBox(height: DirasstySpace.sm),
          child,
        ],
      ),
    );
  }
}

class _MistakeRow extends StatelessWidget {
  const _MistakeRow({
    required this.index,
    required this.mistake,
    required this.dir,
  });

  final int index;
  final CorrectionMistake mistake;
  final TextDirection dir;

  @override
  Widget build(BuildContext context) {
    final DirasstyType type = context.dirasstyType;
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: DirasstySpace.sm),
      child: Directionality(
        textDirection: dir,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: DirasstyColors.errorTint,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$index',
                style: type.label.copyWith(
                  color: DirasstyColors.error,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: DirasstySpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (mistake.step.isNotEmpty)
                    Text(
                      cleanMathForDisplay(mistake.step),
                      style: type.label.copyWith(
                        color: DirasstyColors.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  Text(
                    cleanMathForDisplay(mistake.issue),
                    style: type.bodySmall.copyWith(color: DirasstyColors.text),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SolutionStep extends StatelessWidget {
  const _SolutionStep({
    required this.index,
    required this.text,
    required this.last,
    required this.dir,
  });

  final int index;
  final String text;
  final bool last;
  final TextDirection dir;

  @override
  Widget build(BuildContext context) {
    final DirasstyType type = context.dirasstyType;
    return Directionality(
      textDirection: dir,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: DirasstyColors.teal,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$index',
                    style: type.label.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (!last)
                  Expanded(
                    child: Container(width: 2, color: DirasstyColors.tealTint),
                  ),
              ],
            ),
            const SizedBox(width: DirasstySpace.md),
            Expanded(
              child: Padding(
                padding: EdgeInsetsDirectional.only(
                  top: 2,
                  bottom: last ? 0 : DirasstySpace.md,
                ),
                child: Text(
                  cleanMathForDisplay(text),
                  style: type.bodySmall
                      .copyWith(color: DirasstyColors.text, height: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A tap-to-open block, closed by default.
class _Foldable extends StatefulWidget {
  const _Foldable({
    required this.icon,
    required this.closedLabel,
    required this.openLabel,
    required this.child,
    this.quiet = false,
  });

  final IconData icon;
  final String closedLabel;
  final String openLabel;
  final Widget child;

  /// Lighter style for secondary info ("what I read").
  final bool quiet;

  @override
  State<_Foldable> createState() => _FoldableState();
}

class _FoldableState extends State<_Foldable> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final DirasstyType type = context.dirasstyType;
    final Color color =
        widget.quiet ? DirasstyColors.textMuted : DirasstyColors.tealDark;
    return Container(
      decoration: BoxDecoration(
        color: widget.quiet ? Colors.transparent : DirasstyColors.surface,
        borderRadius: DirasstyRadius.cardR,
        border: widget.quiet ? null : Border.all(color: DirasstyColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: DirasstyRadius.cardR,
            onTap: () => setState(() => _open = !_open),
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(minHeight: DirasstySize.minTouch),
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: DirasstySpace.md,
                  vertical: DirasstySpace.sm,
                ),
                child: Row(
                  children: [
                    Icon(widget.icon, size: 18, color: color),
                    const SizedBox(width: DirasstySpace.sm),
                    Expanded(
                      child: Text(
                        _open ? widget.openLabel : widget.closedLabel,
                        style: (widget.quiet ? type.label : type.subheading)
                            .copyWith(
                          fontSize: widget.quiet ? 12 : 14,
                          color: color,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _open ? 0.5 : 0,
                      duration: DirasstyMotion.fast,
                      child: Icon(Icons.expand_more_rounded, color: color),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: DirasstyMotion.fast,
            curve: DirasstyMotion.curve,
            alignment: AlignmentDirectional.topStart,
            child: _open
                ? Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      DirasstySpace.md,
                      0,
                      DirasstySpace.md,
                      DirasstySpace.md,
                    ),
                    child: widget.child,
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body(this.text, {required this.dir});

  final String text;
  final TextDirection dir;

  @override
  Widget build(BuildContext context) => Text(
        cleanMathForDisplay(text),
        textDirection: dir,
        style: context.dirasstyType.bodySmall
            .copyWith(color: DirasstyColors.text, height: 1.5),
      );
}
