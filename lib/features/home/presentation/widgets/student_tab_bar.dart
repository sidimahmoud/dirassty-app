import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/dirassty/dirassty_widgets.dart';
import '../../../courses/presentation/courses_screen.dart';
import '../../../exams/presentation/exams_list_screen.dart';
import '../../../profile/presentation/profile_screen.dart';
import '../student_home_screen.dart';

/// The student space's 4 root tabs — Accueil / Matières / Examens /
/// Profil (DESIGN_SPEC §2 "Tab bars"). Each root screen puts this in its
/// Scaffold's bottomNavigationBar; switching tabs `go`es to the tab's
/// existing route (replacing, not stacking), so the routes and deep links
/// stay exactly as they were.
class StudentTabBar extends StatelessWidget {
  const StudentTabBar({required this.currentIndex, super.key});

  final int currentIndex;

  static const List<String> _paths = [
    StudentHomeScreen.path,
    CoursesScreen.path,
    ExamsListScreen.path,
    ProfileScreen.path,
  ];

  @override
  Widget build(BuildContext context) {
    return DirasstyTabBar.student(
      context: context,
      currentIndex: currentIndex,
      onTap: (i) {
        if (i != currentIndex) context.go(_paths[i]);
      },
    );
  }
}
