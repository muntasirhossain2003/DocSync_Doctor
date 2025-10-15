import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/services/incoming_call_service.dart';
import '../../domain/models/incoming_call.dart';

/// Full-screen incoming call dialog
class IncomingCallDialog extends ConsumerWidget {
  final IncomingCall call;

  const IncomingCallDialog({super.key, required this.call});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.black87,
      child: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            // Patient avatar
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.blue,
              backgroundImage: call.patientImageUrl != null
                  ? NetworkImage(call.patientImageUrl!)
                  : null,
              child: call.patientImageUrl == null
                  ? Text(
                      call.patientName[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 48,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),

            const SizedBox(height: 24),

            // Patient name
            Text(
              call.patientName,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Call type
            const Text(
              'Incoming Video Call',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),

            const SizedBox(height: 16),

            // Animated ringing indicator
            const _RingingIndicator(),

            const Spacer(),

            // Action buttons
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Reject button
                  _CallActionButton(
                    icon: Icons.call_end,
                    label: 'Reject',
                    color: Colors.red,
                    onPressed: () => _rejectCall(context, ref),
                  ),

                  // Accept button
                  _CallActionButton(
                    icon: Icons.videocam,
                    label: 'Accept',
                    color: Colors.green,
                    onPressed: () => _acceptCall(context, ref),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _acceptCall(BuildContext context, WidgetRef ref) async {
    try {
      // Accept the call in database
      await ref
          .read(incomingCallServiceProvider)
          .acceptCall(call.consultationId);

      if (context.mounted) {
        // Navigate to video call page
        context.go(
          '/video-call',
          extra: {
            'consultationId': call.consultationId,
            'patientId': call.patientId,
            'patientName': call.patientName,
            'patientImageUrl': call.patientImageUrl,
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept call: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectCall(BuildContext context, WidgetRef ref) async {
    try {
      // Reject the call in database
      await ref
          .read(incomingCallServiceProvider)
          .rejectCall(call.consultationId, reason: 'Doctor declined');

      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject call: $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }
}

/// Animated ringing indicator
class _RingingIndicator extends StatefulWidget {
  const _RingingIndicator();

  @override
  State<_RingingIndicator> createState() => _RingingIndicatorState();
}

class _RingingIndicatorState extends State<_RingingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: Icon(
            Icons.phone_in_talk,
            size: 48,
            color: Colors.white.withOpacity(0.7),
          ),
        );
      },
    );
  }
}

/// Call action button (Accept/Reject)
class _CallActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _CallActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(icon, size: 32),
            color: Colors.white,
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
