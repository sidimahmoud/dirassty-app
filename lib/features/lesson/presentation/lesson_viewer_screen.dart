import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/explanation_body.dart';
import '../../../core/models/lesson.dart';
import '../../../core/models/lesson_progress_summary.dart';
import '../../../core/models/student.dart';
import '../../../core/models/summary_body.dart';
import '../../../core/models/video_body.dart';
import '../../../core/theme/dirassty_theme.dart';
import '../../../core/widgets/dirassty/dirassty_widgets.dart';
import '../../../core/offline/offline_videos_controller.dart';
import '../../../core/widgets/course_video_player.dart';
import '../../../l10n/app_localizations.dart';
import '../../courses/application/courses_providers.dart';
import '../../progress/application/progress_providers.dart';
import '../../student/application/student_providers.dart';
import '../application/lesson_providers.dart';
import '../../tutor/presentation/tutor_sheet.dart';
import 'widgets/concept_step_view.dart';
import 'widgets/lesson_blocks.dart';

sealed class _LessonStep {
  const _LessonStep();
}

/// The lesson's explanation video(s) — always first when there's at
/// least one.
final class _VideoStep extends _LessonStep {
  const _VideoStep(this.videos);
  final List<VideoBody> videos;
}

/// A lesson with no structured concept sections (no authored content
/// yet, or the legacy flat-text format) — its only details step.
final class _DetailsStep extends _LessonStep {
  const _DetailsStep(this.body);
  final ExplanationBody? body;
}

final class _ConceptStep extends _LessonStep {
  const _ConceptStep(this.section, this.index, this.total);
  final ConceptSection section;
  final int index;
  final int total;
}

final class _WorkedExampleStep extends _LessonStep {
  const _WorkedExampleStep(this.text);
  final String text;
}

/// The lesson's revision card, when it has one — last before the QCM.
final class _RevisionStep extends _LessonStep {
  const _RevisionStep(this.summary);
  final SummaryBody summary;
}

/// Video → Concept 1..n → Worked example → Revision sheet (then the QCM),
/// DESIGN_SPEC §4 "Lesson flow".
List<_LessonStep> _buildSteps(
    ExplanationBody? body, List<VideoBody> videos, SummaryBody? summary) {
  final List<_LessonStep> steps = [
    if (videos.isNotEmpty) _VideoStep(videos),
  ];
  if (body == null || !body.hasStructuredSections) {
    steps.add(_DetailsStep(body));
  } else {
    for (final (int i, ConceptSection section) in body.sections.indexed) {
      steps.add(_ConceptStep(section, i, body.sections.length));
    }
    if (body.workedExample != null)
      steps.add(_WorkedExampleStep(body.workedExample!));
  }
  if (summary != null && summary.points.isNotEmpty)
    steps.add(_RevisionStep(summary));
  return steps;
}

/// The lesson player: a dedicated video step (when the lesson has one),
/// then the written lesson one concept at a time — each gated by its
/// mini-quiz — the worked example and the revision sheet, handing off to
/// the QCM. A lesson already read opens on a resume screen instead
/// (redo / QCM / guided exercises). No lesson is ever locked.
///
/// design_handoff LessonVideo / LessonConcept / WorkedExample /
/// RevisionSheet · DESIGN_SPEC §4 "Lesson flow".
class LessonViewerScreen extends ConsumerStatefulWidget {
  const LessonViewerScreen({required this.lessonId, super.key});

  static const String path = '/lesson/:lessonId';
  static const String name = 'lessonViewer';

  final String lessonId;

  @override
  ConsumerState<LessonViewerScreen> createState() => _LessonViewerScreenState();
}

class _LessonViewerScreenState extends ConsumerState<LessonViewerScreen> {
  int _stepIndex = 0;
  final DateTime _viewStartedAt = DateTime.now();

  /// True once the student picks "Revoir le cours" on the resume screen —
  /// from then on this visit shows the normal flow.
  bool _resuming = false;

