import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Example demonstrating how to start a video call from anywhere in the app
class VideoCallExample extends StatelessWidget {
  const VideoCallExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Video Call Example')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Starting a Video Call',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'To start a video call with a patient, use the following code:',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const SelectableText('''context.push(
  '/video-call/\$consultationId',
  extra: {
    'patientId': 'patient-uuid',
    'patientName': 'John Doe',
    'patientImageUrl': 'https://...',
  },
);''', style: TextStyle(fontFamily: 'monospace')),
            ),
            const SizedBox(height: 24),
            const Text(
              'Required Parameters:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• consultationId: The ID of the consultation'),
            const Text('• patientId: The patient\'s user ID (optional)'),
            const Text('• patientName: The patient\'s full name (optional)'),
            const Text(
              '• patientImageUrl: URL to patient\'s profile picture (optional)',
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Example: Start a demo video call
                context.push(
                  '/video-call/demo-consultation-123',
                  extra: {
                    'patientId': 'demo-patient-id',
                    'patientName': 'Demo Patient',
                    'patientImageUrl': null,
                  },
                );
              },
              icon: const Icon(Icons.video_call),
              label: const Text('Start Demo Video Call'),
            ),
          ],
        ),
      ),
    );
  }
}
