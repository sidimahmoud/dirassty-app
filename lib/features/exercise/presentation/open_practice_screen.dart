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
import '../../tutor/presentation/rafiq_chip.dart';
import '../../tutor/presentation/tutor_sheet.dart';
import '../application/open_practice_controller.dart';
import '../application/open_practice_state.dart';
import 'widgets/correction_result.dart';
import 'widgets/exercise_video_section.dart';
import 'widgets/symbol_toolbar.dart';

/// Open (free-answer) practice with AI correction, in three numbered steps
/// (same design as the student website, app/(eleve)/(app)/pratique):
///   1. Lis l'exercice — the statement, with an optional hint toggle;
///   2. Réponds — "Photo de ma feuille" (first) or "Écrire", both can be
///      sent together, with a line saying what will be sent;
///   3. Correction — Rafiq's verdict, then Réessayer / similar / videos.
/// A bottom bar keeps Rafiq and the main action always in reach.
/// Calls go through OpenPracticeController.submitAnswer.
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

enum _AnswerMode { photo, write }

class _ActiveViewState extends ConsumerState<_ActiveView> {
  static const int _maxPhotos = 3;

  late final TextEditingController _controller =
      TextEditingController(text: widget.state.draftAnswer);
  late final FocusNode _focusNode = FocusNode();
  final List<({Uint8List bytes, String filename})> _photos = [];
  _AnswerMode _mode = _AnswerMode.photo;
  bool _hintOpen = false;

  OpenPracticeController get _notifier =>
      ref.read(openPracticeControllerProvider(widget.lessonId).notifier);

