import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/focus_settings.dart';

/// One focus-mode exit, as shown to the parent.
class FocusEvent {
  const FocusEvent({required this.kind, required this.occurredAt});

  factory FocusEvent.fromJson(Map<String, dynamic> json) => FocusEvent(
        kind: json['kind'] as String,
        occurredAt: DateTime.parse(json['occurred_at'] as String).toLocal(),
      );

  /// 'left_app' or 'pin_unlock' — see 042_focus_mode.sql.
  final String kind;
  final DateTime occurredAt;

  Map<String, dynamic> toJson() => {
        'kind': kind,
        'occurred_at': occurredAt.toUtc().toIso8601String(),
      };
}

/// Reads/writes `focus_settings` and `focus_events`, plus the student
/// device's local copies: the last-fetched settings (so enforcement works
/// offline) and a queue of events recorded while offline.
class FocusRepository {
  FocusRepository(this._client);

  final SupabaseClient _client;

  static const String _cacheKey = 'focus.settings.cache.v1';
  static const String _overrideKey = 'focus.override_until';
  static const String _queueKey = 'focus.event_queue.v1';

  Future<FocusSettings> getSettings(String studentId) async {
    final Map<String, dynamic>? row = await _client
        .from('focus_settings')
        .select('student_id, enabled, windows, pin_salt, pin_hash')
        .eq('student_id', studentId)
        .maybeSingle();
    return row == null
        ? FocusSettings.empty(studentId)
        : FocusSettings.fromJson(row);
  }

  Future<void> saveSettings(FocusSettings settings) async {
    await _client.from('focus_settings').upsert(settings.toJson());
  }

  /// Saves from the student's own session (a parent using the child's
  /// phone) through the PIN-checking RPC in
  /// 043_focus_mode_student_device.sql. Returns 'ok', 'wrong_pin' or
  /// 'pin_locked'.
  Future<String> saveSettingsAsStudent({
    required String? currentPin,
    required FocusSettings settings,
    required bool pinChanged,
  }) async {
    final Object? result = await _client.rpc<Object?>(
      'save_focus_settings_as_student',
      params: {
        'p_current_pin': currentPin,
        'p_enabled': settings.enabled,
        'p_windows': settings.windows.map((w) => w.toJson()).toList(),
        'p_new_salt': pinChanged ? settings.pinSalt : null,
        'p_new_hash': pinChanged ? settings.pinHash : null,
      },
    );
    return result as String? ?? 'ok';
  }

  Future<List<FocusEvent>> getRecentEvents(String studentId) async {
    final List<Map<String, dynamic>> rows = await _client
        .from('focus_events')
        .select('kind, occurred_at')
        .eq('student_id', studentId)
        .order('occurred_at', ascending: false)
        .limit(20);
    return rows.map(FocusEvent.fromJson).toList();
  }

  // ── Student-device local state ───────────────────────────────────

  Future<FocusSettings?> readCachedSettings() async {
    final String? raw =
        (await SharedPreferences.getInstance()).getString(_cacheKey);
    return raw == null
        ? null
        : FocusSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> cacheSettings(FocusSettings settings) async {
    await (await SharedPreferences.getInstance())
        .setString(_cacheKey, jsonEncode(settings.toJson()));
  }

  /// A PIN unlock suspends focus mode until the end of the window it was
  /// entered in — persisted so an app restart doesn't re-lock.
  Future<DateTime?> readOverrideUntil() async {
    final String? raw =
        (await SharedPreferences.getInstance()).getString(_overrideKey);
    return raw == null ? null : DateTime.parse(raw);
  }

  Future<void> writeOverrideUntil(DateTime until) async {
    await (await SharedPreferences.getInstance())
        .setString(_overrideKey, until.toIso8601String());
  }

  /// Called on sign-out — a schedule belongs to the account, not the
  /// device.
  static Future<void> clearLocal() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove(_overrideKey);
    await prefs.remove(_queueKey);
  }

  /// Queues [event] locally, then tries to send everything queued. Never
  /// throws — anything unsent stays queued for the next attempt.
  Future<void> logEvent(String studentId, FocusEvent event) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> queue = prefs.getStringList(_queueKey) ?? [];
    queue.add(jsonEncode({'student_id': studentId, ...event.toJson()}));
    await prefs.setStringList(_queueKey, queue);
    await flushEvents();
  }

  Future<void> flushEvents() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> queue = prefs.getStringList(_queueKey) ?? [];
    if (queue.isEmpty) return;
    try {
      await _client.from('focus_events').insert(
            queue.map((e) => jsonDecode(e) as Map<String, dynamic>).toList(),
          );
      await prefs.remove(_queueKey);
    } catch (_) {
      // Offline — retried on the next event or app resume.
    }
  }
}
