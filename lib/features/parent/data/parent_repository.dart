import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/models/parent.dart';
import '../../../core/models/student.dart';

/// The only place in the app that reads the `parents` table or creates
/// `students` rows on a parent's behalf. Ported from
/// packages/shared/src/api/students.ts's `getStudentsByParent`/
/// `createStudent`.
class ParentRepository {
  ParentRepository(this._client);

  final SupabaseClient _client;

  /// `parents.id` always equals the auth user's id by convention (see
  /// AuthRepository.resolveRole) — no `auth_user_id` indirection needed,
  /// unlike students.
  Future<Parent> getCurrentParent(String authUserId) async {
    final Map<String, dynamic> row =
        await _client.from('parents').select('*').eq('id', authUserId).single();
    return Parent.fromJson(row);
  }

  Future<List<Student>> getStudentsByParent(String parentId) async {
    final List<Map<String, dynamic>> rows = await _client
        .from('students')
        .select('*')
        .eq('parent_id', parentId)
        .order('created_at', ascending: true);
    return rows.map(Student.fromJson).toList();
  }

  /// Self-service "add a child" — allowed by the existing
  /// `parents_see_children` RLS policy (`FOR ALL`, which covers INSERT)
  /// as long as `parent_id` matches the caller's own `parents.id`. No
  /// backend change was needed for this; it just had no UI trigger
  /// before (web only ever calls this once, from the first-run
  /// onboarding wizard — this screen is what a *returning* parent uses
  /// to add another child, which had no entry point on either platform
  /// until now).
  Future<Student> createStudent({
    required String parentId,
    required String name,
    required int grade,
    required String avatarId,
    String country = 'mauritania',
  }) async {
    final Map<String, dynamic> row = await _client
        .from('students')
        .insert({
          'parent_id': parentId,
          'registration_source': 'parent',
          'name': name,
          'grade': grade,
          'country': country,
          'avatar_id': avatarId,
        })
        .select()
        .single();
    return Student.fromJson(row);
  }

  /// Sets the login credentials — the username, the PIN (always 4
  /// digits), or both — for one of the caller's own children. See
  /// supabase/functions/set-student-pin. Covers three cases: a brand-new
  /// child (right after [createStudent], from AddChildScreen — both are
  /// required there), resetting an existing child's PIN, and changing an
  /// existing child's username (ChildProgressScreen, either or both).
  /// Returns the student's username, since a parent setting a brand-new
  /// child's login for the first time has no other way to learn it if
  /// they didn't choose one themselves.
  Future<String> setStudentCredentials({
    required String studentId,
    String? pin,
    String? username,
  }) async {
    assert(pin != null || username != null, 'nothing to update');
    final String? accessToken = _client.auth.currentSession?.accessToken;
    if (accessToken == null) {
      throw StateError('setStudentCredentials called with no active session');
    }

    final Uri uri =
        Uri.parse('${SupabaseConfig.url}/functions/v1/set-student-pin');
    final http.Response response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
        'apikey': SupabaseConfig.anonKey,
      },
      body: jsonEncode({
        'student_id': studentId,
        if (pin != null) 'pin': pin,
        if (username != null) 'username': username,
      }),
    );

    final Map<String, dynamic> data =
        jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(data['error']?.toString() ?? 'unknown_error');
    }

    return data['username'] as String;
  }
}
