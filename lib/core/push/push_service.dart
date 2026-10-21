import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Background / terminated-app messages. Notification messages (all ours
/// carry a `notification`) are drawn by Android/iOS themselves in the
/// "Dirassty" channel; this handler only has to exist (registered before
/// runApp, see [PushService.setUpBackgroundHandling]) so the plugin can
/// deliver data in the background. Must be a top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) await Firebase.initializeApp();
}

/// One notification, as the app needs it (foreground banner / tap).
@immutable
class PushMessage {
  const PushMessage({
    required this.title,
    required this.body,
    this.image,
    this.route,
  });

  factory PushMessage.fromRemote(RemoteMessage m) => PushMessage(
        title: m.notification?.title ?? '',
        body: m.notification?.body ?? '',
        image: m.notification?.android?.imageUrl ??
            m.notification?.apple?.imageUrl,
        route: m.data['route'] as String?,
      );

  final String title;
  final String body;
  final String? image;

  /// A go_router path ("/exams") or a screen key ("exams") — see
  /// [PushService.routeFor].
  final String? route;
}

/// Push notifications on this device: registers its FCM token in
/// `device_tokens` (036_device_tokens.sql, for one-person sends and event
/// notifications) and subscribes it to its broadcast topics — `all`,
/// `parents` / `students`, and `students_g<grade>` / `parents_g<grade>` —
/// so an admin group send is ONE Firebase message whatever the audience
/// size (see supabase/functions/send-push). Also surfaces messages that
/// arrive while the app is open ([foreground]) and taps ([taps]).
///
/// Dormant until the Firebase project exists (native config files
/// android/app/google-services.json and ios/Runner/GoogleService-Info.plist,
/// plus FIREBASE_SERVICE_ACCOUNT_JSON server-side — see
/// supabase/functions/_shared/fcm.ts). Until then every method fails soft
/// rather than breaking startup. Skipped on web.
class PushService {
  PushService(this._client);

  final SupabaseClient _client;

  static const String _topicsKey = 'push.topics';

  bool _firebaseReady = false;
  bool _listening = false;
  String? _token;
  StreamSubscription<String>? _tokenRefresh;

  final StreamController<PushMessage> _foreground =
      StreamController<PushMessage>.broadcast();
  final StreamController<PushMessage> _taps =
      StreamController<PushMessage>.broadcast();

  /// Notifications received while the app is in the foreground (the OS
  /// doesn't show those itself) — shown as an in-app banner.
  Stream<PushMessage> get foreground => _foreground.stream;

  /// Notifications the user tapped (from the background, or the one that
  /// launched the app) — the app opens their screen.
  Stream<PushMessage> get taps => _taps.stream;

  /// Where a notification's `route` leads for this kind of user: a path is
  /// used as-is; a screen key (sent by admin notifications) maps to the
  /// student's or the parent's version of that screen.
  static String routeFor(String? route, {required bool isParent}) {
    if (route == null || route.isEmpty) {
      return isParent ? '/parent/home' : '/home';
    }
    if (route.startsWith('/')) return route;
    return switch (route) {
      'exams' => isParent ? '/parent/home' : '/exams',
      'subjects' => isParent ? '/parent/home' : '/courses',
      'subscription' => isParent ? '/parent/subscriptions' : '/profile',
      'profile' => isParent ? '/parent/home' : '/profile',
      _ => isParent ? '/parent/home' : '/home',
    };
  }

  /// The broadcast topics for a student of [grade].
  static List<String> studentTopics(int grade) =>
      ['all', 'students', 'students_g$grade'];

  /// The broadcast topics for a parent whose children are in
  /// [childGrades].
  static List<String> parentTopics(Iterable<int> childGrades) => [
        'all',
        'parents',
        for (final int g in childGrades.toSet()) 'parents_g$g',
      ];

