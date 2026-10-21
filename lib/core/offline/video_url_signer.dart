import 'package:supabase_flutter/supabase_flutter.dart';

/// The `videos` bucket is private (see
/// supabase/migrations/041_private_videos.sql): [VideoBody.url] keeps its
/// old public-URL shape as a stable identifier — it's also what offline
/// downloads are keyed on, so a video stays "downloaded" no matter where
/// it's opened from — and is swapped for a short-lived signed URL right
/// before streaming or downloading. Mirrors
/// apps/web/hooks/useSignedVideoUrl.ts.
class VideoUrlSigner {
  const VideoUrlSigner(this._client);

  final SupabaseClient _client;

  static const List<String> _pathMarkers = [
    '/storage/v1/object/public/videos/',
    '/storage/v1/object/sign/videos/',
    '/storage/v1/object/videos/',
  ];

  /// Long enough to finish (and seek around in) any lesson video — the
  /// player keeps re-requesting byte ranges with the same URL.
  static const int _ttlSeconds = 6 * 60 * 60;

  /// Object path inside the `videos` bucket, or null for anything that
  /// isn't one of our own Storage URLs.
  static String? storagePath(String url) {
    for (final String marker in _pathMarkers) {
      final int i = url.indexOf(marker);
      if (i != -1) {
        return Uri.decodeComponent(
          url.substring(i + marker.length).split('?').first,
        );
      }
    }
    return null;
  }

  /// A URL the player/downloader can actually fetch. Throws if Storage
  /// refuses to sign (no active subscription, or no connection).
  Future<String> fetchableUrl(String url) async {
    final String? path = storagePath(url);
    if (path == null) return url;
    return _client.storage.from('videos').createSignedUrl(path, _ttlSeconds);
  }
}
