import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../doctor/presentation/providers/doctor_profile_provider.dart';
import '../../domain/models/incoming_call.dart';

/// Provider for incoming call service
final incomingCallServiceProvider = Provider<IncomingCallService>((ref) {
  final doctor = ref.watch(doctorProfileProvider).value;
  return IncomingCallService(
    supabaseClient: Supabase.instance.client,
    doctorId: doctor?.id,
  );
});

/// Provider for incoming call stream
final incomingCallStreamProvider = StreamProvider<IncomingCall?>((ref) {
  final service = ref.watch(incomingCallServiceProvider);
  return service.incomingCallStream;
});

/// Service to handle incoming video calls from patients
class IncomingCallService {
  final SupabaseClient supabaseClient;
  final String? doctorId;

  late final StreamController<IncomingCall?> _callController;
  RealtimeChannel? _channel;

  IncomingCallService({required this.supabaseClient, required this.doctorId}) {
    _callController = StreamController<IncomingCall?>.broadcast();
    if (doctorId != null) {
      _startListening();
    }
  }

  /// Stream of incoming calls
  Stream<IncomingCall?> get incomingCallStream => _callController.stream;

  /// Start listening for incoming calls via Supabase Realtime
  void _startListening() {
    if (doctorId == null) return;

    print('🎧 Starting to listen for incoming calls for doctor: $doctorId');

    // Subscribe to consultations table for new video call requests
    _channel = supabaseClient
        .channel('doctor_calls_$doctorId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'consultations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'doctor_id',
            value: doctorId,
          ),
          callback: (payload) {
            print('📞 New consultation received: ${payload.newRecord}');
            _handleNewConsultation(payload.newRecord);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'consultations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'doctor_id',
            value: doctorId,
          ),
          callback: (payload) {
            print('📱 Consultation updated: ${payload.newRecord}');
            _handleConsultationUpdate(payload.newRecord);
          },
        )
        .subscribe();
  }

  /// Handle new consultation (potential incoming call)
  void _handleNewConsultation(Map<String, dynamic> data) {
    try {
      final status = data['consultation_status'] as String?;

      // Check if this is a video call request
      if (status == 'scheduled' || status == 'calling') {
        _fetchConsultationDetails(data['id'] as String);
      }
    } catch (e) {
      print('❌ Error handling new consultation: $e');
    }
  }

  /// Handle consultation update (status changes)
  void _handleConsultationUpdate(Map<String, dynamic> data) {
    try {
      final status = data['consultation_status'] as String?;

      // If patient is calling, show incoming call screen
      if (status == 'calling') {
        _fetchConsultationDetails(data['id'] as String);
      }

      // If call was cancelled by patient, dismiss incoming call
      if (status == 'canceled' || status == 'rejected') {
        _callController.add(null); // Clear incoming call
      }
    } catch (e) {
      print('❌ Error handling consultation update: $e');
    }
  }

  /// Fetch full consultation details including patient info
  Future<void> _fetchConsultationDetails(String consultationId) async {
    try {
      final response = await supabaseClient
          .from('consultations')
          .select('''
            id,
            patient_id,
            consultation_status,
            agora_channel_name,
            agora_token,
            scheduled_time,
            patient:users!consultations_patient_id_fkey(
              id,
              full_name,
              profile_picture_url
            )
          ''')
          .eq('id', consultationId)
          .single();

      print('✅ Fetched consultation details: $response');

      // Extract patient info
      final patient = response['patient'] as Map<String, dynamic>?;
      if (patient == null) {
        print('❌ No patient info found');
        return;
      }

      final incomingCall = IncomingCall(
        consultationId: consultationId,
        patientId: response['patient_id'] as String,
        patientName: patient['full_name'] as String? ?? 'Unknown Patient',
        patientImageUrl: patient['profile_picture_url'] as String?,
        channelName: response['agora_channel_name'] as String? ?? '',
        token: response['agora_token'] as String? ?? '',
        callTime: DateTime.now(),
      );

      // Emit incoming call
      _callController.add(incomingCall);
      print('📞 Incoming call emitted: ${incomingCall.patientName}');
    } catch (e) {
      print('❌ Error fetching consultation details: $e');
    }
  }

  /// Accept incoming call
  Future<void> acceptCall(String consultationId) async {
    try {
      await supabaseClient
          .from('consultations')
          .update({
            'consultation_status': 'in_progress',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', consultationId);

      print('✅ Call accepted: $consultationId');
      _callController.add(null); // Clear incoming call
    } catch (e) {
      print('❌ Error accepting call: $e');
      rethrow;
    }
  }

  /// Reject incoming call
  Future<void> rejectCall(String consultationId, {String? reason}) async {
    try {
      await supabaseClient
          .from('consultations')
          .update({
            'consultation_status': 'rejected',
            'rejection_reason': reason,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', consultationId);

      print('❌ Call rejected: $consultationId');
      _callController.add(null); // Clear incoming call
    } catch (e) {
      print('❌ Error rejecting call: $e');
      rethrow;
    }
  }

  /// Dispose resources
  void dispose() {
    _channel?.unsubscribe();
    _callController.close();
    print('🛑 Incoming call service disposed');
  }
}
