import 'package:dartz/dartz.dart';

import '../entities/doctor.dart';
import '../repositories/doctor_repository.dart';

/// Use case to get doctor profile by doctor ID
class GetDoctorProfile {
  final DoctorRepository repository;

  GetDoctorProfile(this.repository);

  Future<Either<String, Doctor>> call(String doctorId) {
    return repository.getDoctorProfile(doctorId);
  }
}

/// Use case to get doctor profile by authentication user ID
class GetDoctorProfileByAuthId {
  final DoctorRepository repository;

  GetDoctorProfileByAuthId(this.repository);

  Future<Either<String, Doctor?>> call(String authId) {
    return repository.getDoctorProfileByAuthId(authId);
  }
}

/// Use case to update doctor profile
class UpdateDoctorProfile {
  final DoctorRepository repository;

  UpdateDoctorProfile(this.repository);

  Future<Either<String, Doctor>> call(Doctor doctor) {
    return repository.updateDoctorProfile(doctor);
  }
}

/// Use case to complete doctor profile (first-time setup)
class CompleteDoctorProfile {
  final DoctorRepository repository;

  CompleteDoctorProfile(this.repository);

  Future<Either<String, Doctor>> call(Doctor doctor) {
    return repository.completeDoctorProfile(doctor);
  }
}

/// Use case to update doctor availability status
class UpdateAvailability {
  final DoctorRepository repository;

  UpdateAvailability(this.repository);

  Future<Either<String, bool>> call(String doctorId, bool isAvailable) {
    return repository.updateAvailability(doctorId, isAvailable);
  }
}

/// Use case to update doctor online status
class UpdateOnlineStatus {
  final DoctorRepository repository;

  UpdateOnlineStatus(this.repository);

  Future<Either<String, bool>> call(String doctorId, bool isOnline) {
    return repository.updateOnlineStatus(doctorId, isOnline);
  }
}

class GetUpcomingConsultations {
  final DoctorRepository repository;

  GetUpcomingConsultations(this.repository);

  Future<List<Map<String, dynamic>>> call(String doctorId) async {
    try {
      return await repository.getUpcomingConsultations(doctorId);
    } catch (e) {
      throw Exception('Failed to fetch upcoming consultations: $e');
    }
  }

}

class GetCompletedConsultations {
  final DoctorRepository repository;

  GetCompletedConsultations(this.repository);

  Future<List<Map<String, dynamic>>> call(String doctorId) async {
    try {
      return await repository.getCompletedConsultations(doctorId);
    } catch (e) {
      throw Exception('Failed to fetch upcoming consultations: $e');
    }
  }

}

class GetCancelledConsultations {
  final DoctorRepository repository;

  GetCancelledConsultations(this.repository);

  Future<List<Map<String, dynamic>>> call(String doctorId) async {
    try {
      return await repository.getCompletedConsultations(doctorId);
    } catch (e) {
      throw Exception('Failed to fetch upcoming consultations: $e');
    }
  }

}

/// Use case to get total patients count
class GetTotalPatientsCount {
  final DoctorRepository repository;

  GetTotalPatientsCount(this.repository);

  Future<int> call(String doctorId) async {
    try {
      return await repository.getTotalPatientsCount(doctorId);
    } catch (e) {
      throw Exception('Failed to fetch total patients count: $e');
    }
  }
}

/// Use case to get scheduled consultations count
class GetScheduledConsultationsCount {
  final DoctorRepository repository;

  GetScheduledConsultationsCount(this.repository);

  Future<int> call(String doctorId) async {
    try {
      return await repository.getScheduledConsultationsCount(doctorId);
    } catch (e) {
      throw Exception('Failed to fetch scheduled consultations count: $e');
    }
  }
}

/// Use case to get total earnings
class GetTotalEarnings {
  final DoctorRepository repository;

  GetTotalEarnings(this.repository);

  Future<double> call(String doctorId) async {
    try {
      return await repository.getTotalEarnings(doctorId);
    } catch (e) {
      throw Exception('Failed to fetch total earnings: $e');
    }
  }
}