  @override
  void didUpdateWidget(_ActiveView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool newExercise = oldWidget.state.activeId != widget.state.activeId;
    final bool backToEditing =
        oldWidget.state.phase != OpenPracticePhase.answering &&
            widget.state.phase == OpenPracticePhase.answering &&
            oldWidget.state.phase != OpenPracticePhase.correcting;
    if (newExercise || backToEditing) {
      _controller.text = widget.state.draftAnswer;
      _photos.clear();
      _hintOpen = false;
    }
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

  bool get _answering =>
      widget.state.phase == OpenPracticePhase.answering ||
      widget.state.phase == OpenPracticePhase.hint;

  bool get _hasText => widget.state.draftAnswer.trim().length >= 3;

  bool get _canSubmit => _hasText || _photos.isNotEmpty;

  void _openTutor() => showTutorSheet(
        context,
        exerciseRef: widget.state.exerciseRef,
        lang: context.isArabicLocale ? 'ar' : 'fr',
      );

  /// Camera (one page) or gallery (the pages left), resized — enough for
  /// handwriting, far fewer image tokens and bytes than a raw photo.
  Future<void> _addPhotos(AppLocalizations l10n) async {
    final int room = _maxPhotos - _photos.length;
    if (room <= 0) return;
    final ImageSource? source = await showDirasstyBottomSheet<ImageSource>(
      context,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.oppTakeAnswerPhoto,
            style: sheetContext.dirasstyType.titleSmall,
          ),
          const SizedBox(height: DirasstySpace.xs),
          Text(l10n.oppPhotoTips, style: sheetContext.dirasstyType.bodySmall),
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
              imageQuality: 80,
            )
                case final XFile f)
              f,
          ]
        : room == 1
            ? [
                if (await picker.pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 1600,
                  imageQuality: 80,
                )
                    case final XFile f)
                  f,
              ]
            : await picker.pickMultiImage(
                limit: room,
                maxWidth: 1600,
                imageQuality: 80,
              );
    if (files.isEmpty || !mounted) return;
    final List<({Uint8List bytes, String filename})> picked = [
      for (final XFile f in files.take(room))
        (bytes: await f.readAsBytes(), filename: f.name),
    ];
    if (!mounted) return;
    setState(() => _photos.addAll(picked));
  }

  void _submit() => _notifier.submitAnswer(List.of(_photos));

  void _retry() {
    _notifier.reviseAnswer();
    setState(() {
      _photos.clear();
      _mode = _AnswerMode.photo;
    });
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
    final OpenExerciseCorrection? c = state.correction;
    final bool corrected = state.phase == OpenPracticePhase.corrected;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsetsDirectional.fromSTEB(
              DirasstySpace.screen,
              DirasstySpace.sm,
              DirasstySpace.screen,
              DirasstySpace.xxl,
            ),
            children: [
              _Header(state: state),
              const SizedBox(height: DirasstySpace.lg),
              _Step(
                n: 1,
                title: l10n.oppStepRead,
                done: !_answering || _canSubmit,
                child: _exerciseCard(l10n, type, state),
              ),
              _Step(
                n: 2,
                title: l10n.oppStepAnswer,
                subtitle: _answering ? l10n.oppStepAnswerSub : null,
                active: _answering,
                done: !_answering,
                child: _answerCard(l10n, type, state),
              ),
              _Step(
                n: 3,
                title: l10n.oppStepCorrection,
                active: !_answering,
                done: c != null && c.score == CorrectionScore.correct,
                last: true,
                child: switch (state.phase) {
                  OpenPracticePhase.correcting => _WaitingCard(
                      title: l10n.oppCorrectingNow,
                      subtitle: l10n.oppCorrectingSub,
                    ),
                  OpenPracticePhase.generating =>
                    _WaitingCard(title: l10n.generatingExercise),
                  _ when corrected && c != null =>
                    _correction(l10n, type, state, c, hasVideos),
                  _ => Text(
                      l10n.oppNotReady,
                      style: type.bodySmall
                          .copyWith(color: DirasstyColors.textMuted),
                    ),
                },
              ),
            ],
          ),
        ),
        _BottomBar(
          onRafiq: _openTutor,
          child: _primaryButton(l10n, state),
        ),
      ],
    );
  }

  Widget _primaryButton(AppLocalizations l10n, OppActive state) {
    switch (state.phase) {
      case OpenPracticePhase.answering:
      case OpenPracticePhase.hint:
      case OpenPracticePhase.correcting:
        return DirasstyButton(
          label: l10n.oppCorrectMyAnswer,
          icon: Icons.auto_awesome_rounded,
          loading: state.phase == OpenPracticePhase.correcting,
          onPressed: _canSubmit && _answering ? _submit : null,
        );
      case OpenPracticePhase.generating:
        return DirasstyButton(
          label: l10n.similarExercise,
          variant: DirasstyButtonVariant.gold,
          loading: true,
          onPressed: null,
        );
      case OpenPracticePhase.corrected:
        return state.hasNextPremade
            ? DirasstyButton(
                label: l10n.nextExercise,
                icon: Icons.arrow_forward_rounded,
                onPressed: _notifier.nextPremadeExercise,
              )
            : DirasstyButton(
                label: l10n.similarExercise,
                icon: Icons.auto_awesome_rounded,
                variant: DirasstyButtonVariant.gold,
                onPressed: _notifier.requestSimilarExercise,
              );
    }
  }

  Widget _exerciseCard(
    AppLocalizations l10n,
    DirasstyType type,
    OppActive state,
  ) {
    final String hint = state.activeBody.hint;
    return Container(
      decoration: BoxDecoration(
        color: DirasstyColors.surface,
        borderRadius: DirasstyRadius.cardR,
        border: Border.all(color: DirasstyColors.line),
        boxShadow: DirasstyShadow.level1,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(DirasstySpace.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (state.activeBody.topic.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: const BoxDecoration(
                      color: DirasstyColors.tealTint,
                      borderRadius: DirasstyRadius.pillR,
                    ),
                    child: Text(
                      state.activeBody.topic,
                      style: type.label.copyWith(
                        color: DirasstyColors.teal,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: DirasstySpace.md),
                ],
                // In the question's own language (direction + font).
                ContentLanguage.of(
                  state.activeBody.question,
                  child: Builder(
                    builder: (context) => Text(
                      cleanMathForDisplay(state.activeBody.question),
                      style: context.dirasstyType.body.copyWith(
                        height: 1.55,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                if (state.activeBody.diagram != null) ...[
                  const SizedBox(height: DirasstySpace.md),
                  DiagramView(
                    spec: state.activeBody.diagram!,
                    color: DirasstyColors.teal,
                  ),
                ],
              ],
            ),
          ),
          if (hint.isNotEmpty)
            Container(
              color: DirasstyColors.ivory,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Divider(height: 1, color: DirasstyColors.line),
                  InkWell(
                    onTap: () => setState(() => _hintOpen = !_hintOpen),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DirasstySpace.lg,
                        vertical: DirasstySpace.md,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.lightbulb_rounded,
                            size: 18,
                            color: DirasstyColors.goldStroke,
                          ),
                          const SizedBox(width: DirasstySpace.sm),
                          Expanded(
                            child: Text(
                              _hintOpen ? l10n.oppHideHint : l10n.oppShowHint,
                              style: type.subheading.copyWith(
                                fontSize: 14,
                                color: DirasstyColors.goldStroke,
                              ),
                            ),
                          ),
                          AnimatedRotation(
                            turns: _hintOpen ? 0.5 : 0,
                            duration: DirasstyMotion.fast,
                            child: const Icon(
                              Icons.expand_more_rounded,
                              color: DirasstyColors.goldStroke,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AnimatedSize(
                    duration: DirasstyMotion.fast,
                    curve: DirasstyMotion.curve,
                    child: _hintOpen
                        ? Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                              DirasstySpace.lg,
                              0,
                              DirasstySpace.lg,
                              DirasstySpace.lg,
                            ),
                            child: ContentLanguage.of(
                              state.activeBody.question,
                              child: Builder(
                                builder: (context) => Text(
                                  cleanMathForDisplay(hint),
                                  style: context.dirasstyType.bodySmall
                                      .copyWith(color: DirasstyColors.text),
                                ),
                              ),
                            ),
                          )
                        : const SizedBox(width: double.infinity),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _answerCard(
    AppLocalizations l10n,
    DirasstyType type,
    OppActive state,
  ) {
    final bool answering = _answering;
    return AnimatedOpacity(
      duration: DirasstyMotion.fast,
      opacity: answering ? 1 : 0.85,
      child: Container(
        padding: const EdgeInsets.all(DirasstySpace.sm),
        decoration: BoxDecoration(
          color: DirasstyColors.surface,
          borderRadius: DirasstyRadius.cardR,
          border: Border.all(
            color: answering
                ? DirasstyColors.teal.withValues(alpha: 0.35)
                : DirasstyColors.line,
            width: answering ? 1.5 : 1,
          ),
          boxShadow: DirasstyShadow.level1,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ModeSwitch(
              mode: _mode,
              photoCount: _photos.length,
              hasText: _hasText,
              onChanged: (m) => setState(() => _mode = m),
            ),
            Padding(
              padding: const EdgeInsets.all(DirasstySpace.sm),
              child: _mode == _AnswerMode.photo
                  ? _photoArea(l10n, type, answering)
                  : _writeArea(l10n, type, answering),
            ),
            if (answering) _readyLine(l10n, type),
            if (state.apiError != null && answering) ...[
              const SizedBox(height: DirasstySpace.sm),
              Container(
                padding: const EdgeInsets.all(DirasstySpace.md),
                decoration: const BoxDecoration(
                  color: DirasstyColors.errorTint,
                  borderRadius: DirasstyRadius.smallR,
                ),
                child: Text(
                  state.apiError!,
                  style: type.bodySmall.copyWith(color: DirasstyColors.error),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _photoArea(AppLocalizations l10n, DirasstyType type, bool answering) {
    if (_photos.isEmpty) {
      return InkWell(
        onTap: answering ? () => _addPhotos(l10n) : null,
        borderRadius: DirasstyRadius.cardR,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: DirasstySpace.xl,
            horizontal: DirasstySpace.lg,
          ),
          decoration: BoxDecoration(
            color: DirasstyColors.tealTint.withValues(alpha: 0.6),
            borderRadius: DirasstyRadius.cardR,
            border: Border.all(
              color: DirasstyColors.teal.withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: DirasstyColors.teal,
                  shape: BoxShape.circle,
                  boxShadow: DirasstyShadow.level1,
                ),
                child: const Icon(
                  Icons.photo_camera_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(height: DirasstySpace.md),
              Text(
                l10n.oppTakeAnswerPhoto,
                textAlign: TextAlign.center,
                style: type.subheading.copyWith(color: DirasstyColors.teal),
              ),
              const SizedBox(height: DirasstySpace.xs),
              Text(
                l10n.oppPhotoTips,
                textAlign: TextAlign.center,
                style: type.label.copyWith(fontWeight: FontWeight.w400),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: DirasstySpace.sm,
          crossAxisSpacing: DirasstySpace.sm,
          childAspectRatio: 3 / 4,
          children: [
            for (int i = 0; i < _photos.length; i++)
              _PhotoThumb(
                bytes: _photos[i].bytes,
                index: i + 1,
                onRemove: answering
                    ? () => setState(() => _photos.removeAt(i))
                    : null,
              ),
            if (answering && _photos.length < _maxPhotos)
              InkWell(
                onTap: () => _addPhotos(l10n),
                borderRadius: DirasstyRadius.cardR,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: DirasstyRadius.cardR,
                    border: Border.all(color: DirasstyColors.idle, width: 1.5),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add_rounded,
                        color: DirasstyColors.textMuted,
                        size: 28,
                      ),
                      const SizedBox(height: DirasstySpace.xs),
                      Text(
                        l10n.oppAddPage,
                        textAlign: TextAlign.center,
                        style: type.label.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: DirasstySpace.sm),
        Text(
          l10n.oppPhotoTips,
          textAlign: TextAlign.center,
          style: type.label.copyWith(fontWeight: FontWeight.w400, fontSize: 11),
        ),
      ],
    );
  }

  Widget _writeArea(AppLocalizations l10n, DirasstyType type, bool answering) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Directionality(
          textDirection: TextDirection.ltr,
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            enabled: answering,
            onChanged: (v) {
              _notifier.updateDraft(v);
              setState(() {});
            },
            minLines: 5,
            maxLines: 10,
            style: type.body.copyWith(fontFamily: 'Inter'),
            decoration: InputDecoration(hintText: l10n.typeAnswer),
          ),
        ),
        if (answering) ...[
          const SizedBox(height: DirasstySpace.md),
          Text(l10n.usefulSymbols, style: type.label),
          const SizedBox(height: DirasstySpace.xs),
          SymbolToolbar(onInsert: _insertSymbol),
        ],
      ],
    );
  }

  Widget _readyLine(AppLocalizations l10n, DirasstyType type) {
    final bool ready = _canSubmit;
    final String what = [
      if (_hasText) l10n.oppReadyText,
      if (_photos.isNotEmpty) l10n.oppReadyPhotos(_photos.length),
    ].join(' + ');
    return Container(
      margin: const EdgeInsets.all(DirasstySpace.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: DirasstySpace.md,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: ready ? DirasstyColors.tealTint : DirasstyColors.ivory,
        borderRadius: DirasstyRadius.smallR,
      ),
      child: Row(
        children: [
          Icon(
            ready ? Icons.check_circle_rounded : Icons.info_outline_rounded,
            size: 18,
            color: ready ? DirasstyColors.teal : DirasstyColors.textMuted,
          ),
          const SizedBox(width: DirasstySpace.sm),
          Expanded(
            child: Text(
              ready ? l10n.oppReady(what) : l10n.oppNotReady,
              style: type.label.copyWith(
                fontSize: 12,
                color: ready ? DirasstyColors.teal : DirasstyColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _correction(
    AppLocalizations l10n,
    DirasstyType type,
    OppActive state,
    OpenExerciseCorrection c,
    bool hasVideos,
  ) {
    // Unreadable photo / not confident: no verdict — ask for a retake.
    if (c.undetermined) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PhotoRetakeCard(issues: c.imageIssues, onRetake: _retry),
          if (c.whatWasRight.isNotEmpty) ...[
            const SizedBox(height: DirasstySpace.md),
            Text(cleanMathForDisplay(c.whatWasRight), style: type.bodySmall),
          ],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CorrectionResult(
          correction: c,
          lang: context.isArabicLocale ? 'ar' : 'fr',
        ),
        if (state.apiError != null) ...[
          const SizedBox(height: DirasstySpace.md),
          Text(
            state.apiError!,
            style: type.label.copyWith(color: DirasstyColors.error),
          ),
        ],
        const SizedBox(height: DirasstySpace.lg),
        Wrap(
          spacing: DirasstySpace.sm,
          runSpacing: DirasstySpace.sm,
          children: [
            DirasstyButton(
              label: l10n.oppTryAgain,
              icon: Icons.refresh_rounded,
              variant: DirasstyButtonVariant.secondary,
              compact: true,
              expand: false,
              onPressed: _retry,
            ),
            if (state.hasNextPremade)
              DirasstyButton(
                label: l10n.similarExercise,
                icon: Icons.auto_awesome_rounded,
                variant: DirasstyButtonVariant.gold,
                compact: true,
                expand: false,
                onPressed: _notifier.requestSimilarExercise,
              ),
            if (hasVideos)
              DirasstyButton(
                label: l10n.watchMethod,
                icon: Icons.play_circle_outline_rounded,
                variant: DirasstyButtonVariant.quiet,
                compact: true,
                expand: false,
                onPressed: () => showDirasstyBottomSheet<void>(
                  context,
                  builder: (sheetContext) => SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.methodVideos,
                          style: sheetContext.dirasstyType.heading,
                        ),
                        const SizedBox(height: DirasstySpace.md),
                        ExerciseVideoSection(
                          lessonId: widget.lessonId,
                          color: DirasstyColors.teal,
                          isArabic: sheetContext.isArabicLocale,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// "Exercice 2 sur 5" + progress dots, and the attempt chip.
class _Header extends StatelessWidget {
  const _Header({required this.state});

  final OppActive state;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    final bool generated = state.generatedToken != null;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                generated
                    ? l10n.similarExercise
                    : l10n.oppExerciseOf(
                        state.exerciseIndex + 1,
                        state.poolSize,
                      ),
                style: type.subheading,
              ),
              if (!generated && state.poolSize > 1) ...[
                const SizedBox(height: 6),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    children: [
                      for (int i = 0; i < state.poolSize; i++)
                        AnimatedContainer(
                          duration: DirasstyMotion.fast,
                          margin: const EdgeInsetsDirectional.only(end: 4),
                          width: i == state.exerciseIndex ? 20 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: i == state.exerciseIndex
                                ? DirasstyColors.teal
                                : i < state.exerciseIndex
                                    ? DirasstyColors.teal
                                        .withValues(alpha: 0.45)
                                    : DirasstyColors.track,
                            borderRadius: DirasstyRadius.pillR,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        if (state.attempt > 1)
          DirasstyChip(label: l10n.attemptN(state.attempt), dense: true),
      ],
    );
  }
}

/// One numbered step on a vertical timeline (✓ when done, gold when it's
/// the student's turn).
class _Step extends StatelessWidget {
  const _Step({
    required this.n,
    required this.title,
    required this.child,
    this.subtitle,
    this.done = false,
    this.active = false,
    this.last = false,
  });

  final int n;
  final String title;
  final String? subtitle;
  final bool done;
  final bool active;
  final bool last;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final DirasstyType type = context.dirasstyType;
    final Color fill = done
        ? DirasstyColors.teal
        : active
            ? DirasstyColors.gold
            : DirasstyColors.surface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            AnimatedContainer(
              duration: DirasstyMotion.fast,
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: fill,
                shape: BoxShape.circle,
                border: done || active
                    ? null
                    : Border.all(color: DirasstyColors.line, width: 2),
              ),
              child: done
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 18,
                    )
                  : Text(
                      '$n',
                      style: type.subheading.copyWith(
                        fontSize: 14,
                        color: active
                            ? DirasstyColors.ink
                            : DirasstyColors.textMuted,
                      ),
                    ),
            ),
            const SizedBox(width: DirasstySpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: type.subheading),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: type.label.copyWith(
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        Container(
          margin: const EdgeInsetsDirectional.only(start: 15),
          padding: EdgeInsetsDirectional.fromSTEB(
            28,
            DirasstySpace.md,
            0,
            last ? 0 : DirasstySpace.xl,
          ),
          decoration: BoxDecoration(
            border: last
                ? null
                : const BorderDirectional(
                    start: BorderSide(color: DirasstyColors.line, width: 2),
                  ),
          ),
          child: child,
        ),
      ],
    );
  }
}

/// "Photo de ma feuille" (first) / "Écrire" segmented switch, with a
/// badge once each side has something.
class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({
    required this.mode,
    required this.photoCount,
    required this.hasText,
    required this.onChanged,
  });

  final _AnswerMode mode;
  final int photoCount;
  final bool hasText;
  final ValueChanged<_AnswerMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    Widget tab(_AnswerMode m, IconData icon, String label, String? badge) {
      final bool on = mode == m;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(m),
          child: AnimatedContainer(
            duration: DirasstyMotion.fast,
            height: 44,
            decoration: BoxDecoration(
              color: on ? DirasstyColors.surface : Colors.transparent,
              borderRadius: DirasstyRadius.smallR,
              boxShadow: on ? DirasstyShadow.level1 : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: on ? DirasstyColors.teal : DirasstyColors.textMuted,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: type.subheading.copyWith(
                      fontSize: 13,
                      color:
                          on ? DirasstyColors.teal : DirasstyColors.textMuted,
                    ),
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    constraints: const BoxConstraints(minWidth: 20),
                    height: 20,
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: DirasstyColors.teal,
                      borderRadius: DirasstyRadius.pillR,
                    ),
                    child: Text(
                      badge,
                      style: type.label.copyWith(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        color: DirasstyColors.track,
        borderRadius: DirasstyRadius.cardR,
      ),
      child: Row(
        children: [
          tab(
            _AnswerMode.photo,
            Icons.photo_camera_rounded,
            l10n.oppModePhoto,
            photoCount > 0 ? '$photoCount' : null,
          ),
          const SizedBox(width: 4),
          tab(
            _AnswerMode.write,
            Icons.edit_rounded,
            l10n.oppModeWrite,
            hasText ? '✓' : null,
          ),
        ],
      ),
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({
    required this.bytes,
    required this.index,
    required this.onRemove,
  });

  final Uint8List bytes;
  final int index;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: DirasstyRadius.cardR,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true),
          PositionedDirectional(
            start: 6,
            bottom: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: DirasstyColors.ink.withValues(alpha: 0.7),
                borderRadius: DirasstyRadius.smallR,
              ),
              child: Text(
                '$index',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          if (onRemove != null)
            PositionedDirectional(
              top: 4,
              end: 4,
              child: Material(
                color: DirasstyColors.ink.withValues(alpha: 0.7),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onRemove,
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Fixed bar at the bottom: Rafiq + the screen's main action.
class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.onRafiq, required this.child});

  final VoidCallback onRafiq;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: DirasstyColors.surface,
        border: Border(top: BorderSide(color: DirasstyColors.line)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1410231F),
            blurRadius: 24,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            DirasstySpace.screen,
            DirasstySpace.md,
            DirasstySpace.screen,
            DirasstySpace.md,
          ),
          child: Row(
            children: [
              RafiqChip(
                onTap: onRafiq,
                showTagline: MediaQuery.sizeOf(context).width >= 380,
              ),
              const SizedBox(width: DirasstySpace.md),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _WaitingCard extends StatelessWidget {
  const _WaitingCard({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final DirasstyType type = context.dirasstyType;
    return Container(
      padding: const EdgeInsets.all(DirasstySpace.lg),
      decoration: BoxDecoration(
        color: DirasstyColors.surface,
        borderRadius: DirasstyRadius.cardR,
        border: Border.all(color: DirasstyColors.line),
        boxShadow: DirasstyShadow.level1,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            padding: const EdgeInsets.all(13),
            decoration: const BoxDecoration(
              color: DirasstyColors.tealTint,
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(strokeWidth: 2.5),
          ),
          const SizedBox(width: DirasstySpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: type.subheading),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: type.label.copyWith(fontWeight: FontWeight.w400),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
