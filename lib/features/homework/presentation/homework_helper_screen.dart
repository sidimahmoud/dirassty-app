import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/i18n/app_lang.dart';
import '../../../core/i18n/app_language_provider.dart';
import '../../../core/models/diagram_spec.dart';
import '../../../core/models/homework_helper_result.dart';
import '../../../core/text/math_format.dart';
import '../../../core/theme/dirassty_theme.dart';
import '../../../core/widgets/diagram_view.dart';
import '../../../core/widgets/dirassty/dirassty_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../ai_report/presentation/report_ai_button.dart';
import '../../student/application/student_providers.dart';
import '../application/homework_providers.dart';
import '../application/homework_state.dart';

/// "Snap a photo of any problem → Dirassty guides you through it."
///
/// Same phase machine and AI call as before (picking → analyzing →
/// result; the model answers either 'solve' with steps + final answer, or
/// 'explain' with key concepts + explanation), presented as a guided
/// conversation: the photo, detected subject/topic chips, then the steps
/// revealed one at a time ("Étape n sur N"), the final answer only on
/// request.
///
/// Deviation from HomeworkHelper.dc.html (backend gap): the AI returns one
/// complete answer, not a conversation, so there's no reply input bar and
/// the guiding questions are the steps themselves. TODO(api): a
/// conversational endpoint that asks questions and withholds the final
/// answer until the student finds it.
class HomeworkHelperScreen extends ConsumerStatefulWidget {
  const HomeworkHelperScreen({super.key});

  static const String path = '/homework-helper';
  static const String name = 'homeworkHelper';

  @override
  ConsumerState<HomeworkHelperScreen> createState() =>
      _HomeworkHelperScreenState();
}

class _HomeworkHelperScreenState extends ConsumerState<HomeworkHelperScreen> {
  Future<void> _analyze() async {
    final int grade = (await ref.read(currentStudentProvider.future)).grade;
    final AppLang lang = ref.read(appLanguageProvider);
    await ref
        .read(homeworkControllerProvider.notifier)
        .analyze(grade: grade, lang: lang.dbValue);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final HomeworkState state = ref.watch(homeworkControllerProvider);
    final HomeworkController controller =
        ref.read(homeworkControllerProvider.notifier);

    return Scaffold(
      backgroundColor: DirasstyColors.background,
      appBar: AppBar(
        title: Text(l10n.homeworkHelper),
        actions: [
          if (state is! HomeworkPicking || state.image != null)
            IconButton(
              tooltip: l10n.retakePhoto,
              icon: const Icon(Icons.photo_camera_outlined),
              onPressed: controller.reset,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(
          DirasstySpace.screen,
          DirasstySpace.sm,
          DirasstySpace.screen,
          DirasstySpace.xxl,
        ),
        children: [
          switch (state) {
            HomeworkPicking() =>
              _PickingView(state: state, onAnalyze: _analyze),
            HomeworkAnalyzing() => const _AnalyzingView(),
            HomeworkResultReady(:final result) =>
              _ResultView(result: result, onNewPhoto: controller.reset),
          },
        ],
      ),
    );
  }
}

class _PickingView extends ConsumerWidget {
  const _PickingView({required this.state, required this.onAnalyze});

  final HomeworkPicking state;
  final VoidCallback onAnalyze;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    final HomeworkController controller =
        ref.read(homeworkControllerProvider.notifier);
    final bool hasImage = state.image != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasImage)
          ClipRRect(
            borderRadius: DirasstyRadius.cardR,
            child: Image.memory(
              state.image!.bytes,
              height: 260,
              fit: BoxFit.cover,
            ),
          )
        else
          Container(
            padding: const EdgeInsetsDirectional.all(DirasstySpace.xl),
            decoration: BoxDecoration(
              color: DirasstyColors.surface,
              borderRadius: DirasstyRadius.cardR,
              border: Border.all(color: DirasstyColors.line, width: 1.5),
            ),
            child: Column(
              children: [
                const IconBadge(icon: Icons.photo_camera_rounded),
                const SizedBox(height: DirasstySpace.lg),
                Text(
                  l10n.photoPrompt,
                  textAlign: TextAlign.center,
                  style: type.heading,
                ),
                const SizedBox(height: DirasstySpace.xs),
                Text(
                  l10n.photoPromptBody,
                  textAlign: TextAlign.center,
                  style: type.bodySmall,
                ),
              ],
            ),
          ),
        const SizedBox(height: DirasstySpace.lg),
        Row(
          children: [
            Expanded(
              child: DirasstyButton(
                label: l10n.camera,
                icon: Icons.photo_camera_rounded,
                variant: hasImage
                    ? DirasstyButtonVariant.quiet
                    : DirasstyButtonVariant.primary,
                onPressed: () => controller.pickImage(ImageSource.camera),
              ),
            ),
            const SizedBox(width: DirasstySpace.md),
            Expanded(
              child: DirasstyButton(
                label: l10n.gallery,
                icon: Icons.photo_library_rounded,
                variant: DirasstyButtonVariant.quiet,
                onPressed: () => controller.pickImage(ImageSource.gallery),
              ),
            ),
          ],
        ),
        if (state.errorMessage != null) ...[
          const SizedBox(height: DirasstySpace.md),
          Text(
            l10n.errGeneric,
            style: type.label.copyWith(color: DirasstyColors.error),
          ),
        ],
        if (hasImage) ...[
          const SizedBox(height: DirasstySpace.md),
          DirasstyButton(
            label: l10n.analyze,
            icon: Icons.auto_awesome_rounded,
            onPressed: onAnalyze,
          ),
        ],
        const SizedBox(height: DirasstySpace.lg),
        const _GuideNote(),
      ],
    );
  }
}

