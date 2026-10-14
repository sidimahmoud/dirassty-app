import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/models/open_exercise_correction.dart';
import '../../../core/models/video_body.dart';
import '../../../core/text/math_format.dart';
import '../../../core/theme/dirassty_theme.dart';
import '../../../core/widgets/diagram_view.dart';
import '../../../core/widgets/dirassty/dirassty_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../courses/application/courses_providers.dart';
import '../../lesson/application/lesson_providers.dart';
import '../application/open_practice_controller.dart';
import '../application/open_practice_state.dart';
import '../../tutor/presentation/tutor_sheet.dart';
import 'widgets/correction_result.dart';
import 'widgets/exercise_video_section.dart';
import 'widgets/symbol_toolbar.dart';

/// Open (free-answer) practice with AI correction: exercise card, "Ta
/// réponse" box (LTR — it's math) with the symbol toolbar, the hint step,
/// then the "Correction Dirassty AI" card (verdict chip Juste / Presque / À
/// revoir, explanation, the right answer) and the actions: similar
/// exercise, method video, revise my answer.
///
/// Flow and AI calls unchanged (OpenPracticeController); "Corriger ma
/// réponse" uses its reviseAnswer step.
///
/// design_handoff OpenPractice.dc.html · DESIGN_SPEC §4 "Open practice".
class OpenPracticeScreen extends ConsumerWidget {
  const OpenPracticeScreen({required this.lessonId, super.key});

  static const String path = '/open-practice/:lessonId';
  static const String name = 'openPractice';

  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final OpenPracticeState state =
        ref.watch(openPracticeControllerProvider(lessonId));
    final String lessonTitle =
        ref.watch(lessonByIdProvider(lessonId)).valueOrNull?.lessonTitle ?? '';

    return Scaffold(
      backgroundColor: DirasstyColors.background,
      appBar: AppBar(
        title: Text(
          lessonTitle.isEmpty
              ? l10n.guidedExercises
              : l10n.openExerciseLabel(lessonTitle),
          style: context.dirasstyType.label.copyWith(fontSize: 14),
        ),
      ),
      body: switch (state) {
        OppLoading() => const Center(child: CircularProgressIndicator()),
        OppError() => Center(
            child: ErrorState(
              title: l10n.exercisesLoadError,
              onRetry: () =>
                  ref.invalidate(openPracticeControllerProvider(lessonId)),
            ),
          ),
        OppEmpty() => Center(
            child: EmptyState(
              icon: Icons.edit_note_rounded,
              title: l10n.noExercisesTitle,
              message: l10n.noExercisesBody,
              actionLabel: l10n.backToLesson,
              onAction: () => Navigator.of(context).maybePop(),
            ),
          ),
        OppActive() => _ActiveView(state: state, lessonId: lessonId),
      },
    );
  }
}

class _ActiveView extends ConsumerStatefulWidget {
  const _ActiveView({required this.state, required this.lessonId});

  final OppActive state;
  final String lessonId;

  @override
  ConsumerState<_ActiveView> createState() => _ActiveViewState();
}

