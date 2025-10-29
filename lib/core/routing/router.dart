import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/log_in.dart';
import '../../features/auth/presentation/pages/register.dart';
import '../../features/auth/presentation/pages/reset_password.dart';
import '../../features/doctor/presentation/pages/doctor_dashboard_page.dart';
import '../../features/doctor/presentation/pages/doctor_main_scaffold.dart';
import '../../features/doctor/presentation/pages/edit_doctor_profile_page.dart';
import '../../features/video_call/presentation/pages/video_call_page.dart';
import '../../shared/widgets/splash_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
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
      // Doctor routes
      GoRoute(
        path: '/doctor/home',
        builder: (context, state) => const DoctorMainScaffold(),
      ),
      GoRoute(
        path: '/doctor/dashboard',
        builder: (context, state) => const DoctorDashboardPage(),
      ),
      GoRoute(
        path: '/doctor/profile/edit',
        builder: (context, state) => const EditDoctorProfilePage(),
      ),
      // Video call route
      GoRoute(
        path: '/video-call/:consultationId',
        builder: (context, state) {
          final consultationId = state.pathParameters['consultationId'] ?? '';
          final extra = state.extra as Map<String, dynamic>?;
          return VideoCallPage(
            consultationId: consultationId,
            patientId: extra?['patientId'],
            patientName: extra?['patientName'],
            patientImageUrl: extra?['patientImageUrl'],
          );
        },
      ),
    ],
  );
});
