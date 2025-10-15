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

// Use case for upcoming consultations
final getUpcomingConsultationsUseCaseProvider = Provider((ref) {
  final repository = ref.watch(doctorRepositoryProvider);
  return GetUpcomingConsultations(repository);
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
  if (!mounted) return;
  state = const AsyncValue.loading();

  try {
    final result = await getDoctorProfileByAuthId(authId);

    result.fold(
      (error) {
        if (!mounted) return;
        state = AsyncValue.error(error, StackTrace.current);
      },
      (doctor) {
        if (!mounted) return;
        state = AsyncValue.data(doctor);
      },
    );
  } catch (e, st) {
    if (!mounted) return;
    state = AsyncValue.error(e.toString(), st);
  }
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


class UpcomingConsultationsNotifier
    extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final GetUpcomingConsultations getUpcomingConsultations;

  UpcomingConsultationsNotifier({required this.getUpcomingConsultations})
      : super(const AsyncValue.loading());

  Future<void> load(String doctorId) async {
  state = const AsyncValue.loading();

  try {
    final consultations = await getUpcomingConsultations(doctorId);
    state = AsyncValue.data(consultations);
  } catch (e, st) {
    state = AsyncValue.error(e.toString(), st);
  }
}

}

// Provider for upcoming consultations
final upcomingConsultationsProvider = StateNotifierProvider<
    UpcomingConsultationsNotifier,
    AsyncValue<List<Map<String, dynamic>>>>((ref) {
  final useCase = ref.watch(getUpcomingConsultationsUseCaseProvider);
  return UpcomingConsultationsNotifier(getUpcomingConsultations: useCase);
});

// Use cases for completed and cancelled consultations
final getCompletedConsultationsUseCaseProvider = Provider((ref) {
  final repository = ref.watch(doctorRepositoryProvider);
  return GetCompletedConsultations(repository);
});

final getCancelledConsultationsUseCaseProvider = Provider((ref) {
  final repository = ref.watch(doctorRepositoryProvider);
  return GetCancelledConsultations(repository);
});

// Completed consultations notifier
class CompletedConsultationsNotifier
    extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final GetCompletedConsultations getCompletedConsultations;

  CompletedConsultationsNotifier({required this.getCompletedConsultations})
      : super(const AsyncValue.loading());

  Future<void> load(String doctorId) async {
    state = const AsyncValue.loading();

    try {
      final consultations = await getCompletedConsultations(doctorId);
      state = AsyncValue.data(consultations);
    } catch (e, st) {
      state = AsyncValue.error(e.toString(), st);
    }
  }
}

// Cancelled consultations notifier
class CancelledConsultationsNotifier
    extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final GetCancelledConsultations getCancelledConsultations;

  CancelledConsultationsNotifier({required this.getCancelledConsultations})
      : super(const AsyncValue.loading());

  Future<void> load(String doctorId) async {
    state = const AsyncValue.loading();

    try {
      final consultations = await getCancelledConsultations(doctorId);
      state = AsyncValue.data(consultations);
    } catch (e, st) {
      state = AsyncValue.error(e.toString(), st);
    }
  }
}

// Providers
final completedConsultationsProvider = StateNotifierProvider<
    CompletedConsultationsNotifier,
    AsyncValue<List<Map<String, dynamic>>>>((ref) {
  final useCase = ref.watch(getCompletedConsultationsUseCaseProvider);
  return CompletedConsultationsNotifier(getCompletedConsultations: useCase);
});

final cancelledConsultationsProvider = StateNotifierProvider<
    CancelledConsultationsNotifier,
    AsyncValue<List<Map<String, dynamic>>>>((ref) {
  final useCase = ref.watch(getCancelledConsultationsUseCaseProvider);
  return CancelledConsultationsNotifier(getCancelledConsultations: useCase);
});
