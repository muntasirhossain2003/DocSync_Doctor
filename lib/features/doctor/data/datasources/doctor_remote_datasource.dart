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

      // Update doctor table
      final doctorData = {
        'bmcd_registration_number': doctor.bmdcRegistrationNumber,
        'specialization': doctor.specialization,
        'qualification': doctor.qualification,
        'consultation_fee': doctor.consultationFee,
        if (doctor.availability != null) 'availability': doctor.availability,
        'is_available': doctor.isAvailable,
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

      // Insert or update doctor record
      final doctorData = {
        'user_id': doctor.userId,
        'bmcd_registration_number': doctor.bmdcRegistrationNumber,
        'specialization': doctor.specialization,
        'qualification': doctor.qualification,
        'consultation_fee': doctor.consultationFee,
        if (doctor.availability != null) 'availability': doctor.availability,
        'is_available': false, // Start with false, doctor can toggle later
        'is_online': false,
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
      await supabaseClient
          .from('doctors')
          .update({
            'is_online': isOnline,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', doctorId); // Schema uses 'id' not 'doctor_id'

      return true;
    } catch (e) {
      throw Exception('Failed to update online status: $e');
    }
  }

  /// Get completed consultations for a doctor
Future<List<Map<String, dynamic>>> getCompletedConsultations(String doctorId) async {
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
Future<List<Map<String, dynamic>>> getCancelledConsultations(String doctorId) async {
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
        .eq('consultation_status', 'cancelled')
        .order('scheduled_time', ascending: false); // Show most recent first

    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    throw Exception('Failed to fetch cancelled consultations: $e');
  }
}



Future<List<Map<String, dynamic>>> getUpcomingConsultations(String doctorId) async {
  try {
    final now = DateTime.now().toIso8601String();

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
        .eq('consultation_status', 'scheduled')
        .gt('scheduled_time', now)
        .order('scheduled_time', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    throw Exception('Failed to fetch upcoming consultations: $e');
  }
}


}
