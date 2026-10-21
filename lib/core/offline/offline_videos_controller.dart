import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/app_auth_state.dart';
import '../../features/auth/application/auth_providers.dart';
import '../../features/student/application/student_providers.dart';
import '../../features/subscription/application/subscription_providers.dart';
import '../analytics/app_analytics.dart';
import '../models/student.dart';
import '../models/subscription.dart';
import '../models/video_body.dart';
import 'offline_video_store.dart';
import 'video_url_signer.dart';

@immutable
class OfflineVideosState {
  const OfflineVideosState({
    this.downloads = const {},
    this.progress = const {},
    this.hasAccess = false,
    this.canDownload = false,
  });

  /// Saved videos, keyed by streaming URL.
  final Map<String, OfflineVideo> downloads;

  /// In-flight downloads, keyed by URL — 0..1, or null while the size is
  /// unknown.
  final Map<String, double?> progress;

  /// Whether this device's downloads may play right now (works offline —
  /// see [OfflineVideoStore.hasAccess]).
  final bool hasAccess;

  /// Whether a paid subscription was confirmed online this session — the
  /// only state in which new downloads are offered. Trial students
  /// stream only.
  final bool canDownload;

  bool isDownloaded(String url) => downloads.containsKey(url);
  bool isDownloading(String url) => progress.containsKey(url);

  /// Lessons with at least one downloaded video.
  Set<String> get offlineLessonIds => {
        for (final OfflineVideo v in downloads.values)
          if (v.lessonId != null) v.lessonId!,
      };

  OfflineVideosState copyWith({
    Map<String, OfflineVideo>? downloads,
    Map<String, double?>? progress,
    bool? hasAccess,
    bool? canDownload,
  }) {
    return OfflineVideosState(
      downloads: downloads ?? this.downloads,
      progress: progress ?? this.progress,
      hasAccess: hasAccess ?? this.hasAccess,
      canDownload: canDownload ?? this.canDownload,
    );
  }
}

/// Offline downloads for the signed-in student. Every time the student's
/// subscription is successfully fetched online, the result is written
/// through to [OfflineVideoStore.syncAccess] — a paid, active plan
/// extends offline playback to its end date; anything else (trial,
/// lapsed, cancelled) wipes the downloads. A failed fetch (no network)
/// changes nothing, so downloads keep working offline until the date
/// last recorded.
class OfflineVideosController extends Notifier<OfflineVideosState> {
  final OfflineVideoStore _store = const OfflineVideoStore();
  final Set<String> _cancelRequested = {};

  String? get _userId => ref.read(supabaseClientProvider).auth.currentUser?.id;

  @override
  OfflineVideosState build() {
    final AppAuthState? auth = ref.watch(appAuthStateProvider).valueOrNull;
    if (auth is AppAuthStudent) {
      final Student? student = ref.watch(currentStudentProvider).valueOrNull;
      if (student != null) {
        ref.listen<AsyncValue<Subscription?>>(
          subscriptionForStudentProvider(student.id),
          (_, next) {
            if (next is AsyncData<Subscription?>) {
              _syncAccess(auth.userId, next.value);
            }
          },
          fireImmediately: true,
        );
      }
    }
    _reload();
    return stateOrNull ?? const OfflineVideosState();
  }

  Future<void> _syncAccess(String userId, Subscription? sub) async {
    final bool isPaid = sub != null &&
        sub.status == SubscriptionStatus.active &&
        sub.grantsAccess;
    await _store.syncAccess(
      userId: userId,
      accessUntil: isPaid ? (sub.currentPeriodEnd ?? DateTime(9999)) : null,
    );
    state = state.copyWith(canDownload: isPaid);
    await _reload();
  }

  Future<void> _reload() async {
    final Map<String, OfflineVideo> downloads = await _store.readIndex();
    final bool hasAccess = await _store.hasAccess(_userId);
    state = state.copyWith(downloads: downloads, hasAccess: hasAccess);
  }

  /// Throws on network/disk failure (so the caller can tell the student);
  /// a user cancel just returns.
  Future<void> download(
    VideoBody video,
    String title, {
    String? lessonId,
  }) async {
    final String url = video.url;
    if (!state.canDownload ||
        state.isDownloading(url) ||
        state.isDownloaded(url)) {
      return;
    }
    _cancelRequested.remove(url);
    _setProgress(url, 0);
    int lastPercent = 0;
    try {
      final String sourceUrl =
          await VideoUrlSigner(ref.read(supabaseClientProvider))
              .fetchableUrl(url);
      await _store.download(
        video: video,
        sourceUrl: sourceUrl,
        title: title,
        lessonId: lessonId,
        isCancelled: () => _cancelRequested.contains(url),
        onProgress: (p) {
          final int percent = p == null ? -1 : (p * 100).floor();
          if (percent != lastPercent) {
            lastPercent = percent;
            _setProgress(url, p);
          }
        },
      );
      // A finished download, for Admin → Vidéos (066_video_stats.sql).
      ref.read(appAnalyticsProvider).track('video_download', {
        'video_url': url,
        'lesson_id': lessonId,
      });
    } on OfflineDownloadCancelled {
      // Nothing to report — the student asked for it.
    } finally {
      _cancelRequested.remove(url);
      state = state.copyWith(progress: Map.of(state.progress)..remove(url));
      await _reload();
    }
  }

  void cancel(String url) => _cancelRequested.add(url);

  Future<void> delete(String url) async {
    await _store.delete(url);
    await _reload();
  }

  Future<void> deleteAll() async {
    await _store.deleteAll();
    await _reload();
  }

  void _setProgress(String url, double? p) {
    state = state.copyWith(progress: {...state.progress, url: p});
  }
}

final NotifierProvider<OfflineVideosController, OfflineVideosState>
    offlineVideosControllerProvider =
    NotifierProvider<OfflineVideosController, OfflineVideosState>(
  OfflineVideosController.new,
);
