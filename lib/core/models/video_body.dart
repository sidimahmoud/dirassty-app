import 'package:flutter/foundation.dart';

/// One labeled timestamp in a video, e.g. for a chapter/section jump list.
/// Ported from `VideoBody['chapters'][number]` in packages/shared/src/types.
@immutable
class VideoChapter {
  const VideoChapter({required this.t, required this.label});

  factory VideoChapter.fromJson(Map<String, dynamic> json) {
    return VideoChapter(
      t: (json['t'] as num).toInt(),
      label: json['label'] as String,
    );
  }

  /// Timestamp in seconds.
  final int t;
  final String label;
}

/// Ported from `VideoBody` in packages/shared/src/types — the body of a
/// `content` row where `type = 'video_url'` (lesson explanation) or
/// `'exercise_video_url'` (exercise walkthrough). `url` is always a plain
/// public HTTPS URL (the Supabase Storage `videos` bucket is public), so it
/// can be handed straight to a native video player — no signed-URL or auth
/// handling needed.
@immutable
class VideoBody {
  const VideoBody({
    required this.url,
    required this.durationSec,
    required this.type,
    this.chapters = const [],
    this.subtitlesUrl,
    this.thumbnailUrl,
    this.title,
  });

  factory VideoBody.fromJson(Map<String, dynamic> json) {
    return VideoBody(
      url: json['url'] as String,
      durationSec: (json['duration_sec'] as num?)?.toInt() ?? 0,
      type: json['type'] as String? ?? 'filmed',
      chapters: (json['chapters'] as List<dynamic>?)
              ?.map((c) => VideoChapter.fromJson(c as Map<String, dynamic>))
              .toList() ??
          const [],
      subtitlesUrl: json['subtitles_url'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      title: json['title'] as String?,
    );
  }

  final String url;
  final int durationSec;

  /// 'ai_generated' (video-studio narrated slides) or 'filmed'.
  final String type;
  final List<VideoChapter> chapters;
  final String? subtitlesUrl;
  final String? thumbnailUrl;

  /// Admin-given name — null for most videos. See
  /// VideoPlaylistPlayer for the lesson-name-plus-index fallback shown
  /// in its place.
  final String? title;
}
