import 'package:equatable/equatable.dart';

/// Doctor entity - represents the business object
class Doctor extends Equatable {
  final String id;
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

  // User information (from users table)
  final String email;
  final String fullName;
  final String? phoneNumber;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? profilePictureUrl;

  const Doctor({
    required this.id,
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

  @override
  List<Object?> get props => [
    id,
    userId,
    bmdcRegistrationNumber,
    specialization,
    qualification,
    consultationFee,
    availability,
    isAvailable,
    isOnline,
    bio,
    experience,
    createdAt,
    updatedAt,
    email,
    fullName,
    phoneNumber,
    gender,
    dateOfBirth,
    profilePictureUrl,
  ];

  Doctor copyWith({
    String? id,
    String? userId,
    String? bmdcRegistrationNumber,
    String? specialization,
    String? qualification,
    double? consultationFee,
    Map<String, dynamic>? availability,
    bool? isAvailable,
    bool? isOnline,
    String? bio,
    int? experience,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? email,
    String? fullName,
    String? phoneNumber,
    String? gender,
    DateTime? dateOfBirth,
    String? profilePictureUrl,
  }) {
    return Doctor(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bmdcRegistrationNumber:
          bmdcRegistrationNumber ?? this.bmdcRegistrationNumber,
      specialization: specialization ?? this.specialization,
      qualification: qualification ?? this.qualification,
      consultationFee: consultationFee ?? this.consultationFee,
      availability: availability ?? this.availability,
      isAvailable: isAvailable ?? this.isAvailable,
      isOnline: isOnline ?? this.isOnline,
      bio: bio ?? this.bio,
      experience: experience ?? this.experience,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
    );
  }

  /// Check if doctor profile is complete
  bool get isProfileComplete {
    return bmdcRegistrationNumber.isNotEmpty &&
        specialization != null &&
        specialization!.isNotEmpty &&
        qualification != null &&
        qualification!.isNotEmpty &&
        consultationFee > 0 &&
        bio != null &&
        bio!.isNotEmpty;
  }

  /// Check if doctor has availability hours set
  bool get hasAvailability {
    return availability != null && availability!.isNotEmpty;
  }
}
