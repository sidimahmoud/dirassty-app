import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../theme/dirassty_theme.dart';

import '../../features/auth/application/app_auth_state.dart';
import '../../features/auth/application/auth_providers.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/choose_class_screen.dart';
import '../../features/auth/presentation/choose_role_screen.dart';
import '../../features/auth/presentation/trial_offer_screen.dart';
import '../../features/auth/presentation/parent_login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/student_login_screen.dart';
import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/courses/presentation/courses_screen.dart';
import '../../features/courses/presentation/subject_detail_screen.dart';
import '../../features/design_system/presentation/design_system_showcase_screen.dart';
import '../../features/exams/presentation/exam_intro_screen.dart';
import '../../features/exams/presentation/exam_session_screen.dart';
import '../../features/exams/presentation/exams_list_screen.dart';
import '../../features/exercise/presentation/open_practice_screen.dart';
import '../../features/exercise/presentation/qcm_session_screen.dart';
import '../../features/home/presentation/student_home_screen.dart';
import '../../features/homework/presentation/homework_helper_screen.dart';
import '../../features/lesson/presentation/lesson_viewer_screen.dart';
import '../../features/onboarding/presentation/parent_onboarding_placeholder_screen.dart';
import '../../features/parent/presentation/subscription_screen.dart';
import '../../features/parent/presentation/add_child_screen.dart';
import '../../features/parent/presentation/child_created_screen.dart';
import '../../features/focus/presentation/focus_settings_screen.dart';
import '../../features/parent/presentation/child_exam_history_screen.dart';
import '../../features/parent/presentation/child_progress_screen.dart';
import '../../features/parent/presentation/parent_shell_screen.dart';
import '../../features/parent/presentation/parent_subject_detail_screen.dart';
import '../../features/profile/presentation/about_screen.dart';
import '../../features/profile/presentation/delete_account_screen.dart';
import '../../features/profile/presentation/downloads_screen.dart';
import '../../features/profile/presentation/faq_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/student/application/student_providers.dart';
import '../../features/subscription/application/subscription_providers.dart';
import '../../features/subscription/presentation/subscribe_flow_screen.dart';
import '../../features/subscription/presentation/subscription_locked_screen.dart';
import '../models/exam.dart';
import '../models/student.dart';
import '../offline/offline_video_store.dart';
import 'go_router_refresh_stream.dart';

/// Reachable without a session. Anything not covered by this bounces an
/// unauthenticated user back to [WelcomeScreen]. `/register/:role` is
/// checked by prefix (like [_isStudentPath] below) since a Set of exact
/// paths can't match a resolved parameterized route (e.g.
/// `/register/parent`) against the `:role` pattern constant.
const Set<String> _publicPaths = {
  WelcomeScreen.path,
  StudentLoginScreen.path,
  ParentLoginScreen.path,
  ChooseRoleScreen.path,
  ChooseClassScreen.path,
  DesignSystemShowcaseScreen.path,
};

bool _isPublicPath(String location) =>
    _publicPaths.contains(location) || location.startsWith('/register/');

