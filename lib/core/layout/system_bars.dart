import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/dirassty_theme.dart';

/// Android 15+ draws apps edge-to-edge, behind the system navigation bar
/// (gesture handle or ◁ ○ □ buttons). Wrapped once around every screen
/// (MaterialApp.builder, see DirasstyApp) so nothing — bottom buttons,
/// last list items — can end up hidden under it, without each screen
/// having to remember a SafeArea. Screens that already use SafeArea (tab
/// bars, AuthScaffold…) are unaffected: the inset is consumed here once.
/// The strip under the content is painted in the app's surface colour.
class SystemNavigationInset extends StatelessWidget {
  const SystemNavigationInset({required this.child, super.key});

  final Widget child;

  /// Dark navigation-bar icons on the app's light surface; transparent so
  /// the strip painted here shows through.
  static const SystemUiOverlayStyle style = SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarContrastEnforced: false,
  );

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: style,
      child: ColoredBox(
        color: DirasstyColors.surface,
        child: SafeArea(top: false, left: false, right: false, child: child),
      ),
    );
  }
}
