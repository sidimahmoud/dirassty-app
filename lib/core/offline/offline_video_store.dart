import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/video_body.dart';

/// One video saved on this device for offline playback.
@immutable
class OfflineVideo {
  const OfflineVideo({
    required this.url,
    required this.fileName,
    required this.title,
    required this.durationSec,
    required this.sizeBytes,
    required this.downloadedAt,
    this.lessonId,
  });

  factory OfflineVideo.fromJson(Map<String, dynamic> json) {
    return OfflineVideo(
      url: json['url'] as String,
      fileName: json['file_name'] as String,
      title: json['title'] as String,
      durationSec: (json['duration_sec'] as num).toInt(),
      sizeBytes: (json['size_bytes'] as num).toInt(),
      downloadedAt: DateTime.parse(json['downloaded_at'] as String),
      lessonId: json['lesson_id'] as String?,
    );
  }

  /// The original streaming URL — the key every lookup goes through, so
  /// a player handed a [VideoBody] can find its local copy.
  final String url;
  final String fileName;
  final String title;
  final int durationSec;
  final int sizeBytes;
  final DateTime downloadedAt;

  /// Lesson the video belongs to (null for downloads made before this was
  /// recorded) — drives the subject screen's "Hors ligne" filter.
  final String? lessonId;

  Map<String, dynamic> toJson() => {
        'url': url,
        'file_name': fileName,
        'title': title,
        'duration_sec': durationSec,
        'size_bytes': sizeBytes,
        'downloaded_at': downloadedAt.toIso8601String(),
        if (lessonId != null) 'lesson_id': lessonId,
      };
}

/// Thrown out of [OfflineVideoStore.download] when its `isCancelled`
/// callback turns true mid-download. The partial file is already removed.
class OfflineDownloadCancelled implements Exception {
  const OfflineDownloadCancelled();
}

/// Device-side storage for downloaded course videos.
///
/// Files live in the app's private support directory (Android internal
/// `files/`, iOS `Library/Application Support/`): no other app, gallery,
/// file manager or the iOS Files app can see them, and they're excluded
/// from device/cloud backups (Android: `res/xml/*backup*_rules.xml`; iOS:
/// the `excludeFromBackup` channel in AppDelegate.swift) so they can't be
/// pulled out through a backup either. This isn't DRM — a rooted or
/// jailbroken device can still read the sandbox — but it gives students
/// no export path through the app or the OS.
///
/// Playback is additionally bound to the owning account and a paid
/// subscription's end date ([syncAccess]): once that date passes,
/// [playableFileFor] stops returning files even with no connection, and
/// the next online check wipes them.
///
/// Stateless — everything is on disk / in SharedPreferences — so it's
/// safe to construct wherever it's needed (e.g. from sign-out).
class OfflineVideoStore {
  const OfflineVideoStore();

  static const String _indexKey = 'offline_videos.index.v1';
  static const String _ownerKey = 'offline_videos.owner';
  static const String _accessUntilKey = 'offline_videos.access_until';
  static const String _dirName = 'offline_videos';
  static const MethodChannel _channel =
      MethodChannel('ai.dirassty/offline_storage');

  Future<Directory> _directory() async {
    final Directory support = await getApplicationSupportDirectory();
    final Directory dir = Directory('${support.path}/$_dirName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
      if (Platform.isIOS) {
        try {
          await _channel.invokeMethod<void>('excludeFromBackup', dir.path);
        } on PlatformException catch (e) {
          debugPrint('OfflineVideoStore: excludeFromBackup failed: $e');
        }
      }
    }
    return dir;
  }