class _ActiveViewState extends ConsumerState<_ActiveView> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.state.draftAnswer);
  late final FocusNode _focusNode = FocusNode();

  OpenPracticeController get _notifier =>
      ref.read(openPracticeControllerProvider(widget.lessonId).notifier);

  @override
  void didUpdateWidget(_ActiveView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new exercise, or going back to edit, resets the field to the
    // controller's draft — without fighting the student's own typing.
    final bool newExercise = oldWidget.state.activeId != widget.state.activeId;
    final bool backToEditing =
        oldWidget.state.phase != OpenPracticePhase.answering &&
            widget.state.phase == OpenPracticePhase.answering;
    if (newExercise || backToEditing)
      _controller.text = widget.state.draftAnswer;
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _insertSymbol(String symbol) {
    final TextSelection selection = _controller.selection;
    final String text = _controller.text;
    final int start = selection.start >= 0 ? selection.start : text.length;
    final int end = selection.end >= 0 ? selection.end : text.length;
    final String newText = text.replaceRange(start, end, symbol);
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + symbol.length),
    );
    _notifier.updateDraft(newText);
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    final OppActive state = widget.state;
    final bool hasVideos =
        (ref.watch(exerciseVideosProvider(widget.lessonId)).valueOrNull ??
                const <VideoBody>[])
            .isNotEmpty;

    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(
          DirasstySpace.screen, DirasstySpace.sm, DirasstySpace.screen, DirasstySpace.xxl),
      children: [
        DirasstyCard(
          variant: DirasstyCardVariant.shadow,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                      child: Text(
                          l10n.exerciseN(state.exerciseIndex + 1).toUpperCase(),
                          style: type.label)),
                  if (state.attempt > 1)
                    DirasstyChip(label: l10n.attemptN(state.attempt), dense: true),
                ],
              ),
              const SizedBox(height: DirasstySpace.sm),
              Text(cleanMathForDisplay(state.activeBody.question),
                  style: type.body.copyWith(height: 1.55)),
              if (state.activeBody.diagram != null) ...[
                const SizedBox(height: DirasstySpace.md),
                DiagramView(
                    spec: state.activeBody.diagram!, color: DirasstyColors.teal),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        switch (state.phase) {
          OpenPracticePhase.answering => _buildAnswering(l10n, type, state),
          OpenPracticePhase.hint => _buildHint(l10n, type, state),
          OpenPracticePhase.correcting => _Waiting(label: l10n.correcting),
          OpenPracticePhase.generating =>
            _Waiting(label: l10n.generatingExercise),
          OpenPracticePhase.corrected =>
            _buildCorrected(l10n, type, state, hasVideos),
        },
      ],
    );
  }

  Widget _buildAnswering(
      AppLocalizations l10n, DirasstyType type, OppActive state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.yourAnswer,
            style: type.label.copyWith(fontSize: 14, color: DirasstyColors.text)),
        const SizedBox(height: DirasstySpace.sm),
        Directionality(
          textDirection: TextDirection.ltr,
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            onChanged: _notifier.updateDraft,
            minLines: 3,
            maxLines: 6,
            style: type.body.copyWith(fontFamily: 'Inter'),
            decoration: InputDecoration(hintText: l10n.typeAnswer),
          ),
        ),
        const SizedBox(height: DirasstySpace.md),
        Text(l10n.usefulSymbols, style: type.label),
        const SizedBox(height: DirasstySpace.xs),
        SymbolToolbar(onInsert: _insertSymbol),
        const SizedBox(height: DirasstySpace.xl),
        DirasstyButton(
          label: l10n.submitAnswer,
          onPressed: state.draftAnswer.trim().length >= 3
              ? _notifier.submitDraft
              : null,
        ),
        const SizedBox(height: DirasstySpace.md),
        DirasstyButton(
          label: l10n.checkWithPhoto,
          variant: DirasstyButtonVariant.secondary,
          onPressed: () => _pickAndCheckPhotos(l10n),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(top: DirasstySpace.xs),
          child: Text(l10n.checkPhotoBody,
              textAlign: TextAlign.center,
              style: type.label.copyWith(fontWeight: FontWeight.w400)),
        ),
        const SizedBox(height: DirasstySpace.sm),
        _TutorButton(state: state),
        if (state.apiError != null) ...[
          const SizedBox(height: DirasstySpace.md),
          Text(state.apiError!,
              style: type.label.copyWith(color: DirasstyColors.error)),
        ],
      ],
    );
  }

  /// Camera (one page) or gallery (up to 3 pages), resized — enough for
  /// handwriting, far fewer image tokens and bytes than a raw photo.
  Future<void> _pickAndCheckPhotos(AppLocalizations l10n) async {
    final ImageSource? source = await showDirasstyBottomSheet<ImageSource>(
      context,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.checkWithPhoto, style: sheetContext.dirasstyType.titleSmall),
          const SizedBox(height: DirasstySpace.xs),
          Text(l10n.checkPhotoBody, style: sheetContext.dirasstyType.bodySmall),
          const SizedBox(height: DirasstySpace.lg),
          DirasstyButton(
            label: l10n.takePhoto,
            icon: Icons.photo_camera_rounded,
            onPressed: () => Navigator.of(sheetContext).pop(ImageSource.camera),
          ),
          const SizedBox(height: DirasstySpace.md),
          DirasstyButton(
            label: l10n.chooseFromGallery,
            icon: Icons.photo_library_outlined,
            variant: DirasstyButtonVariant.secondary,
            onPressed: () =>
                Navigator.of(sheetContext).pop(ImageSource.gallery),
          ),
        ],
      ),
    );
    if (source == null) return;
    final ImagePicker picker = ImagePicker();
    final List<XFile> files = source == ImageSource.camera
        ? [
            if (await picker.pickImage(
                    source: ImageSource.camera,
                    maxWidth: 1600,
                    imageQuality: 80)
                case final XFile f)
              f,
          ]
        : await picker.pickMultiImage(
            limit: 3, maxWidth: 1600, imageQuality: 80);
    if (files.isEmpty) return;
    final photos = <({Uint8List bytes, String filename})>[
      for (final XFile f in files.take(3))
        (bytes: await f.readAsBytes(), filename: f.name),
    ];
    await _notifier.checkPhotos(photos);
  }

  Widget _buildHint(AppLocalizations l10n, DirasstyType type, OppActive state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AnswerEcho(answer: state.submittedAnswer),
        const SizedBox(height: DirasstySpace.lg),
        if (state.activeBody.hint.isNotEmpty) ...[
          Container(
            padding: const EdgeInsetsDirectional.all(DirasstySpace.lg),
            decoration: const BoxDecoration(
                color: DirasstyColors.goldTint, borderRadius: DirasstyRadius.cardR),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_rounded,
                    color: DirasstyColors.goldStroke, size: 20),
                const SizedBox(width: DirasstySpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.hint,
                          style: type.subheading.copyWith(fontSize: 14)),
                      const SizedBox(height: DirasstySpace.xs),
                      Text(cleanMathForDisplay(state.activeBody.hint),
                          style:
                              type.bodySmall.copyWith(color: DirasstyColors.text)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DirasstySpace.sm),
        ],
        Text(l10n.hintBeforeCorrection,
            style: type.label.copyWith(fontWeight: FontWeight.w400)),
        if (state.apiError != null) ...[
          const SizedBox(height: DirasstySpace.md),
          Text(state.apiError!,
              style: type.label.copyWith(color: DirasstyColors.error)),
        ],
        const SizedBox(height: DirasstySpace.xl),
        DirasstyButton(
            label: l10n.seeCorrection,
            icon: Icons.auto_awesome_rounded,
            onPressed: _notifier.requestCorrection),
        const SizedBox(height: DirasstySpace.sm),
        TextButton(
            onPressed: _notifier.reviseAnswer, child: Text(l10n.reviseAnswer)),
      ],
    );
  }

  Widget _buildCorrected(
      AppLocalizations l10n, DirasstyType type, OppActive state, bool hasVideos) {
    final OpenExerciseCorrection c = state.correction!;
    // Unreadable photo / not confident: no verdict — ask for a retake.
    if (c.undetermined) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PhotoRetakeCard(
              issues: c.imageIssues, onRetake: () => _pickAndCheckPhotos(l10n)),
          if (c.whatWasRight.isNotEmpty) ...[
            const SizedBox(height: DirasstySpace.md),
            Text(cleanMathForDisplay(c.whatWasRight), style: type.bodySmall),
          ],
          const SizedBox(height: DirasstySpace.md),
          TextButton(
              onPressed: _notifier.reviseAnswer,
              child: Text(l10n.writeAnswerInstead)),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.submittedAnswer.isNotEmpty) ...[
          _AnswerEcho(answer: state.submittedAnswer),
          const SizedBox(height: DirasstySpace.lg),
        ],
        CorrectionResult(
            correction: c, lang: context.isArabicLocale ? 'ar' : 'fr'),
        if (state.apiError != null) ...[
          const SizedBox(height: DirasstySpace.md),
          Text(state.apiError!,
              style: type.label.copyWith(color: DirasstyColors.error)),
        ],
        const SizedBox(height: DirasstySpace.xl),
        DirasstyButton(
            label: l10n.similarExercise,
            icon: Icons.auto_awesome_rounded,
            onPressed: _notifier.requestSimilarExercise),
        const SizedBox(height: DirasstySpace.md),
        _TutorButton(state: state),
        if (hasVideos) ...[
          const SizedBox(height: DirasstySpace.md),
          DirasstyButton(
            label: l10n.watchMethod,
            icon: Icons.play_circle_outline_rounded,
            variant: DirasstyButtonVariant.secondary,
            onPressed: () => showDirasstyBottomSheet<void>(
              context,
              builder: (sheetContext) => SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l10n.methodVideos,
                        style: sheetContext.dirasstyType.heading),
                    const SizedBox(height: DirasstySpace.md),
                    ExerciseVideoSection(
                        lessonId: widget.lessonId,
                        color: DirasstyColors.teal,
                        isArabic: sheetContext.isArabicLocale),
                  ],
                ),
              ),
            ),
          ),
        ],
        if (state.hasNextPremade) ...[
          const SizedBox(height: DirasstySpace.md),
          DirasstyButton(
              label: l10n.nextExercise,
              variant: DirasstyButtonVariant.quiet,
              onPressed: _notifier.nextPremadeExercise),
        ],
        const SizedBox(height: DirasstySpace.sm),
        TextButton(
            onPressed: _notifier.reviseAnswer, child: Text(l10n.reviseAnswer)),
      ],
    );
  }
}

