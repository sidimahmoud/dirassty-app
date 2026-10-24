import 'dart:math';

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

  /// One QCM session: every available question up to [sessionSize] (10) —
  /// a lesson with 7 verified questions gives 7, one with 15 gives 10.
  /// Balanced across difficulties: every level the lesson has (easy,
  /// medium, hard) is represented, split as evenly as possible — 10 with
  /// all three levels = 4 easy, 3 medium, 3 hard — then ordered easy → hard. Questions are drawn at random
  /// within each level from all the lesson's verified ones (one request).
  Future<List<ExerciseContent>> getSessionExercises(
    String lessonId, {
    int sessionSize = 10,
  }) async {
    final List<Map<String, dynamic>> rows = await _client
        .from('content')
        .select('*')
        .eq('lesson_id', lessonId)
        .eq('type', 'exercise')
        .eq('verified', true)
        .limit(200);
    return balancedSession(
      _parseEach(rows, ExerciseContent.fromJson),
      sessionSize,
      Random(),
    );
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
    required String lang,
    Map<String, String>? exerciseRef,
    String? lessonId,
    String message = '',
    List<TutorTurn> history = const [],
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

/// Picks [size] exercises from [all] with every available difficulty
/// represented, as evenly as possible (the extra slots go to the easier
/// levels first); a level with too few exercises hands its slots to the
/// others. Random within each level; returned easy → medium → hard.
@visibleForTesting
List<ExerciseContent> balancedSession(
  List<ExerciseContent> all,
  int size,
  Random random,
) {
  final Map<Difficulty, List<ExerciseContent>> byLevel = {
    for (final Difficulty d in Difficulty.values)
      d: all.where((e) => e.difficulty == d).toList()..shuffle(random),
  };
  final List<Difficulty> levels =
      Difficulty.values.where((d) => byLevel[d]!.isNotEmpty).toList();
  if (levels.isEmpty || size <= 0) return const [];

  // Even split, remainder to the easier levels.
  final Map<Difficulty, int> take = {
    for (final (int i, Difficulty d) in levels.indexed)
      d: size ~/ levels.length + (i < size % levels.length ? 1 : 0),
  };
  // Cap at what each level has; give the shortfall to levels with more.
  int missing = 0;
  for (final Difficulty d in levels) {
    final int available = byLevel[d]!.length;
    if (take[d]! > available) {
      missing += take[d]! - available;
      take[d] = available;
    }
  }
  for (final Difficulty d in levels) {
    if (missing == 0) break;
    final int extra = min(missing, byLevel[d]!.length - take[d]!);
    take[d] = take[d]! + extra;
    missing -= extra;
  }

  return [
    for (final Difficulty d in levels) ...byLevel[d]!.take(take[d]!),
  ];
}
