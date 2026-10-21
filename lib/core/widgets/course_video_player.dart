import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../features/auth/application/auth_providers.dart';
import '../../l10n/app_localizations.dart';
import '../analytics/app_analytics.dart';
import '../models/video_body.dart';
import '../offline/offline_video_store.dart';
import '../offline/offline_videos_controller.dart';
import '../offline/video_url_signer.dart';
import '../theme/dirassty_theme.dart';
import 'dirassty/dirassty_widgets.dart';
import 'video_watermark.dart';

/// A course-video player styled after Coursera/Khan Academy: a poster
/// frame (thumbnail, or a color gradient when there is none) with a big
/// centered play button and a duration badge — never a bare player that
/// starts loading or shows scrub controls before the student asked for
/// it. Tapping the poster is what initializes the real player and starts
/// playback. Used both for the lesson explanation video (`content` type
/// `video_url`, as the lesson viewer's hero) and the exercise walkthrough
/// video (`exercise_video_url`, in the QCM/open-practice results).
///
/// Plays the device's downloaded copy instead of streaming whenever one
/// exists and offline access is still valid (see [OfflineVideoStore]),
/// and — for paid subscribers — shows a download control on the poster.
///
/// Disposes both controllers when its owner is torn down — give this a
/// fresh `key` per video if it can be swapped for another one in place,
/// so no stale controller lingers.
class CourseVideoPlayer extends ConsumerStatefulWidget {
  const CourseVideoPlayer({
    required this.video,
    required this.color,
    required this.isArabic,
    super.key,
    this.borderRadius = DirasstyRadius.cardR,
    this.downloadTitle,
    this.lessonId,
    this.showDownloadControl = true,
    this.posterTitle,
    this.autoPlay = false,
  });

  final VideoBody video;
  final Color color;
  final bool isArabic;

  /// Pass [BorderRadius.zero] for an edge-to-edge hero placement.
  final BorderRadius borderRadius;

  /// Name the video is listed under in the Downloads screen — falls back
  /// to [VideoBody.title].
  final String? downloadTitle;

  /// Recorded with a download so the lesson shows as available offline.
  final String? lessonId;

  /// False on the Downloads screen itself, where deleting lives in the
  /// list instead.
  final bool showDownloadControl;

  /// Optional caption drawn over the poster before playback starts.
  final String? posterTitle;

  /// Starts playing as soon as this mounts, skipping the poster tap — for
  /// a video the student just picked (Next/Previous, playlist).
  final bool autoPlay;

  @override
  ConsumerState<CourseVideoPlayer> createState() => _CourseVideoPlayerState();
}

class _CourseVideoPlayerState extends ConsumerState<CourseVideoPlayer> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _starting = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    if (widget.autoPlay) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _play();
      });
    }
  }

  Future<void> _play() async {
    setState(() => _starting = true);
    VideoPlayerController? controller;
    try {
      // A downloaded copy always wins, wherever this video is opened
      // from — no network request at all in that case, not even signing.
      final File? localFile = await const OfflineVideoStore().playableFileFor(
        widget.video.url,
        ref.read(supabaseClientProvider).auth.currentUser?.id,
      );
      if (localFile != null) {
        controller = VideoPlayerController.file(localFile);
      } else {
        final String streamUrl =
            await VideoUrlSigner(ref.read(supabaseClientProvider))
                .fetchableUrl(widget.video.url);
        controller = VideoPlayerController.networkUrl(Uri.parse(streamUrl));
      }
      if (!mounted) {
        await controller.dispose();
        return;
      }
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      // One "play" per start, for Admin → Vidéos (066_video_stats.sql).
      ref.read(appAnalyticsProvider).track('video_play', {
        'video_url': widget.video.url,
        'lesson_id': widget.lessonId,
        'offline': localFile != null,
      });
      final VideoPlayerController ready = controller;
      setState(() {
        _videoController = ready;
        _chewieController = ChewieController(
          videoPlayerController: ready,
          aspectRatio:
              ready.value.aspectRatio == 0 ? 16 / 9 : ready.value.aspectRatio,
          autoPlay: true,
          looping: false,
          allowFullScreen: true,
          allowMuting: true,
          // Student-name watermark, also shown in fullscreen.
          overlay: VideoWatermark(controller: ready),
          // Gold played bar on the ink stage (LessonVideo.dc.html).
          materialProgressColors: ChewieProgressColors(
            playedColor: DirasstyColors.gold,
            handleColor: DirasstyColors.gold,
            bufferedColor: Colors.white.withValues(alpha: 0.4),
            backgroundColor: Colors.white.withValues(alpha: 0.2),
          ),
          errorBuilder: (context, message) =>
              _VideoError(isArabic: widget.isArabic),
        );
      });
    } catch (e) {
      await controller?.dispose();
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: LayoutBuilder(
        builder: (context, constraints) => AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          height: _stageHeight(context, constraints.maxWidth),
          color: Colors.black,
          child: _error != null
              ? _VideoError(isArabic: widget.isArabic)
              : _chewieController != null
                  ? Chewie(controller: _chewieController!)
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        _Poster(
                          video: widget.video,
                          color: widget.color,
                          loading: _starting,
                          onTap: _starting ? null : _play,
                          title: widget.posterTitle,
                        ),
                        if (widget.showDownloadControl && !_starting)
                          PositionedDirectional(
                            top: DirasstySpace.sm,
                            end: DirasstySpace.sm,
                            child: _DownloadChip(
                              video: widget.video,
                              title: widget.downloadTitle ??
                                  widget.video.title ??
                                  AppLocalizations.of(context).videoLabel,
                              isArabic: widget.isArabic,
                              lessonId: widget.lessonId,
                            ),
                          ),
                      ],
                    ),
        ),
      ),
    );
  }

  /// A 3:2 stage (a bit taller than 16:9, so the player has presence on a
  /// phone screen) until the real video is loaded, then that video's own
  /// shape when it's taller still —
  /// a phone-filmed (portrait) video gets a much taller player instead of
  /// being squeezed into a widescreen box — capped so the controls and
  /// playlist below stay on screen.
  double _stageHeight(BuildContext context, double width) {
    final double minHeight = width * 2 / 3;
    final double maxHeight = MediaQuery.sizeOf(context).height * 0.62;
    final double? aspect = _videoController?.value.aspectRatio;
    if (aspect == null || aspect <= 0) return minHeight;
    return (width / aspect)
        .clamp(minHeight, maxHeight < minHeight ? minHeight : maxHeight);
  }
}

