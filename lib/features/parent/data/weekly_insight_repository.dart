import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/api_config.dart';
import '../../../core/models/weekly_insight.dart';

String _mondayOf(DateTime date) {
  final DateTime monday = date.subtract(Duration(days: date.weekday - 1));
  final DateTime d = DateTime(monday.year, monday.month, monday.day);
  final String y = d.year.toString().padLeft(4, '0');
  final String m = d.month.toString().padLeft(2, '0');
  final String day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

/// Reads/generates a student's weekly insight. The AI call itself has to
/// stay server-side (see /api/generate/weekly-insight) — this repository
/// tries a direct, RLS-protected read of the cached row first (free, no
/// AI call, no network round-trip to Next.js), and only calls the API
/// route if nothing's cached yet for the current week.
class WeeklyInsightRepository {
  WeeklyInsightRepository(this._client);

  final SupabaseClient _client;

  Future<WeeklyInsight?> _getCached(String studentId) async {
    final Map<String, dynamic>? row = await _client
        .from('weekly_insights')
        .select('*')
        .eq('student_id', studentId)
        .eq('week_start', _mondayOf(DateTime.now()))
        .maybeSingle();
    if (row == null) return null;
    return WeeklyInsight.fromJson(row);
  }

  Future<WeeklyInsight> _generate(String studentId) async {
    final Uri uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/generate/weekly-insight',
    );
    final http.Response response = await http.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'student_id': studentId}),
    );
    final Map<String, dynamic> data =
        jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(data['error']?.toString() ?? 'Erreur IA');
    }
    return WeeklyInsight.fromJson(data);
  }

  Future<WeeklyInsight> getOrGenerate(String studentId) async {
    final WeeklyInsight? cached = await _getCached(studentId);
    if (cached != null) return cached;
    return _generate(studentId);
  }
}
