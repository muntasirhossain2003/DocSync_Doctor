import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/doctor_model.dart';

/// Doctor Remote Data Source
/// Handles all Supabase API calls for doctor data
class DoctorRemoteDataSource {
  final SupabaseClient supabaseClient;

  DoctorRemoteDataSource({required this.supabaseClient});

  /// Get doctor profile by doctor ID
  Future<DoctorModel> getDoctorProfile(String doctorId) async {
    try {
      final response = await supabaseClient
          .from('doctors')
          .select('''
            *,
            user:users!doctors_user_id_fkey(*)
          ''')
          .eq('id', doctorId)
          .single();

      return DoctorModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch doctor profile: $e');
    }
  }

  /// Get doctor profile by authentication user ID
  /// Returns null if doctor profile doesn't exist (user needs to complete profile)
  Future<DoctorModel?> getDoctorProfileByAuthId(String authId) async {
    try {
      // First, get the user record to find the user.id
      final userResponse = await supabaseClient
          .from('users')
          .select('id')
          .eq('auth_id', authId)
          .maybeSingle();

      if (userResponse == null) {
        throw Exception('User not found for auth_id: $authId');
      }

      final userId = userResponse['id'] as String;

      // Then get the doctor profile using the user.id
      final response = await supabaseClient
          .from('doctors')
          .select('''
            *,
            user:users!doctors_user_id_fkey(*)
          ''')
          .eq('user_id', userId)
          .maybeSingle();

      // Return null if no doctor record exists (profile not completed)
      if (response == null) {
        return null;
      }

      return DoctorModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch doctor profile by auth ID: $e');
    }
  }

