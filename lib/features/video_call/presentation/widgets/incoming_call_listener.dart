import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/incoming_call_service.dart';
import 'incoming_call_dialog.dart';

/// Widget that listens for incoming calls and displays the dialog
class IncomingCallListener extends ConsumerWidget {
  final Widget child;

  const IncomingCallListener({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen for incoming calls
    ref.listen(incomingCallStreamProvider, (previous, next) {
      if (next.hasValue && next.value != null) {
        final incomingCall = next.value!;

        // Show incoming call dialog as full-screen overlay
        showGeneralDialog(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.black.withOpacity(0.8),
          transitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (context, animation, secondaryAnimation) {
            return FadeTransition(
              opacity: animation,
              child: IncomingCallDialog(call: incomingCall),
            );
          },
        );
      }
    });

    return child;
  }
}
