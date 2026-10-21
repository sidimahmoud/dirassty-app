import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../features/auth/application/auth_providers.dart';

/// What the app should do about its version, from the admin's settings
/// (app_settings, 055_app_versions.sql) vs the installed version.
enum UpdateKind { none, available, required }

@immutable
class AppUpdateStatus {
  const AppUpdateStatus({
    required this.kind,
    this.latestVersion,
    this.url,
    this.notesFr,
    this.notesAr,
  });

  static const AppUpdateStatus none = AppUpdateStatus(kind: UpdateKind.none);

  final UpdateKind kind;

  /// The newest version the admin published for this platform.
  final String? latestVersion;

  /// Store listing or direct download link; null = none configured.
  final String? url;
  final String? notesFr;
  final String? notesAr;
}

/// A pubspec-style version ("1.2.0" or "1.2.0+14") as comparable numbers:
/// major, minor, patch, then the build number (0 when absent).
@visibleForTesting
List<int>? parseVersion(String? raw) {
  if (raw == null) return null;
  final RegExpMatch? m =
      RegExp(r'^\s*(\d+)\.(\d+)\.(\d+)(?:\+(\d+))?\s*$').firstMatch(raw);
  if (m == null) return null;
  return [
    for (int i = 1; i <= 4; i++) int.parse(m.group(i) ?? '0'),
  ];
}

/// Negative when [a] is older than [b], 0 when equal, positive when newer.
/// A side given without a build number ("1.2.0") is compared on
/// major.minor.patch only.
@visibleForTesting
int compareVersions(List<int> a, List<int> b, {bool withBuild = true}) {
  for (int i = 0; i < (withBuild ? 4 : 3); i++) {
    if (a[i] != b[i]) return a[i] - b[i];
  }
  return 0;
}

/// Is [installed] below [target]? Unknown/invalid → false (never blocks).
@visibleForTesting
bool isBelow(List<int> installed, String? target) {
  final List<int>? t = parseVersion(target);
  if (t == null) return false;
  return compareVersions(installed, t, withBuild: target!.contains('+')) < 0;
}

/// Pure decision, so it can be unit-tested without Supabase/platforms.
@visibleForTesting
AppUpdateStatus decideUpdate({
  required String installedVersion,
  required String installedBuild,
  required bool isIos,
  required Map<String, dynamic> settings,
}) {
  final List<int>? installed = parseVersion(
    '$installedVersion+${installedBuild.isEmpty ? '0' : installedBuild}',
  );
  if (installed == null) return AppUpdateStatus.none;
  final String p = isIos ? 'ios' : 'android';
  final String? min = settings['${p}_min_version'] as String?;
  final String? latest = settings['${p}_latest_version'] as String?;
  final String? url = (settings['${p}_update_url'] as String?)?.trim();
  final UpdateKind kind = isBelow(installed, min)
      ? UpdateKind.required
      : isBelow(installed, latest)
          ? UpdateKind.available
          : UpdateKind.none;
  if (kind == UpdateKind.none) return AppUpdateStatus.none;
  return AppUpdateStatus(
    kind: kind,
    latestVersion: latest ?? min,
    url: url == null || url.isEmpty ? null : url,
    notesFr: settings['update_notes_fr'] as String?,
    notesAr: settings['update_notes_ar'] as String?,
  );
}

/// Checked at launch and re-checked on every resume (app.dart invalidates
/// it) — one small read of the settings row. Fails soft: any error means
/// "no update", so a network problem never locks anyone out.
final FutureProvider<AppUpdateStatus> appUpdateStatusProvider =
    FutureProvider((ref) async {
  if (kIsWeb) return AppUpdateStatus.none;
  try {
    final PackageInfo info = await PackageInfo.fromPlatform();
    final Map<String, dynamic>? row = await ref
        .read(supabaseClientProvider)
        .from('app_settings')
        .select(
          'android_min_version, android_latest_version, android_update_url, '
          'ios_min_version, ios_latest_version, ios_update_url, '
          'update_notes_fr, update_notes_ar',
        )
        .limit(1)
        .maybeSingle();
    if (row == null) return AppUpdateStatus.none;
    return decideUpdate(
      installedVersion: info.version,
      installedBuild: info.buildNumber,
      isIos: defaultTargetPlatform == TargetPlatform.iOS,
      settings: row,
    );
  } catch (_) {
    return AppUpdateStatus.none;
  }
});
