import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/dirassty_theme.dart';
import '../../../core/widgets/dirassty/dirassty_widgets.dart';
import 'parent_profile_screen.dart';
import '../../subscription/presentation/subscribe_flow_screen.dart';
import 'widgets/parent_home_tab.dart';

/// The parent app's 3 top-level destinations (Home, Subscription,
/// Profile) as bottom-nav tabs — unlike the student side, which is a
/// drill-down flow with no persistent tab bar, these three are true
/// siblings, matching the web parent layout's persistent top nav
/// (dashboard/subscription/profile), just adapted to a mobile bottom bar.
/// Kept as one route (`StudentHomeScreen`'s `/parent/home` path, so no
/// router-redirect changes were needed) with an [IndexedStack] so
/// switching tabs doesn't lose each tab's scroll position/state.
class ParentShellScreen extends ConsumerStatefulWidget {
  const ParentShellScreen({super.key});

  static const String path = '/parent/home';
  static const String name = 'parentHome';

  @override
  ConsumerState<ParentShellScreen> createState() => _ParentShellScreenState();
}

class _ParentShellScreenState extends ConsumerState<ParentShellScreen>
    with SingleTickerProviderStateMixin {
  int _index = 0;

  /// Tabs cross-fade in 200 ms (DESIGN_SPEC §6). A controller rather than
  /// a keyed AnimatedSwitcher so the [IndexedStack] — and each tab's
  /// scroll position — survives the switch.
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: DirasstyMotion.fast,
    value: 1,
  );

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  void _select(int i) {
    if (i == _index) return;
    setState(() => _index = i);
    if (!context.reduceMotion) _fade.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DirasstyColors.background,
      body: FadeTransition(
        opacity: _fade,
        child: IndexedStack(
          index: _index,
          children: const [
            ParentHomeTab(),
            SubscribeFlowScreen(embedded: true),
            ParentProfileScreen(),
          ],
        ),
      ),
      bottomNavigationBar: DirasstyTabBar.parent(
        context: context,
        currentIndex: _index,
        onTap: _select,
      ),
    );
  }
}
