import 'package:flutter/material.dart';

import '../../domain/models/call_state.dart';

/// Widget to display call status and duration
class VideoCallStatus extends StatelessWidget {
  final CallState callState;

  const VideoCallStatus({super.key, required this.callState});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withOpacity(0.7), Colors.transparent],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Patient info
            if (callState.patientName != null) ...[
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: callState.patientImageUrl != null
                        ? NetworkImage(callState.patientImageUrl!)
                        : null,
                    child: callState.patientImageUrl == null
                        ? Text(
                            callState.patientName![0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          callState.patientName!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getStatusText(),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],

            // Duration
            if (callState.duration != null) ...[
              const SizedBox(height: 8),
              Text(
                _formatDuration(callState.duration!),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],

            // Connection status indicator
            if (callState.status == CallStatus.connecting ||
                callState.status == CallStatus.reconnecting) ...[
              const SizedBox(height: 8),
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getStatusText() {
    switch (callState.status) {
      case CallStatus.connecting:
        return 'Connecting...';
      case CallStatus.connected:
        return callState.remoteUid != null
            ? 'Connected'
            : 'Waiting for patient...';
      case CallStatus.reconnecting:
        return 'Reconnecting...';
      case CallStatus.disconnected:
        return 'Call ended';
      case CallStatus.failed:
        return 'Connection failed';
      default:
        return '';
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }
}