  /// How far time-on-task has already been flushed (null until the first
  /// flush), so the next flush only counts the time since.
  DateTime? _loggedUpTo;

  /// Captured up front because [_flushTimeSpent] also runs from
  /// [dispose], where `ref` already throws — and that throw would abort
  /// Riverpod's unmount before it closes this screen's subscriptions.
  late final ProviderContainer _container;

  @override
  void initState() {
    super.initState();
    _container = ProviderScope.containerOf(context, listen: false);
  }

  /// Logs time-on-task not logged yet — when the student moves on to the
  /// QCM (a push, so [dispose] may not come for a long time) and again
  /// from [dispose].
  void _flushTimeSpent() {
    final String? studentId =
        _container.read(currentStudentProvider).valueOrNull?.id;
    if (studentId == null) return;
    final DateTime from = _loggedUpTo ?? _viewStartedAt;
    _loggedUpTo = DateTime.now();
    _container
        .read(progressRepositoryProvider)
        .logStudySession(studentId: studentId, startedAt: from);
    // studentStatsProvider is a one-shot fetch — refresh it so study time
    // on home / child progress reflects this session.
    _container.invalidate(studentStatsProvider);
  }

  /// Reaching the end marks the lesson viewed (mastery floor, subject
  /// progress), a no-op on repeat views.
  Future<void> _markViewed() async {
    final String? studentId = ref.read(currentStudentProvider).valueOrNull?.id;
    if (studentId == null) return;
    await ref
        .read(progressRepositoryProvider)
        .markLessonViewed(studentId: studentId, lessonId: widget.lessonId);
    if (!mounted) return;
    ref.invalidate(viewedLessonIdsProvider);
    ref.invalidate(subjectMasteryProvider);
    ref.invalidate(lessonMasteryMapProvider);
    ref.invalidate(subjectsWithMasteryProvider);
    ref.invalidate(subjectsWithMasteryForStudentProvider);
  }

  Future<void> _finishAndStartQcm() async {
    await _markViewed();
    _flushTimeSpent();
    if (!mounted) return;
    context.push('/exercise/${widget.lessonId}');
  }

