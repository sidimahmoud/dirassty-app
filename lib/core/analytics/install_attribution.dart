import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_install_referrer/play_install_referrer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/application/auth_providers.dart';

/// Home-made install attribution (docs/attribution.md), Android only:
/// a Dirassty tracking link (`/go/<slug>`) sends Android users to Google
/// Play with `referrer=dirassty_click=<id>`; Google Play hands that string
/// back to the app through its official Install Referrer API.
///
/// 1. First launch ever: read it once, count the install
///    (`marketing_record_install`, works signed out), keep the click id.
/// 2. Once a parent/student is signed in: attribute the account to the
///    link's campaign (`marketing_claim_install`, first touch), forget it.
///
/// No advertising id, no device data — just Google Play's referrer string.
/// Fails silently; iPhone has no referrer (codes cover it).
class InstallAttribution {
  InstallAttribution(this._client);

  final SupabaseClient _client;

  static const String _checkedKey = 'attribution.referrerChecked';
  static const String _pendingKey = 'attribution.pendingClick';
  static final RegExp _click = RegExp(r'dirassty_click=([0-9a-fA-F-]{36})');

  Future<void> checkFirstLaunch() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_checkedKey) ?? false) return;
      await prefs.setBool(_checkedKey, true);
      final ReferrerDetails details = await PlayInstallReferrer.installReferrer;
      final String raw = Uri.decodeComponent(details.installReferrer ?? '');
      final String? click = _click.firstMatch(raw)?.group(1);
      if (click == null) return;
      await prefs.setString(_pendingKey, click);
      await _client
          .rpc<dynamic>('marketing_record_install', params: {'p_click': click});
    } catch (_) {
      // Not installed from Google Play (sideload / emulator) or offline.
    }
  }

  Future<void> claimIfPending() async {
    if (kIsWeb || _client.auth.currentSession == null) return;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? click = prefs.getString(_pendingKey);
      if (click == null) return;
      await _client
          .rpc<dynamic>('marketing_claim_install', params: {'p_click': click});
      await prefs.remove(_pendingKey);
    } catch (_) {
      // Retried at the next sign-in / launch.
    }
  }
}

final Provider<InstallAttribution> installAttributionProvider =
    Provider((ref) => InstallAttribution(ref.watch(supabaseClientProvider)));
