import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/gamification/gamification.dart';
import '../../../core/models/difficulty.dart';
import '../../../core/models/lesson_progress_summary.dart';
import '../../../core/models/progress.dart';
import '../../../core/models/student_stats.dart';
import '../../../core/models/subject_mastery.dart';

/// Result of [ProgressRepository.addXp] — mirrors the return shape of
/// `addXP` in packages/shared/src/api/students.ts so callers can show a
/// level-up celebration without a second query.
class XpAwardResult {
  const XpAwardResult({
    required this.xpTotal,
    required this.level,
    required this.leveledUp,
  });

  final int xpTotal;
  final int level;
  final bool leveledUp;
}

/// A lesson the student has opened and read through at least once (see
/// [ProgressRepository.markLessonViewed]) but hasn't yet answered any
/// exercise for shows this much mastery instead of a flat 0 — reading the
/// explanation is real progress too, just less than actually attempting
/// exercises (whose first correct answer already starts at 0.3, see
/// [ProgressRepository.updateMastery]).
const double kViewedOnlyMastery = 0.15;

/// The only place in the app that writes to `progress`, `xp_events`, or
/// the gamification columns on `students` (`xp_total`, `level`, `streak`,
/// `streak_last_date`). Ported from packages/shared/src/api/progress.ts
/// and the XP/streak parts of packages/shared/src/api/students.ts.
class ProgressRepository {
  ProgressRepository(this._client);

  final SupabaseClient _client;

  Future<List<Progress>> getProgress(String studentId, String lessonId) async {
    final List<Map<String, dynamic>> rows = await _client
        .from('progress')
        .select('*')
        .eq('student_id', studentId)
        .eq('lesson_id', lessonId);
    return rows.map(Progress.fromJson).toList();
  }

  /// Weighted moving average (recent answer weighted 70/30 against
  /// history) plus a spaced-repetition `next_review` date. Fires once per
  /// answered QCM question — never for open exercises (the web app
  /// doesn't record those either, see open-practice's data-write notes).
  Future<void> updateMastery({
    required String studentId,
    required String lessonId,
    required String concept,
    required bool correct,
  }) async {
    final Map<String, dynamic>? existing = await _client
        .from('progress')
        .select('*')
        .eq('student_id', studentId)
        .eq('lesson_id', lessonId)
        .eq('concept', concept)
        .maybeSingle();

    final int newAttempts;
    final int newCorrect;
    final double newMastery;
    if (existing != null) {
      newAttempts = (existing['attempts'] as int) + 1;
      newCorrect = (existing['correct'] as int) + (correct ? 1 : 0);
      final double recentScore = correct ? 1 : 0;
      newMastery = ((existing['mastery'] as num) * 0.7 + recentScore * 0.3)
          .clamp(0, 1)
          .toDouble();
    } else {
      newAttempts = 1;
      newCorrect = correct ? 1 : 0;
      newMastery = correct ? 0.3 : 0;
    }

    final int daysUntilReview = newMastery > 0.8
        ? 7
        : correct
            ? 3
            : 1;
    final DateTime nextReview = DateTime.now().add(
      Duration(days: daysUntilReview),
    );
    final Difficulty difficultyLevel = newMastery < 0.4
        ? Difficulty.easy
        : newMastery < 0.7
            ? Difficulty.medium
            : Difficulty.hard;

    await _client.from('progress').upsert(
      {
        'student_id': studentId,
        'lesson_id': lessonId,
        'concept': concept,
        'attempts': newAttempts,
        'correct': newCorrect,
        'mastery': double.parse(newMastery.toStringAsFixed(2)),
        'difficulty_level': difficultyLevel.dbValue,
        'next_review': nextReview.toIso8601String().split('T').first,
        'last_attempted': DateTime.now().toIso8601String(),
      },
      onConflict: 'student_id,lesson_id,concept',
    );
  }

