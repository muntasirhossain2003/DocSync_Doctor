import 'package:flutter/material.dart';

/// Video call control buttons
class VideoCallControls extends StatelessWidget {
  final bool isVideoEnabled;
  final bool isAudioEnabled;
  final bool isSpeakerEnabled;
  final VoidCallback onToggleVideo;
  final VoidCallback onToggleAudio;
  final VoidCallback onToggleSpeaker;
  final VoidCallback onSwitchCamera;
  final VoidCallback onEndCall;

  const VideoCallControls({
    super.key,
    required this.isVideoEnabled,
    required this.isAudioEnabled,
    required this.isSpeakerEnabled,
    required this.onToggleVideo,
    required this.onToggleAudio,
    required this.onToggleSpeaker,
    required this.onSwitchCamera,
    required this.onEndCall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
        ),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildControlButton(
              icon: isVideoEnabled ? Icons.videocam : Icons.videocam_off,
              onPressed: onToggleVideo,
              backgroundColor: isVideoEnabled ? Colors.white24 : Colors.red,
              tooltip: isVideoEnabled ? 'Turn off camera' : 'Turn on camera',
            ),
            _buildControlButton(
              icon: isAudioEnabled ? Icons.mic : Icons.mic_off,
              onPressed: onToggleAudio,
              backgroundColor: isAudioEnabled ? Colors.white24 : Colors.red,
              tooltip: isAudioEnabled ? 'Mute' : 'Unmute',
            ),
            _buildControlButton(
              icon: Icons.flip_camera_ios,
              onPressed: onSwitchCamera,
              backgroundColor: Colors.white24,
              tooltip: 'Switch camera',
            ),
            _buildControlButton(
              icon: isSpeakerEnabled ? Icons.volume_up : Icons.volume_off,
              onPressed: onToggleSpeaker,
              backgroundColor: isSpeakerEnabled ? Colors.white24 : Colors.red,
              tooltip: isSpeakerEnabled ? 'Speaker off' : 'Speaker on',
            ),
            _buildControlButton(
              icon: Icons.call_end,
              onPressed: onEndCall,
              backgroundColor: Colors.red,
              tooltip: 'End call',
              size: 64,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color backgroundColor,
    required String tooltip,
    double size = 56,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: backgroundColor,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            child: Icon(icon, color: Colors.white, size: size * 0.4),
          ),
        ),
      ),
    );
  }
}
