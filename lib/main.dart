import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app.dart';

String? recoveryAccessToken; // Global variable to hold the token

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  if (kIsWeb) {
    final uri = Uri.base;
    if (uri.fragment.contains('type=recovery')) {
      final fragmentParams = Uri.splitQueryString(uri.fragment);
      recoveryAccessToken = fragmentParams['access_token'];
    }
  }

  runApp(const ProviderScope(child: MyApp()));
}
