import 'package:equatable/equatable.dart';

/// Represents the state of a video call
class CallState extends Equatable {
  final String callId;
  final String channelName;
  final String? patientId;
  final String? patientName;
  final String? patientImageUrl;
  final CallStatus status;
  final bool isVideoEnabled;
  final bool isAudioEnabled;
  final bool isSpeakerEnabled;
  final DateTime? startTime;
  final Duration? duration;
  final int? remoteUid;

  const CallState({
    required this.callId,
    required this.channelName,
    this.patientId,
    this.patientName,
    this.patientImageUrl,
    this.status = CallStatus.idle,
    this.isVideoEnabled = true,
    this.isAudioEnabled = true,
    this.isSpeakerEnabled = true,
    this.startTime,
    this.duration,
    this.remoteUid,
  });

  CallState copyWith({
    String? callId,
    String? channelName,
    String? patientId,
    String? patientName,
    String? patientImageUrl,
    CallStatus? status,
    bool? isVideoEnabled,
    bool? isAudioEnabled,
    bool? isSpeakerEnabled,
    DateTime? startTime,
    Duration? duration,
    int? remoteUid,
  }) {
    return CallState(
      callId: callId ?? this.callId,
      channelName: channelName ?? this.channelName,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      patientImageUrl: patientImageUrl ?? this.patientImageUrl,
      status: status ?? this.status,
      isVideoEnabled: isVideoEnabled ?? this.isVideoEnabled,
      isAudioEnabled: isAudioEnabled ?? this.isAudioEnabled,
      isSpeakerEnabled: isSpeakerEnabled ?? this.isSpeakerEnabled,
      startTime: startTime ?? this.startTime,
      duration: duration ?? this.duration,
      remoteUid: remoteUid ?? this.remoteUid,
    );
  }

  @override
  List<Object?> get props => [
    callId,
    channelName,
    patientId,
    patientName,
    patientImageUrl,
    status,
    isVideoEnabled,
    isAudioEnabled,
    isSpeakerEnabled,
    startTime,
    duration,
    remoteUid,
  ];
}

/// Status of a video call
enum CallStatus {
  idle,
  connecting,
  connected,
  reconnecting,
  disconnected,
  failed,
}
