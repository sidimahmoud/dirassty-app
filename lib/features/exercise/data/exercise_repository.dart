import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/content.dart';
import '../../../core/models/difficulty.dart';
import '../../../core/models/open_exercise_body.dart';
import '../../../core/models/open_exercise_correction.dart';
import '../../../core/models/tutor_reply.dart';
import '../../../core/network/api_client.dart';

/// The only place in the app that reads `content` rows of type
/// `'exercise'`/`'open_exercise'`, or calls the AI grading/generation
/// routes. Ported from packages/shared/src/api/content.ts and the
/// `/api/correct-open-exercise` + `/api/generate-similar-exercise` Next.js
/// routes.
class ExerciseRepository {
  ExerciseRepository(this._client, this._api);

  final SupabaseClient _client;
  final ApiClient _api;

  /// One malformed row (e.g. a half-filled admin edit) is skipped instead
  /// of failing the whole list — which used to show "Impossible de
  /// charger" for a lesson that does have usable exercises.
  static List<T> _parseEach<T>(
    List<Map<String, dynamic>> rows,
    T Function(Map<String, dynamic>) parse,
  ) {
    final List<T> out = [];
    for (final Map<String, dynamic> row in rows) {
      try {
        out.add(parse(row));
      } catch (e) {
        debugPrint('Skipping unreadable content row ${row['id']}: $e');
      }
    }
    return out;
  }

  Future<List<ExerciseContent>> getExercises(
    String lessonId,
    Difficulty difficulty, {
    int limit = 10,
  }) async {
    final List<Map<String, dynamic>> rows = await _client
        .from('content')
        .select('*')
        .eq('lesson_id', lessonId)
        .eq('type', 'exercise')
        .eq('difficulty', difficulty.dbValue)
        .eq('verified', true)
        .limit(limit);
    return _parseEach(rows, ExerciseContent.fromJson);
  }

  /// One fixed-size QCM session: pools up to 5 verified exercises from
  /// each difficulty (up to 15 total), then randomly draws [sessionSize]
  /// from that pool — so a session can mix difficulties in whatever
  /// proportion the random draw lands on, not a curated ramp. Mirrors
  /// apps/web/app/(student)/exercise/[id]/page.tsx exactly.
  Future<List<ExerciseContent>> getSessionExercises(
    String lessonId, {
    int sessionSize = 5,
  }) async {
    final List<List<ExerciseContent>> pools = await Future.wait([
      getExercises(lessonId, Difficulty.easy, limit: 5),
      getExercises(lessonId, Difficulty.medium, limit: 5),
      getExercises(lessonId, Difficulty.hard, limit: 5),
    ]);
    final List<ExerciseContent> all = pools.expand((p) => p).toList()
      ..shuffle(Random());
    return all.take(sessionSize).toList();
  }

  /// Open-ended exercises for a lesson, oldest first — mirrors the direct
  /// query in apps/web/app/(student)/open-practice/[id]/page.tsx (which,
  /// unlike the QCM/explanation queries, doesn't go through a
  /// packages/shared helper — it queries `content` inline).
  Future<List<OpenExerciseContent>> getOpenExercises(String lessonId) async {
    final List<Map<String, dynamic>> rows = await _client
        .from('content')
        .select('*')
        .eq('lesson_id', lessonId)
        .eq('type', 'open_exercise')
        .order('created_at', ascending: true);
    return _parseEach(rows, OpenExerciseContent.fromJson);
  }

  /// Checks a typed answer. [exerciseRef] is `{'content_id': id}` for a
  /// saved exercise or `{'generated_token': token}` for an AI follow-up —
  /// the server loads the exercise and its official solution itself.
  Future<OpenExerciseCorrection> correctOpenExercise({
    required Map<String, String> exerciseRef,
    required String studentAnswer,
    required String lang,
  }) async {
    final Map<String, dynamic> json = await _api.postJson(
      '/api/correct-open-exercise',
      {...exerciseRef, 'student_answer': studentAnswer, 'lang': lang},
    );
    return OpenExerciseCorrection.fromJson(json);
  }

  /// Checks a handwritten solution from 1-3 photos (page order).
  Future<OpenExerciseCorrection> checkSolutionPhotos({
    required Map<String, String> exerciseRef,
    required List<({Uint8List bytes, String filename})> photos,
    required String lang,
  }) async {
    final Map<String, dynamic> json = await _api.postMultipart(
      '/api/correct-open-exercise',
      fields: {...exerciseRef, 'lang': lang},
      files: photos,
    );
    return OpenExerciseCorrection.fromJson(json);
  }

  /// A new exercise on the same topic. Returns it with the encrypted token
  /// that identifies it to the server (its solution stays server-side).
  Future<({OpenExerciseBody body, String token})> generateSimilarExercise({
    required Map<String, String> exerciseRef,
    required String lang,
  }) async {
    final Map<String, dynamic> json = await _api.postJson(
      '/api/generate-similar-exercise',
      {...exerciseRef, 'lang': lang},
    );
    return (
      body: OpenExerciseBody.fromJson(json),
      token: json['generated_token'] as String? ?? '',
    );
  }

  /// Dirassty AI tutor — exercise solver (`mode: exercise`, with [exerciseRef])
  /// or lesson explainer (`mode: lesson`, with [lessonId]). See
  /// apps/web/app/api/tutor/route.ts for the actions.
  Future<TutorReply> askTutor({
    required String mode,
    required String action,
    Map<String, String>? exerciseRef,
    String? lessonId,
    String message = '',
    List<TutorTurn> history = const [],
    required String lang,
  }) async {
    final Map<String, dynamic> json = await _api.postJson('/api/tutor', {
      'mode': mode,
      'action': action,
      ...?exerciseRef,
      if (lessonId != null) 'lesson_id': lessonId,
      if (message.isNotEmpty) 'message': message,
      'history': history.map((t) => t.toJson()).toList(),
      'lang': lang,
    });
    return TutorReply.fromJson(json);
  }
}
