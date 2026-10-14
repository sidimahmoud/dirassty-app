import 'package:flutter/foundation.dart';

/// How this student's account came to exist — set once at creation and
/// never changed after (see supabase/migrations/017_student_
/// notifications.sql). Determines who progress reports/notifications go
/// to server-side (the parent, or the student's own WhatsApp number when
/// there is no parent) and is shown on the student's own Profile screen.
enum StudentRegistrationSource {
  /// Created directly by a parent (AddChildScreen) — always has a
  /// [Student.parentId].
  parent,

  /// Created independently through the WhatsApp-OTP flow — either the
  /// student registered themselves, or claimed an admin-issued invite
  /// code. Either way there's no parent account; [Student.parentId] is
  /// null.
  self;

  static StudentRegistrationSource fromDb(String value) => switch (value) {
        'self' => StudentRegistrationSource.self,
        _ => StudentRegistrationSource.parent,
      };
}

/// Ported from `Student` in packages/shared/src/types — the `students`
/// table row for the logged-in student.
@immutable
class Student {
  const Student({
    required this.id,
    required this.parentId,
    required this.registrationSource,
    required this.name,
    required this.grade,
    required this.country,
    required this.avatarId,
    required this.streak,
    required this.streakLastDate,
    required this.xpTotal,
    required this.level,
    required this.lastActive,
    required this.username,
    required this.authUserId,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as String,
      // Null for a self-registered/admin-invited student — there is no
      // parent account (see [registrationSource]).
      parentId: json['parent_id'] as String?,
      registrationSource: StudentRegistrationSource.fromDb(
        json['registration_source'] as String? ?? 'parent',
      ),
      name: json['name'] as String,
      grade: json['grade'] as int,
      country: json['country'] as String,
      avatarId: json['avatar_id'] as String,
      streak: json['streak'] as int,
      streakLastDate: json['streak_last_date'] as String?,
      xpTotal: json['xp_total'] as int,
      level: json['level'] as int,
      lastActive: json['last_active'] as String?,
      username: json['username'] as String?,
      authUserId: json['auth_user_id'] as String?,
    );
  }

  final String id;
  final String? parentId;
  final StudentRegistrationSource registrationSource;
  final String name;
  final int grade;
  final String country;
  final String avatarId;
  final int streak;

  /// ISO date (`YYYY-MM-DD`), not a timestamp — matches how the backend
  /// compares it against "today"/"yesterday" for streak continuation.
  final String? streakLastDate;
  final int xpTotal;
  final int level;
  final String? lastActive;
  final String? username;
  final String? authUserId;

  Student copyWith({
    int? streak,
    String? streakLastDate,
    int? xpTotal,
    int? level,
  }) {
    return Student(
      id: id,
      parentId: parentId,
      registrationSource: registrationSource,
      name: name,
      grade: grade,
      country: country,
      avatarId: avatarId,
      streak: streak ?? this.streak,
      streakLastDate: streakLastDate ?? this.streakLastDate,
      xpTotal: xpTotal ?? this.xpTotal,
      level: level ?? this.level,
      lastActive: lastActive,
      username: username,
      authUserId: authUserId,
    );
  }
}
