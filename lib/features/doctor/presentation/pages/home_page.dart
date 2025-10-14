import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_theme.dart';
import '../providers/doctor_profile_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
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
        title: const Text('Dashboard'),
        actions: [
          // Online/Offline toggle
          doctorProfile.when(
            data: (doctor) {
              if (doctor == null) return const SizedBox.shrink();
              return Row(
                children: [
                  Text(
                    doctor.isOnline ? 'Online' : 'Offline',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Switch(
                    value: doctor.isOnline,
                    onChanged: (_) {
                      ref
                          .read(doctorProfileProvider.notifier)
                          .toggleOnlineStatus();
                    },
                  ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Navigate to notifications
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications coming soon!')),
              );
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
                  // Welcome card
                  Card(
                    elevation: 2,
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
                                Text(
                                  'Dr. ${doctor.fullName}',
                                  style: AppTextStyles.h3,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  doctor.specialization ?? 'Specialist',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
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
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: doctor.isOnline
                                            ? AppColors.success
                                            : AppColors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Stats cards
                  Text('Today\'s Overview', style: AppTextStyles.h4),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.people,
                          title: 'Patients',
                          value: '0',
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.video_call,
                          title: 'Consultations',
                          value: '0',
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.calendar_today,
                          title: 'Appointments',
                          value: '0',
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.attach_money,
                          title: 'Earnings',
                          value: '৳0',
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Quick actions
                  Text('Quick Actions', style: AppTextStyles.h4),
                  const SizedBox(height: AppSpacing.md),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(
                            Icons.schedule,
                            color: AppColors.primary,
                          ),
                          title: const Text('Manage Schedule'),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () {
                            // TODO: Navigate to schedule
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Schedule management coming soon!',
                                ),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(
                            Icons.edit,
                            color: AppColors.primary,
                          ),
                          title: const Text('Update Profile'),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () => context.push('/doctor/profile/edit'),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(
                            Icons.history,
                            color: AppColors.primary,
                          ),
                          title: const Text('Consultation History'),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () {
                            // TODO: Navigate to history
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Consultation history coming soon!',
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Recent consultations placeholder
                  Text('Recent Consultations', style: AppTextStyles.h4),
                  const SizedBox(height: AppSpacing.md),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 60,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'No recent consultations',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Colors.red),
                const SizedBox(height: AppSpacing.md),
                Text('Error loading profile', style: AppTextStyles.h3),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.lg),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: AppSpacing.sm),
            Text(value, style: AppTextStyles.h3.copyWith(color: color)),
            const SizedBox(height: AppSpacing.xs),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
