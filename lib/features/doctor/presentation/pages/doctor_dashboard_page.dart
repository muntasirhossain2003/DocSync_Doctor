import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_theme.dart';
import '../providers/doctor_profile_provider.dart';

class DoctorDashboardPage extends ConsumerStatefulWidget {
  const DoctorDashboardPage({super.key});

  @override
  ConsumerState<DoctorDashboardPage> createState() =>
      _DoctorDashboardPageState();
}

class _DoctorDashboardPageState extends ConsumerState<DoctorDashboardPage> {
  @override
  void initState() {
    super.initState();
    // Load doctor profile when page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authId = Supabase.instance.client.auth.currentUser?.id;
      if (authId != null) {
        ref.read(doctorProfileProvider.notifier).loadProfile(authId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final doctorProfile = ref.watch(doctorProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Dashboard'),
        actions: [
          // Online/Offline toggle
          doctorProfile.when(
            data: (doctor) {
              if (doctor == null) return const SizedBox.shrink();
              return Switch(
                value: doctor.isOnline,
                onChanged: (_) {
                  ref.read(doctorProfileProvider.notifier).toggleOnlineStatus();
                },
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: doctorProfile.when(
        data: (doctor) {
          if (doctor == null) {
            // No doctor record found - show setup prompt
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.medical_services_outlined,
                      size: 100,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Welcome, Doctor!', style: AppTextStyles.h2),
                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      'Let\'s set up your doctor profile to get started.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text('Set Up Profile'),
                      onPressed: () => context.push('/doctor/profile/edit'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      'You\'ll need to provide:\n'
                      '• BMDC Registration Number\n'
                      '• Specialization\n'
                      '• Qualification\n'
                      '• Consultation Fee',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Check if profile is complete
          if (!doctor.isProfileComplete) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.account_circle,
                    size: 100,
                    color: AppColors.grey,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Complete Your Profile', style: AppTextStyles.h3),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'Please complete your profile to start consultations',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ElevatedButton(
                    onPressed: () => context.push('/doctor/profile/edit'),
                    child: const Text('Complete Profile'),
                  ),
                ],
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: doctor.profilePictureUrl != null
                                ? NetworkImage(doctor.profilePictureUrl!)
                                : null,
                            child: doctor.profilePictureUrl == null
                                ? Text(
                                    doctor.fullName.isNotEmpty
                                        ? doctor.fullName[0].toUpperCase()
                                        : 'D',
                                    style: AppTextStyles.h2,
                                  )
                                : null,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(doctor.fullName, style: AppTextStyles.h3),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  doctor.specialization ?? 'Specialist',
                                  style: AppTextStyles.bodyMedium,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
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
                                      style: AppTextStyles.bodySmall,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () =>
                                context.push('/doctor/profile/edit'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Availability toggle
                  Card(
                    child: SwitchListTile(
                      title: const Text('Available for Consultations'),
                      subtitle: Text(
                        doctor.isAvailable
                            ? 'You are currently accepting consultations'
                            : 'Toggle to start accepting consultations',
                      ),
                      value: doctor.isAvailable,
                      onChanged: (_) {
                        ref
                            .read(doctorProfileProvider.notifier)
                            .toggleAvailability();
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Stats cards
                  Text('Today\'s Overview', style: AppTextStyles.h3),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.calendar_today,
                          title: 'Appointments',
                          value: '0',
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.people,
                          title: 'Patients',
                          value: '0',
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.video_call,
                          title: 'Consultations',
                          value: '0',
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.payment,
                          title: 'Revenue',
                          value: '৳0',
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Quick actions
                  Text('Quick Actions', style: AppTextStyles.h3),
                  const SizedBox(height: AppSpacing.md),
                  _QuickActionButton(
                    icon: Icons.calendar_month,
                    label: 'View Appointments',
                    onTap: () {
                      // TODO: Navigate to appointments
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _QuickActionButton(
                    icon: Icons.people_outline,
                    label: 'My Patients',
                    onTap: () {
                      // TODO: Navigate to patients
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _QuickActionButton(
                    icon: Icons.medication,
                    label: 'Prescriptions',
                    onTap: () {
                      // TODO: Navigate to prescriptions
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _QuickActionButton(
                    icon: Icons.settings,
                    label: 'Settings',
                    onTap: () {
                      // TODO: Navigate to settings
                    },
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) {
          final errorMessage = error.toString();

          // Check if it's a "profile not found" error
          if (errorMessage.contains('Doctor profile not found') ||
              errorMessage.contains('User not found')) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.person_add_outlined,
                      size: 80,
                      color: AppColors.warning,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Profile Not Set Up', style: AppTextStyles.h2),
                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      'Your doctor profile hasn\'t been created yet.\n'
                      'Click below to set up your profile.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text('Create Profile'),
                      onPressed: () => context.push('/doctor/profile/edit'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Generic error
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 60, color: AppColors.error),
                  const SizedBox(height: AppSpacing.md),
                  Text('Error Loading Profile', style: AppTextStyles.h3),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    errorMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        onPressed: () {
                          final authId =
                              Supabase.instance.client.auth.currentUser?.id;
                          if (authId != null) {
                            ref
                                .read(doctorProfileProvider.notifier)
                                .loadProfile(authId);
                          }
                        },
                      ),
                      const SizedBox(width: AppSpacing.md),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.edit),
                        label: const Text('Set Up Profile'),
                        onPressed: () => context.push('/doctor/profile/edit'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: AppSpacing.sm),
            Text(value, style: AppTextStyles.h2.copyWith(color: color)),
            const SizedBox(height: AppSpacing.xs),
            Text(
              title,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(label),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
