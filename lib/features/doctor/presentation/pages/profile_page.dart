import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_theme.dart';
import '../providers/doctor_profile_provider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    final doctorProfile = ref.watch(doctorProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/doctor/profile/edit'),
          ),
        ],
      ),
      body: doctorProfile.when(
        data: (doctor) {
          if (doctor == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.account_circle,
                      size: 100,
                      color: AppColors.grey,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('No Profile Found', style: AppTextStyles.h3),
                    const SizedBox(height: AppSpacing.md),
                    ElevatedButton(
                      onPressed: () => context.push('/doctor/profile/edit'),
                      child: const Text('Create Profile'),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(doctorProfileProvider.notifier).refresh();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile picture
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: doctor.profilePictureUrl != null
                        ? NetworkImage(doctor.profilePictureUrl!)
                        : null,
                    child: doctor.profilePictureUrl == null
                        ? Text(
                            doctor.fullName.isNotEmpty
                                ? doctor.fullName[0].toUpperCase()
                                : 'D',
                            style: const TextStyle(fontSize: 40),
                          )
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Name and specialization
                  Text('Dr. ${doctor.fullName}', style: AppTextStyles.h2),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    doctor.specialization ?? 'Specialist',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: doctor.isOnline
                              ? AppColors.success
                              : AppColors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        doctor.isOnline ? 'Online' : 'Offline',
                        style: TextStyle(
                          fontSize: 14,
                          color: doctor.isOnline
                              ? AppColors.success
                              : AppColors.grey,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Profile information cards
                  _buildInfoCard(
                    title: 'Personal Information',
                    children: [
                      _buildInfoRow('Email', doctor.email),
                      if (doctor.phoneNumber != null)
                        _buildInfoRow('Phone', doctor.phoneNumber!),
                      if (doctor.gender != null)
                        _buildInfoRow('Gender', doctor.gender!),
                      if (doctor.dateOfBirth != null)
                        _buildInfoRow(
                          'Date of Birth',
                          '${doctor.dateOfBirth!.day}/${doctor.dateOfBirth!.month}/${doctor.dateOfBirth!.year}',
                        ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.md),

                  _buildInfoCard(
                    title: 'Professional Information',
                    children: [
                      _buildInfoRow(
                        'BMDC Registration',
                        doctor.bmdcRegistrationNumber,
                      ),
                      if (doctor.qualification != null)
                        _buildInfoRow('Qualification', doctor.qualification!),
                      _buildInfoRow(
                        'Consultation Fee',
                        '৳${doctor.consultationFee.toStringAsFixed(0)}',
                      ),
                      if (doctor.experience != null)
                        _buildInfoRow(
                          'Experience',
                          '${doctor.experience} years',
                        ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.md),

                  if (doctor.bio != null && doctor.bio!.isNotEmpty)
                    _buildInfoCard(
                      title: 'About',
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          child: Text(
                            doctor.bio!,
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: AppSpacing.lg),

                  // Settings and actions
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(
                            Icons.settings,
                            color: AppColors.primary,
                          ),
                          title: const Text('Settings'),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Settings coming soon!'),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(
                            Icons.help,
                            color: AppColors.primary,
                          ),
                          title: const Text('Help & Support'),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Help & Support coming soon!'),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(
                            Icons.privacy_tip,
                            color: AppColors.primary,
                          ),
                          title: const Text('Privacy Policy'),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Privacy Policy coming soon!'),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.logout, color: Colors.red),
                          title: const Text(
                            'Logout',
                            style: TextStyle(color: Colors.red),
                          ),
                          onTap: () => _showLogoutDialog(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Version info
                  Text(
                    'DocSync Doctor v1.0.0',
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: AppSpacing.md),
              Text('Error loading profile', style: AppTextStyles.h3),
              const SizedBox(height: AppSpacing.sm),
              Text(error.toString(), textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                onPressed: () {
                  final authId = Supabase.instance.client.auth.currentUser?.id;
                  if (authId != null) {
                    ref
                        .read(doctorProfileProvider.notifier)
                        .loadProfile(authId);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.h4),
            const SizedBox(height: AppSpacing.md),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(child: Text(value, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                Navigator.pop(context);
                context.go('/login');
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
