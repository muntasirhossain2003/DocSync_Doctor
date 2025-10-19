import '../../domain/entities/prescription.dart';
import '../../domain/repositories/prescription_repository.dart';
import '../datasources/prescription_remote_datasource.dart';
import '../models/prescription_model.dart';

class PrescriptionRepositoryImpl implements PrescriptionRepository {
  final PrescriptionRemoteDataSource remoteDataSource;

  PrescriptionRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<Prescription>> getDoctorPrescriptions() async {
    return await remoteDataSource.getDoctorPrescriptions();
  }

  @override
  Future<List<Prescription>> getPatientPrescriptions(String patientId) async {
    return await remoteDataSource.getPatientPrescriptions(patientId);
  }

  @override
  Future<Prescription?> getPrescriptionByConsultation(
    String consultationId,
  ) async {
    return await remoteDataSource.getPrescriptionByConsultation(consultationId);
  }

  @override
  Future<Prescription> createPrescription(Prescription prescription) async {
    final model = PrescriptionModel(
      id: prescription.id,
      consultationId: prescription.consultationId,
      patientId: prescription.patientId,
      doctorId: prescription.doctorId,
      diagnosis: prescription.diagnosis,
      symptoms: prescription.symptoms,
      medicalNotes: prescription.medicalNotes,
      followUpDate: prescription.followUpDate,
      medications: prescription.medications,
      tests: prescription.tests,
    );
    return await remoteDataSource.createPrescription(model);
  }

  @override
  Future<Prescription> updatePrescription(Prescription prescription) async {
    final model = PrescriptionModel(
      id: prescription.id,
      consultationId: prescription.consultationId,
      patientId: prescription.patientId,
      doctorId: prescription.doctorId,
      diagnosis: prescription.diagnosis,
      symptoms: prescription.symptoms,
      medicalNotes: prescription.medicalNotes,
      followUpDate: prescription.followUpDate,
      medications: prescription.medications,
      tests: prescription.tests,
    );
    return await remoteDataSource.updatePrescription(model);
  }

  @override
  Future<void> deletePrescription(String prescriptionId) async {
    await remoteDataSource.deletePrescription(prescriptionId);
  }

  @override
  Future<void> addMedication(
    String prescriptionId,
    Medication medication,
  ) async {
    final model = MedicationModel(
      id: medication.id,
      medicationName: medication.medicationName,
      dosage: medication.dosage,
      frequency: medication.frequency,
      duration: medication.duration,
      instructions: medication.instructions,
    );
    await remoteDataSource.addMedication(prescriptionId, model);
  }

  @override
  Future<void> removeMedication(String medicationId) async {
    await remoteDataSource.removeMedication(medicationId);
  }

  @override
  Future<void> addMedicalTest(String prescriptionId, MedicalTest test) async {
    final model = MedicalTestModel(
      id: test.id,
      testName: test.testName,
      testReason: test.testReason,
      urgency: test.urgency,
    );
    await remoteDataSource.addMedicalTest(prescriptionId, model);
  }

  @override
  Future<void> removeMedicalTest(String testId) async {
    await remoteDataSource.removeMedicalTest(testId);
  }
}
