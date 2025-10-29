import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../core/services/image_upload_service.dart';
import '../../domain/entities/doctor.dart';
import '../providers/doctor_profile_provider.dart';

class EditDoctorProfilePage extends ConsumerStatefulWidget {
  const EditDoctorProfilePage({super.key});

  @override
  ConsumerState<EditDoctorProfilePage> createState() =>
      _EditDoctorProfilePageState();
}

class _EditDoctorProfilePageState extends ConsumerState<EditDoctorProfilePage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isUploadingImage = false;

  // Image upload
  XFile? _selectedImage;
  String? _currentProfilePictureUrl;
  late ImageUploadService _imageUploadService;

  // Controllers
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _bmdcController;
  late TextEditingController _specializationController;
  late TextEditingController _qualificationController;
  late TextEditingController _consultationFeeController;
  late TextEditingController _bioController;
  late TextEditingController _experienceController;

  // Availability schedule state
  Map<String, Map<String, dynamic>> _availabilitySchedule = {
    'monday': {'start': '09:00', 'end': '17:00', 'available': true},
    'tuesday': {'start': '09:00', 'end': '17:00', 'available': true},
    'wednesday': {'start': '09:00', 'end': '17:00', 'available': true},
    'thursday': {'start': '09:00', 'end': '17:00', 'available': true},
    'friday': {'start': '09:00', 'end': '17:00', 'available': true},
    'saturday': {'start': '09:00', 'end': '13:00', 'available': true},
    'sunday': {'start': '00:00', 'end': '00:00', 'available': false},
  };

  @override
  void initState() {
    super.initState();

    // Initialize image upload service
    _imageUploadService = ImageUploadService(Supabase.instance.client);

    // Initialize controllers
    _fullNameController = TextEditingController();
    _phoneController = TextEditingController();
    _bmdcController = TextEditingController();
    _specializationController = TextEditingController();
    _qualificationController = TextEditingController();
    _consultationFeeController = TextEditingController();
    _bioController = TextEditingController();
    _experienceController = TextEditingController();

    // Load existing profile data or user data from Supabase
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final doctorProfile = ref.read(doctorProfileProvider);
      doctorProfile.whenData((doctor) {
        if (doctor != null) {
          _fullNameController.text = doctor.fullName;
          _phoneController.text = doctor.phoneNumber ?? '';
          _bmdcController.text = doctor.bmdcRegistrationNumber;
          _specializationController.text = doctor.specialization ?? '';
          _qualificationController.text = doctor.qualification ?? '';
          _consultationFeeController.text = doctor.consultationFee.toString();
          _bioController.text = doctor.bio ?? '';
          _experienceController.text = doctor.experience?.toString() ?? '';

          // Load current profile picture
          _currentProfilePictureUrl = doctor.profilePictureUrl;

          // Load availability schedule if exists
          if (doctor.availability != null && doctor.availability!.isNotEmpty) {
            setState(() {
              _availabilitySchedule = Map<String, Map<String, dynamic>>.from(
                doctor.availability!.map(
                  (key, value) =>
                      MapEntry(key, Map<String, dynamic>.from(value as Map)),
                ),
              );
            });
          }
        } else {
          // Load user data from users table
          _loadUserData();
        }
      });
    });
  }

  Future<void> _loadUserData() async {
    try {
      final authId = Supabase.instance.client.auth.currentUser?.id;
      if (authId == null) return;

      final userData = await Supabase.instance.client
          .from('users')
          .select()
          .eq('auth_id', authId)
          .single();

      setState(() {
        _fullNameController.text = userData['full_name'] ?? '';
        _phoneController.text = userData['phone'] ?? '';
        _currentProfilePictureUrl = userData['profile_picture_url'];
      });
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final image = await _imageUploadService.pickImageFromGallery();
                if (image != null) {
                  setState(() => _selectedImage = image);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(context);
                final image = await _imageUploadService.pickImageFromCamera();
                if (image != null) {
                  setState(() => _selectedImage = image);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _bmdcController.dispose();
    _specializationController.dispose();
    _qualificationController.dispose();
    _consultationFeeController.dispose();
    _bioController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final currentProfile = ref.read(doctorProfileProvider).value;
      final authId = Supabase.instance.client.auth.currentUser?.id;

      if (authId == null) {
        throw Exception('User not authenticated');
      }

      // Upload profile image if selected
      String? uploadedImageUrl;
      if (_selectedImage != null) {
        setState(() => _isUploadingImage = true);
        try {
          // Get user ID for the upload path
          final userRecord = await Supabase.instance.client
              .from('users')
              .select('id')
              .eq('auth_id', authId)
              .single();
          final userId = userRecord['id'] as String;

          uploadedImageUrl = await _imageUploadService.uploadProfileImage(
            _selectedImage!,
            userId,
          );

          // Delete old image if exists
          if (_currentProfilePictureUrl != null &&
              _currentProfilePictureUrl!.isNotEmpty) {
            await _imageUploadService.deleteProfileImage(
              _currentProfilePictureUrl!,
            );
          }
        } catch (e) {
          print('Error uploading image: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Image upload failed: ${e.toString()}')),
            );
          }
        } finally {
          setState(() => _isUploadingImage = false);
        }
      }

      // Update profile picture in users table if uploaded
      if (uploadedImageUrl != null) {
        try {
          final userRecord = await Supabase.instance.client
              .from('users')
              .select('id')
              .eq('auth_id', authId)
              .single();
          final userId = userRecord['id'] as String;

          await Supabase.instance.client
              .from('users')
              .update({
                'profile_picture_url': uploadedImageUrl,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', userId);
        } catch (e) {
          print('Error updating profile picture in users table: $e');
        }
      }

      // Create updated doctor object
      Doctor updatedDoctor;

      if (currentProfile != null) {
        // Update existing profile
        updatedDoctor = currentProfile.copyWith(
          fullName: _fullNameController.text.trim(),
          phoneNumber: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          bmdcRegistrationNumber: _bmdcController.text.trim(),
          specialization: _specializationController.text.trim(),
          qualification: _qualificationController.text.trim(),
          consultationFee:
              double.tryParse(_consultationFeeController.text) ?? 0,
          bio: _bioController.text.trim().isEmpty
              ? null
              : _bioController.text.trim(),
          experience: int.tryParse(_experienceController.text),
          availability: _availabilitySchedule,
          // Don't pass profilePictureUrl to Doctor entity since doctors table doesn't have it
        );

        final success = await ref
            .read(doctorProfileProvider.notifier)
            .updateProfile(updatedDoctor);

        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile updated successfully!')),
            );
            context.pop();
          }
        }
      } else {
        // Complete profile for the first time
        // First, get the user.id from the users table using auth_id
        final userRecord = await Supabase.instance.client
            .from('users')
            .select('id')
            .eq('auth_id', authId)
            .single();

        final userId = userRecord['id'] as String;

        updatedDoctor = Doctor(
          id: '', // Will be set by database
          userId: userId, // Use the user.id from users table
          fullName: _fullNameController.text.trim(),
          email: Supabase.instance.client.auth.currentUser!.email!,
          phoneNumber: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          bmdcRegistrationNumber: _bmdcController.text.trim(),
          specialization: _specializationController.text.trim(),
          qualification: _qualificationController.text.trim(),
          consultationFee:
              double.tryParse(_consultationFeeController.text) ?? 0,
          bio: _bioController.text.trim().isEmpty
              ? null
              : _bioController.text.trim(),
          experience: int.tryParse(_experienceController.text),
          availability: _availabilitySchedule,
          // Don't pass profilePictureUrl to Doctor entity since doctors table doesn't have it
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final success = await ref
            .read(doctorProfileProvider.notifier)
            .completeProfile(updatedDoctor);

        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile completed successfully!')),
            );
            context.go('/doctor/home');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(icon: const Icon(Icons.check), onPressed: _saveProfile),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile picture section
              Center(
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.greyLight,
                        backgroundImage: _selectedImage != null
                            ? FileImage(File(_selectedImage!.path))
                            : (_currentProfilePictureUrl != null &&
                                          _currentProfilePictureUrl!.isNotEmpty
                                      ? CachedNetworkImageProvider(
                                          _currentProfilePictureUrl!,
                                        )
                                      : null)
                                  as ImageProvider?,
                        child:
                            _selectedImage == null &&
                                (_currentProfilePictureUrl == null ||
                                    _currentProfilePictureUrl!.isEmpty)
                            ? Icon(
                                Icons.person,
                                size: 50,
                                color: AppColors.grey,
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(AppSpacing.xs),
                          child: _isUploadingImage
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.camera_alt,
                                  size: 20,
                                  color: Colors.white,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Personal Information Section
              Text('Personal Information', style: AppTextStyles.h3),
              const SizedBox(height: AppSpacing.md),

              TextFormField(
                controller: _fullNameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your full name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Professional Information Section
              Text('Professional Information', style: AppTextStyles.h3),
              const SizedBox(height: AppSpacing.md),

              TextFormField(
                controller: _bmdcController,
                decoration: InputDecoration(
                  labelText: 'BMDC Registration Number',
                  prefixIcon: const Icon(Icons.badge),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your BMDC registration number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              TextFormField(
                controller: _specializationController,
                decoration: InputDecoration(
                  labelText: 'Specialization',
                  prefixIcon: const Icon(Icons.medical_services),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your specialization';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              TextFormField(
                controller: _qualificationController,
                decoration: InputDecoration(
                  labelText: 'Qualification',
                  prefixIcon: const Icon(Icons.school),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  hintText: 'e.g., MBBS, MD',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your qualification';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              TextFormField(
                controller: _experienceController,
                decoration: InputDecoration(
                  labelText: 'Years of Experience',
                  prefixIcon: const Icon(Icons.work),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpacing.md),

              TextFormField(
                controller: _consultationFeeController,
                decoration: InputDecoration(
                  labelText: 'Consultation Fee (৳)',
                  prefixIcon: const Icon(Icons.payments),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter consultation fee';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              TextFormField(
                controller: _bioController,
                decoration: InputDecoration(
                  labelText: 'Bio',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  hintText: 'Tell patients about yourself',
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a brief bio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // Availability Schedule Section
              Text('Availability Schedule', style: AppTextStyles.h3),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Set your available hours for each day',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              ..._buildAvailabilitySchedule(),

              const SizedBox(height: AppSpacing.xl),

              // Save button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Profile'),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  /// Build availability schedule widgets
  List<Widget> _buildAvailabilitySchedule() {
    final days = [
      {'key': 'monday', 'label': 'Monday'},
      {'key': 'tuesday', 'label': 'Tuesday'},
      {'key': 'wednesday', 'label': 'Wednesday'},
      {'key': 'thursday', 'label': 'Thursday'},
      {'key': 'friday', 'label': 'Friday'},
      {'key': 'saturday', 'label': 'Saturday'},
      {'key': 'sunday', 'label': 'Sunday'},
    ];

    return days.map((day) {
      final dayKey = day['key'] as String;
      final dayLabel = day['label'] as String;
      final daySchedule = _availabilitySchedule[dayKey]!;
      final isAvailable = daySchedule['available'] as bool;

      return Card(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      dayLabel,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    isAvailable ? 'Available' : 'Closed',
                    style: TextStyle(
                      color: isAvailable ? AppColors.success : AppColors.grey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Switch(
                    value: isAvailable,
                    onChanged: (value) {
                      setState(() {
                        _availabilitySchedule[dayKey]!['available'] = value;
                      });
                    },
                  ),
                ],
              ),
              if (isAvailable) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectTime(dayKey, 'start'),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Start Time',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                          ),
                          child: Text(
                            daySchedule['start'] as String,
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectTime(dayKey, 'end'),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'End Time',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                          ),
                          child: Text(
                            daySchedule['end'] as String,
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    }).toList();
  }

  /// Select time for availability
  Future<void> _selectTime(String dayKey, String timeType) async {
    final currentTime = _availabilitySchedule[dayKey]![timeType] as String;
    final timeParts = currentTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      setState(() {
        _availabilitySchedule[dayKey]![timeType] =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }
}