  /// Diluted across every active lesson in the subject (untouched *and
  /// unviewed* lessons count as 0), so this is on the same 0–1 scale
  /// regardless of how many lessons the student has actually tried yet.
  /// A lesson the student has only viewed (see [markLessonViewed]), never
  /// exercised, contributes [kViewedOnlyMastery] instead of 0.
  /// [lessonsCompleted] still only counts lessons with real exercise
  /// attempts — "completed" means exercised, not just read.
  Future<SubjectMastery> getSubjectMastery({
    required String studentId,
    required String subjectKey,
    required int grade,
  }) async {
    final List<Map<String, dynamic>> rows = await _client
        .from('progress')
        .select(
          'lesson_id, mastery, lessons!inner(chapter:chapter_id!inner(subject:subject_id!inner(key, grade)))',
        )
        .eq('student_id', studentId)
        .eq('lessons.chapter.subject.key', subjectKey)
        .eq('lessons.chapter.subject.grade', grade);

    final Map<String, List<double>> perLesson = {};
    for (final Map<String, dynamic> row in rows) {
      final String lessonId = row['lesson_id'] as String;
      perLesson
          .putIfAbsent(lessonId, () => [])
          .add((row['mastery'] as num).toDouble());
    }

    // A plain row fetch + client-side length, not a head/count request —
    // avoids depending on the exact count-request API shape for this
    // package version, and a subject's lesson count is small enough
    // (tens, not thousands) that this is cheap either way.
    final List<Map<String, dynamic>> totalLessonRows = await _client
        .from('lessons')
        .select(
          'id, chapter:chapter_id!inner(subject:subject_id!inner(key, grade))',
        )
        .eq('chapter.subject.key', subjectKey)
        .eq('chapter.subject.grade', grade)
        .eq('is_active', true);
    final int totalLessons = totalLessonRows.length;

    final Set<String> viewedLessonIds = await getViewedLessonIds(studentId);
    final List<double> lessonMasteries = [];
    for (final Map<String, dynamic> row in totalLessonRows) {
      final String lessonId = row['id'] as String;
      final List<double>? values = perLesson[lessonId];
      if (values != null) {
        lessonMasteries.add(values.reduce((a, b) => a + b) / values.length);
      } else if (viewedLessonIds.contains(lessonId)) {
        lessonMasteries.add(kViewedOnlyMastery);
      }
    }

    final double mastery = totalLessons > 0
        ? lessonMasteries.fold(0.0, (sum, m) => sum + m) / totalLessons
        : 0;

    return SubjectMastery(
      subject: subjectKey,
      mastery: double.parse(mastery.toStringAsFixed(2)),
      lessonsCompleted: perLesson.length,
      totalLessons: totalLessons,
    );
  }

  /// Per-lesson mastery for every lesson the student has attempted *or
  /// viewed* in a subject — used to color-code lesson rows in the subject
  /// detail screen (green/amber/untouched). A viewed-but-unexercised
  /// lesson maps to [kViewedOnlyMastery] rather than being absent — see
  /// [getSubjectMastery] for why.
  Future<Map<String, double>> getLessonMasteryMap({
    required String studentId,
    required String subjectKey,
    required int grade,
  }) async {
    final List<Map<String, dynamic>> rows = await _client
        .from('progress')
        .select(
          'lesson_id, mastery, lessons!inner(chapter:chapter_id!inner(subject:subject_id!inner(key, grade)))',
        )
        .eq('student_id', studentId)
        .eq('lessons.chapter.subject.key', subjectKey)
        .eq('lessons.chapter.subject.grade', grade);

    final Map<String, List<double>> totals = {};
    for (final Map<String, dynamic> row in rows) {
      final String lessonId = row['lesson_id'] as String;
      totals
          .putIfAbsent(lessonId, () => [])
          .add((row['mastery'] as num).toDouble());
    }
    final Map<String, double> masteryMap = totals.map(
      (lessonId, values) =>
          MapEntry(lessonId, values.reduce((a, b) => a + b) / values.length),
    );

    // Viewed ids aren't scoped to this subject (a single cheap query
    // shared by every subject screen) — harmless here since only ids
    // belonging to the current subject's lessons are ever looked up in
    // this map.
    final Set<String> viewedLessonIds = await getViewedLessonIds(studentId);
    for (final String lessonId in viewedLessonIds) {
      masteryMap.putIfAbsent(lessonId, () => kViewedOnlyMastery);
    }
    return masteryMap;
  }

