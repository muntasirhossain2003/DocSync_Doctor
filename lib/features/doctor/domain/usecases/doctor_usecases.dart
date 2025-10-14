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
