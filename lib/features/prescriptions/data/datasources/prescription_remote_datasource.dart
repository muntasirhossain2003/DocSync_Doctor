import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/prescription_model.dart';

/// Remote data source for prescription operations
class PrescriptionRemoteDataSource {
  final SupabaseClient _supabase;

  PrescriptionRemoteDataSource(this._supabase);

  /// Get all prescriptions for the logged-in doctor
  Future<List<PrescriptionModel>> getDoctorPrescriptions() async {
    try {
      // Get current user's auth ID
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('❌ getDoctorPrescriptions: User not authenticated');
        throw Exception('Not authenticated');
      }
      print('✅ Current user auth_id: ${user.id}');

      // First, get the user record to find the user.id
      final userResponse = await _supabase
          .from('users')
          .select('id')
          .eq('auth_id', user.id)
          .maybeSingle();

      if (userResponse == null) {
        print('❌ getDoctorPrescriptions: User not found in users table');
        throw Exception('User not found');
      }

      final userId = userResponse['id'] as String;
      print('✅ User ID: $userId');

      // Then get the doctor profile using the user.id
      final doctorResponse = await _supabase
          .from('doctors')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (doctorResponse == null) {
        // Doctor profile not found, return empty list
        print(
          '❌ getDoctorPrescriptions: Doctor profile not found for user_id: $userId',
        );
        return [];
      }

      final doctorId = doctorResponse['id'] as String;
      print('✅ Doctor ID: $doctorId');

      // Get prescriptions
      final response = await _supabase
          .from('prescriptions')
          .select()
          .eq('doctor_id', doctorId)
          .order('created_at', ascending: false);

      print('✅ Prescriptions query response: $response');
      print('✅ Number of prescriptions found: ${(response as List).length}');

      final prescriptions = (response as List)
          .map(
            (json) => PrescriptionModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();

      // Load medications and tests for each prescription
      for (var i = 0; i < prescriptions.length; i++) {
        final medications = await _getMedications(prescriptions[i].id!);
        final tests = await _getMedicalTests(prescriptions[i].id!);

        prescriptions[i] = prescriptions[i].copyWith(
          medications: medications,
          tests: tests,
        );
      }

      return prescriptions;
    } catch (e) {
      throw Exception('Failed to get prescriptions: $e');
    }
  }

