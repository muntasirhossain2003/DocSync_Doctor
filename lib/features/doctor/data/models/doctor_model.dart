import '../../domain/entities/doctor.dart';

/// Doctor data model - for JSON serialization/deserialization
class DoctorModel {
  final String doctorId;
  final String userId;
  final String bmdcRegistrationNumber;
  final String? specialization;
  final String? qualification;
  final double consultationFee;
  final Map<String, dynamic>? availability;
  final bool isAvailable;
  final bool isOnline;
  final String? bio;
  final int? experience;
  final DateTime createdAt;
  final DateTime updatedAt;

  // User information (from joined users table)
  final String email;
  final String fullName;
  final String? phoneNumber;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? profilePictureUrl;

  DoctorModel({
    required this.doctorId,
    required this.userId,
    required this.bmdcRegistrationNumber,
    this.specialization,
    this.qualification,
    required this.consultationFee,
    this.availability,
    this.isAvailable = false,
    this.isOnline = false,
    this.bio,
    this.experience,
    required this.createdAt,
    required this.updatedAt,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    this.gender,
    this.dateOfBirth,
    this.profilePictureUrl,
  });

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    // Handle joined user data (can be 'user' or 'users' depending on query)
    final userData =
        json['user'] as Map<String, dynamic>? ??
        json['users'] as Map<String, dynamic>?;

    return DoctorModel(
      doctorId: json['id'] as String, // Schema uses 'id' not 'doctor_id'
      userId: json['user_id'] as String,
      bmdcRegistrationNumber: json['bmcd_registration_number'] as String,
      specialization: json['specialization'] as String?,
      qualification: json['qualification'] as String?,
      consultationFee: (json['consultation_fee'] as num?)?.toDouble() ?? 0.0,
      availability: json['availability'] as Map<String, dynamic>?,
      isAvailable: json['is_available'] as bool? ?? false,
      isOnline: json['is_online'] as bool? ?? false,
      bio: json['bio'] as String?,
      experience: json['experience'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      // User data
      email: userData?['email'] as String? ?? '',
      fullName: userData?['full_name'] as String? ?? '',
      phoneNumber:
          userData?['phone']
              as String?, // Schema uses 'phone' not 'phone_number'
      gender: userData?['gender'] as String?,
      dateOfBirth: userData?['date_of_birth'] != null
          ? DateTime.parse(userData!['date_of_birth'] as String)
          : null,
      profilePictureUrl: userData?['profile_picture_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': doctorId, // Schema uses 'id' not 'doctor_id'
      'user_id': userId,
      'bmcd_registration_number': bmdcRegistrationNumber,
      'specialization': specialization,
      'qualification': qualification,
      'consultation_fee': consultationFee,
      'availability': availability,
      'is_available': isAvailable,
      'is_online': isOnline,
      'bio': bio,
      'experience': experience,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Convert to domain entity
  Doctor toEntity() {
    return Doctor(
      id: doctorId,
      userId: userId,
      bmdcRegistrationNumber: bmdcRegistrationNumber,
      specialization: specialization,
      qualification: qualification,
      consultationFee: consultationFee,
      availability: availability,
      isAvailable: isAvailable,
      isOnline: isOnline,
      bio: bio,
      experience: experience,
      createdAt: createdAt,
      updatedAt: updatedAt,
      email: email,
      fullName: fullName,
      phoneNumber: phoneNumber,
      gender: gender,
      dateOfBirth: dateOfBirth,
      profilePictureUrl: profilePictureUrl,
    );
  }

  // Create from domain entity
  factory DoctorModel.fromEntity(Doctor doctor) {
    return DoctorModel(
      doctorId: doctor.id,
      userId: doctor.userId,
      bmdcRegistrationNumber: doctor.bmdcRegistrationNumber,
      specialization: doctor.specialization,
      qualification: doctor.qualification,
      consultationFee: doctor.consultationFee,
      availability: doctor.availability,
      isAvailable: doctor.isAvailable,
      isOnline: doctor.isOnline,
      bio: doctor.bio,
      experience: doctor.experience,
      createdAt: doctor.createdAt,
      updatedAt: doctor.updatedAt,
      email: doctor.email,
      fullName: doctor.fullName,
      phoneNumber: doctor.phoneNumber,
      gender: doctor.gender,
      dateOfBirth: doctor.dateOfBirth,
      profilePictureUrl: doctor.profilePictureUrl,
    );
  }
}
