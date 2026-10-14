import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/explanation_body.dart';
import '../../../core/models/summary_body.dart';
import '../../../core/models/video_body.dart';

/// The only place in the app that reads `content` rows of
/// `type = 'explanation'`/`'video_url'`/`'exercise_video_url'`/`'summary'`.
/// Ported from `getExplanation`/`getVideos`/`getExerciseVideos`/
/// `getSummary` in packages/shared/src/api/content.ts.
class LessonRepository {
  LessonRepository(this._client);

  final SupabaseClient _client;

  /// Null when no verified explanation has been generated for this
  /// lesson yet — callers show a "coming soon" state, not an error.
  Future<ExplanationBody?> getExplanation(String lessonId) async {
    final Map<String, dynamic>? row = await _client
        .from('content')
        .select('*')
        .eq('lesson_id', lessonId)
        .eq('type', 'explanation')
        .eq('verified', true)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (row == null) return null;
    return ExplanationBody.fromJson(row['body'] as Map<String, dynamic>);
  }

  /// Every verified explanation video for this lesson, oldest (first
  /// uploaded) first — a lesson can have several, not just one. Empty
  /// when none has been generated yet — callers simply omit the video
  /// player, they don't show an error (most lessons have no video).
  Future<List<VideoBody>> getVideos(String lessonId) async {
    final List<Map<String, dynamic>> rows = await _client
        .from('content')
        .select('*')
        .eq('lesson_id', lessonId)
        .eq('type', 'video_url')
        .eq('verified', true)
        .order('created_at', ascending: true);

    return rows
        .map((row) => VideoBody.fromJson(row['body'] as Map<String, dynamic>))
        .toList();
  }

  /// Every "how to solve these exercises" walkthrough video, distinct
  /// from the lesson-explanation videos above, oldest first. Empty when
  /// none has been generated for this lesson yet.
  Future<List<VideoBody>> getExerciseVideos(String lessonId) async {
    final List<Map<String, dynamic>> rows = await _client
        .from('content')
        .select('*')
        .eq('lesson_id', lessonId)
        .eq('type', 'exercise_video_url')
        .eq('verified', true)
        .order('created_at', ascending: true);

    return rows
        .map((row) => VideoBody.fromJson(row['body'] as Map<String, dynamic>))
        .toList();
  }

  /// The short "revision card" summary (formulas/definitions/key facts —
  /// see SummaryBody's doc comment), null when none has been generated
  /// for this lesson yet.
  Future<SummaryBody?> getSummary(String lessonId) async {
    final Map<String, dynamic>? row = await _client
        .from('content')
        .select('*')
        .eq('lesson_id', lessonId)
        .eq('type', 'summary')
        .eq('verified', true)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (row == null) return null;
    return SummaryBody.fromJson(row['body'] as Map<String, dynamic>);
  }

  /// Which of the given lesson ids have a verified summary — a single
  /// batched query (never one query per lesson row) so the subject
  /// screen's lesson list can gate the "Résumé" shortcut per row without
  /// an N+1 fan-out.
  Future<Set<String>> getLessonIdsWithSummary(List<String> lessonIds) async {
    if (lessonIds.isEmpty) return {};
    final List<Map<String, dynamic>> rows = await _client
        .from('content')
        .select('lesson_id')
        .eq('type', 'summary')
        .eq('verified', true)
        .inFilter('lesson_id', lessonIds);
    return rows.map((row) => row['lesson_id'] as String).toSet();
  }
}
