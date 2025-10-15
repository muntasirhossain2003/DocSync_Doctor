import 'package:flutter/material.dart';

// Conditional imports - only import web libraries when on web platform
import 'web_video_view_stub.dart'
    if (dart.library.html) 'web_video_view_web.dart';

/// Web-specific video view widget using HTML video elements
/// Uses conditional imports to avoid importing dart:html on native platforms
class WebVideoView extends StatelessWidget {
  final int uid;
  final bool isLocal;

  const WebVideoView({super.key, required this.uid, this.isLocal = false});

  @override
  Widget build(BuildContext context) {
    // Delegate to platform-specific implementation
    return WebVideoViewImpl(uid: uid, isLocal: isLocal);
  }
}
