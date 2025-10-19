import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/datasources/prescription_remote_datasource.dart';
import '../../data/repositories/prescription_repository_impl.dart';
import '../../domain/entities/prescription.dart';
import '../../domain/repositories/prescription_repository.dart';

// Data source provider
final prescriptionDataSourceProvider = Provider<PrescriptionRemoteDataSource>((
  ref,
) {
  return PrescriptionRemoteDataSource(Supabase.instance.client);
});

// Repository provider
final prescriptionRepositoryProvider = Provider<PrescriptionRepository>((ref) {
  return PrescriptionRepositoryImpl(ref.read(prescriptionDataSourceProvider));
});

// Prescriptions list provider
final prescriptionsProvider = FutureProvider.autoDispose<List<Prescription>>((
  ref,
) async {
  final repository = ref.read(prescriptionRepositoryProvider);
  return await repository.getDoctorPrescriptions();
});

// Single prescription provider by consultation ID
final prescriptionByConsultationProvider = FutureProvider.family
    .autoDispose<Prescription?, String>((ref, consultationId) async {
      final repository = ref.read(prescriptionRepositoryProvider);
      return await repository.getPrescriptionByConsultation(consultationId);
    });

// Prescription notifier for create/update operations
final prescriptionNotifierProvider =
    StateNotifierProvider<PrescriptionNotifier, AsyncValue<Prescription?>>((
      ref,
    ) {
      return PrescriptionNotifier(ref.read(prescriptionRepositoryProvider));
    });

class PrescriptionNotifier extends StateNotifier<AsyncValue<Prescription?>> {
  final PrescriptionRepository _repository;

  PrescriptionNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> createPrescription(Prescription prescription) async {
    state = const AsyncValue.loading();
    try {
      final created = await _repository.createPrescription(prescription);
      state = AsyncValue.data(created);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      // Re-throw the exception to be caught in the UI
      rethrow;
    }
  }

  Future<void> updatePrescription(Prescription prescription) async {
    state = const AsyncValue.loading();
    try {
      final updated = await _repository.updatePrescription(prescription);
      state = AsyncValue.data(updated);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deletePrescription(String prescriptionId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deletePrescription(prescriptionId);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}
