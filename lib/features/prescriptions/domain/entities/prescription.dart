import 'package:equatable/equatable.dart';

/// Medication entity
class Medication extends Equatable {
  final String? id;
  final String medicationName;
  final String dosage;
  final String frequency;
  final String duration;
  final String? instructions;

  const Medication({
    this.id,
    required this.medicationName,
    required this.dosage,
    required this.frequency,
    required this.duration,
    this.instructions,
  });

  @override
  List<Object?> get props => [
    id,
    medicationName,
    dosage,
    frequency,
    duration,
    instructions,
  ];

  Medication copyWith({
    String? id,
    String? medicationName,
    String? dosage,
    String? frequency,
    String? duration,
    String? instructions,
  }) {
    return Medication(
      id: id ?? this.id,
      medicationName: medicationName ?? this.medicationName,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      duration: duration ?? this.duration,
      instructions: instructions ?? this.instructions,
    );
  }
}

/// Medical test entity
class MedicalTest extends Equatable {
  final String? id;
  final String testName;
  final String? testReason;
  final String urgency; // 'urgent', 'normal', 'routine'

  const MedicalTest({
    this.id,
    required this.testName,
    this.testReason,
    this.urgency = 'normal',
  });

  @override
  List<Object?> get props => [id, testName, testReason, urgency];

  MedicalTest copyWith({
    String? id,
    String? testName,
    String? testReason,
    String? urgency,
  }) {
    return MedicalTest(
      id: id ?? this.id,
      testName: testName ?? this.testName,
      testReason: testReason ?? this.testReason,
      urgency: urgency ?? this.urgency,
    );
  }
}

/// Prescription entity
class Prescription extends Equatable {
  final String? id;
  final String consultationId;
  final String patientId;
  final String doctorId;
  final String diagnosis;
  final String? symptoms;
  final String? medicalNotes;
  final DateTime? followUpDate;
  final List<Medication> medications;
  final List<MedicalTest> tests;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Prescription({
    this.id,
    required this.consultationId,
    required this.patientId,
    required this.doctorId,
    required this.diagnosis,
    this.symptoms,
    this.medicalNotes,
    this.followUpDate,
    this.medications = const [],
    this.tests = const [],
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    consultationId,
    patientId,
    doctorId,
    diagnosis,
    symptoms,
    medicalNotes,
    followUpDate,
    medications,
    tests,
    createdAt,
    updatedAt,
  ];

  Prescription copyWith({
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
    return Prescription(
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
