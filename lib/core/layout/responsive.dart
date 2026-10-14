import 'package:flutter/material.dart';

/// Below this logical width, the device is treated as a phone — every
/// screen renders exactly as it always has, untouched. At or above it
/// (small tablets, iPad portrait/landscape, foldables), see
/// [ResponsiveShell] and [adaptiveGridColumns]. Matches Material's
/// "compact" window size class cutoff.
const double kTabletBreakpoint = 600;

/// The single-column width content is capped at once the device crosses
/// [kTabletBreakpoint] — keeps forms, lists, and reading content at a
/// comfortable line length instead of stretching edge-to-edge across a
/// full iPad screen, without requiring a bespoke multi-column redesign of
/// every individual screen.
const double kMaxContentWidth = 720;

/// How many columns a stat/subject grid should use — [compact] (2, to
/// match every grid's existing phone layout) below [kTabletBreakpoint],
/// [expanded] (3) at or above it. Reads the device's actual width via
/// [MediaQuery], not whatever local width a [ResponsiveShell] further up
/// the tree constrained its content to — [MediaQuery] carries the real
/// screen size regardless of a descendant [ConstrainedBox], so this still
/// correctly detects "this is a tablet" even though the grid itself
/// renders inside a capped-width column.
int adaptiveGridColumns(
  BuildContext context, {
  int compact = 2,
  int expanded = 3,
}) {
  return MediaQuery.sizeOf(context).width >= kTabletBreakpoint
      ? expanded
      : compact;
}

/// Wraps the whole app's routed content (see `DirasstyApp`'s
/// `MaterialApp.router(builder: ...)`) — the one place that makes every
/// screen tablet/iPad-friendly at once, instead of editing each of them
/// individually one by one. Below [kTabletBreakpoint] this is a no-op:
/// `child` passes straight through, byte-for-byte the same phone layout
/// as before this existed. At or above it, content (the screen's own
/// Scaffold, AppBar included) is capped at [kMaxContentWidth] and
/// centered, with the current theme's scaffold background color filling
/// the margins on either side — reads as a deliberate centered column
/// rather than a stretched-out phone screen or a widget floating in
/// blank space.
class ResponsiveShell extends StatelessWidget {
  const ResponsiveShell({super.key, required this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final Widget? content = child;
    if (content == null) return const SizedBox.shrink();
    if (MediaQuery.sizeOf(context).width < kTabletBreakpoint) return content;

    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
          child: content,
        ),
      ),
    );
  }
}
