import 'package:dartz/dartz.dart';

import '../entities/doctor.dart';

/// Doctor Repository Interface
/// Defines contracts for doctor data operations
abstract class DoctorRepository {
  /// Get doctor profile by doctor ID
  Future<Either<String, Doctor>> getDoctorProfile(String doctorId);

  /// Get doctor profile by authentication user ID
  /// Returns null if doctor profile doesn't exist
  Future<Either<String, Doctor?>> getDoctorProfileByAuthId(String authId);

  /// Update doctor profile
  Future<Either<String, Doctor>> updateDoctorProfile(Doctor doctor);

  /// Complete doctor profile (first-time setup)
  Future<Either<String, Doctor>> completeDoctorProfile(Doctor doctor);

  Future<List<Map<String, dynamic>>> getUpcomingConsultations(String doctorId);

 Future<List<Map<String, dynamic>>> getCompletedConsultations(String doctorId);

 Future<List<Map<String, dynamic>>> getCancelledConsultations(String doctorId);

  /// Get total number of unique patients for a doctor
  Future<int> getTotalPatientsCount(String doctorId);

  /// Get count of scheduled consultations for a doctor
  Future<int> getScheduledConsultationsCount(String doctorId);

  /// Get total earnings for a doctor
  Future<double> getTotalEarnings(String doctorId);
  

  /// Update doctor availability status
  Future<Either<String, bool>> updateAvailability(
    String doctorId,
    bool isAvailable,
  );

  /// Update doctor online status
  Future<Either<String, bool>> updateOnlineStatus(
    String doctorId,
    bool isOnline,
  );
}
