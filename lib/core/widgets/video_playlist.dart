import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../models/video_body.dart';
import '../theme/dirassty_theme.dart';
import 'course_video_player.dart';
import 'dirassty/playlist_item.dart';

/// One big player for whichever video is active, plus — only once there's
/// more than one — a list of the others underneath, the way a real course
/// app (or YouTube) presents a playlist: a single player at a time, not
/// every video's full-size poster stacked one after another.
///
/// Deliberately header-less: the screen's app bar already names the
/// lesson, so the active video's own name goes on its poster (only when
/// there's something to tell apart) and the list rows speak for
/// themselves.
class VideoPlaylistPlayer extends StatefulWidget {
  const VideoPlaylistPlayer({
    required this.videos,
    required this.lessonTitle,
    required this.color,
    required this.isArabic,
    super.key,
    this.borderRadius = DirasstyRadius.cardR,
    this.lessonId,
  });

  /// Must be non-empty — callers already gate on `videos.isNotEmpty`
  /// before reaching for this widget.
  final List<VideoBody> videos;

  /// Used, with the video's position appended, for any video the admin
  /// didn't give its own name — see [_labelFor].
  final String lessonTitle;
  final Color color;
  final bool isArabic;

  /// Pass [BorderRadius.zero] for an edge-to-edge hero placement.
  final BorderRadius borderRadius;

  /// Lesson these videos belong to — recorded with downloads.
  final String? lessonId;

  @override
  State<VideoPlaylistPlayer> createState() => _VideoPlaylistPlayerState();
}

class _VideoPlaylistPlayerState extends State<VideoPlaylistPlayer> {
  int _activeIndex = 0;

  /// False only for the very first video on screen open (the student
  /// hasn't asked for anything yet); any explicit pick starts playing.
  bool _autoPlay = false;

  void _goTo(int index) {
    if (index < 0 || index >= widget.videos.length || index == _activeIndex) {
      return;
    }
    setState(() {
      _activeIndex = index;
      _autoPlay = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final VideoBody active = widget.videos[_activeIndex];
    final bool hasPlaylist = widget.videos.length > 1;
    final String activeLabel =
        _labelFor(active, _activeIndex, widget.lessonTitle);
    final String? customTitle = active.title?.trim();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CourseVideoPlayer(
          key: ValueKey(active.url),
          video: active,
          color: widget.color,
          isArabic: widget.isArabic,
          borderRadius: widget.borderRadius,
          downloadTitle: activeLabel,
          lessonId: widget.lessonId,
          // A lone, unnamed video would just repeat the app bar's lesson
          // title — only caption the poster when it adds something.
          posterTitle: hasPlaylist || (customTitle?.isNotEmpty ?? false)
              ? activeLabel
              : null,
          autoPlay: _autoPlay,
        ),
        // Always shown, even for a single video (both buttons disabled) —
        // keeps the player's layout identical across lessons.
        _PrevNextBar(
          index: _activeIndex,
          count: widget.videos.length,
          color: widget.color,
          isArabic: widget.isArabic,
          onPrevious: () => _goTo(_activeIndex - 1),
          onNext: () => _goTo(_activeIndex + 1),
        ),
        if (hasPlaylist)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              DirasstySpace.lg,
              DirasstySpace.sm,
              DirasstySpace.lg,
              0,
            ),
            child: Column(
              children: [
                for (int i = 0; i < widget.videos.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: DirasstySpace.xs),
                    child: PlaylistItem(
                      index: i,
                      label: _labelFor(widget.videos[i], i, widget.lessonTitle),
                      video: widget.videos[i],
                      active: i == _activeIndex,
                      color: widget.color,
                      isArabic: widget.isArabic,
                      onTap: () => _goTo(i),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// The admin's own name for the video if they gave it one, otherwise the
/// lesson's title with this video's 1-based upload-order position — never
/// a bare "Vidéo N" placeholder.
String _labelFor(VideoBody video, int index, String lessonTitle) {
  final String? title = video.title?.trim();
  if (title != null && title.isNotEmpty) return title;
  return '$lessonTitle (${index + 1})';
}

class _PrevNextBar extends StatelessWidget {
  const _PrevNextBar({
    required this.index,
    required this.count,
    required this.color,
    required this.isArabic,
    required this.onPrevious,
    required this.onNext,
  });

  final int index;
  final int count;
  final Color color;
  final bool isArabic;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final bool hasPrevious = index > 0;
    final bool hasNext = index < count - 1;
    final ButtonStyle style = TextButton.styleFrom(
      foregroundColor: color,
      disabledForegroundColor: DirasstyColors.textMuted.withValues(alpha: 0.5),
      padding: const EdgeInsets.symmetric(
        horizontal: DirasstySpace.md,
        vertical: DirasstySpace.sm,
      ),
      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
    );

    return Container(
      color: DirasstyColors.surface,
      padding:
          const EdgeInsets.symmetric(horizontal: DirasstySpace.xs, vertical: 2),
      child: Row(
        children: [
          TextButton.icon(
            style: style,
            onPressed: hasPrevious ? onPrevious : null,
            // Row order flips in RTL but these icons don't mirror on their own.
            icon: Icon(
              isArabic ? Icons.skip_next_rounded : Icons.skip_previous_rounded,
              size: 22,
            ),
            label: Text(AppLocalizations.of(context).previousVideo),
          ),
          Expanded(
            child: Text(
              '${index + 1} / $count',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: DirasstyColors.textMuted,
                fontSize: 12,
              ),
            ),
          ),
          // Label before icon, so the arrow sits on the outer edge.
          TextButton(
            style: style,
            onPressed: hasNext ? onNext : null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(AppLocalizations.of(context).nextVideo),
                const SizedBox(width: 4),
                Icon(
                  isArabic
                      ? Icons.skip_previous_rounded
                      : Icons.skip_next_rounded,
                  size: 22,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
