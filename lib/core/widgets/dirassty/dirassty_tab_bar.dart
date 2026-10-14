import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../theme/dirassty_theme.dart';
import 'dirassty_context.dart';

/// One tab: outline icon when idle, filled when active.
class DirasstyTabItem {
  const DirasstyTabItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

/// Bottom tab bar: white, top line border, 84 high including the bottom
/// safe area. Active tab is teal for students, ink for parents; labels
/// 11/600 (700 when active, 12 in Arabic).
///
/// DESIGN_SPEC.md §2 "Tab bars".
class DirasstyTabBar extends StatelessWidget {
  const DirasstyTabBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    super.key,
    this.activeColor = DirasstyColors.teal,
  });

  /// Student: Accueil / Matières / Examens / Profil.
  factory DirasstyTabBar.student({
    required BuildContext context,
    required int currentIndex,
    required ValueChanged<int> onTap,
    Key? key,
  }) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return DirasstyTabBar(
      key: key,
      currentIndex: currentIndex,
      onTap: onTap,
      items: [
        DirasstyTabItem(
            label: l10n.tabHome,
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded),
        DirasstyTabItem(
            label: l10n.tabSubjects,
            icon: Icons.menu_book_outlined,
            activeIcon: Icons.menu_book_rounded),
        DirasstyTabItem(
            label: l10n.tabExams,
            icon: Icons.assignment_outlined,
            activeIcon: Icons.assignment_rounded),
        DirasstyTabItem(
            label: l10n.tabProfile,
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded),
      ],
    );
  }

  /// Parent: Accueil / Abonnement / Profil — active tab in ink.
  factory DirasstyTabBar.parent({
    required BuildContext context,
    required int currentIndex,
    required ValueChanged<int> onTap,
    Key? key,
  }) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return DirasstyTabBar(
      key: key,
      currentIndex: currentIndex,
      onTap: onTap,
      activeColor: DirasstyColors.ink,
      items: [
        DirasstyTabItem(
            label: l10n.tabHome,
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded),
        DirasstyTabItem(
            label: l10n.tabSubscription,
            icon: Icons.credit_card_outlined,
            activeIcon: Icons.credit_card_rounded),
        DirasstyTabItem(
            label: l10n.tabProfile,
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded),
      ],
    );
  }

  final List<DirasstyTabItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    final DirasstyType type = context.dirasstyType;
    // A fixed 64 pt bar: like Material's NavigationBar, labels stop
    // growing at 1.3× so they never clip; screen content scales fully.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: DirasstyColors.surface,
          border: Border(top: BorderSide(color: DirasstyColors.line)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                for (int i = 0; i < items.length; i++)
                  Expanded(
                    child: Semantics(
                      button: true,
                      selected: i == currentIndex,
                      label: items[i].label,
                      excludeSemantics: true,
                      child: InkWell(
                        onTap: () => onTap(i),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              i == currentIndex
                                  ? items[i].activeIcon
                                  : items[i].icon,
                              size: DirasstySize.iconDefault,
                              color: i == currentIndex
                                  ? activeColor
                                  : DirasstyColors.textMuted,
                            ),
                            const SizedBox(height: DirasstySpace.xs),
                            Text(
                              items[i].label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: type.tab.copyWith(
                                color: i == currentIndex
                                    ? activeColor
                                    : DirasstyColors.textMuted,
                                fontWeight: i == currentIndex
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
