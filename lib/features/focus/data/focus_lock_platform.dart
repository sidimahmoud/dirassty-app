import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Native side of focus mode (MainActivity.kt / AppDelegate.swift).
///
/// - Android: screen pinning (`startLockTask`) — Home/Recents stop
///   working until the app unpins itself, or the student does the system
///   unpin gesture (hold Back + Recents), which [isLocked] detects.
/// - iOS: apps can't pin themselves outside MDM-supervised devices;
///   Guided Access has to be started by the student (triple-click). This
///   only reports whether it's on.
class FocusLockPlatform {
  const FocusLockPlatform();

  static const MethodChannel _channel = MethodChannel('ai.dirassty/focus_lock');

  /// Whether this platform can pin itself ([pin] does something).
  bool get canSelfPin => Platform.isAndroid;

  Future<void> pin() => _call('pin');

  Future<void> unpin() => _call('unpin');

  /// Android: pinned right now. iOS: Guided Access is active.
  Future<bool> isLocked() async {
    try {
      return await _channel.invokeMethod<bool>('isLocked') ?? false;
    } on PlatformException catch (e) {
      debugPrint('FocusLockPlatform.isLocked: $e');
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<void> _call(String method) async {
    if (!canSelfPin) return;
    try {
      await _channel.invokeMethod<void>(method);
    } on PlatformException catch (e) {
      debugPrint('FocusLockPlatform.$method: $e');
    }
  }
}
