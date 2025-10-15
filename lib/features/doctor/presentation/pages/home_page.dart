import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/doctor_remote_datasource.dart';
import '../../../../core/constants/app_theme.dart';
import '../providers/doctor_profile_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();

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
        title: doctorProfile.when(
          data: (doctor) {
            if (doctor == null || doctor.fullName.isEmpty) {
              return const Text('Dashboard');
            }
            final firstname = doctor.fullName.split(' ').first;
            return Text('Welcome Dr. $firstname!');
          },
          loading: () => const Text('Dashboard'),
          error: (_, __) => const Text('Dashboard'),
        ),
        actions: [
          // Online/Offline toggle
          // doctorProfile.when(
          //   data: (doctor) {
          //     if (doctor == null) return const SizedBox.shrink();
          //     return Row(
          //       children: [
          //         Text(
          //           doctor.isOnline ? 'Online' : 'Offline',
          //           style: const TextStyle(fontSize: 12),
          //         ),
          //         Switch(
          //           value: doctor.isOnline,
          //           onChanged: (_) {
          //             ref
          //                 .read(doctorProfileProvider.notifier)
          //                 .toggleOnlineStatus();
          //           },
          //         ),
          //       ],
          //     );
          //   },
          //   loading: () => const SizedBox.shrink(),
          //   error: (_, __) => const SizedBox.shrink(),
          // ),
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
                  // Show upcoming consultations
                  Text(
                    'Upcoming Consultations',
                    style: AppTextStyles.h4,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Horizontal scrollable consultation cards
                  SizedBox(
                    height: 160,
                    child: Consumer(
                      builder: (context, ref, _) {
                        final consultationsAsync =
                            ref.watch(upcomingConsultationsProvider);
                        final doctor =
                            ref.watch(doctorProfileProvider).value;

                        if (doctor != null) {
                          ref
                              .read(upcomingConsultationsProvider.notifier)
                              .load(doctor.id);
                        }

                        return consultationsAsync.when(
                          data: (consultations) {
                            if (consultations.isEmpty) {
                              return const Center(
                                  child: Text("No upcoming consultations!"));
                            }

                            return ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: consultations.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: AppSpacing.md),
                              itemBuilder: (context, index) {
                                final consultation = consultations[index];
                                final patient = consultation['patient'];
                                final dateTime = DateTime.parse(
                                    consultation['scheduled_time']);
                                final formattedTime =
                                    '${dateTime.day}/${dateTime.month} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';

                                return Container(
                                  width: 220,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 24,
                                            backgroundImage: patient[
                                                        'profile_picture_url'] !=
                                                    null
                                                ? NetworkImage(patient[
                                                    'profile_picture_url'])
                                                : null,
                                            child: patient['profile_picture_url'] ==
                                                    null
                                                ? Text(
                                                    patient['full_name'][0]
                                                        .toUpperCase(),
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 18,
                                                    ),
                                                  )
                                                : null,
                                          ),
                                          const SizedBox(width: AppSpacing.sm),
                                          Expanded(
                                            child: Text(
                                              patient['full_name'],
                                              style: AppTextStyles.h4,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Spacer(),
                                      Text(
                                        'Time: $formattedTime',
                                        style: AppTextStyles.bodyMedium
                                            .copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      Text(
                                        'Status: ${consultation['consultation_status']}',
                                        style: AppTextStyles.bodySmall
                                            .copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (error, stack) => Center(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.error_outline,
                                      size: 60, color: Colors.red),
                                  const SizedBox(height: AppSpacing.md),
                                  Text('Error loading consultations',
                                      style: AppTextStyles.h3),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    error.toString(),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Stats cards
                  Text('Overview', style: AppTextStyles.h4),
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
