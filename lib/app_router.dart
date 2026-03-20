import 'package:go_router/go_router.dart';
import 'main.dart' show authService;
import 'features/auth/login_screen.dart';
import 'features/auth/onboarding_screen.dart';
import 'features/visitor/check_in_screen.dart';
import 'features/admin/admin_shell.dart';
import 'features/admin/admin_dashboard_screen.dart';
import 'features/admin/user_search_screen.dart';
import 'features/admin/visitors_by_reason_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  refreshListenable: authService,
  redirect: (context, state) {
    final isSignedIn = authService.isSignedIn;
    final isOnLoginPage = state.matchedLocation == '/login';

    // Not signed in — force to login.
    if (!isSignedIn && !isOnLoginPage) return '/login';

    // Signed in but still on login — route by role & setup status.
    if (isSignedIn && isOnLoginPage) {
      final user = authService.currentUser!;
      if (user.isAdmin) return '/admin';
      if (user.setupComplete) return '/check-in';
      return '/onboarding';
    }

    return null; // No redirect.
  },
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/check-in',
      builder: (context, state) => const CheckInScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => AdminShell(child: child),
      routes: [
        GoRoute(
          path: '/admin',
          builder: (context, state) => const AdminDashboardScreen(),
        ),
        GoRoute(
          path: '/admin/users',
          builder: (context, state) => const UserSearchScreen(),
        ),
        GoRoute(
          path: '/admin/visitors',
          builder: (context, state) {
            final reason = state.uri.queryParameters['reason'];
            return VisitorsByReasonScreen(reason: reason);
          },
        ),
      ],
    ),
  ],
);
