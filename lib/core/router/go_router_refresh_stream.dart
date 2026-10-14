import 'dart:async';

import 'package:flutter/foundation.dart';

/// Bridges any [Stream] into a [Listenable] so it can be handed to
/// [GoRouter]'s `refreshListenable` — go_router only knows how to listen
/// to a [Listenable], Supabase's auth changes only come as a [Stream].
/// This is the adapter between the two, so every sign-in/sign-out
/// re-evaluates the router's redirect logic automatically.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