class _Poster extends StatelessWidget {
  const _Poster({
    required this.video,
    required this.color,
    required this.loading,
    required this.onTap,
    this.title,
  });

  final VideoBody video;
  final Color color;
  final bool loading;
  final VoidCallback? onTap;

  /// Shown bottom-left over the poster — only passed when it tells the
  /// student something the screen doesn't already (see
  /// VideoPlaylistPlayer).
  final String? title;

  String get _durationLabel {
    final int totalSeconds = video.durationSec;
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final String? thumbnailUrl = video.thumbnailUrl;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (thumbnailUrl != null)
            Image.network(
              thumbnailUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) =>
                  const ColoredBox(color: DirasstyColors.ink),
            )
          else
            const ColoredBox(color: DirasstyColors.ink),
          // Bottom scrim so the title/duration stay readable on any frame.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.45, 1],
                colors: [
                  Colors.transparent,
                  DirasstyColors.ink.withValues(alpha: 0.7),
                ],
              ),
            ),
          ),
          Center(
            child: loading
                ? const SizedBox(
                    width: 44,
                    height: 44,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                // 64 px white disc, ink triangle (LessonVideo.dc.html).
                : Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: DirasstyColors.ink,
                      size: 34,
                    ),
                  ),
          ),
          Positioned(
            left: DirasstySpace.md,
            right: DirasstySpace.md,
            bottom: DirasstySpace.sm,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: title == null
                      ? const SizedBox.shrink()
                      : Text(
                          title!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                            shadows: [
                              Shadow(color: Colors.black54, blurRadius: 6),
                            ],
                          ),
                        ),
                ),
                if (video.durationSec > 0) ...[
                  const SizedBox(width: DirasstySpace.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: DirasstyRadius.pillR,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 12,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _durationLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
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

/// Download / progress / "available offline" pill on the poster. Hidden
/// entirely for students who can't download (trial, lapsed) unless the
/// video is already saved.
class _DownloadChip extends ConsumerWidget {
  const _DownloadChip({
    required this.video,
    required this.title,
    required this.isArabic,
    this.lessonId,
  });

  final VideoBody video;
  final String title;
  final bool isArabic;
  final String? lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final OfflineVideosState offline =
        ref.watch(offlineVideosControllerProvider);
    final OfflineVideosController controller =
        ref.read(offlineVideosControllerProvider.notifier);
    final String url = video.url;

    if (offline.isDownloading(url)) {
      final double? p = offline.progress[url];
      return _Pill(
        onTap: () => controller.cancel(url),
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              value: p,
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 6),
          Text(p == null ? '…' : '${(p * 100).floor()}%'),
          const SizedBox(width: 4),
          const Icon(Icons.close_rounded, size: 14, color: Colors.white),
        ],
      );
    }

    if (offline.isDownloaded(url)) {
      return _Pill(
        onTap: () => _confirmDelete(context, controller),
        children: [
          const Icon(Icons.offline_pin_rounded, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(AppLocalizations.of(context).offlineShort),
        ],
      );
    }

    if (!offline.canDownload) return const SizedBox.shrink();

    return _Pill(
      onTap: () async {
        try {
          await controller.download(video, title, lessonId: lessonId);
        } catch (_) {
          if (!context.mounted) return;
          showDirasstySnackBar(
            context,
            AppLocalizations.of(context).downloadFailed,
          );
        }
      },
      children: [
        const Icon(Icons.download_rounded, size: 16, color: Colors.white),
        const SizedBox(width: 6),
        Text(AppLocalizations.of(context).downloadNoSize),
      ],
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    OfflineVideosController controller,
  ) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool confirmed = await showDirasstyDialog<bool>(
          context,
          icon: Icons.delete_outline_rounded,
          iconBackground: DirasstyColors.errorTint,
          iconColor: DirasstyColors.error,
          title: l10n.deleteDownloadTitle,
          message: l10n.deleteDownloadBody,
          actions: [
            DirasstyDialogAction(
              label: l10n.delete,
              value: true,
              variant: DirasstyButtonVariant.danger,
            ),
            DirasstyDialogAction(
              label: l10n.cancel,
              value: false,
              variant: DirasstyButtonVariant.quiet,
            ),
          ],
        ) ??
        false;
    if (confirmed) await controller.delete(video.url);
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.children, required this.onTap});

  final List<Widget> children;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.6),
      borderRadius: DirasstyRadius.pillR,
      child: InkWell(
        borderRadius: DirasstyRadius.pillR,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DirasstySpace.sm,
            vertical: 6,
          ),
          child: DefaultTextStyle(
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: children),
          ),
        ),
      ),
    );
  }
}

class _VideoError extends StatelessWidget {
  const _VideoError({required this.isArabic});

  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DirasstySpace.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white70),
            const SizedBox(height: DirasstySpace.xs),
            Text(
              isArabic
                  ? 'تعذّر تحميل الفيديو'
                  : 'Impossible de charger la vidéo',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