  @override
  void dispose() {
    _flushTimeSpent();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<CurriculumLesson> lesson =
        ref.watch(lessonByIdProvider(widget.lessonId));
    final AsyncValue<ExplanationBody?> explanation =
        ref.watch(explanationProvider(widget.lessonId));
    final List<VideoBody> videos =
        ref.watch(lessonVideosProvider(widget.lessonId)).valueOrNull ??
            const [];
    // Optional last step — never blocks the lesson while loading.
    final SummaryBody? summary =
        ref.watch(lessonSummaryProvider(widget.lessonId)).valueOrNull;
    final String? studentId = ref.watch(currentStudentProvider).valueOrNull?.id;
    final bool alreadyViewed = studentId != null &&
        (ref.watch(viewedLessonIdsProvider(studentId)).valueOrNull ?? const {})
            .contains(widget.lessonId);

    return Scaffold(
      backgroundColor: DirasstyColors.background,
      body: SafeArea(
        child: lesson.when(
          loading: () => const _LoadingBody(),
          error: (_, __) => _MessageBody(
            child: ErrorState(
              title: l10n.lessonNotFound,
              onRetry: () =>
                  ref.invalidate(lessonByIdProvider(widget.lessonId)),
            ),
          ),
          data: (lessonData) => explanation.when(
            loading: () => const _LoadingBody(),
            error: (_, __) => _MessageBody(
              child: ErrorState(
                title: l10n.lessonLoadError,
                onRetry: () =>
                    ref.invalidate(explanationProvider(widget.lessonId)),
              ),
            ),
            data: (body) {
              if (alreadyViewed && !_resuming) {
                return _LessonChrome(
                  lesson: lessonData,
                  journeyIndex: null,
                  hasVideo: videos.isNotEmpty,
                  child: _LessonResumeView(
                    lesson: lessonData,
                    onRedo: () => setState(() => _resuming = true),
                    onQcm: () => context.push('/exercise/${widget.lessonId}'),
                    onExercises: () =>
                        context.push('/open-practice/${widget.lessonId}'),
                  ),
                );
              }
              final List<_LessonStep> steps =
                  _buildSteps(body, videos, summary);
              final int index = _stepIndex.clamp(0, steps.length - 1);
              final _LessonStep step = steps[index];
              final bool isLast = index == steps.length - 1;
              void goNext() => isLast
                  ? _finishAndStartQcm()
                  : setState(() => _stepIndex = index + 1);
              final String? lastLabel = isLast ? l10n.startQcm : null;

              return _LessonChrome(
                lesson: lessonData,
                journeyIndex:
                    step is _VideoStep ? 0 : (videos.isNotEmpty ? 1 : 0),
                hasVideo: videos.isNotEmpty,
                child: AnimatedSwitcher(
                  duration:
                      context.reduceMotion ? Duration.zero : DirasstyMotion.fast,
                  child: switch (step) {
                    _VideoStep(videos: final vs) => _VideoStepView(
                        key: const ValueKey('video'),
                        lesson: lessonData,
                        videos: vs,
                        onContinue: goNext,
                      ),
                    _DetailsStep(body: final b) => _DetailsStepView(
                        key: const ValueKey('details'),
                        lesson: lessonData,
                        body: b,
                        continueLabel: lastLabel ?? l10n.continueAction,
                        onContinue: goNext,
                      ),
                    _ConceptStep(
                      section: final s,
                      index: final i,
                      total: final n
                    ) =>
                      ConceptStepView(
                        key: ValueKey('concept-$i-${s.title}'),
                        section: s,
                        index: i,
                        total: n,
                        continueLabel: lastLabel,
                        onContinue: goNext,
                      ),
                    _WorkedExampleStep(text: final t) => _WorkedExampleStepView(
                        key: const ValueKey('example'),
                        text: t,
                        continueLabel: lastLabel ??
                            (summary != null
                                ? l10n.revisionSheet
                                : l10n.continueAction),
                        onReviewVideo: videos.isEmpty
                            ? null
                            : () => setState(() => _stepIndex = 0),
                        onContinue: goNext,
                      ),
                    _RevisionStep(summary: final sm) => _RevisionStepView(
                        key: const ValueKey('revision'),
                        lesson: lessonData,
                        summary: sm,
                        onContinue: goNext,
                      ),
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Top of every lesson step: back button + "Chapter · Leçon n", then the
/// Vidéo → Leçon → Exercices journey bar ([journeyIndex] null hides it).
class _LessonChrome extends StatelessWidget {
  const _LessonChrome({
    required this.lesson,
    required this.journeyIndex,
    required this.hasVideo,
    required this.child,
  });

  final CurriculumLesson lesson;
  final int? journeyIndex;
  final bool hasVideo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
              DirasstySpace.sm, DirasstySpace.xs, DirasstySpace.screen, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close_rounded),
                color: DirasstyColors.ink,
                tooltip: AppLocalizations.of(context).close,
              ),
              Expanded(
                child: Text(
                  l10n.lessonLabel(lesson.chapterTitle, lesson.lessonNum),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.dirasstyType.label.copyWith(fontSize: 14),
                ),
              ),
              // Dirassty AI explainer on this lesson's own content.
              TextButton.icon(
                onPressed: () => showTutorSheet(context,
                    lessonId: lesson.id,
                    lang: context.isArabicLocale ? 'ar' : 'fr'),
                icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                label: Text(l10n.askDirassty),
              ),
            ],
          ),
        ),
        if (journeyIndex != null)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(DirasstySpace.screen,
                DirasstySpace.xs, DirasstySpace.screen, DirasstySpace.sm),
            child: JourneyBar(
              steps: [
                if (hasVideo) l10n.journeyVideo,
                l10n.journeyLesson,
                l10n.journeyExercises,
              ],
              currentIndex: journeyIndex!,
              activeIcon: hasVideo && journeyIndex == 0
                  ? Icons.play_arrow_rounded
                  : null,
            ),
          ),
        Expanded(child: child),
      ],
    );
  }
}

/// Step 1 of the lesson flow: player, video title + "Vidéo n sur N ·
/// x min", download (outlined, with the Wi-Fi tip), "Dans cette leçon"
/// when there are several videos, and — pinned — a square "previous
/// video" button next to "Continuer vers la leçon".
///
/// Deviations from LessonVideo.dc.html: no teacher name or file size in
/// the meta/download label (content rows don't carry them yet —
/// TODO(api)), and the stage keeps its taller 3:2 minimum (asked for
/// earlier) instead of the mock's 16:9.
///
/// design_handoff LessonVideo.dc.html · DESIGN_SPEC §4 "Lesson flow".
class _VideoStepView extends ConsumerStatefulWidget {
  const _VideoStepView({
    required this.lesson,
    required this.videos,
    required this.onContinue,
    super.key,
  });

