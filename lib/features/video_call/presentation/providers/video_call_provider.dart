import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/agora_config.dart';
import '../../data/services/agora_service.dart';
import '../../domain/models/call_state.dart';

/// Provider for Agora service
final agoraServiceProvider = Provider<AgoraService>((ref) {
  final service = AgoraService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for video call state
final videoCallProvider = StateNotifierProvider<VideoCallNotifier, CallState>((
  ref,
) {
  return VideoCallNotifier(ref.read(agoraServiceProvider));
});

class VideoCallNotifier extends StateNotifier<CallState> {
  final AgoraService _agoraService;
  Timer? _durationTimer;

  VideoCallNotifier(this._agoraService)
    : super(CallState(callId: '', channelName: AgoraConfig.channelName));

  /// Initialize and start a call
  Future<void> startCall({
    required String consultationId,
    required String? patientId,
    required String? patientName,
    String? patientImageUrl,
  }) async {
    try {
      state = state.copyWith(
        callId: consultationId,
        patientId: patientId,
        patientName: patientName,
        patientImageUrl: patientImageUrl,
        status: CallStatus.connecting,
      );

      // Initialize Agora
      if (!_agoraService.isInitialized) {
        await _agoraService.initialize();
      }

      // Register event handlers
      _agoraService.registerEventHandlers(
        onJoinChannelSuccess: _onJoinChannelSuccess,
        onUserJoined: _onUserJoined,
        onUserOffline: _onUserOffline,
        onError: _onError,
        onLeaveChannel: _onLeaveChannel,
      );

      // Join the channel
      final uid = DateTime.now().millisecondsSinceEpoch % 100000;
      await _agoraService.joinChannel(
        state.channelName,
        AgoraConfig.token,
        uid,
      );
    } catch (e) {
      state = state.copyWith(status: CallStatus.failed);
      print('Failed to start call: $e');
      rethrow;
    }
  }

  /// Handle successful channel join
  void _onJoinChannelSuccess(RtcConnection connection, int elapsed) {
    state = state.copyWith(
      status: CallStatus.connected,
      startTime: DateTime.now(),
    );
    _startDurationTimer();
  }

  /// Handle remote user joined
  void _onUserJoined(RtcConnection connection, int remoteUid, int elapsed) {
    state = state.copyWith(remoteUid: remoteUid);
  }

  /// Handle remote user left
  void _onUserOffline(
    RtcConnection connection,
    int remoteUid,
    UserOfflineReasonType reason,
  ) {
    if (state.remoteUid == remoteUid) {
      state = state.copyWith(remoteUid: null);
    }
  }

  /// Handle errors
  void _onError(ErrorCodeType err, String msg) {
    print('Agora Error: $err - $msg');
    state = state.copyWith(status: CallStatus.failed);
  }

  /// Handle leave channel
  void _onLeaveChannel(RtcConnection connection, RtcStats stats) {
    state = state.copyWith(status: CallStatus.disconnected, remoteUid: null);
    _stopDurationTimer();
  }

  /// Start duration timer
  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.startTime != null) {
        final duration = DateTime.now().difference(state.startTime!);
        state = state.copyWith(duration: duration);
      }
    });
  }

  /// Stop duration timer
  void _stopDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  /// Toggle video
  Future<void> toggleVideo() async {
    final newValue = !state.isVideoEnabled;
    await _agoraService.toggleVideo(newValue);
    state = state.copyWith(isVideoEnabled: newValue);
  }

  /// Toggle audio
  Future<void> toggleAudio() async {
    final newValue = !state.isAudioEnabled;
    await _agoraService.toggleAudio(newValue);
    state = state.copyWith(isAudioEnabled: newValue);
  }

  /// Toggle speaker
  Future<void> toggleSpeaker() async {
    final newValue = !state.isSpeakerEnabled;
    await _agoraService.setSpeakerphone(newValue);
    state = state.copyWith(isSpeakerEnabled: newValue);
  }

  /// Switch camera
  Future<void> switchCamera() async {
    await _agoraService.switchCamera();
  }

  /// End the call
  Future<void> endCall() async {
    await _agoraService.leaveChannel();
    _stopDurationTimer();
    state = CallState(
      callId: '',
      channelName: AgoraConfig.channelName,
      status: CallStatus.disconnected,
    );
  }

  @override
  void dispose() {
    _stopDurationTimer();
    super.dispose();
  }
}
