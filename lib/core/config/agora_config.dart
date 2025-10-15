import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Agora configuration for video calling
class AgoraConfig {
  static String get appId => dotenv.env['AGORA_APP_ID'] ?? '';
  static String get channelName =>
      dotenv.env['AGORA_CHANNEL_NAME'] ?? 'DocSync';
  static String get token => dotenv.env['AGORA_TOKEN'] ?? '';

  /// Validate if Agora configuration is complete
  static bool get isConfigured {
    return appId.isNotEmpty && channelName.isNotEmpty && token.isNotEmpty;
  }

  /// Get error message if configuration is incomplete
  static String? get configError {
    if (appId.isEmpty) return 'AGORA_APP_ID is missing in .env file';
    if (channelName.isEmpty)
      return 'AGORA_CHANNEL_NAME is missing in .env file';
    if (token.isEmpty) return 'AGORA_TOKEN is missing in .env file';
    return null;
  }
}
