import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/datasources/doctor_remote_datasource.dart';
import '../../data/repositories/doctor_repository_impl.dart';
import '../../domain/entities/doctor.dart';
import '../../domain/repositories/doctor_repository.dart';
import '../../domain/usecases/doctor_usecases.dart';

// Supabase client provider
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// Data source provider
final doctorRemoteDataSourceProvider = Provider<DoctorRemoteDataSource>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return DoctorRemoteDataSource(supabaseClient: supabaseClient);
});

// Repository provider
final doctorRepositoryProvider = Provider<DoctorRepository>((ref) {
  final remoteDataSource = ref.watch(doctorRemoteDataSourceProvider);
  return DoctorRepositoryImpl(remoteDataSource: remoteDataSource);
});

// Use case providers
final getDoctorProfileUseCaseProvider = Provider((ref) {
  final repository = ref.watch(doctorRepositoryProvider);
  return GetDoctorProfile(repository);
});

final getDoctorProfileByAuthIdUseCaseProvider = Provider((ref) {
  final repository = ref.watch(doctorRepositoryProvider);
  return GetDoctorProfileByAuthId(repository);
});

final updateDoctorProfileUseCaseProvider = Provider((ref) {
  final repository = ref.watch(doctorRepositoryProvider);
  return UpdateDoctorProfile(repository);
});

final completeDoctorProfileUseCaseProvider = Provider((ref) {
  final repository = ref.watch(doctorRepositoryProvider);
  return CompleteDoctorProfile(repository);
});

final updateAvailabilityUseCaseProvider = Provider((ref) {
  final repository = ref.watch(doctorRepositoryProvider);
  return UpdateAvailability(repository);
});

final updateOnlineStatusUseCaseProvider = Provider((ref) {
  final repository = ref.watch(doctorRepositoryProvider);
  return UpdateOnlineStatus(repository);
});

// Doctor profile state notifier
class DoctorProfileNotifier extends StateNotifier<AsyncValue<Doctor?>> {
  final GetDoctorProfileByAuthId getDoctorProfileByAuthId;
  final UpdateDoctorProfile updateDoctorProfile;
  final CompleteDoctorProfile completeDoctorProfile;
  final UpdateAvailability updateAvailability;
  final UpdateOnlineStatus updateOnlineStatus;

  DoctorProfileNotifier({
    required this.getDoctorProfileByAuthId,
    required this.updateDoctorProfile,
    required this.completeDoctorProfile,
    required this.updateAvailability,
    required this.updateOnlineStatus,
  }) : super(const AsyncValue.data(null));

  /// Load doctor profile by authentication ID
  Future<void> loadProfile(String authId) async {
    state = const AsyncValue.loading();

    final result = await getDoctorProfileByAuthId(authId);

    result.fold(
      (error) => state = AsyncValue.error(error, StackTrace.current),
      (doctor) => state = AsyncValue.data(doctor),
    );
  }

  /// Update doctor profile
  Future<bool> updateProfile(Doctor doctor) async {
    final result = await updateDoctorProfile(doctor);

    return result.fold(
      (error) {
        state = AsyncValue.error(error, StackTrace.current);
        return false;
      },
      (updatedDoctor) {
        state = AsyncValue.data(updatedDoctor);
        return true;
      },
    );
  }

  /// Complete doctor profile (first-time)
  Future<bool> completeProfile(Doctor doctor) async {
    final result = await completeDoctorProfile(doctor);

    return result.fold(
      (error) {
        state = AsyncValue.error(error, StackTrace.current);
        return false;
      },
      (completedDoctor) {
        state = AsyncValue.data(completedDoctor);
        return true;
      },
    );
  }

  /// Toggle availability
  Future<bool> toggleAvailability() async {
    final currentDoctor = state.value;
    if (currentDoctor == null) return false;

    final newAvailability = !currentDoctor.isAvailable;
    final result = await updateAvailability(currentDoctor.id, newAvailability);

    return result.fold((error) => false, (success) {
      if (success) {
        state = AsyncValue.data(
          currentDoctor.copyWith(isAvailable: newAvailability),
        );
      }
      return success;
    });
  }

  /// Toggle online status
  Future<bool> toggleOnlineStatus() async {
    final currentDoctor = state.value;
    if (currentDoctor == null) return false;

    final newOnlineStatus = !currentDoctor.isOnline;
    final result = await updateOnlineStatus(currentDoctor.id, newOnlineStatus);

    return result.fold((error) => false, (success) {
      if (success) {
        state = AsyncValue.data(
          currentDoctor.copyWith(isOnline: newOnlineStatus),
        );
      }
      return success;
    });
  }

  /// Refresh profile
  Future<void> refresh() async {
    final currentDoctor = state.value;
    if (currentDoctor == null) return;

    await loadProfile(currentDoctor.userId);
  }
}

// Doctor profile state notifier provider
final doctorProfileProvider =
    StateNotifierProvider<DoctorProfileNotifier, AsyncValue<Doctor?>>((ref) {
      return DoctorProfileNotifier(
        getDoctorProfileByAuthId: ref.watch(
          getDoctorProfileByAuthIdUseCaseProvider,
        ),
        updateDoctorProfile: ref.watch(updateDoctorProfileUseCaseProvider),
        completeDoctorProfile: ref.watch(completeDoctorProfileUseCaseProvider),
        updateAvailability: ref.watch(updateAvailabilityUseCaseProvider),
        updateOnlineStatus: ref.watch(updateOnlineStatusUseCaseProvider),
      );
    });