/// The app's single route table. Each feature owns its own screens under
/// `features/<name>/presentation/` — this file only wires paths to
/// screens and holds the auth-redirect gate; it never contains
/// screen-building or business logic itself.
final Provider<GoRouter> goRouterProvider = Provider((ref) {
  final AuthRepository repo = ref.watch(authRepositoryProvider);

  return GoRouter(
    initialLocation: WelcomeScreen.path,
    refreshListenable: GoRouterRefreshStream(repo.onAuthStateChange),
    redirect: (context, state) => _redirect(ref, state, repo),
    routes: [
      GoRoute(
        path: WelcomeScreen.path,
        name: WelcomeScreen.name,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: StudentLoginScreen.path,
        name: StudentLoginScreen.name,
        builder: (context, state) => const StudentLoginScreen(),
      ),
      GoRoute(
        path: ParentLoginScreen.path,
        name: ParentLoginScreen.name,
        builder: (context, state) => const ParentLoginScreen(),
      ),
      GoRoute(
        path: RegisterScreen.path,
        name: RegisterScreen.name,
        builder: (context, state) => RegisterScreen(
          role: state.pathParameters['role']!,
          initialGrade: int.tryParse(state.uri.queryParameters['grade'] ?? ''),
        ),
      ),
      GoRoute(
        path: ChooseClassScreen.path,
        name: ChooseClassScreen.name,
        builder: (context, state) => const ChooseClassScreen(),
      ),
      GoRoute(
        path: ChooseRoleScreen.path,
        name: ChooseRoleScreen.name,
        builder: (context, state) => const ChooseRoleScreen(),
      ),
      GoRoute(
        path: TrialOfferScreen.path,
        name: TrialOfferScreen.name,
        builder: (context, state) => const TrialOfferScreen(),
      ),
      GoRoute(
        path: StudentHomeScreen.path,
        name: StudentHomeScreen.name,
        pageBuilder: (context, state) =>
            _tabPage(state, const StudentHomeScreen()),
      ),
      GoRoute(
        path: CoursesScreen.path,
        name: CoursesScreen.name,
        pageBuilder: (context, state) => _tabPage(state, const CoursesScreen()),
      ),
      GoRoute(
        path: SubjectDetailScreen.path,
        name: SubjectDetailScreen.name,
        builder: (context, state) => SubjectDetailScreen(
          subjectKey: state.pathParameters['subjectKey']!,
        ),
      ),
      GoRoute(
        path: LessonViewerScreen.path,
        name: LessonViewerScreen.name,
        builder: (context, state) =>
            LessonViewerScreen(lessonId: state.pathParameters['lessonId']!),
      ),
      GoRoute(
        path: QcmSessionScreen.path,
        name: QcmSessionScreen.name,
        builder: (context, state) =>
            QcmSessionScreen(lessonId: state.pathParameters['lessonId']!),
      ),
      GoRoute(
        path: OpenPracticeScreen.path,
        name: OpenPracticeScreen.name,
        builder: (context, state) =>
            OpenPracticeScreen(lessonId: state.pathParameters['lessonId']!),
      ),
      GoRoute(
        path: HomeworkHelperScreen.path,
        name: HomeworkHelperScreen.name,
        builder: (context, state) => const HomeworkHelperScreen(),
      ),
      GoRoute(
        path: ExamsListScreen.path,
        name: ExamsListScreen.name,
        pageBuilder: (context, state) =>
            _tabPage(state, const ExamsListScreen()),
      ),
      GoRoute(
        path: ExamIntroScreen.path,
        name: ExamIntroScreen.name,
        builder: (context, state) => ExamIntroScreen(exam: state.extra as Exam),
      ),
      GoRoute(
        path: ExamSessionScreen.path,
        name: ExamSessionScreen.name,
        builder: (context, state) =>
            ExamSessionScreen(examId: state.pathParameters['examId']!),
      ),
      GoRoute(
        path: ProfileScreen.path,
        name: ProfileScreen.name,
        pageBuilder: (context, state) => _tabPage(state, const ProfileScreen()),
      ),
      GoRoute(
        path: FaqScreen.path,
        name: FaqScreen.name,
        builder: (context, state) => const FaqScreen(),
      ),
      GoRoute(
        path: AboutScreen.path,
        name: AboutScreen.name,
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: DownloadsScreen.path,
        name: DownloadsScreen.name,
        builder: (context, state) => const DownloadsScreen(),
      ),
      GoRoute(
        path: DeleteAccountScreen.path,
        name: DeleteAccountScreen.name,
        builder: (context, state) => const DeleteAccountScreen(),
      ),
      GoRoute(
        path: ParentShellScreen.path,
        name: ParentShellScreen.name,
        builder: (context, state) => const ParentShellScreen(),
      ),
      GoRoute(
        path: AddChildScreen.path,
        name: AddChildScreen.name,
        builder: (context, state) => const AddChildScreen(),
      ),
      GoRoute(
        path: ChildCreatedScreen.path,
        name: ChildCreatedScreen.name,
        builder: (context, state) =>
            ChildCreatedScreen(args: state.extra! as ChildCreatedArgs),
      ),
      GoRoute(
        path: ChildProgressScreen.path,
        name: ChildProgressScreen.name,
        builder: (context, state) => ChildProgressScreen(
          studentId: state.pathParameters['studentId']!,
        ),
      ),
      GoRoute(
        path: ParentSubjectDetailScreen.path,
        name: ParentSubjectDetailScreen.name,
        builder: (context, state) => ParentSubjectDetailScreen(
          studentId: state.pathParameters['studentId']!,
          subjectKey: state.pathParameters['subjectKey']!,
        ),
      ),
      GoRoute(
        path: StudentParentalControlScreen.path,
        name: StudentParentalControlScreen.name,
        builder: (context, state) => const StudentParentalControlScreen(),
      ),
      GoRoute(
        path: FocusSettingsScreen.path,
        name: FocusSettingsScreen.name,
        builder: (context, state) => FocusSettingsScreen(
          studentId: state.pathParameters['studentId']!,
        ),
      ),
      GoRoute(
        path: ChildExamHistoryScreen.path,
        name: ChildExamHistoryScreen.name,
        builder: (context, state) => ChildExamHistoryScreen(
          studentId: state.pathParameters['studentId']!,
        ),
      ),
      GoRoute(
        path: SubscriptionScreen.path,
        name: SubscriptionScreen.name,
        builder: (context, state) => const SubscriptionScreen(),
      ),
      GoRoute(
        path: SubscribeFlowScreen.path,
        name: SubscribeFlowScreen.name,
        builder: (context, state) => SubscribeFlowScreen(
          preselectedStudentId: state.extra as String?,
        ),
      ),
      GoRoute(
        path: SubscriptionLockedScreen.path,
        name: SubscriptionLockedScreen.name,
        builder: (context, state) => const SubscriptionLockedScreen(),
      ),
      GoRoute(
        path: ParentOnboardingPlaceholderScreen.path,
        name: ParentOnboardingPlaceholderScreen.name,
        builder: (context, state) => const ParentOnboardingPlaceholderScreen(),
      ),
      GoRoute(
        path: DesignSystemShowcaseScreen.path,
        name: DesignSystemShowcaseScreen.name,
        builder: (context, state) => const DesignSystemShowcaseScreen(),
      ),
    ],
  );
});

