import '../../domain/entities/prescription.dart';

/// Prescription model for data layer
class PrescriptionModel extends Prescription {
  const PrescriptionModel({
    super.id,
    required super.consultationId,
    required super.patientId,
    required super.doctorId,
    required super.diagnosis,
    super.symptoms,
    super.medicalNotes,
    super.followUpDate,
    super.medications,
    super.tests,
    super.createdAt,
    super.updatedAt,
  });

  factory PrescriptionModel.fromJson(Map<String, dynamic> json) {
    // ... (existing fromJson implementation)
    return PrescriptionModel(
      id: json['id'] as String?,
      consultationId: json['consultation_id'] as String,
      patientId: json['patient_id'] as String,
      doctorId: json['doctor_id'] as String,
      diagnosis: json['diagnosis'] as String,
      symptoms: json['symptoms'] as String?,
      medicalNotes: json['medical_notes'] as String?,
      followUpDate: json['follow_up_date'] != null
          ? DateTime.parse(json['follow_up_date'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      // Note: medications and tests are loaded separately
    );
  }

  Map<String, dynamic> toJson() {
    // ... (existing toJson implementation)
    return {
      if (id != null) 'id': id,
      'consultation_id': consultationId,
      'patient_id': patientId,
      'doctor_id': doctorId,
      'diagnosis': diagnosis,
      if (symptoms != null) 'symptoms': symptoms,
      if (medicalNotes != null) 'medical_notes': medicalNotes,
      if (followUpDate != null)
        'follow_up_date': followUpDate!.toIso8601String(),
    };
  }

  @override
  PrescriptionModel copyWith({
    String? id,
    String? consultationId,
    String? patientId,
    String? doctorId,
    String? diagnosis,
    String? symptoms,
    String? medicalNotes,
    DateTime? followUpDate,
    List<Medication>? medications,
    List<MedicalTest>? tests,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PrescriptionModel(
      id: id ?? this.id,
      consultationId: consultationId ?? this.consultationId,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      diagnosis: diagnosis ?? this.diagnosis,
      symptoms: symptoms ?? this.symptoms,
      medicalNotes: medicalNotes ?? this.medicalNotes,
      followUpDate: followUpDate ?? this.followUpDate,
      medications: medications ?? this.medications,
      tests: tests ?? this.tests,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Medication model
class MedicationModel extends Medication {
  const MedicationModel({
    super.id,
    required super.medicationName,
    required super.dosage,
    required super.frequency,
    required super.duration,
    super.instructions,
  });

  factory MedicationModel.fromJson(Map<String, dynamic> json) {
    return MedicationModel(
      id: json['id'] as String?,
      medicationName: json['medication_name'] as String,
      dosage: json['dosage'] as String,
      frequency: json['frequency'] as String,
      duration: json['duration'] as String,
      instructions: json['instructions'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'medication_name': medicationName,
      'dosage': dosage,
      'frequency': frequency,
      'duration': duration,
      if (instructions != null) 'instructions': instructions,
    };
  }
}

/// Medical test model
class MedicalTestModel extends MedicalTest {
  const MedicalTestModel({
    super.id,
    required super.testName,
    super.testReason,
    super.urgency = 'normal',
  });

  factory MedicalTestModel.fromJson(Map<String, dynamic> json) {
    return MedicalTestModel(
      id: json['id'] as String?,
      testName: json['test_name'] as String,
      testReason: json['test_reason'] as String?,
      urgency: json['urgency'] as String? ?? 'normal',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'test_name': testName,
      if (testReason != null) 'test_reason': testReason,
      'urgency': urgency,
    };
  }
}