  /// Marks a lesson as viewed by this student — upserts and ignores a
  /// repeat view, so only the *first* time is recorded (that's what gates
  /// the exercise shortcuts and the mastery floor above). Called once,
  /// from LessonViewerScreen's Ready step.
  Future<void> markLessonViewed({
    required String studentId,
    required String lessonId,
  }) async {
    await _client.from('lesson_views').upsert(
      {'student_id': studentId, 'lesson_id': lessonId},
      onConflict: 'student_id,lesson_id',
      ignoreDuplicates: true,
    );
  }

  /// Every lesson id this student has ever viewed once (see
  /// [markLessonViewed]) — used to gate the QCM/open-exercise shortcuts on
  /// the subject screen and to give unexercised-but-viewed lessons a
  /// mastery floor (see [getSubjectMastery]/[getLessonMasteryMap]).
  Future<Set<String>> getViewedLessonIds(String studentId) async {
    final List<Map<String, dynamic>> rows = await _client
        .from('lesson_views')
        .select('lesson_id')
        .eq('student_id', studentId);
    return rows.map((r) => r['lesson_id'] as String).toSet();
  }

  /// Marks a lesson's open-practice exercises as done at least once by
  /// this student — upserts and ignores a repeat, same as
  /// [markLessonViewed]. Called once an AI correction actually comes back
  /// for a submitted answer (see OpenPracticeController.requestCorrection)
  /// — the only per-lesson signal open practice writes anywhere, since
  /// normal attempts never touch `progress` (see 039_open_practice_views.sql).
  Future<void> markOpenPracticeViewed({
    required String studentId,
    required String lessonId,
  }) async {
    await _client.from('open_practice_views').upsert(
      {'student_id': studentId, 'lesson_id': lessonId},
      onConflict: 'student_id,lesson_id',
      ignoreDuplicates: true,
    );
  }

  /// Every lesson id this student has ever completed an open-practice
  /// exercise for at least once (see [markOpenPracticeViewed]) — used by
  /// the lesson resume screen to offer "redo the exercises" only once
  /// they've actually been attempted before.
  Future<Set<String>> getOpenPracticeViewedLessonIds(String studentId) async {
    final List<Map<String, dynamic>> rows = await _client
        .from('open_practice_views')
        .select('lesson_id')
        .eq('student_id', studentId);
    return rows.map((r) => r['lesson_id'] as String).toSet();
  }