/// Opens the Dirassty tutor on this exercise (hint, guide, check a step,
/// full solution…).
class _TutorButton extends StatelessWidget {
  const _TutorButton({required this.state});

  final OppActive state;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return DirasstyButton(
      label: l10n.askDirassty,
      icon: Icons.auto_awesome_rounded,
      variant: DirasstyButtonVariant.quiet,
      onPressed: () => showTutorSheet(context,
          exerciseRef: state.exerciseRef,
          lang: context.isArabicLocale ? 'ar' : 'fr'),
    );
  }
}

/// The submitted answer, read-only, LTR.
class _AnswerEcho extends StatelessWidget {
  const _AnswerEcho({required this.answer});

  final String answer;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.yourAnswer,
            style: type.label.copyWith(fontSize: 14, color: DirasstyColors.text)),
        const SizedBox(height: DirasstySpace.sm),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Container(
            padding: const EdgeInsetsDirectional.symmetric(
                horizontal: DirasstySpace.lg, vertical: 14),
            decoration: BoxDecoration(
              color: DirasstyColors.surface,
              borderRadius: DirasstyRadius.cardR,
              border: Border.all(color: DirasstyColors.line, width: 1.5),
            ),
            child: Text(cleanMathForDisplay(answer),
                style: type.body.copyWith(fontFamily: 'Inter')),
          ),
        ),
      ],
    );
  }
}

class _Waiting extends StatelessWidget {
  const _Waiting({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: DirasstySpace.xxl),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: DirasstySpace.lg),
          Text(label, style: context.dirasstyType.bodySmall),
        ],
      ),
    );
  }
}
