import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

String? recoveryAccessToken; // Global variable to hold the token

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  if (kIsWeb) {
    final uri = Uri.base;

    if (kDebugMode) {
      print('=== Password Reset Debug ===');
      print('Current URL: ${uri.toString()}');
      print('Path: ${uri.path}');
      print('Query params: ${uri.queryParameters}');
      print('Fragment: ${uri.fragment}');
    }

    // Handle recovery token from URL fragment
    if (uri.fragment.contains('type=recovery')) {
      final fragmentParams = Uri.splitQueryString(uri.fragment);
      recoveryAccessToken = fragmentParams['access_token'];
      if (kDebugMode) {
        print(
          'Found recovery token in fragment: ${recoveryAccessToken?.substring(0, 20)}...',
        );
      }
    }
    // Handle recovery code from query parameters (email deep link)
    if (uri.queryParameters.containsKey('code') ||
        uri.queryParameters.containsKey('token')) {
      recoveryAccessToken =
          uri.queryParameters['code'] ?? uri.queryParameters['token'];
      if (kDebugMode) {
        print(
          'Found recovery code in query params: ${recoveryAccessToken?.substring(0, 20)}...',
        );
      }
    }

    if (kDebugMode) {
      print(
        'Final recovery token: ${recoveryAccessToken != null ? "SET" : "NOT SET"}',
      );
      print('========================');
    }
  }

  runApp(const ProviderScope(child: MyApp()));
}