  /// Per-lesson "did they open it" + "did they practice it" for every
  /// lesson in a subject — what the parent's subject drill-down shows
  /// (see ParentSubjectDetailScreen). Unlike [getLessonMasteryMap] (which
  /// folds a viewed-only lesson into a small mastery floor for the
  /// student's own motivational display), this keeps [viewed] and
  /// [LessonProgressSummary.exercisesDone] as two separate facts — a
  /// parent asking "was this actually practiced" needs the real answer,
  /// not a blended number. A lesson absent from the map was neither
  /// viewed nor exercised.
  Future<Map<String, LessonProgressSummary>> getLessonProgressSummary({
    required String studentId,
    required String subjectKey,
    required int grade,
  }) async {
    final List<Map<String, dynamic>> progressRows = await _client
        .from('progress')
        .select(
          'lesson_id, attempts, correct, mastery, lessons!inner(chapter:chapter_id!inner(subject:subject_id!inner(key, grade)))',
        )
        .eq('student_id', studentId)
        .eq('lessons.chapter.subject.key', subjectKey)
        .eq('lessons.chapter.subject.grade', grade);

    final Map<String, List<Map<String, dynamic>>> byLesson = {};
    for (final Map<String, dynamic> row in progressRows) {
      final String lessonId = row['lesson_id'] as String;
      byLesson.putIfAbsent(lessonId, () => []).add(row);
    }

    final Set<String> viewedLessonIds = await getViewedLessonIds(studentId);

    final Map<String, LessonProgressSummary> summary = {};
    for (final MapEntry<String, List<Map<String, dynamic>>> entry
        in byLesson.entries) {
      final int attempts =
          entry.value.fold(0, (sum, r) => sum + (r['attempts'] as int));
      final double mastery = entry.value
              .map((r) => (r['mastery'] as num).toDouble())
              .reduce((a, b) => a + b) /
          entry.value.length;
      summary[entry.key] = LessonProgressSummary(
        viewed: viewedLessonIds.contains(entry.key),
        exercisesDone: attempts > 0,
        attempts: attempts,
        mastery: mastery,
      );
    }
    for (final String lessonId in viewedLessonIds) {
      summary.putIfAbsent(
        lessonId,
        () => const LessonProgressSummary(
          viewed: true,
          exercisesDone: false,
          attempts: 0,
          mastery: 0,
        ),
      );
    }
    return summary;
  }

  /// Single XP write for a whole session (not per-question) — inserts one
  /// `xp_events` row and bumps `students.xp_total`/`level`.
  Future<XpAwardResult> addXp({
    required String studentId,
    required int points,
    required XpSource source,
    Map<String, dynamic> metadata = const {},
  }) async {
    final Map<String, dynamic> student = await _client
        .from('students')
        .select('xp_total, level')
        .eq('id', studentId)
        .single();

    final int newXp = (student['xp_total'] as int) + points;
    final int newLevel = levelFromXp(newXp);
    final bool leveledUp = newLevel > (student['level'] as int);

    await _client.from('students').update({
      'xp_total': newXp,
      'level': newLevel,
      'last_active': DateTime.now().toIso8601String(),
    }).eq('id', studentId);

    await _client.from('xp_events').insert({
      'student_id': studentId,
      'source': source.dbValue,
      'points': points,
      'metadata': metadata,
    });

    return XpAwardResult(xpTotal: newXp, level: newLevel, leveledUp: leveledUp);
  }

  /// No-op if already updated today; +1 if the student's last active day
  /// was within the last 3 days; resets to 1 otherwise (streak broken).
  /// Same grace window as supabase/functions/check-streaks, which zeroes
  /// out `streak` on the same 3-day cutoff for a student who never comes
  /// back at all — missing 1 or 2 days in a row no longer breaks the
  /// streak, only a 3rd consecutive missed day does.
  Future<int> updateStreak(String studentId) async {
    final Map<String, dynamic> student = await _client
        .from('students')
        .select('streak, streak_last_date')
        .eq('id', studentId)
        .single();

    final DateTime now = DateTime.now();
    final String today = now.toIso8601String().split('T').first;
    final String? lastDate = student['streak_last_date'] as String?;
    if (lastDate == today) return student['streak'] as int;

    final int newStreak = nextStreak(
      currentStreak: student['streak'] as int,
      lastDate: lastDate,
      now: now,
    );

    await _client.from('students').update({
      'streak': newStreak,
      'streak_last_date': today,
      'last_active': DateTime.now().toIso8601String(),
    }).eq('id', studentId);

    return newStreak;
  }

