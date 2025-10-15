import 'package:flutter/material.dart';

/// Stub implementation for non-web platforms
class WebVideoViewImpl extends StatelessWidget {
  final int uid;
  final bool isLocal;

  const WebVideoViewImpl({super.key, required this.uid, this.isLocal = false});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('WebVideoView is only available on web platform'),
    );
  }
}