  /// Call once in bootstrap, before runApp: initializes Firebase and
  /// registers [firebaseMessagingBackgroundHandler]. Fails soft.
  static Future<void> setUpBackgroundHandling() async {
    if (kIsWeb) return;
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    } catch (_) {
      // No Firebase config on this platform yet — push stays off.
    }
  }

  /// Starts delivering [foreground] messages and [taps] — including the
  /// tap that launched the app from a closed state. Called by the banner
  /// host right after it subscribes, so that first tap is never emitted
  /// before anyone listens; independent of sign-in / permission.
  Future<void> start() async {
    if (kIsWeb) return;
    await _ensureFirebaseInitialized();
    if (_firebaseReady) _listen();
  }

  Future<void> _ensureFirebaseInitialized() async {
    if (_firebaseReady || kIsWeb) return;
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();
      _firebaseReady = true;
    } catch (_) {
      // No config yet (or platform not set up) — push just stays off.
    }
  }

  void _listen() {
    if (_listening) return;
    _listening = true;
    FirebaseMessaging.onMessage.listen(
      (RemoteMessage m) => _foreground.add(PushMessage.fromRemote(m)),
    );
    FirebaseMessaging.onMessageOpenedApp
        .listen((RemoteMessage m) => _taps.add(PushMessage.fromRemote(m)));
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? m) {
      if (m != null) _taps.add(PushMessage.fromRemote(m));
    });
  }

  /// Asks for notification permission, registers this device for the
  /// signed-in parent/student and subscribes it to [topics]. Safe to call
  /// on every sign-in (re-points a shared device at the new owner).
  /// Exactly one of [parentId]/[studentRowId] should be set.
  Future<void> registerCurrentDevice({
    String? parentId,
    String? studentRowId,
    List<String> topics = const [],
  }) async {
    if (kIsWeb) return;
    if (parentId == null && studentRowId == null) return;

    await _ensureFirebaseInitialized();
    if (!_firebaseReady) return;

    try {
      final FirebaseMessaging messaging = FirebaseMessaging.instance;
      final NotificationSettings settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      // iOS: show the system banner even while the app is open (Android
      // relies on the in-app banner instead, see PushBannerHost).
      await messaging.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: true,
        sound: true,
      );
      _listen();

      final String? token = await messaging.getToken();
      if (token == null) return;
      _token = token;
      await _upsertToken(token, parentId: parentId, studentRowId: studentRowId);
      await _syncTopics(topics);

      await _tokenRefresh?.cancel();
      _tokenRefresh = messaging.onTokenRefresh.listen((String newToken) {
        _token = newToken;
        _upsertToken(newToken, parentId: parentId, studentRowId: studentRowId);
      });
    } catch (_) {
      // Permission dialog dismissed, platform channel unavailable, etc.
    }
  }

  /// Subscribes to [wanted] and drops topics from a previous account or
  /// grade (remembered across launches).
  Future<void> _syncTopics(List<String> wanted) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Set<String> previous =
        (prefs.getStringList(_topicsKey) ?? []).toSet();
    final Set<String> next = wanted.toSet();
    final FirebaseMessaging messaging = FirebaseMessaging.instance;
    for (final String t in previous.difference(next)) {
      await messaging.unsubscribeFromTopic(t);
    }
    for (final String t in next.difference(previous)) {
      await messaging.subscribeToTopic(t);
    }
    await prefs.setStringList(_topicsKey, next.toList());
  }

  /// On sign-out: stop broadcasts and one-person sends reaching this
  /// device for the account that just left (shared family phones).
  Future<void> signOut() async {
    if (kIsWeb || !_firebaseReady) return;
    try {
      await _syncTopics(const []);
      await _tokenRefresh?.cancel();
      _tokenRefresh = null;
      final String? token = _token;
      if (token != null) {
        await _client.from('device_tokens').delete().eq('token', token);
      }
      await FirebaseMessaging.instance.deleteToken();
      _token = null;
    } catch (_) {
      // Best-effort.
    }
  }

  Future<void> _upsertToken(
    String token, {
    String? parentId,
    String? studentRowId,
  }) async {
    try {
      await _client.from('device_tokens').upsert(
        {
          'token': token,
          'platform':
              defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
          'parent_id': parentId,
          'student_id': studentRowId,
          'last_seen_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'token',
      );
    } catch (_) {
      // Best-effort — retried on the next launch.
    }
  }
}
