import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_theme.dart';
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

  // Controllers
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _bmdcController;
  late TextEditingController _specializationController;
  late TextEditingController _qualificationController;
  late TextEditingController _consultationFeeController;
  late TextEditingController _bioController;
  late TextEditingController _experienceController;

  @override
  void initState() {
    super.initState();

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
      });
    } catch (e) {
      print('Error loading user data: $e');
    }
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
              // Profile picture section (placeholder for now)
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.greyLight,
                      child: Icon(
                        Icons.person,
                        size: 50,
                        color: AppColors.grey,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(AppSpacing.xs),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 20,
                          color: Colors.white,
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
}
