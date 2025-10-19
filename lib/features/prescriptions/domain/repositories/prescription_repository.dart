import '../entities/prescription.dart';

/// Repository interface for prescription operations
abstract class PrescriptionRepository {
  /// Get all prescriptions for the logged-in doctor
  Future<List<Prescription>> getDoctorPrescriptions();

  /// Get prescriptions for a specific patient
  Future<List<Prescription>> getPatientPrescriptions(String patientId);

  /// Get prescription by consultation ID
  Future<Prescription?> getPrescriptionByConsultation(String consultationId);

  /// Create a new prescription
  Future<Prescription> createPrescription(Prescription prescription);

  /// Update an existing prescription
  Future<Prescription> updatePrescription(Prescription prescription);

  /// Delete a prescription
  Future<void> deletePrescription(String prescriptionId);

  /// Add medication to prescription
  Future<void> addMedication(String prescriptionId, Medication medication);

  /// Remove medication from prescription
  Future<void> removeMedication(String medicationId);

  /// Add medical test to prescription
  Future<void> addMedicalTest(String prescriptionId, MedicalTest test);

  /// Remove medical test from prescription
  Future<void> removeMedicalTest(String testId);
}
