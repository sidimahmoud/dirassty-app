import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/student.dart';

/// The only place in the app that reads/writes the `students` table row
/// for "the logged-in student themselves" (as opposed to a parent's list
/// of children — that's a separate, not-yet-built parent-mode concern).
class StudentRepository {
  StudentRepository(this._client);

  final SupabaseClient _client;

  /// Resolves the current student from the session, the same way for
  /// every screen — unlike the web app, which inconsistently uses
  /// `getCurrentStudent` (auth_user_id OR parent_id) on some pages and
  /// `getStudentsByParent` (parent_id only) on others. A directly
  /// logged-in student (auth_user_id set) would resolve to nothing on
  /// those parent_id-only pages; standardizing on this one path avoids
  /// reproducing that bug.
  Future<Student> getCurrentStudent(String authUserId) async {
    final Map<String, dynamic>? direct = await _client
        .from('students')
        .select('*')
        .eq('auth_user_id', authUserId)
        .maybeSingle();
    if (direct != null) return Student.fromJson(direct);

    final Map<String, dynamic>? viaParent = await _client
        .from('students')
        .select('*')
        .eq('parent_id', authUserId)
        .order('created_at', ascending: true)
        .limit(1)
        .maybeSingle();
    if (viaParent != null) return Student.fromJson(viaParent);

    throw StateError('No student found for this account');
  }
}