  /// Get prescriptions for a specific patient
  Future<List<PrescriptionModel>> getPatientPrescriptions(
    String patientId,
  ) async {
    try {
      final response = await _supabase
          .from('prescriptions')
          .select()
          .eq('patient_id', patientId)
          .order('created_at', ascending: false);

      final prescriptions = (response as List)
          .map(
            (json) => PrescriptionModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();

      for (var i = 0; i < prescriptions.length; i++) {
        final medications = await _getMedications(prescriptions[i].id!);
        final tests = await _getMedicalTests(prescriptions[i].id!);

        prescriptions[i] = prescriptions[i].copyWith(
          medications: medications,
          tests: tests,
        );
      }

      return prescriptions;
    } catch (e) {
      throw Exception('Failed to get patient prescriptions: $e');
    }
  }

  /// Get prescription by consultation ID
  Future<PrescriptionModel?> getPrescriptionByConsultation(
    String consultationId,
  ) async {
    try {
      final response = await _supabase
          .from('prescriptions')
          .select()
          .eq('consultation_id', consultationId)
          .maybeSingle();

      if (response == null) return null;

      var prescription = PrescriptionModel.fromJson(response);

      final medications = await _getMedications(prescription.id!);
      final tests = await _getMedicalTests(prescription.id!);

      prescription = prescription.copyWith(
        medications: medications,
        tests: tests,
      );

      return prescription;
    } catch (e) {
      throw Exception('Failed to get prescription: $e');
    }
  }

  /// Create a new prescription
  Future<PrescriptionModel> createPrescription(
    PrescriptionModel prescription,
  ) async {
    try {
      print('📝 Creating prescription in database...');
      print('   Consultation ID: ${prescription.consultationId}');
      print('   Patient ID: ${prescription.patientId}');
      print('   Doctor ID: ${prescription.doctorId}');
      print('   Diagnosis: ${prescription.diagnosis}');
      final prescriptionJson = prescription.toJson();
      print('   toJson(): $prescriptionJson');

      // Ensure patient_id is not an empty string before inserting
      if (prescriptionJson['patient_id'] == null ||
          (prescriptionJson['patient_id'] as String).isEmpty) {
        throw const PostgrestException(
          message: 'Patient ID cannot be null or empty.',
        );
      }

      print('🔹 Step 1: Inserting prescription...');
      // Insert prescription
      final response = await _supabase
          .from('prescriptions')
          .insert(prescription.toJson())
          .select()
          .single();

      print('✅ Prescription inserted with ID: ${response['id']}');
      print('   Full response: $response');

      final createdPrescription = PrescriptionModel.fromJson(response);

      // Insert medications
      if (prescription.medications.isNotEmpty) {
        print(
          '💊 Step 2: Inserting ${prescription.medications.length} medications...',
        );
        for (var i = 0; i < prescription.medications.length; i++) {
          final medication = prescription.medications[i];
          print('   💊 Medication ${i + 1}: ${medication.medicationName}');
          try {
            // Convert to MedicationModel if it's not already
            final medicationModel = medication is MedicationModel
                ? medication
                : MedicationModel(
                    id: medication.id,
                    medicationName: medication.medicationName,
                    dosage: medication.dosage,
                    frequency: medication.frequency,
                    duration: medication.duration,
                    instructions: medication.instructions,
                  );
            await addMedication(createdPrescription.id!, medicationModel);
            print('   ✅ Medication ${i + 1} inserted');
          } catch (e) {
            print('   ❌ Failed to insert medication ${i + 1}: $e');
            rethrow;
          }
        }
        print('✅ All medications inserted');
      } else {
        print('ℹ️ No medications to insert');
      }

      // Insert medical tests
      if (prescription.tests.isNotEmpty) {
        print('🔹 Step 3: Inserting ${prescription.tests.length} tests...');
        for (var i = 0; i < prescription.tests.length; i++) {
          final test = prescription.tests[i];
          print('   🧪 Test ${i + 1}: ${test.testName}');
          try {
            // Convert to MedicalTestModel if it's not already
            final testModel = test is MedicalTestModel
                ? test
                : MedicalTestModel(
                    id: test.id,
                    testName: test.testName,
                    testReason: test.testReason,
                    urgency: test.urgency,
                  );
            await addMedicalTest(createdPrescription.id!, testModel);
            print('   ✅ Test ${i + 1} inserted');
          } catch (e) {
            print('   ❌ Failed to insert test ${i + 1}: $e');
            rethrow;
          }
        }
        print('✅ All tests inserted');
      } else {
        print('ℹ️ No tests to insert');
      }

      print('🔹 Step 4: Fetching complete prescription...');
      final finalPrescription = await getPrescriptionByConsultation(
        prescription.consultationId,
      );

      if (finalPrescription == null) {
        print(
          '⚠️ Warning: Could not fetch prescription after creation, returning created prescription',
        );
        return createdPrescription;
      }

      print('✅ Prescription creation complete!');
      print('   Total medications: ${finalPrescription.medications.length}');
      print('   Total tests: ${finalPrescription.tests.length}');

      return finalPrescription;
    } catch (e, stackTrace) {
      print('❌ Failed to create prescription: $e');
      print('❌ Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Update an existing prescription
  Future<PrescriptionModel> updatePrescription(
    PrescriptionModel prescription,
  ) async {
    try {
      await _supabase
          .from('prescriptions')
          .update(prescription.toJson())
          .eq('id', prescription.id!);

      return getPrescriptionByConsultation(
        prescription.consultationId,
      ).then((p) => p!);
    } catch (e) {
      throw Exception('Failed to update prescription: $e');
    }
  }

  /// Delete a prescription
  Future<void> deletePrescription(String prescriptionId) async {
    try {
      await _supabase.from('prescriptions').delete().eq('id', prescriptionId);
    } catch (e) {
      throw Exception('Failed to delete prescription: $e');
    }
  }

  /// Add medication to prescription
  Future<void> addMedication(
    String prescriptionId,
    MedicationModel medication,
  ) async {
    try {
      final data = medication.toJson();
      data['prescription_id'] = prescriptionId;
      await _supabase.from('prescription_medications').insert(data);
    } catch (e) {
      throw Exception('Failed to add medication: $e');
    }
  }

  /// Remove medication from prescription
  Future<void> removeMedication(String medicationId) async {
    try {
      await _supabase
          .from('prescription_medications')
          .delete()
          .eq('id', medicationId);
    } catch (e) {
      throw Exception('Failed to remove medication: $e');
    }
  }

  /// Add medical test to prescription
  Future<void> addMedicalTest(
    String prescriptionId,
    MedicalTestModel test,
  ) async {
    try {
      final data = test.toJson();
      data['prescription_id'] = prescriptionId;
      await _supabase.from('medical_tests').insert(data);
    } catch (e) {
      throw Exception('Failed to add medical test: $e');
    }
  }

  /// Remove medical test from prescription
  Future<void> removeMedicalTest(String testId) async {
    try {
      await _supabase.from('medical_tests').delete().eq('id', testId);
    } catch (e) {
      throw Exception('Failed to remove medical test: $e');
    }
  }

  /// Get medications for a prescription
  Future<List<MedicationModel>> _getMedications(String prescriptionId) async {
    try {
      final response = await _supabase
          .from('prescription_medications')
          .select()
          .eq('prescription_id', prescriptionId);

      return (response as List)
          .map((json) => MedicationModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get medical tests for a prescription
  Future<List<MedicalTestModel>> _getMedicalTests(String prescriptionId) async {
    try {
      final response = await _supabase
          .from('medical_tests')
          .select()
          .eq('prescription_id', prescriptionId);

      return (response as List)
          .map(
            (json) => MedicalTestModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }
}