/// Every path a logged-in student may be on. `state.matchedLocation` is
/// the *resolved* path (e.g. `/lesson/abc123`, not the `:lessonId`
/// pattern), so this matches by prefix rather than against the route
/// pattern constants.
bool _isStudentPath(String location) {
  return location == StudentHomeScreen.path ||
      // Registration's last step — shown right after sign-up, so it must
      // be reachable by the now signed-in student.
      location == TrialOfferScreen.path ||
      location == CoursesScreen.path ||
      location.startsWith('/courses/') ||
      location.startsWith('/lesson/') ||
      location.startsWith('/exercise/') ||
      location.startsWith('/open-practice/') ||
      location == HomeworkHelperScreen.path ||
      location == ExamsListScreen.path ||
      location.startsWith('/exam/') ||
      location.startsWith('/profile') ||
      location == SubscriptionLockedScreen.path ||
      // A self-registered student (no parent account) subscribes for
      // themselves through the same flow a parent uses for their
      // children — see SubscribeFlowScreen.
      location == SubscribeFlowScreen.path;
}

/// Paths that actually teach something (or spend AI budget, in the
/// homework helper's case) — blocked once a student's subscription has
/// lapsed. Home and Profile stay reachable regardless, so a locked-out
/// student can still see their own status and reach support.
bool _requiresActiveSubscription(String location) {
  return location == CoursesScreen.path ||
      location.startsWith('/courses/') ||
      location.startsWith('/lesson/') ||
      location.startsWith('/exercise/') ||
      location.startsWith('/open-practice/') ||
      location == HomeworkHelperScreen.path ||
      location == ExamsListScreen.path ||
      location.startsWith('/exam/');
}

/// Every path a logged-in, fully-onboarded parent may be on.
/// `/parent/home` itself hosts the Home/Subscription/Profile tabs (see
/// [ParentShellScreen]) — [AddChildScreen] and [ChildProgressScreen] are
/// separate pushed routes on top of that shell, not tabs, hence the
/// separate prefixes here. `/profile/...` (FAQ, About, delete account) is
/// shared with the student's own Profile screen — without this prefix, a
/// parent tapping any of those from [ParentProfileScreen] would get
/// bounced straight back to [ParentShellScreen] on the next redirect
/// check, since [ParentShellScreen] renders its tabs via a plain
/// `IndexedStack` (not a nested Navigator), so every push still goes
/// through this same top-level redirect.
bool _isParentPath(String location) {
  return location == ParentShellScreen.path ||
      location.startsWith('/parent/child/') ||
      location == AddChildScreen.path ||
      location == ChildCreatedScreen.path ||
      location == SubscribeFlowScreen.path ||
      location == SubscriptionScreen.path ||
      location.startsWith('/profile');
}

