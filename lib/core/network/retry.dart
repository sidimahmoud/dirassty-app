/// Runs [request] again when it throws — up to [attempts] times, waiting a
/// little longer each time (0.6 s, 1.2 s…). For short reads the app can't
/// work without (account role, student profile): a phone just woken up or
/// switching networks often fails the very first request, and one failure
/// shouldn't leave the app showing "offline" while the connection is fine.
Future<T> retryRequest<T>(
  Future<T> Function() request, {
  int attempts = 3,
}) async {
  for (int attempt = 1;; attempt++) {
    try {
      return await request();
    } catch (_) {
      if (attempt >= attempts) rethrow;
      await Future<void>.delayed(Duration(milliseconds: 600 * attempt));
    }
  }
}
