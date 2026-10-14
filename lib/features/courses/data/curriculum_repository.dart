import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/chapter.dart';
import '../../../core/models/grade.dart';
import '../../../core/models/lesson.dart';
import '../../../core/models/subject.dart';

const String _lessonJoinSelect = '''
  id, num, title, concepts, pdf_pages, is_active, created_at,
  chapter:chapter_id!inner (
    id, num, title,
    subject:subject_id!inner ( id, country, grade, key, label, lang, icon )
  )
''';

/// The only place in the app that reads `subjects`/`chapters`/`lessons`.
/// Ported from packages/shared/src/api/curriculum.ts.
class CurriculumRepository {
  CurriculumRepository(this._client);

  final SupabaseClient _client;

  /// Subjects for a grade that have at least one active lesson — unlike a
  /// plain `subjects` select, this excludes subjects with no curriculum
  /// content yet (so the student never sees an empty subject card).
  Future<List<Subject>> getSubjectsWithContent({
    required String country,
    required int grade,
  }) async {
    final List<Map<String, dynamic>> rows = await _client
        .from('subjects')
        .select('*, chapters(id, lessons(id, is_active))')
        .eq('country', country)
        .eq('grade', grade)
        .eq('is_active', true)
        .order('key', ascending: true);

    return rows
        .where((row) {
          final List<dynamic> chapters =
              (row['chapters'] as List<dynamic>?) ?? const [];
          return chapters.any((c) {
            final List<dynamic> lessons =
                (c as Map<String, dynamic>)['lessons'] as List<dynamic>? ??
                    const [];
            return lessons
                .any((l) => (l as Map<String, dynamic>)['is_active'] == true);
          });
        })
        .map(Subject.fromJson)
        .toList();
  }

  /// Chapters (with nested lessons) for a subject, sorted by chapter then
  /// lesson number.
  Future<List<Chapter>> getChapters({
    required String country,
    required int grade,
    required String subjectKey,
  }) async {
    final List<Map<String, dynamic>> rows = await _client
        .from('lessons')
        .select(_lessonJoinSelect)
        .eq('chapter.subject.country', country)
        .eq('chapter.subject.grade', grade)
        .eq('chapter.subject.key', subjectKey)
        .eq('is_active', true)
        .order('num', ascending: true);

    // Sorted client-side by (chapter num, lesson num) rather than via a
    // second server-side `order(..., referencedTable: ...)` on the joined
    // chapter — keeps this query on only the well-established single-table
    // `order()` signature instead of a cross-version-sensitive option.
    final List<CurriculumLesson> lessons =
        rows.map(CurriculumLesson.fromJoinedJson).toList()
          ..sort((a, b) {
            final int chapterCompare = a.chapterNum.compareTo(b.chapterNum);
            return chapterCompare != 0
                ? chapterCompare
                : a.lessonNum.compareTo(b.lessonNum);
          });
    return Chapter.groupFrom(lessons);
  }

  Future<CurriculumLesson> getLessonById(String lessonId) async {
    final Map<String, dynamic> row = await _client.from('lessons').select('''
          id, num, title, concepts, pdf_pages, is_active, created_at,
          chapter:chapter_id (
            id, num, title,
            subject:subject_id ( id, country, grade, key, label, lang, icon )
          )
        ''').eq('id', lessonId).single();
    return CurriculumLesson.fromJoinedJson(row);
  }

  /// IDs of grades an admin has left open for new registrations — see
  /// `grades.is_active` (supabase/migrations/006_grades_table.sql). Read
  /// with no auth required (RLS: `grades_public_read`), so this works
  /// before a student/parent has an account, on the registration form
  /// itself.
  Future<Set<int>> getActiveGradeIds() async =>
      (await getOpenGrades()).map((g) => g.id).toSet();

  /// The open classes with the name, code and exam an admin saved
  /// (Curriculum page), in the admin's order — what the class pickers show.
  Future<List<GradeOption>> getOpenGrades() async {
    final List<Map<String, dynamic>> rows = await _client
        .from('grades')
        .select('id, label, short, cycle, exam, sort_order')
        .eq('is_active', true)
        .order('sort_order');
    return rows.map(GradeOption.fromJson).toList();
  }
}
