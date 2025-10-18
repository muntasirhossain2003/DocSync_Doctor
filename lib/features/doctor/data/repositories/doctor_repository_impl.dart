import 'package:dartz/dartz.dart';

import '../../domain/entities/doctor.dart';
import '../../domain/repositories/doctor_repository.dart';
import '../datasources/doctor_remote_datasource.dart';
import '../models/doctor_model.dart';

/// Doctor Repository Implementation
/// Implements the DoctorRepository interface
class DoctorRepositoryImpl implements DoctorRepository {
  final DoctorRemoteDataSource remoteDataSource;

  DoctorRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<String, Doctor>> getDoctorProfile(String doctorId) async {
    try {
      final doctorModel = await remoteDataSource.getDoctorProfile(doctorId);
      return Right(doctorModel.toEntity());
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getUpcomingConsultations(
      String doctorId) async {
    try {
      final consultations =
          await remoteDataSource.getUpcomingConsultations(doctorId);
      return consultations;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getCompletedConsultations(
      String doctorId) async {
    try {
      final consultations =
          await remoteDataSource.getCompletedConsultations(doctorId);
      return consultations;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getCancelledConsultations(
      String doctorId) async {
    try {
      final consultations =
          await remoteDataSource.getCancelledConsultations(doctorId);
      return consultations;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<int> getTotalPatientsCount(String doctorId) async {
    try {
      return await remoteDataSource.getTotalPatientsCount(doctorId);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<int> getScheduledConsultationsCount(String doctorId) async {
    try {
      return await remoteDataSource.getScheduledConsultationsCount(doctorId);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<double> getTotalEarnings(String doctorId) async {
    try {
      return await remoteDataSource.getTotalEarnings(doctorId);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<Either<String, Doctor?>> getDoctorProfileByAuthId(
    String authId,
  ) async {
    try {
      final doctorModel =
          await remoteDataSource.getDoctorProfileByAuthId(authId);
      // Return null if doctor profile doesn't exist
      if (doctorModel == null) {
        return const Right(null);
      }
      return Right(doctorModel.toEntity());
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, Doctor>> updateDoctorProfile(Doctor doctor) async {
    try {
      final doctorModel = DoctorModel.fromEntity(doctor);
      final updatedModel =
          await remoteDataSource.updateDoctorProfile(doctorModel);
      return Right(updatedModel.toEntity());
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, Doctor>> completeDoctorProfile(Doctor doctor) async {
    try {
      final doctorModel = DoctorModel.fromEntity(doctor);
      final completedModel =
          await remoteDataSource.completeDoctorProfile(doctorModel);
      return Right(completedModel.toEntity());
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, bool>> updateAvailability(
      String doctorId, bool isAvailable) async {
    try {
      final result =
          await remoteDataSource.updateAvailability(doctorId, isAvailable);
      return Right(result);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, bool>> updateOnlineStatus(
      String doctorId, bool isOnline) async {
    try {
      final result =
          await remoteDataSource.updateOnlineStatus(doctorId, isOnline);
      return Right(result);
    } catch (e) {
      return Left(e.toString());
    }
  }
}
