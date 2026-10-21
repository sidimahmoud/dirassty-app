import 'dart:math';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/app_settings.dart';
import '../../../core/models/plan.dart';
import '../../../core/models/subscription.dart';

const String _subscriptionSelect = '*, plan:plan_id(*)';

/// Ported from packages/shared/src/api/subscriptions.ts, scoped per
/// student (see supabase/migrations/016_student_subscriptions.sql and
/// 018_configurable_plans.sql). Deliberately never exposes a way to set
/// `status: active` — only an admin, from the web panel, can activate a
/// subscription; RLS enforces this server-side too (parents/students can
/// only INSERT rows with status in trial/pending/unpaid), so this isn't
/// just a client-side convention.
class SubscriptionRepository {
  SubscriptionRepository(this._client);

  final SupabaseClient _client;

  /// Admin-controlled app-wide settings — whether new students currently
  /// get a free trial at all, and for how long. See
  /// supabase/migrations/020_trial_toggle.sql.
  Future<AppSettings> getAppSettings() async {
    final Map<String, dynamic> row =
        await _client.from('app_settings').select('*').eq('id', true).single();
    return AppSettings.fromJson(row);
  }

  /// Every plan currently offered, cheapest/shortest first.
  Future<List<Plan>> getActivePlans() async {
    final List<Map<String, dynamic>> rows = await _client
        .from('plans')
        .select('*')
        .eq('is_active', true)
        .order('sort_order', ascending: true);
    return rows.map(Plan.fromJson).toList();
  }

  /// Every subscription row for every child of this parent, newest first
  /// — callers reduce this to "latest row per student" themselves (see
  /// [subscriptionsByStudentProvider]) since a student can have several
  /// rows over time (trial, then a renewed/expired paid period, etc).
  Future<List<Subscription>> getSubscriptionsForParent(String parentId) async {
    final List<Map<String, dynamic>> rows = await _client
        .from('subscriptions')
        .select(_subscriptionSelect)
        .eq('parent_id', parentId)
        .order('created_at', ascending: false);
    return rows.map(Subscription.fromJson).toList();
  }

  /// The subscription row that actually grants (or most recently granted)
  /// a single student's course access — NOT simply the most recently
  /// created row, since an early renewal (see the admin activation logic)
  /// leaves a student with two 'active' rows at once: the one currently
  /// in effect and a future one scheduled to take over once it ends (see
  /// [Subscription.isUpcoming]). Looks at a handful of recent rows and
  /// picks the one that grants access right now, falling back to the
  /// newest row otherwise (so a lapsed/pending student still sees
  /// something sensible instead of null).
  Future<Subscription?> getLatestForStudent(String studentId) async {
    final List<Map<String, dynamic>> rows = await _client
        .from('subscriptions')
        .select(_subscriptionSelect)
        .eq('student_id', studentId)
        .order('created_at', ascending: false)
        .limit(5);
    if (rows.isEmpty) return null;
    final List<Subscription> subs = rows.map(Subscription.fromJson).toList();
    return subs.firstWhere(
      (Subscription s) => s.grantsAccess,
      orElse: () => subs.first,
    );
  }

  /// The row scheduled to take over once the current period ends (an
  /// early renewal), or null if there isn't one. A separate, narrowly
  /// targeted query rather than folded into [getLatestForStudent] so the
  /// access-gate hot path (router redirect, lock screen) never pays for
  /// it — only screens that actually display "you have another plan
  /// starting on X" call this.
  Future<Subscription?> getUpcomingForStudent(String studentId) async {
    final Map<String, dynamic>? row = await _client
        .from('subscriptions')
        .select(_subscriptionSelect)
        .eq('student_id', studentId)
        .eq('status', 'scheduled')
        .order('current_period_start', ascending: true)
        .limit(1)
        .maybeSingle();
    if (row == null) return null;
    return Subscription.fromJson(row);
  }

  /// [parentId] is null for a self-registered student (no parent
  /// account) getting their own trial. [durationDays] should come from
  /// [getAppSettings] — callers are expected to have already checked
  /// `trialEnabled` there before calling this at all (RLS also enforces
  /// it server-side either way, see 020_trial_toggle.sql, so a stale
  /// check here can't actually create a trial when one isn't allowed).
  Future<Subscription> createTrial({
    required String? parentId,
    required String studentId,
    int durationDays = 30,
  }) async {
    final DateTime trialEnd = DateTime.now().add(Duration(days: durationDays));
    final Map<String, dynamic> row = await _client
        .from('subscriptions')
        .insert({
          'parent_id': parentId,
          'student_id': studentId,
          'status': 'trial',
          'trial_ends': trialEnd.toIso8601String().split('T').first,
        })
        .select(_subscriptionSelect)
        .single();
    return Subscription.fromJson(row);
  }

  /// Submits a Bankily payment for one or more children at once (or a
  /// student subscribing for themselves): uploads the payer's screenshot
  /// of the Bankily confirmation to the private `payment-proofs` bucket
  /// (`<uid>/<random>.jpg`, migration 064), then `request_subscriptions()`
  /// creates one 'pending' row per student, priced server-side, with the
  /// screenshot attached — an admin checks it in Abonnements and activates.
  /// Returns the server's quote (`total_mru`, `family_discount_percent`…).
  Future<Map<String, dynamic>> submitBankilyPayment({
    required List<String> studentIds,
    required String planId,
    required String phone,
    required Uint8List proofJpeg,
  }) async {
    final String uid = _client.auth.currentUser!.id;
    final String path = '$uid/${DateTime.now().millisecondsSinceEpoch}'
        '_${Random.secure().nextInt(1 << 32)}.jpg';
    await _client.storage.from('payment-proofs').uploadBinary(
          path,
          proofJpeg,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );
    return _request(
      studentIds,
      planId,
      'bankily',
      phone: phone,
      proofPath: path,
    );
  }

  /// "Payer manuellement": records that a subscriber will pay with the
  /// team's help instead — one 'unpaid' row per student (same server-side pricing),
  /// activated once payment is arranged over WhatsApp.
  Future<Map<String, dynamic>> submitContactRequest({
    required List<String> studentIds,
    required String planId,
  }) =>
      _request(studentIds, planId, 'contact');

  Future<Map<String, dynamic>> _request(
    List<String> studentIds,
    String planId,
    String method, {
    String? phone,
    String? proofPath,
  }) async {
    final dynamic result = await _client.rpc<dynamic>(
      'request_subscriptions',
      params: {
        'p_student_ids': studentIds,
        'p_plan_id': planId,
        'p_method': method,
        'p_phone': phone,
        if (proofPath != null) 'p_proof_path': proofPath,
      },
    );
    return Map<String, dynamic>.from(result as Map);
  }
}