  Future<Map<String, OfflineVideo>> readIndex() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_indexKey);
    if (raw == null) return {};
    final Map<String, dynamic> decoded =
        jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map(
      (url, json) =>
          MapEntry(url, OfflineVideo.fromJson(json as Map<String, dynamic>)),
    );
  }

  Future<void> _writeIndex(Map<String, OfflineVideo> index) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _indexKey,
      jsonEncode(index.map((url, video) => MapEntry(url, video.toJson()))),
    );
  }

  /// Auth user id the current downloads belong to, if any.
  Future<String?> owner() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_ownerKey);
  }

  /// End of the paid period downloads may play until, as of the last
  /// successful online subscription check.
  Future<DateTime?> accessUntil() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_accessUntilKey);
    return raw == null ? null : DateTime.parse(raw);
  }

  /// Whether [userId] may play this device's downloads right now —
  /// works fully offline, from what [syncAccess] last recorded.
  Future<bool> hasAccess(String? userId) async {
    if (userId == null || await owner() != userId) return false;
    final DateTime? until = await accessUntil();
    return until != null && DateTime.now().isBefore(until);
  }

  /// Records the result of an online subscription check. [accessUntil]
  /// null means "no paid access" — every download is wiped. A different
  /// [userId] than the current owner (another account on this device)
  /// also wipes them first.
  Future<void> syncAccess({
    required String userId,
    required DateTime? accessUntil,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? currentOwner = prefs.getString(_ownerKey);
    if (accessUntil == null ||
        (currentOwner != null && currentOwner != userId)) {
      await deleteAll();
    }
    if (accessUntil == null) return;
    await prefs.setString(_ownerKey, userId);
    await prefs.setString(_accessUntilKey, accessUntil.toIso8601String());
  }

  /// The local file for [url], or null if it isn't downloaded or
  /// [userId] no longer has offline access.
  Future<File?> playableFileFor(String url, String? userId) async {
    if (!await hasAccess(userId)) return null;
    final OfflineVideo? video = (await readIndex())[url];
    if (video == null) return null;
    final File file = File('${(await _directory()).path}/${video.fileName}');
    return await file.exists() ? file : null;
  }

  /// Streams [video] to disk, reporting progress in 0..1 (or null while
  /// the server hasn't sent a Content-Length). Writes to a `.part` file
  /// and only renames it into place once complete, so an interrupted
  /// download never shows up as playable.
  /// [sourceUrl] is what's actually fetched (a signed URL — see
  /// VideoUrlSigner); the saved entry is keyed on the stable
  /// [VideoBody.url] so every player finds it.
  Future<OfflineVideo> download({
    required VideoBody video,
    required String sourceUrl,
    required String title,
    required void Function(double? progress) onProgress,
    required bool Function() isCancelled,
    String? lessonId,
  }) async {
    final Directory dir = await _directory();
    final String fileName = _fileNameFor(video.url);
    final File target = File('${dir.path}/$fileName');
    final File partial = File('${target.path}.part');

    final http.Client client = http.Client();
    IOSink? sink;
    try {
      final http.StreamedResponse response =
          await client.send(http.Request('GET', Uri.parse(sourceUrl)));
      if (response.statusCode != 200) {
        throw HttpException('HTTP ${response.statusCode}');
      }
      final int? total = response.contentLength;
      int received = 0;
      sink = partial.openWrite();
      await for (final List<int> chunk in response.stream) {
        if (isCancelled()) throw const OfflineDownloadCancelled();
        sink.add(chunk);
        received += chunk.length;
        onProgress(total == null || total == 0 ? null : received / total);
      }
      await sink.close();
      sink = null;
      await partial.rename(target.path);

      final OfflineVideo saved = OfflineVideo(
        url: video.url,
        fileName: fileName,
        title: title,
        durationSec: video.durationSec,
        sizeBytes: received,
        downloadedAt: DateTime.now(),
        lessonId: lessonId,
      );
      final Map<String, OfflineVideo> index = await readIndex();
      index[video.url] = saved;
      await _writeIndex(index);
      return saved;
    } catch (_) {
      await sink?.close();
      if (await partial.exists()) await partial.delete();
      rethrow;
    } finally {
      client.close();
    }
  }

  Future<void> delete(String url) async {
    final Map<String, OfflineVideo> index = await readIndex();
    final OfflineVideo? video = index.remove(url);
    if (video == null) return;
    final File file = File('${(await _directory()).path}/${video.fileName}');
    if (await file.exists()) await file.delete();
    await _writeIndex(index);
  }

  /// Removes every downloaded file and forgets the owner/access window.
  Future<void> deleteAll() async {
    final Directory dir = await _directory();
    if (await dir.exists()) await dir.delete(recursive: true);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_indexKey);
    await prefs.remove(_ownerKey);
    await prefs.remove(_accessUntilKey);
  }

  String _fileNameFor(String url) {
    final String path = Uri.parse(url).path;
    final int dot = path.lastIndexOf('.');
    final String ext =
        dot != -1 && path.length - dot <= 5 ? path.substring(dot) : '.mp4';
    return '${sha1.convert(utf8.encode(url))}$ext';
  }
}
