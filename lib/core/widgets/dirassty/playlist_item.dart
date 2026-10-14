import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/video_body.dart';
import '../../offline/offline_videos_controller.dart';
import '../../theme/dirassty_theme.dart';
import 'dirassty_context.dart';
import '../../../l10n/app_localizations.dart';

/// One row of a lesson's video playlist: mini thumbnail with its number,
/// title, duration, "En cours" marker when [active], and an offline pin
/// when the video is downloaded. DESIGN_SPEC.md §2 "PlaylistItem".
class PlaylistItem extends ConsumerWidget {
  const PlaylistItem({
    super.key,
    required this.index,
    required this.label,
    required this.video,
    required this.active,
    required this.color,
    required this.isArabic,
    required this.onTap,
  });

  final int index;
  final String label;
  final VideoBody video;
  final bool active;
  final Color color;
  final bool isArabic;
  final VoidCallback onTap;

  String? get _durationLabel {
    final int totalSeconds = video.durationSec;
    if (totalSeconds <= 0) return null;
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    final bool downloaded = ref.watch(
      offlineVideosControllerProvider.select((s) => s.isDownloaded(video.url)),
    );
    final String? meta =
        active ? l10n.nowPlaying : (downloaded ? l10n.offlineShort : null);

    // LessonVideo.dc.html "Dans cette leçon": the playing video gets a
    // pale-teal fill and teal border, the others white with a hairline.
    return Material(
      color: active ? const Color(0xFFF6FAF9) : DirasstyColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: DirasstyRadius.cardR,
        side: BorderSide(color: active ? color : DirasstyColors.line, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: active ? null : onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.all(DirasstySpace.sm),
          child: Row(
            children: [
              _MiniThumb(video: video, duration: _durationLabel),
              const SizedBox(width: DirasstySpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: type.body
                          .copyWith(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    if (meta != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        meta,
                        style: type.label.copyWith(
                          fontWeight: FontWeight.w400,
                          color: active ? color : DirasstyColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 96×54 ink thumbnail (or the video's own thumbnail), white play glyph,
/// duration badge in the bottom corner.
class _MiniThumb extends StatelessWidget {
  const _MiniThumb({required this.video, required this.duration});

  final VideoBody video;
  final String? duration;

  @override
  Widget build(BuildContext context) {
    final String? thumbnailUrl = video.thumbnailUrl;
    return ClipRRect(
      borderRadius: DirasstyRadius.smallR,
      child: SizedBox(
        width: 96,
        height: 54,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: DirasstyColors.ink),
            if (thumbnailUrl != null)
              Image.network(
                thumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) =>
                    const SizedBox.shrink(),
              ),
            const Center(
              child:
                  Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
            ),
            if (duration != null)
              PositionedDirectional(
                end: 4,
                bottom: 4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    duration!,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Previous / "2 / 3" / Next, right under the player. Each end's button
/// is disabled on the first/last video. Icons follow reading direction,
/// so in Arabic "next" points left.