class _AnalyzingView extends StatelessWidget {
  const _AnalyzingView();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Skeleton(height: 150, radius: DirasstyRadius.card),
        const SizedBox(height: DirasstySpace.lg),
        const Skeleton(height: 28, width: 200, radius: DirasstyRadius.pill),
        const SizedBox(height: DirasstySpace.lg),
        _AiBubble(
          child: Text(
            l10n.analyzingPhoto,
            style: context.dirasstyType.bodySmall
                .copyWith(color: DirasstyColors.text),
          ),
        ),
      ],
    );
  }
}

class _ResultView extends ConsumerStatefulWidget {
  const _ResultView({required this.result, required this.onNewPhoto});

  final HomeworkHelperResult result;
  final VoidCallback onNewPhoto;

  @override
  ConsumerState<_ResultView> createState() => _ResultViewState();
}

class _ResultViewState extends ConsumerState<_ResultView> {
  /// Steps revealed so far (at least the first), and whether the final
  /// answer was asked for.
  int _shownSteps = 1;
  bool _answerShown = false;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    final HomeworkHelperResult r = widget.result;
    final HomeworkState state = ref.watch(homeworkControllerProvider);
    final List<String> steps = r.steps ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state is HomeworkResultReady && state.image != null)
          ClipRRect(
            borderRadius: DirasstyRadius.cardR,
            child: Image.memory(
              state.image!.bytes,
              height: 150,
              fit: BoxFit.cover,
            ),
          ),
        const SizedBox(height: DirasstySpace.lg),
        Wrap(
          spacing: DirasstySpace.sm,
          runSpacing: DirasstySpace.sm,
          children: [
            if (r.detectedSubject.isNotEmpty)
              DirasstyChip(
                label: l10n.detectedSubject(r.detectedSubject),
                variant: DirasstyChipVariant.teal,
                dense: true,
              ),
            if (r.detectedTopic.isNotEmpty)
              DirasstyChip(label: r.detectedTopic, dense: true),
          ],
        ),
        const SizedBox(height: DirasstySpace.lg),
        if (!r.readable)
          PhotoRetakeCard(issues: r.imageIssues, onRetake: widget.onNewPhoto)
        else if (r.isSolve) ...[
          _AiBubble(
            child: Text.rich(
              TextSpan(
                children: [
                  if (r.problemStatement != null) ...[
                    TextSpan(text: '${l10n.readProblem} '),
                    TextSpan(
                      text: cleanMathForDisplay(r.problemStatement!),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const TextSpan(text: '\n'),
                  ],
                  TextSpan(text: l10n.letsSolveTogether),
                ],
              ),
              style: type.bodySmall.copyWith(color: DirasstyColors.text),
            ),
          ),
          if (r.figure != null) ...[
            const SizedBox(height: DirasstySpace.md),
            _FigureCard(spec: r.figure!),
          ],
          for (int i = 0; i < _shownSteps && i < steps.length; i++) ...[
            const SizedBox(height: DirasstySpace.md),
            _StepCard(index: i, total: steps.length, text: steps[i]),
          ],
          const SizedBox(height: DirasstySpace.lg),
          if (_shownSteps < steps.length)
            DirasstyButton(
              label: l10n.nextStep,
              variant: DirasstyButtonVariant.secondary,
              compact: true,
              onPressed: () => setState(() => _shownSteps++),
            )
          else if ((r.fullSolution != null || r.finalAnswer != null) &&
              !_answerShown)
            DirasstyButton(
              label: l10n.showAnswer,
              variant: DirasstyButtonVariant.quiet,
              compact: true,
              onPressed: () => setState(() => _answerShown = true),
            ),
          if (_answerShown && (r.fullSolution != null || r.finalAnswer != null))
            _FullAnswer(
              fullSolution: r.fullSolution,
              finalAnswer: r.finalAnswer,
            ),
        ] else ...[
          if (r.keyConcepts != null && r.keyConcepts!.isNotEmpty) ...[
            Text(
              l10n.keyConceptsLabel,
              style:
                  type.label.copyWith(fontSize: 14, color: DirasstyColors.text),
            ),
            const SizedBox(height: DirasstySpace.sm),
            Wrap(
              spacing: DirasstySpace.sm,
              runSpacing: DirasstySpace.sm,
              children: [
                for (final String c in r.keyConcepts!)
                  DirasstyChip(
                    label: c,
                    variant: DirasstyChipVariant.gold,
                    dense: true,
                  ),
              ],
            ),
            const SizedBox(height: DirasstySpace.lg),
          ],
          if (r.figure != null) ...[
            _FigureCard(spec: r.figure!),
            const SizedBox(height: DirasstySpace.lg),
          ],
          if (r.explanation != null)
            for (final String para in r.explanation!
                .split(RegExp(r'\n\s*\n'))
                .where((p) => p.trim().isNotEmpty)) ...[
              _AiBubble(
                child: Text(
                  cleanMathForDisplay(para.trim()),
                  style: type.bodySmall.copyWith(color: DirasstyColors.text),
                ),
              ),
              const SizedBox(height: DirasstySpace.md),
            ],
        ],
        if (r.readable) ...[
          const SizedBox(height: DirasstySpace.md),
          ReportAiButton(
            feature: 'homework',
            aiText: [
              if (r.problemStatement != null) r.problemStatement!,
              ...steps,
              if (r.fullSolution != null) r.fullSolution!,
              if (r.finalAnswer != null) '= ${r.finalAnswer}',
              if (r.explanation != null) r.explanation!,
            ].join('\n'),
            reportContext: {
              'kind': r.kind,
              'subject': r.detectedSubject,
              'topic': r.detectedTopic,
            },
          ),
        ],
        const SizedBox(height: DirasstySpace.lg),
        const _GuideNote(),
        const SizedBox(height: DirasstySpace.xl),
        DirasstyButton(
          label: l10n.newPhoto,
          icon: Icons.photo_camera_rounded,
          variant: DirasstyButtonVariant.quiet,
          onPressed: widget.onNewPhoto,
        ),
      ],
    );
  }
}