Future<bool> _hasOfflineVideosFor(String userId) async {
  const OfflineVideoStore store = OfflineVideoStore();
  return await store.owner() == userId && (await store.readIndex()).isNotEmpty;
}

/// Role is resolved from the session on every navigation, not cached —
/// see [AuthRepository.resolveRole] for why (a relaunched app has no
/// memory of which login form was used).
///
/// This used to collapse every authenticated role to a single allowed
/// "home" path and redirect away from anything else — correct while the
/// only authenticated screens were each role's lone landing page, but it
/// would have made every student content screen (courses, lessons,
/// exercises) unreachable the moment navigation was wired up: the gate
/// itself would bounce every one of those routes straight back to
/// `/home`. Each role now gets an allow-list of paths instead of a
/// single one.
Future<String?> _redirect(
    Ref ref, GoRouterState state, AuthRepository repo) async {
  final String location = state.matchedLocation;
  final session = repo.currentSession;

  if (session == null) {
    return _isPublicPath(location) ? null : WelcomeScreen.path;
  }

  // A standalone dev/design tool — reachable regardless of role.
  if (location == DesignSystemShowcaseScreen.path) return null;

  // A session already exists at this point — a transient failure here
  // (network blip resolving role) must never bounce a logged-in user
  // back to Welcome, which would look exactly like being logged out.
  // Staying put (no redirect) is the safe default; the screen they land
  // on has its own loading/error handling for whatever it fetches.
  final AppAuthState authState;
  try {
    authState = await repo.resolveRole(session.user.id);
  } catch (_) {
    // Most often: no connection. A relaunched app would otherwise sit on
    // Welcome (the initial location) with nothing usable — if this
    // account has videos saved on the device, open those instead.
    if (location == WelcomeScreen.path &&
        await _hasOfflineVideosFor(session.user.id)) {
      return DownloadsScreen.path;
    }
    return null;
  }

  return switch (authState) {
    AppAuthUnauthenticated() => WelcomeScreen.path,
    AppAuthStudent() => await _redirectForStudent(ref, location),
    AppAuthParent(needsOnboarding: true) =>
      location == ParentOnboardingPlaceholderScreen.path
          ? null
          : ParentOnboardingPlaceholderScreen.path,
    AppAuthParent(needsOnboarding: false) =>
      _isParentPath(location) ? null : ParentShellScreen.path,
  };
}

/// Beyond the plain role check, a logged-in student also needs an active
/// subscription to reach anything that actually teaches (see
/// [_requiresActiveSubscription]) — checked here, once, rather than in
/// every gated screen, so a deep link straight into e.g. `/lesson/xyz`
/// can't skip it.
Future<String?> _redirectForStudent(Ref ref, String location) async {
  if (!_isStudentPath(location)) return StudentHomeScreen.path;
  if (location == SubscriptionLockedScreen.path) return null;
  if (!_requiresActiveSubscription(location)) return null;

  // Fails closed, deliberately: if we can't even resolve which student is
  // logged in, treat it the same as "no access" (the friendly lock
  // screen) rather than letting the exception escape the redirect
  // callback and crash the app on an unhandled Future error.
  try {
    final Student student = await ref.read(currentStudentProvider.future);
    final bool hasAccess =
        await ref.read(studentHasAccessProvider(student.id).future);
    return hasAccess ? null : SubscriptionLockedScreen.path;
  } catch (_) {
    return SubscriptionLockedScreen.path;
  }
}

/// The 4 student tabs switch with `context.go`, so they cross-fade in
/// 200 ms instead of sliding like a pushed screen (DESIGN_SPEC §6).
CustomTransitionPage<void> _tabPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: DirasstyMotion.fast,
    reverseTransitionDuration: DirasstyMotion.fast,
    transitionsBuilder: (context, animation, _, child) =>
        (MediaQuery.maybeDisableAnimationsOf(context) ?? false)
            ? child
            : FadeTransition(opacity: animation, child: child),
  );
}
