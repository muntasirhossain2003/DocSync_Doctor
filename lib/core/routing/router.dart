import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/log_in.dart';
import '../../features/auth/presentation/pages/register.dart';
import '../../features/auth/presentation/pages/reset_password.dart';
//import '../pages/dashboard_page.dart';
import '../../features/auth/presentation/provider/auth_provider.dart';
import '../../shared/widgets/splash_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    // Override URL path strategy to handle password reset links with hash fragments
    redirect: (context, state) {
      // If we're on web and the base URI has a password reset code, navigate to reset_password
      if (kIsWeb) {
        final uri = Uri.base;
        if ((uri.queryParameters.containsKey('code') ||
                uri.queryParameters.containsKey('token')) &&
            uri.path.contains('reset_password')) {
          return '/reset_password';
        }
      }
      return null; // No redirect needed
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/reset_password',
        builder: (context, state) => const ResetPasswordPage(),
      ),
    ],
  );
});