/// Dirassty's side of the conversation: white bubble, start-aligned, max 82%
/// width, radius 16 with a small corner at the start-bottom.
class _AiBubble extends StatelessWidget {
  const _AiBubble({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: FractionallySizedBox(
        widthFactor: 0.82,
        alignment: AlignmentDirectional.centerStart,
        child: Container(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 14,
            vertical: DirasstySpace.md,
          ),
          decoration: BoxDecoration(
            color: DirasstyColors.surface,
            border: Border.all(color: DirasstyColors.line),
            borderRadius: const BorderRadiusDirectional.only(
              topStart: Radius.circular(16),
              topEnd: Radius.circular(16),
              bottomEnd: Radius.circular(16),
              bottomStart: Radius.circular(4),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.index,
    required this.total,
    required this.text,
  });

  final int index;
  final int total;
  final String text;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    return Container(
      padding: const EdgeInsetsDirectional.all(14),
      decoration: BoxDecoration(
        color: Color.lerp(DirasstyColors.tealTint, DirasstyColors.surface, 0.5),
        borderRadius: DirasstyRadius.cardR,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.stepOf(index + 1, total).toUpperCase(),
            style: type.label.copyWith(
              color: DirasstyColors.teal,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: DirasstySpace.xs),
          Text(
            cleanMathForDisplay(text),
            style: type.body.copyWith(fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _GuideNote extends StatelessWidget {
  const _GuideNote();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.info_outline_rounded,
          size: 16,
          color: DirasstyColors.textMuted,
        ),
        const SizedBox(width: DirasstySpace.sm),
        Expanded(
          child: Text(
            AppLocalizations.of(context).helperGuideNote,
            style: context.dirasstyType.label
                .copyWith(fontWeight: FontWeight.w400),
          ),
        ),
      ],
    );
  }
}

/// The revealed answer: the complete written solution (every sub-question,
/// each calculation and why) as a student would write it on their copy,
/// then the result(s) highlighted. Falls back to the result alone for an
/// older API response without `full_solution`.
class _FullAnswer extends StatelessWidget {
  const _FullAnswer({required this.fullSolution, required this.finalAnswer});

  final String? fullSolution;
  final String? finalAnswer;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    final String? full =
        fullSolution?.trim().isEmpty == true ? null : fullSolution?.trim();
    return Container(
      padding: const EdgeInsetsDirectional.all(DirasstySpace.lg),
      decoration: BoxDecoration(
        color: DirasstyColors.surface,
        borderRadius: DirasstyRadius.cardR,
        border: Border.all(color: DirasstyColors.teal.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            (full != null ? l10n.fullAnswerLabel : l10n.answerLabel)
                .toUpperCase(),
            style: type.label.copyWith(color: DirasstyColors.tealDark),
          ),
          if (full != null) ...[
            const SizedBox(height: DirasstySpace.sm),
            Text(
              cleanMathForDisplay(full),
              style: type.bodySmall
                  .copyWith(color: DirasstyColors.text, height: 1.6),
            ),
          ],
          if (finalAnswer != null && finalAnswer!.trim().isNotEmpty) ...[
            const SizedBox(height: DirasstySpace.md),
            Container(
              padding: const EdgeInsetsDirectional.all(DirasstySpace.md),
              decoration: const BoxDecoration(
                color: DirasstyColors.tealTint,
                borderRadius: DirasstyRadius.smallR,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (full != null) ...[
                    Text(
                      l10n.answerLabel,
                      style:
                          type.label.copyWith(color: DirasstyColors.tealDark),
                    ),
                    const SizedBox(height: DirasstySpace.xs),
                  ],
                  Text(
                    cleanMathForDisplay(finalAnswer!.trim()),
                    style: type.subheading
                        .copyWith(color: DirasstyColors.tealDark),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The exercise's figure, drawn to scale from the AI's coordinates.
class _FigureCard extends StatelessWidget {
  const _FigureCard({required this.spec});

  final DiagramSpec spec;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsetsDirectional.all(DirasstySpace.md),
      decoration: BoxDecoration(
        color: DirasstyColors.surface,
        borderRadius: DirasstyRadius.cardR,
        border: Border.all(color: DirasstyColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.figureLabel.toUpperCase(),
            style: context.dirasstyType.label
                .copyWith(color: DirasstyColors.tealDark),
          ),
          const SizedBox(height: DirasstySpace.sm),
          DiagramView(spec: spec),
        ],
      ),
    );
  }
}
