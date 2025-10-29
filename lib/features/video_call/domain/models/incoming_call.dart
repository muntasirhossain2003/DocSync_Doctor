/// Model for incoming video call
class IncomingCall {
  final String consultationId;
  final String patientId;
  final String patientName;
  final String? patientImageUrl;
  final String channelName;
  final String token;
  final DateTime callTime;

  const IncomingCall({
    required this.consultationId,
    required this.patientId,
    required this.patientName,
    this.patientImageUrl,
    required this.channelName,
    required this.token,
    required this.callTime,
  });

  factory IncomingCall.fromJson(Map<String, dynamic> json) {
    return IncomingCall(
      consultationId: json['consultation_id'] as String,
      patientId: json['patient_id'] as String,
      patientName: json['patient_name'] as String,
      patientImageUrl: json['patient_image_url'] as String?,
      channelName: json['channel_name'] as String,
      token: json['token'] as String,
      callTime: DateTime.parse(json['call_time'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'consultation_id': consultationId,
      'patient_id': patientId,
      'patient_name': patientName,
      'patient_image_url': patientImageUrl,
      'channel_name': channelName,
      'token': token,
      'call_time': callTime.toIso8601String(),
    };
  }
}