  /// Logs one chunk of time-on-task as a single row — a finished QCM
  /// session (see QcmSessionController.next()) or a lesson-viewer visit
  /// (see LessonViewerScreen.dispose(), which calls this regardless of
  /// whether the student reached the end). Never continuous, so this is
  /// one cheap insert per session/visit rather than a write per second.
  Future<void> logStudySession({
    required String studentId,
    required DateTime startedAt,
  }) async {
    final int durationSeconds = DateTime.now().difference(startedAt).inSeconds;
    if (durationSeconds <= 0) return;
    try {
      await _client.from('study_sessions').insert({
        'student_id': studentId,
        'started_at': startedAt.toIso8601String(),
        'duration_seconds': durationSeconds,
      });
    } catch (e) {
      // Every caller fires this without awaiting (often from a
      // dispose()), so a failure here would otherwise vanish silently
      // with no way to ever notice it.
      debugPrint('logStudySession failed: $e');
    }
  }

  /// Streak plus rolling week/month stats for the home screen's stat
  /// tiles and the parent's per-child progress view. One fetch per
  /// underlying table (progress, study_sessions, students) covering the
  /// full 30-day window — the 7-day ("week") figures are derived from
  /// those same rows rather than issuing a second round-trip per period.
  Future<StudentStats> getStudentStats(String studentId) async {
    final DateTime monthStart =
        DateTime.now().subtract(const Duration(days: 30));

    final List<Map<String, dynamic>> progressRows = await _client
        .from('progress')
        .select('attempts, correct, last_attempted')
        .eq('student_id', studentId)
        .gte('last_attempted', monthStart.toIso8601String());

    final List<Map<String, dynamic>> sessionRows = await _client
        .from('study_sessions')
        .select('duration_seconds, started_at')
        .eq('student_id', studentId)
        .gte('started_at', monthStart.toIso8601String());

    final Map<String, dynamic> student = await _client
        .from('students')
        .select('streak')
        .eq('id', studentId)
        .single();

    PeriodStats statsSince(DateTime cutoff, int periodDays) {
      final Iterable<Map<String, dynamic>> progressInPeriod =
          progressRows.where(
        (r) => DateTime.parse(r['last_attempted'] as String).isAfter(cutoff),
      );
      final int attempts = progressInPeriod.fold(
        0,
        (sum, r) => sum + (r['attempts'] as int),
      );
      final int correct = progressInPeriod.fold(
        0,
        (sum, r) => sum + (r['correct'] as int),
      );
      final Set<String> activeDays = progressInPeriod
          .map((r) => (r['last_attempted'] as String).split('T').first)
          .toSet();
      final int totalSeconds = sessionRows
          .where(
            (r) => DateTime.parse(r['started_at'] as String).isAfter(cutoff),
          )
          .fold(0, (sum, r) => sum + (r['duration_seconds'] as int));
      // Rounded, not floor-divided — floor-dividing silently hid every
      // sub-60s session (a quick lesson re-read, a short QCM retry) as
      // "0min" even though real time was logged.
      final int minutesOnApp = (totalSeconds / 60).round();

      return PeriodStats(
        periodDays: periodDays,
        exercisesDone: attempts,
        correctRate: attempts > 0 ? correct / attempts : 0,
        daysActive: activeDays.length,
        minutesOnApp: minutesOnApp,
      );
    }

    final DateTime weekStart = DateTime.now().subtract(const Duration(days: 7));

    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final List<int> dailySeconds = List<int>.filled(7, 0);
    for (final Map<String, dynamic> r in sessionRows) {
      final DateTime local =
          DateTime.parse(r['started_at'] as String).toLocal();
      final int daysAgo =
          today.difference(DateTime(local.year, local.month, local.day)).inDays;
      if (daysAgo < 0 || daysAgo > 6) continue;
      dailySeconds[6 - daysAgo] += r['duration_seconds'] as int;
    }

    return StudentStats(
      streak: student['streak'] as int,
      week: statsSince(weekStart, 7),
      month: statsSince(monthStart, 30),
      last7DaysMinutes: [for (final int s in dailySeconds) (s / 60).round()],
    );
  }
}
