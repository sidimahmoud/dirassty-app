import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/explanation_body.dart';
import '../../../core/models/summary_body.dart';
import '../../../core/models/video_body.dart';

/// The only place in the app that reads `content` rows of
/// `type = 'explanation'`/`'video_url'`/`'exercise_video_url'`/`'summary'`.
/// Ported from `getExplanation`/`getVideos`/`getExerciseVideos`/
/// `getSummary` in packages/shared/src/api/content.ts.
/// Which practice parts a lesson has — decides where the lesson flow goes
/// after the video / written lesson (see [LessonRepository.getPractice]).
typedef LessonPractice = ({bool hasQcm, bool hasOpenExercises});

/// Optional PDF the admin attached for students (migration 084).
typedef LessonPdf = ({String path, String name, int? size});

class LessonRepository {
  LessonRepository(this._client);

  final SupabaseClient _client;

  /// The lesson's downloadable PDF, or null when it has none. Never throws
  /// (null too before migration 084 is applied) — it's an optional extra.
  Future<LessonPdf?> getLessonPdf(String lessonId) async {
    try {
      final Map<String, dynamic>? row = await _client
          .from('lessons')
          .select('student_pdf_path, student_pdf_name, student_pdf_size')
          .eq('id', lessonId)
          .maybeSingle();
      final String? path = row?['student_pdf_path'] as String?;
      if (path == null || path.isEmpty) return null;
      final String? name = row?['student_pdf_name'] as String?;
      return (
        path: path,
        name: (name == null || name.isEmpty) ? 'cours.pdf' : name,
        size: (row?['student_pdf_size'] as num?)?.toInt(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Short-lived (10 min) download link for [pdf] — private bucket
  /// `lesson-pdfs`; Storage only signs it for a student allowed to open
  /// the lesson (subscription / trial / free first lesson).
  Future<String> lessonPdfDownloadUrl(LessonPdf pdf) async {
    final String url = await _client.storage
        .from('lesson-pdfs')
        .createSignedUrl(pdf.path, 600);
    final String sep = url.contains('?') ? '&' : '?';
    return '$url${sep}download=${Uri.encodeQueryComponent(pdf.name)}';
  }

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

  /// Every verified explanation video for this lesson, in the admin's
  /// order — a lesson can have several, not just one. Empty
  /// when none has been generated yet — callers simply omit the video
  /// player, they don't show an error (most lessons have no video).
  Future<List<VideoBody>> getVideos(String lessonId) async {
    final List<Map<String, dynamic>> rows = await _client
        .from('content')
        .select('*')
        .eq('lesson_id', lessonId)
        .eq('type', 'video_url')
        .eq('verified', true)
        // Admin order (sort_order, migration 070); new uploads last.
        .order('sort_order', ascending: true, nullsFirst: false)
        .order('created_at', ascending: true);

    return rows
        .map((row) => VideoBody.fromJson(row['body'] as Map<String, dynamic>))
        .toList();
  }

  /// Every "how to solve these exercises" walkthrough video, distinct
  /// from the lesson-explanation videos above, in the admin's order. Empty when
  /// none has been generated for this lesson yet.
  Future<List<VideoBody>> getExerciseVideos(String lessonId) async {
    final List<Map<String, dynamic>> rows = await _client
        .from('content')
        .select('*')
        .eq('lesson_id', lessonId)
        .eq('type', 'exercise_video_url')
        .eq('verified', true)
        // Admin order (sort_order, migration 070); new uploads last.
        .order('sort_order', ascending: true, nullsFirst: false)
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

  /// Whether the lesson has a QCM (verified `exercise` rows — what the QCM
  /// screen loads) and open exercises (`open_exercise` rows — what open
  /// practice loads). One small query, two columns, no bodies.
  Future<LessonPractice> getPractice(String lessonId) async {
    final List<Map<String, dynamic>> rows = await _client
        .from('content')
        .select('type, verified')
        .eq('lesson_id', lessonId)
        .inFilter('type', ['exercise', 'open_exercise']);
    return (
      hasQcm: rows.any((r) => r['type'] == 'exercise' && r['verified'] == true),
      hasOpenExercises: rows.any((r) => r['type'] == 'open_exercise'),
    );
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