  final CurriculumLesson lesson;
  final List<VideoBody> videos;
  final VoidCallback onContinue;

  @override
  ConsumerState<_VideoStepView> createState() => _VideoStepViewState();
}

class _VideoStepViewState extends ConsumerState<_VideoStepView> {
  int _current = 0;

  /// Only a video the student picked starts on its own; the first one
  /// waits for a tap on the poster.
  bool _autoPlay = false;

  String _titleOf(int i) {
    final String? t = widget.videos[i].title;
    if (t != null && t.trim().isNotEmpty) return t;
    return widget.videos.length == 1
        ? widget.lesson.lessonTitle
        : '${widget.lesson.lessonTitle} · ${i + 1}';
  }

  void _select(int i) => setState(() {
        _current = i;
        _autoPlay = true;
      });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    final VideoBody video = widget.videos[_current];
    final int total = widget.videos.length;
    final int minutes = (video.durationSec / 60).round();
    final String? meta = total > 1
        ? l10n.videoOfMeta(_current + 1, total, minutes)
        : (video.durationSec > 0 ? l10n.videoMinutes(minutes) : null);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              CourseVideoPlayer(
                key: ValueKey(video.url),
                video: video,
                color: DirasstyColors.teal,
                isArabic: context.isArabicLocale,
                borderRadius: BorderRadius.zero,
                downloadTitle: _titleOf(_current),
                showDownloadControl: false,
                autoPlay: _autoPlay,
                lessonId: widget.lesson.id,
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                    DirasstySpace.screen, DirasstySpace.screen, DirasstySpace.screen, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(_titleOf(_current),
                        style: type.titleSmall
                            .copyWith(fontWeight: FontWeight.w800)),
                    if (meta != null) ...[
                      const SizedBox(height: 6),
                      Text(meta,
                          style: type.bodySmall
                              .copyWith(color: DirasstyColors.textMuted)),
                    ],
                    _DownloadBlock(
                        video: video,
                        title: _titleOf(_current),
                        lessonId: widget.lesson.id),
                    if (total > 1) ...[
                      const SizedBox(height: DirasstySpace.section),
                      Text(l10n.inThisLesson, style: type.subheading),
                      const SizedBox(height: 10),
                      for (int i = 0; i < total; i++) ...[
                        if (i > 0) const SizedBox(height: 10),
                        PlaylistItem(
                          index: i,
                          label: _titleOf(i),
                          video: widget.videos[i],
                          active: i == _current,
                          color: DirasstyColors.teal,
                          isArabic: context.isArabicLocale,
                          onTap: () => _select(i),
                        ),
                      ],
                    ],
                    const SizedBox(height: DirasstySpace.xl),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(DirasstySpace.screen,
              DirasstySpace.sm, DirasstySpace.screen, DirasstySpace.lg),
          child: Row(
            children: [
              SizedBox.square(
                dimension: DirasstySize.button,
                child: Material(
                  color: DirasstyColors.surface,
                  shape: const RoundedRectangleBorder(
                    borderRadius: DirasstyRadius.cardR,
                    side: BorderSide(color: DirasstyColors.line, width: 1.5),
                  ),
                  child: InkWell(
                    borderRadius: DirasstyRadius.cardR,
                    onTap: _current == 0 ? null : () => _select(_current - 1),
                    child: Tooltip(
                      message: l10n.previousVideo,
                      child: Icon(
                        rtl
                            ? Icons.chevron_right_rounded
                            : Icons.chevron_left_rounded,
                        color:
                            _current == 0 ? DirasstyColors.idle : DirasstyColors.ink,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: DirasstySpace.md),
              Expanded(
                child: DirasstyButton(
                  label: l10n.continueToLesson,
                  onPressed: widget.onContinue,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// "Télécharger" (outlined, full width) + the Wi-Fi tip, the progress
/// while downloading, or an "offline" chip once saved. Only for students
/// allowed to download (paid plan, see OfflineVideosState.canDownload).
class _DownloadBlock extends ConsumerWidget {
  const _DownloadBlock({
    required this.video,
    required this.title,
    required this.lessonId,
  });

  final VideoBody video;
  final String title;
  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    final OfflineVideosState offline =
        ref.watch(offlineVideosControllerProvider);
    final OfflineVideosController controller =
        ref.read(offlineVideosControllerProvider.notifier);
    final bool downloaded = offline.isDownloaded(video.url);
    final bool downloading = offline.isDownloading(video.url);
    if (!downloaded && !downloading && !offline.canDownload) {
      return const SizedBox.shrink();
    }
    if (downloaded) {
      return Padding(
        padding: const EdgeInsetsDirectional.only(top: DirasstySpace.section),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: DirasstyChip(
            label: l10n.statusDownloaded,
            variant: DirasstyChipVariant.teal,
            icon: Icons.offline_pin_rounded,
          ),
        ),
      );
    }
    final double? progress = offline.progress[video.url];

    return Padding(
      padding: const EdgeInsetsDirectional.only(top: DirasstySpace.section),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 48,
            child: Material(
              color: DirasstyColors.surface,
              shape: const RoundedRectangleBorder(
                borderRadius: DirasstyRadius.cardR,
                side: BorderSide(color: DirasstyColors.line, width: 1.5),
              ),
              child: InkWell(
                borderRadius: DirasstyRadius.cardR,
                onTap: downloading
                    ? () => controller.cancel(video.url)
                    : () async {
                        try {
                          await controller.download(video, title,
                              lessonId: lessonId);
                        } catch (_) {
                          if (context.mounted) {
                            showDirasstySnackBar(context, l10n.downloadFailed,
                                offline: true);
                          }
                        }
                      },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                        downloading
                            ? Icons.close_rounded
                            : Icons.download_rounded,
                        size: 18,
                        color: DirasstyColors.ink),
                    const SizedBox(width: DirasstySpace.sm),
                    Text(
                      downloading
                          ? '${((progress ?? 0) * 100).round()} %'
                          : l10n.downloadNoSize,
                      style: type.subheading.copyWith(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: DirasstySpace.lg),
          Container(
            padding: const EdgeInsetsDirectional.symmetric(
                horizontal: 14, vertical: DirasstySpace.md),
            decoration: const BoxDecoration(
                color: DirasstyColors.ivory, borderRadius: DirasstyRadius.cardR),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 18, color: DirasstyColors.teal),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(l10n.downloadWifiHint,
                      style: type.label.copyWith(
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF3E4A47),
                          height: 1.5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsStepView extends StatelessWidget {
  const _DetailsStepView({
    required this.lesson,
    required this.body,
    required this.continueLabel,
    required this.onContinue,
    super.key,
  });

  final CurriculumLesson lesson;
  final ExplanationBody? body;
  final String continueLabel;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String? text = body?.text;
    return _StepList(
      children: [
        Text(lesson.lessonTitle,
            style: context.dirasstyType.titleSmall.copyWith(fontSize: 22)),
        if (text == null)
          EmptyState(
              icon: Icons.hourglass_empty_rounded,
              title: l10n.comingSoon,
              message: l10n.lessonComingSoon)
        else
          DirasstyCard(child: LessonText(text)),
      ],
      bottom: [DirasstyButton(label: continueLabel, onPressed: onContinue)],
    );
  }
}

/// The lesson's worked example: statement card with the solution revealed
/// on demand, "Revoir la vidéo" + continue.
///
/// Deviation from WorkedExample.dc.html (content gap): the example is
/// authored as one text, so it's shown as a whole instead of numbered
/// steps, and there's no "Erreur fréquente" callout. TODO(content):
/// structured steps + common-mistake field, then use NumberedStep /
/// GoldCallout.
class _WorkedExampleStepView extends StatefulWidget {
  const _WorkedExampleStepView({
    required this.text,
    required this.continueLabel,
    required this.onContinue,
    super.key,
    this.onReviewVideo,
  });

  final String text;
  final String continueLabel;
  final VoidCallback onContinue;
  final VoidCallback? onReviewVideo;

  @override
  State<_WorkedExampleStepView> createState() => _WorkedExampleStepViewState();
}

class _WorkedExampleStepViewState extends State<_WorkedExampleStepView> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    return _StepList(
      children: [
        Text(l10n.workedExample, style: type.titleSmall.copyWith(fontSize: 22)),
        DirasstyCard(
          variant: DirasstyCardVariant.shadow,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.statement.toUpperCase(), style: type.label),
              const SizedBox(height: DirasstySpace.md),
              if (_revealed)
                LessonText(widget.text)
              else
                DirasstyButton(
                  label: l10n.showSolution,
                  icon: Icons.visibility_outlined,
                  variant: DirasstyButtonVariant.secondary,
                  compact: true,
                  onPressed: () => setState(() => _revealed = true),
                ),
            ],
          ),
        ),
      ],
      bottom: [
        Row(
          children: [
            if (widget.onReviewVideo != null) ...[
              Expanded(
                child: DirasstyButton(
                  label: l10n.reviewVideo,
                  variant: DirasstyButtonVariant.quiet,
                  onPressed: widget.onReviewVideo,
                ),
              ),
              const SizedBox(width: DirasstySpace.md),
            ],
            Expanded(
                child: DirasstyButton(
                    label: widget.continueLabel, onPressed: widget.onContinue)),
          ],
        ),
      ],
    );
  }
}

/// Quick-revision card before the exercises.
///
/// Deviation from RevisionSheet.dc.html (content gap): summaries are one
/// list of key points, not separate formulas / definitions / facts, and
/// they aren't cached for offline yet — so a single "À savoir" section
/// and no "Disponible hors ligne" chip. TODO(content/api).
class _RevisionStepView extends StatelessWidget {
  const _RevisionStepView({
    required this.lesson,
    required this.summary,
    required this.onContinue,
    super.key,
  });

  final CurriculumLesson lesson;
  final SummaryBody summary;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    return _StepList(
      children: [
        Text(l10n.revisionSheet.toUpperCase(), style: type.label),
        Text(lesson.lessonTitle, style: type.title),
        LessonCard(
          label: l10n.keyFacts,
          children: [
            for (final (int i, String point) in summary.points.indexed) ...[
              if (i > 0) const SizedBox(height: DirasstySpace.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const IconBadge(icon: Icons.check_rounded, size: 24),
                  const SizedBox(width: DirasstySpace.md),
                  Expanded(child: LessonText(point)),
                ],
              ),
            ],
          ],
        ),
      ],
      bottom: [DirasstyButton(label: l10n.goToExercises, onPressed: onContinue)],
    );
  }
}

/// A lesson already read: pick what to do instead of redoing the whole
/// walkthrough.
class _LessonResumeView extends ConsumerWidget {
  const _LessonResumeView({
    required this.lesson,
    required this.onRedo,
    required this.onQcm,
    required this.onExercises,
  });

  final CurriculumLesson lesson;
  final VoidCallback onRedo;
  final VoidCallback onQcm;
  final VoidCallback onExercises;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    final Student? student = ref.watch(currentStudentProvider).valueOrNull;

    bool qcmDone = false;
    bool exercisesDone = false;
    if (student != null) {
      final Map<String, LessonProgressSummary>? summary = ref
          .watch(lessonProgressSummaryProvider((
            studentId: student.id,
            subjectKey: lesson.subjectKey,
            grade: student.grade,
          )))
          .valueOrNull;
      qcmDone = summary?[lesson.id]?.exercisesDone ?? false;
      exercisesDone = (ref
                  .watch(openPracticeViewedLessonIdsProvider(student.id))
                  .valueOrNull ??
              const {})
          .contains(lesson.id);
    }

    return _StepList(
      children: [
        Text(lesson.lessonTitle, style: type.titleSmall.copyWith(fontSize: 22)),
        Text(l10n.alreadyReadBody, style: type.bodySmall),
        _ResumeOption(
            icon: Icons.play_circle_rounded,
            title: l10n.redoLesson,
            subtitle: l10n.redoLessonSub,
            onTap: onRedo),
        _ResumeOption(
          icon: Icons.bolt_rounded,
          title: l10n.qcmTitle,
          subtitle: l10n.qcmSub,
          done: qcmDone,
          onTap: onQcm,
        ),
        _ResumeOption(
          icon: Icons.edit_note_rounded,
          title: l10n.guidedExercises,
          subtitle: l10n.guidedExercisesSub,
          done: exercisesDone,
          onTap: onExercises,
        ),
      ],
      bottom: const [],
    );
  }
}

class _ResumeOption extends StatelessWidget {
  const _ResumeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.done = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    return DirasstyCard(
      onTap: onTap,
      child: Row(
        children: [
          IconBadge(icon: icon, size: 44),
          const SizedBox(width: DirasstySpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: DirasstySpace.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(title, style: type.subheading),
                    if (done)
                      DirasstyChip(
                          label: l10n.alreadyDone,
                          variant: DirasstyChipVariant.teal,
                          icon: Icons.check_rounded,
                          dense: true),
                  ],
                ),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: type.label.copyWith(fontWeight: FontWeight.w400)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: DirasstyColors.textMuted),
        ],
      ),
    );
  }
}

/// Scrolling step body (20 px padding, 18 gap) with actions under the
/// content.
class _StepList extends StatelessWidget {
  const _StepList({required this.children, required this.bottom});

  final List<Widget> children;
  final List<Widget> bottom;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(
          DirasstySpace.screen, DirasstySpace.md, DirasstySpace.screen, DirasstySpace.xxl),
      children: [
        for (int i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: 18),
          children[i],
        ],
        if (bottom.isNotEmpty) const SizedBox(height: DirasstySpace.xl),
        for (int i = 0; i < bottom.length; i++) ...[
          if (i > 0) const SizedBox(height: DirasstySpace.sm),
          bottom[i],
        ],
      ],
    );
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsetsDirectional.all(DirasstySpace.screen),
      children: const [
        Skeleton(height: 20, width: 180),
        SizedBox(height: DirasstySpace.lg),
        Skeleton(height: 30),
        SizedBox(height: DirasstySpace.xl),
        Skeleton(height: 200, radius: 0),
        SizedBox(height: DirasstySpace.xl),
        Skeleton(height: 24),
        SizedBox(height: DirasstySpace.md),
        Skeleton(height: 90, radius: DirasstyRadius.card),
      ],
    );
  }
}

class _MessageBody extends StatelessWidget {
  const _MessageBody({required this.child});

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
