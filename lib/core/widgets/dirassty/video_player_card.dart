import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../models/video_body.dart';
import '../../offline/offline_videos_controller.dart';
import '../../theme/dirassty_theme.dart';
import '../course_video_player.dart';
import 'dirassty_button.dart';
import 'dirassty_chip.dart';
import 'dirassty_context.dart';
import 'overlays.dart';

/// The lesson video block: the player (full width, adapts to portrait
/// video — see [CourseVideoPlayer]) with, under it, the download action
/// with its size, the Wi-Fi hint, and an "offline" chip once saved.
/// Downloads are only offered to paid subscribers
/// ([OfflineVideosState.canDownload]).
///
/// DESIGN_SPEC.md §2 "VideoPlayerCard", §4 "Lesson flow › Video".
class VideoPlayerCard extends ConsumerWidget {
  const VideoPlayerCard({
    required this.video,
    required this.title,
    super.key,
    this.sizeLabel,
    this.autoPlay = false,
    this.lessonId,
  });

  final VideoBody video;

  /// Name shown in the Downloads screen and over the poster.
  final String title;

  /// Human file size ("45 Mo") for the download button — omitted from
  /// the label when unknown. // TODO(api): content rows don't carry a
  /// video file size yet.
  final String? sizeLabel;
  final bool autoPlay;
  final String? lessonId;

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
    final double? progress = offline.progress[video.url];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        CourseVideoPlayer(
          key: ValueKey(video.url),
          video: video,
          color: DirasstyColors.teal,
          isArabic: context.isArabicLocale,
          borderRadius: BorderRadius.zero,
          downloadTitle: title,
          posterTitle: title,
          showDownloadControl: false,
          autoPlay: autoPlay,
          lessonId: lessonId,
        ),
        if (downloaded || downloading || offline.canDownload)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              DirasstySpace.screen,
              DirasstySpace.md,
              DirasstySpace.screen,
              0,
            ),
            child: downloaded
                ? Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: DirasstyChip(
                      label: l10n.statusDownloaded,
                      variant: DirasstyChipVariant.teal,
                      icon: Icons.offline_pin_rounded,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DirasstyButton(
                        label: downloading
                            ? '${((progress ?? 0) * 100).round()}%'
                            : sizeLabel == null
                                ? l10n.downloadNoSize
                                : l10n.download(sizeLabel!),
                        icon: downloading
                            ? Icons.close_rounded
                            : Icons.download_rounded,
                        variant: DirasstyButtonVariant.quiet,
                        compact: true,
                        onPressed: downloading
                            ? () => controller.cancel(video.url)
                            : () async {
                                try {
                                  await controller.download(
                                    video,
                                    title,
                                    lessonId: lessonId,
                                  );
                                } catch (_) {
                                  if (context.mounted) {
                                    showDirasstySnackBar(
                                      context,
                                      l10n.downloadFailed,
                                      offline: true,
                                    );
                                  }
                                }
                              },
                      ),
                      const SizedBox(height: DirasstySpace.sm),
                      Text(
                        l10n.downloadWifiHint,
                        style: type.label.copyWith(fontWeight: FontWeight.w400),
                      ),
                    ],
                  ),
          ),
      ],
    );
  }
}
