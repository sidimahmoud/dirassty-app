import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

/// One recurring focus window, e.g. Mon–Fri 17:00–19:00. Times are
/// device-local wall-clock minutes since midnight. `end < start` means
/// the window runs past midnight (e.g. 21:00–06:00): it starts on one of
/// [days] and ends the next morning.
@immutable
class FocusWindow {
  const FocusWindow({
    required this.days,
    required this.startMinute,
    required this.endMinute,
  });

  factory FocusWindow.fromJson(Map<String, dynamic> json) {
    return FocusWindow(
      days: (json['days'] as List<dynamic>)
          .map((d) => (d as num).toInt())
          .toSet(),
      startMinute: _parseTime(json['start'] as String),
      endMinute: _parseTime(json['end'] as String),
    );
  }

  /// ISO weekdays, 1 = Monday … 7 = Sunday (same as [DateTime.weekday]).
  final Set<int> days;
  final int startMinute;
  final int endMinute;

  bool get crossesMidnight => endMinute <= startMinute;

  Map<String, dynamic> toJson() => {
        'days': (days.toList()..sort()),
        'start': formatMinute(startMinute),
        'end': formatMinute(endMinute),
      };

  /// When the window containing [now] ends, or null if [now] is outside it.
  DateTime? endIfActive(DateTime now) {
    final int minute = now.hour * 60 + now.minute;
    final DateTime today = DateTime(now.year, now.month, now.day);
    if (!crossesMidnight) {
      if (days.contains(now.weekday) &&
          minute >= startMinute &&
          minute < endMinute) {
        return today.add(Duration(minutes: endMinute));
      }
      return null;
    }
    if (days.contains(now.weekday) && minute >= startMinute) {
      return today.add(Duration(days: 1, minutes: endMinute));
    }
    final int yesterday = now.weekday == 1 ? 7 : now.weekday - 1;
    if (days.contains(yesterday) && minute < endMinute) {
      return today.add(Duration(minutes: endMinute));
    }
    return null;
  }

  FocusWindow copyWith({Set<int>? days, int? startMinute, int? endMinute}) {
    return FocusWindow(
      days: days ?? this.days,
      startMinute: startMinute ?? this.startMinute,
      endMinute: endMinute ?? this.endMinute,
    );
  }

  static String formatMinute(int m) =>
      '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';

  static int _parseTime(String hhmm) {
    final List<String> parts = hhmm.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}

/// A student's focus-mode configuration — the `focus_settings` row (see
/// supabase/migrations/042_focus_mode.sql).
@immutable
class FocusSettings {
  const FocusSettings({
    required this.studentId,
    required this.enabled,
    required this.windows,
    required this.pinSalt,
    required this.pinHash,
  });

  factory FocusSettings.empty(String studentId) => FocusSettings(
        studentId: studentId,
        enabled: false,
        windows: const [],
        pinSalt: null,
        pinHash: null,
      );

  factory FocusSettings.fromJson(Map<String, dynamic> json) {
    return FocusSettings(
      studentId: json['student_id'] as String,
      enabled: json['enabled'] as bool? ?? false,
      windows: (json['windows'] as List<dynamic>? ?? const [])
          .map((w) => FocusWindow.fromJson(w as Map<String, dynamic>))
          .toList(),
      pinSalt: json['pin_salt'] as String?,
      pinHash: json['pin_hash'] as String?,
    );
  }

  final String studentId;
  final bool enabled;
  final List<FocusWindow> windows;
  final String? pinSalt;
  final String? pinHash;

  bool get hasPin => pinSalt != null && pinHash != null;

  Map<String, dynamic> toJson() => {
        'student_id': studentId,
        'enabled': enabled,
        'windows': windows.map((w) => w.toJson()).toList(),
        'pin_salt': pinSalt,
        'pin_hash': pinHash,
      };

  /// End of the focus window [now] falls in (the latest one, if windows
  /// overlap), or null when focus mode isn't in effect.
  DateTime? activeUntil(DateTime now) {
    if (!enabled || !hasPin) return null;
    DateTime? until;
    for (final FocusWindow w in windows) {
      final DateTime? end = w.endIfActive(now);
      if (end != null && (until == null || end.isAfter(until))) until = end;
    }
    return until;
  }

  bool verifyPin(String pin) => hasPin && _hash(pinSalt!, pin) == pinHash;

  FocusSettings copyWith({
    bool? enabled,
    List<FocusWindow>? windows,
    String? pin,
  }) {
    String? salt = pinSalt;
    String? hash = pinHash;
    if (pin != null) {
      final Random rng = Random.secure();
      salt = base64Url.encode(List<int>.generate(16, (_) => rng.nextInt(256)));
      hash = _hash(salt, pin);
    }
    return FocusSettings(
      studentId: studentId,
      enabled: enabled ?? this.enabled,
      windows: windows ?? this.windows,
      pinSalt: salt,
      pinHash: hash,
    );
  }

  static String _hash(String salt, String pin) =>
      sha256.convert(utf8.encode('$salt:$pin')).toString();
}