  /// Update doctor profile
  Future<DoctorModel> updateDoctorProfile(DoctorModel doctor) async {
    try {
      // Update user table first
      await supabaseClient
          .from('users')
          .update({
            'full_name': doctor.fullName,
            'phone':
                doctor.phoneNumber, // Schema uses 'phone' not 'phone_number'
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', doctor.userId); // Schema uses 'id' not 'user_id'

      // Generate default availability if not set
      Map<String, dynamic>? availability = doctor.availability;
      if (availability == null || availability.isEmpty) {
        availability = _generateDefaultAvailability();
      }

      // Check if doctor has at least one available day
      bool hasAvailableDay = availability.values.any((day) {
        if (day is Map) {
          return day['available'] == true;
        }
        return false;
      });

      // is_available uses OR condition: true if EITHER is_online OR has availability schedule
      bool isAvailable = doctor.isOnline || hasAvailableDay;

      // Update doctor table
      final doctorData = {
        'bmcd_registration_number': doctor.bmdcRegistrationNumber,
        'specialization': doctor.specialization,
        'qualification': doctor.qualification,
        'consultation_fee': doctor.consultationFee,
        'availability': availability,
        'is_available': isAvailable, // OR condition: is_online OR has_schedule
        'is_online': doctor.isOnline,
        if (doctor.bio != null) 'bio': doctor.bio,
        if (doctor.experience != null) 'experience': doctor.experience,
        if (doctor.profilePictureUrl != null)
          'profile_picture_url': doctor.profilePictureUrl,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await supabaseClient
          .from('doctors')
          .update(doctorData)
          .eq('id', doctor.doctorId) // Schema uses 'id' not 'doctor_id'
          .select('''
            *,
            user:users!doctors_user_id_fkey(*)
          ''')
          .single();

      return DoctorModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update doctor profile: $e');
    }
  }

  /// Complete doctor profile (first-time setup)
  Future<DoctorModel> completeDoctorProfile(DoctorModel doctor) async {
    try {
      // Update user table first
      await supabaseClient
          .from('users')
          .update({
            'full_name': doctor.fullName,
            'phone':
                doctor.phoneNumber, // Schema uses 'phone' not 'phone_number'
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', doctor.userId); // Schema uses 'id' not 'user_id'

      // Generate default availability if not set
      Map<String, dynamic>? availability = doctor.availability;
      if (availability == null || availability.isEmpty) {
        availability = _generateDefaultAvailability();
      }

      // Insert or update doctor record
      // Note: is_online is set to true on profile completion, so is_available will also be true
      // (using OR condition: is_online OR has_schedule)
      final doctorData = {
        'user_id': doctor.userId,
        'bmcd_registration_number': doctor.bmdcRegistrationNumber,
        'specialization': doctor.specialization,
        'qualification': doctor.qualification,
        'consultation_fee': doctor.consultationFee,
        'availability': availability,
        'is_available': true, // Always true on completion (is_online is true)
        'is_online': true, // Set to true when profile is complete
        if (doctor.bio != null) 'bio': doctor.bio,
        if (doctor.experience != null) 'experience': doctor.experience,
        if (doctor.profilePictureUrl != null)
          'profile_picture_url': doctor.profilePictureUrl,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await supabaseClient
          .from('doctors')
          .upsert(doctorData)
          .select('''
            *,
            user:users!doctors_user_id_fkey(*)
          ''')
          .single();

      return DoctorModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to complete doctor profile: $e');
    }
  }

  /// Update doctor availability status
  Future<bool> updateAvailability(String doctorId, bool isAvailable) async {
    try {
      await supabaseClient
          .from('doctors')
          .update({
            'is_available': isAvailable,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', doctorId); // Schema uses 'id' not 'doctor_id'

      return true;
    } catch (e) {
      throw Exception('Failed to update availability: $e');
    }
  }

  /// Update doctor online status
  Future<bool> updateOnlineStatus(String doctorId, bool isOnline) async {
    try {
      final now = DateTime.now();

      // Get current doctor data to check availability schedule
      final doctorData = await supabaseClient
          .from('doctors')
          .select('availability')
          .eq('id', doctorId)
          .single();

      // Check if doctor has availability schedule
      final availability = doctorData['availability'] as Map<String, dynamic>?;
      bool hasAvailableDay = false;
      if (availability != null && availability.isNotEmpty) {
        hasAvailableDay = availability.values.any((day) {
          if (day is Map) {
            return day['available'] == true;
          }
          return false;
        });
      }

      // is_available uses OR condition: true if EITHER is_online OR has availability schedule
      bool isAvailable = isOnline || hasAvailableDay;

      // Prepare update data
      final updateData = <String, dynamic>{
        'is_online': isOnline,
        'is_available': isAvailable, // Update based on OR condition
        'updated_at': now.toIso8601String(),
      };

      // If going online, set availability_start to current time
      // If going offline, set availability_end to current time
      if (isOnline) {
        updateData['availability_start'] = now.toIso8601String();
        // Clear availability_end when going online
        updateData['availability_end'] = null;
      } else {
        updateData['availability_end'] = now.toIso8601String();
      }

      await supabaseClient
          .from('doctors')
          .update(updateData)
          .eq('id', doctorId); // Schema uses 'id' not 'doctor_id'

      return true;
    } catch (e) {
      throw Exception('Failed to update online status: $e');
    }
  }

  /// Get completed consultations for a doctor
  Future<List<Map<String, dynamic>>> getCompletedConsultations(
    String doctorId,
  ) async {
    try {
      final response = await supabaseClient
          .from('consultations')
          .select('''
          id,
          scheduled_time,
          consultation_type,
          consultation_status,
          patient:users!consultations_patient_id_fkey(full_name, profile_picture_url)
        ''')
          .eq('doctor_id', doctorId)
          .eq('consultation_status', 'completed')
          .order('scheduled_time', ascending: false); // Show most recent first

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch completed consultations: $e');
    }
  }

  /// Get cancelled consultations for a doctor
  Future<List<Map<String, dynamic>>> getCancelledConsultations(
    String doctorId,
  ) async {
    try {
      final response = await supabaseClient
          .from('consultations')
          .select('''
          id,
          scheduled_time,
          consultation_type,
          consultation_status,
          patient:users!consultations_patient_id_fkey(full_name, profile_picture_url)
        ''')
          .eq('doctor_id', doctorId)
          .inFilter('consultation_status', [
            'canceled',
            'rejected',
          ]) // Fixed: canceled (single 'l') and rejected
          .order('scheduled_time', ascending: false); // Show most recent first

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch cancelled consultations: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getUpcomingConsultations(
    String doctorId,
  ) async {
    try {
      // Get current time - Supabase will handle timezone conversion
      final now = DateTime.now().toIso8601String();
      final nowUtc = DateTime.now().toUtc().toIso8601String();
      print('🔍 Fetching upcoming consultations for doctor: $doctorId');
      print('🔍 Local time (Dhaka): $now');
      print('🔍 UTC time: $nowUtc');

      final response = await supabaseClient
          .from('consultations')
          .select('''
          id,
          scheduled_time,
          consultation_type,
          consultation_status,
          patient:users!consultations_patient_id_fkey(full_name, profile_picture_url)
        ''')
          .eq('doctor_id', doctorId)
          .inFilter('consultation_status', [
            'scheduled',
            'calling',
            'in_progress',
          ]) // Include all active consultations
          .gte('scheduled_time', nowUtc) // Use UTC time for comparison
          .order('scheduled_time', ascending: true);

      print('🔍 Query returned ${response.length} consultations');
      if (response.isEmpty) {
        print('⚠️ No consultations found! Checking without time filter...');
        final allConsultations = await supabaseClient
            .from('consultations')
            .select('id, scheduled_time, consultation_status')
            .eq('doctor_id', doctorId)
            .inFilter('consultation_status', [
              'scheduled',
              'calling',
              'in_progress',
            ]);
        print(
          '🔍 Total consultations (no time filter): ${allConsultations.length}',
        );
        for (var c in allConsultations) {
          print(
            '  - ${c['id']}: ${c['scheduled_time']} (${c['consultation_status']})',
          );
        }
      }

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch upcoming consultations: $e');
    }
  }

  /// Generate default availability schedule (9 AM - 5 PM, Monday to Friday)
  Map<String, dynamic> _generateDefaultAvailability() {
    return {
      'monday': {'start': '09:00', 'end': '17:00', 'available': true},
      'tuesday': {'start': '09:00', 'end': '17:00', 'available': true},
      'wednesday': {'start': '09:00', 'end': '17:00', 'available': true},
      'thursday': {'start': '09:00', 'end': '17:00', 'available': true},
      'friday': {'start': '09:00', 'end': '17:00', 'available': true},
      'saturday': {'start': '09:00', 'end': '13:00', 'available': true},
      'sunday': {'start': '00:00', 'end': '00:00', 'available': false},
    };
  }
}
