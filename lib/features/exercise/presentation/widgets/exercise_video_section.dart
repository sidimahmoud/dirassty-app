import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/video_body.dart';
import '../../../../core/widgets/video_playlist.dart';
import '../../../courses/application/courses_providers.dart';
import '../../../lesson/application/lesson_providers.dart';
import '../../../../core/theme/dirassty_theme.dart';

/// Shows every exercise "how to solve these" walkthrough video (`content`
/// rows of type `exercise_video_url` — a lesson may have several) under a
/// small header, or nothing at all when the lesson has none. Lives in
/// exactly one place — [OpenPracticeScreen], right below the question,
/// visible for as long as the student is working on it — not duplicated
/// at the end of the QCM results screen the way it used to be, since
/// that's the wrong exercise type for a "how to solve this" video and
/// showing the same video in two different screens was confusing.
class ExerciseVideoSection extends ConsumerWidget {
  const ExerciseVideoSection({
    super.key,
    required this.lessonId,
    required this.color,
    required this.isArabic,
  });

  final String lessonId;
  final Color color;
  final bool isArabic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<VideoBody>> videos =
        ref.watch(exerciseVideosProvider(lessonId));
    // Only needed for the "no admin-given name" fallback label in the
    // playlist (see VideoPlaylistPlayer) — an empty string there just
    // means that fallback briefly reads "(1)" until this resolves.
    final String lessonTitle =
        ref.watch(lessonByIdProvider(lessonId)).valueOrNull?.lessonTitle ?? '';

    return videos.when(
      data: (v) => v.isEmpty
          ? const SizedBox.shrink()
          : _Section(
              videos: v,
              lessonTitle: lessonTitle,
              color: color,
              isArabic: isArabic,
            ),
      // Most lessons have no walkthrough video yet — never show a
      // loading flicker or error for what's an optional bonus section.
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.videos,
    required this.lessonTitle,
    required this.color,
    required this.isArabic,
  });

  final List<VideoBody> videos;
  final String lessonTitle;
  final Color color;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: DirasstySpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🎥', style: TextStyle(fontSize: 18)),
              const SizedBox(width: DirasstySpace.xs),
              Expanded(
                child: Text(
                  isArabic
                      ? 'فيديو: كيف تُحل هذه التمارين'
                      : 'Vidéo : comment résoudre ces exercices',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DirasstySpace.sm),
          VideoPlaylistPlayer(
            videos: videos,
            lessonTitle: lessonTitle,
            color: color,
            isArabic: isArabic,
          ),
        ],
      ),
    );
  }
}
