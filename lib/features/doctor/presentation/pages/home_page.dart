import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../core/theme/theme_colors.dart';
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
      backgroundColor: context.background,
      appBar: AppBar(
        backgroundColor: context.surface,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  context.borderColor.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        title: doctorProfile.when(
          data: (doctor) {
            if (doctor == null || doctor.fullName.isEmpty) {
              return Text('Dashboard', style: AppTextStyles.h3);
            }
            final firstname = doctor.fullName.split(' ').first;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back!',
                  style: AppTextStyles.caption.copyWith(
                    color: context.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Dr. $firstname',
                  style: AppTextStyles.h3.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            );
          },
          loading: () => Text('Dashboard', style: AppTextStyles.h3),
          error: (_, __) => Text('Dashboard', style: AppTextStyles.h3),
        ),
        actions: [
          // Online/Offline toggle with modern design
          doctorProfile.when(
            data: (doctor) {
              if (doctor == null) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: doctor.isOnline
                      ? context.success.withOpacity(0.1)
                      : context.greyLight,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(
                    color: doctor.isOnline
                        ? context.success
                        : context.borderColor,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: doctor.isOnline
                            ? context.success
                            : context.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      doctor.isOnline ? 'Online' : 'Offline',
                      style: AppTextStyles.caption.copyWith(
                        color: doctor.isOnline
                            ? context.success
                            : context.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    SizedBox(
                      height: 24,
                      child: Switch(
                        value: doctor.isOnline,
                        activeColor: context.success,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onChanged: (_) {
                          ref
                              .read(doctorProfileProvider.notifier)
                              .toggleOnlineStatus();
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: doctorProfile.when(
        data: (doctor) {
          if (doctor == null) {
            // No doctor record found - show setup prompt with modern design
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    context.primaryColor.withOpacity(0.1),
                    context.background,
                  ],
                ),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: context.surface,
                      borderRadius: BorderRadius.circular(AppRadius.xxl),
                      boxShadow: [
                        BoxShadow(
                          color: context.primaryColor.withOpacity(0.1),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: context.primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.medical_services_rounded,
                            size: 64,
                            color: context.primaryColor,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Welcome, Doctor!',
                          style: AppTextStyles.h2.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Let\'s set up your profile to get started',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: context.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: context.greyLight,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildRequirementItem('BMDC Registration Number'),
                              _buildRequirementItem('Specialization'),
                              _buildRequirementItem('Qualification'),
                              _buildRequirementItem('Consultation Fee'),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => context.push('/doctor/profile/edit'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.primaryColor,
                              foregroundColor: context.onPrimary,
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadius.lg),
                              ),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.edit_rounded, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Set Up Profile',
                                  style: AppTextStyles.button,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          // Check if profile is complete
          if (!doctor.isProfileComplete) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    context.warning.withOpacity(0.1),
                    context.background,
                  ],
                ),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: context.surface,
                      borderRadius: BorderRadius.circular(AppRadius.xxl),
                      boxShadow: [
                        BoxShadow(
                          color: context.warning.withOpacity(0.1),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: context.warning.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.account_circle_rounded,
                            size: 64,
                            color: context.warning,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Complete Your Profile',
                          style: AppTextStyles.h2.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Please complete your profile to start consultations',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: context.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => context.push('/doctor/profile/edit'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.warning,
                              foregroundColor: context.onPrimary,
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadius.lg),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Complete Profile',
                              style: AppTextStyles.button,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          return RefreshIndicator(
            color: context.primaryColor,
            onRefresh: () async {
              await ref.read(doctorProfileProvider.notifier).refresh();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section header with modern styling
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          color: context.primaryColor,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Upcoming Consultations',
                        style: AppTextStyles.h3.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Horizontal scrollable consultation cards with modern design
                  SizedBox(
                    height: 210,
                    child: Consumer(
                      builder: (context, ref, _) {
                        final consultationsAsync = ref.watch(
                          upcomingConsultationsProvider,
                        );
                        final doctor = ref.watch(doctorProfileProvider).value;

                        // Load consultations only when loading and doctor is available
                        consultationsAsync.whenOrNull(
                          loading: () {
                            if (doctor != null) {
                              Future.microtask(
                                () => ref
                                    .read(
                                      upcomingConsultationsProvider.notifier,
                                    )
                                    .load(doctor.id),
                              );
                            }
                          },
                        );

                        return consultationsAsync.when(
                          data: (consultations) {
                            if (consultations.isEmpty) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: context.greyLight,
                                  borderRadius: BorderRadius.circular(AppRadius.xl),
                                  border: Border.all(
                                    color: context.borderColor,
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.calendar_today_rounded,
                                        size: 48,
                                        color: context.textSecondary.withOpacity(0.5),
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      Text(
                                        "No upcoming consultations",
                                        style: AppTextStyles.bodyMedium.copyWith(
                                          color: context.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
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
                                  consultation['scheduled_time'],
                                );
                                
                                // Format date and time separately
                                final months = [
                                  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                                  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                                ];
                                final formattedDate = '${dateTime.day} ${months[dateTime.month - 1]}, ${dateTime.year}';
                                
                                // Format time with AM/PM
                                final hour = dateTime.hour;
                                final period = hour >= 12 ? 'PM' : 'AM';
                                final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
                                final formattedTime = '${displayHour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} $period';

                                return Container(
                                  width: 260,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        context.surface,
                                        context.primaryColor.withOpacity(0.05),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(AppRadius.xl),
                                    border: Border.all(
                                      color: context.primaryColor.withOpacity(0.2),
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: context.primaryColor.withOpacity(0.08),
                                        blurRadius: 20,
                                        offset: const Offset(0, 4),
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
                                          Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: context.primaryColor,
                                                width: 2,
                                              ),
                                            ),
                                            child: CircleAvatar(
                                              radius: 26,
                                              backgroundColor: context.primaryColor.withOpacity(0.1),
                                              backgroundImage:
                                                  patient['profile_picture_url'] !=
                                                      null
                                                  ? NetworkImage(
                                                      patient['profile_picture_url'],
                                                    )
                                                  : null,
                                              child:
                                                  patient['profile_picture_url'] ==
                                                      null
                                                  ? Text(
                                                      patient['full_name'][0]
                                                          .toUpperCase(),
                                                      style: AppTextStyles.h3.copyWith(
                                                        color: context.primaryColor,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    )
                                                  : null,
                                            ),
                                          ),
                                          const SizedBox(width: AppSpacing.sm),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  patient['full_name'],
                                                  style: AppTextStyles.h4.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 2),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: context.primaryColor.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(
                                                      AppRadius.sm,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    consultation['consultation_type']
                                                        .toString()
                                                        .toUpperCase(),
                                                    style: AppTextStyles.caption.copyWith(
                                                      color: context.primaryColor,
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: AppSpacing.md),
                                      // Date information
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.sm,
                                          vertical: AppSpacing.xs + 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: context.greyLight,
                                          borderRadius: BorderRadius.circular(AppRadius.md),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_today_rounded,
                                              size: 14,
                                              color: context.textSecondary,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Date:',
                                              style: AppTextStyles.caption.copyWith(
                                                color: context.textSecondary,
                                                fontWeight: FontWeight.w500,
                                                fontSize: 11,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                formattedDate,
                                                style: AppTextStyles.bodySmall.copyWith(
                                                  color: context.textPrimary,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 11,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      // Time information
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.sm,
                                          vertical: AppSpacing.xs + 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: context.greyLight,
                                          borderRadius: BorderRadius.circular(AppRadius.md),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.access_time_rounded,
                                              size: 14,
                                              color: context.textSecondary,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Time:',
                                              style: AppTextStyles.caption.copyWith(
                                                color: context.textSecondary,
                                                fontWeight: FontWeight.w500,
                                                fontSize: 11,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              formattedTime,
                                              style: AppTextStyles.bodySmall.copyWith(
                                                color: context.textPrimary,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      const Spacer(),
                                      if (consultation['consultation_type'] ==
                                          'video')
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            onPressed: () {
                                              context.push(
                                                '/video-call/${consultation['id']}',
                                                extra: {
                                                  'patientId': patient['id'],
                                                  'patientName':
                                                      patient['full_name'],
                                                  'patientImageUrl':
                                                      patient['profile_picture_url'],
                                                },
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: context.primaryColor,
                                              foregroundColor: context.onPrimary,
                                              elevation: 0,
                                              padding: const EdgeInsets.symmetric(
                                                vertical: 12,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(
                                                  AppRadius.md,
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                const Icon(
                                                  Icons.video_call_rounded,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  'Join Call',
                                                  style: AppTextStyles.buttonSmall,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                          loading: () => Center(
                            child: CircularProgressIndicator(
                              color: context.primaryColor,
                            ),
                          ),
                          error: (error, stack) => Container(
                            decoration: BoxDecoration(
                              color: context.error.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(AppRadius.xl),
                              border: Border.all(
                                color: context.error.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline_rounded,
                                    size: 48,
                                    color: context.error.withOpacity(0.7),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    'Error loading consultations',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: context.error,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Overview section header
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          color: context.secondaryColor,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Overview',
                        style: AppTextStyles.h3.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Statistics consumer
                  Consumer(
                    builder: (context, ref, _) {
                      final statisticsAsync = ref.watch(doctorStatisticsProvider);
                      final doctor = ref.watch(doctorProfileProvider).value;

                      // Load statistics when doctor is available
                      statisticsAsync.whenOrNull(
                        loading: () {
                          if (doctor != null) {
                            Future.microtask(
                              () => ref
                                  .read(doctorStatisticsProvider.notifier)
                                  .load(doctor.id),
                            );
                          }
                        },
                      );

                      return statisticsAsync.when(
                        data: (stats) {
                          final totalPatients = stats['totalPatients'] ?? 0;
                          final scheduledConsultations = stats['scheduledConsultations'] ?? 0;
                          final totalEarnings = stats['totalEarnings'] ?? 0.0;

                          return Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      icon: Icons.people_rounded,
                                      title: 'Total Patients',
                                      value: totalPatients.toString(),
                                      color: context.info,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: _buildStatCard(
                                      icon: Icons.event_available_rounded,
                                      title: 'Scheduled Consultations',
                                      value: scheduledConsultations.toString(),
                                      color: context.secondaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _buildStatCard(
                                icon: Icons.account_balance_wallet_rounded,
                                title: 'Total Earnings',
                                value: '৳${totalEarnings.toStringAsFixed(0)}',
                                color: context.warning,
                                isFullWidth: true,
                              ),
                            ],
                          );
                        },
                        loading: () => Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildLoadingStatCard(
                                    icon: Icons.people_rounded,
                                    title: 'Total Patients',
                                    color: context.info,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: _buildLoadingStatCard(
                                    icon: Icons.event_available_rounded,
                                    title: 'Scheduled Consultations',
                                    color: context.secondaryColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _buildLoadingStatCard(
                              icon: Icons.account_balance_wallet_rounded,
                              title: 'Total Earnings',
                              color: context.warning,
                              isFullWidth: true,
                            ),
                          ],
                        ),
                        error: (error, stack) => Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    icon: Icons.people_rounded,
                                    title: 'Total Patients',
                                    value: '0',
                                    color: context.info,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: _buildStatCard(
                                    icon: Icons.event_available_rounded,
                                    title: 'Scheduled Consultations',
                                    value: '0',
                                    color: context.secondaryColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _buildStatCard(
                              icon: Icons.account_balance_wallet_rounded,
                              title: 'Total Earnings',
                              value: '৳0',
                              color: context.warning,
                              isFullWidth: true,
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(
            color: context.primaryColor,
          ),
        ),
        error: (error, stack) => Container(
          color: context.background,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: context.surface,
                  borderRadius: BorderRadius.circular(AppRadius.xxl),
                  boxShadow: [
                    BoxShadow(
                      color: context.error.withOpacity(0.1),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: context.error.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.error_outline_rounded,
                        size: 64,
                        color: context.error,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Error Loading Profile',
                      style: AppTextStyles.h2.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      error.toString(),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: context.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final authId =
                              Supabase.instance.client.auth.currentUser?.id;
                          if (authId != null) {
                            ref
                                .read(doctorProfileProvider.notifier)
                                .loadProfile(authId);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.primaryColor,
                          foregroundColor: context.onPrimary,
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.refresh_rounded, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Retry',
                              style: AppTextStyles.button,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingStatCard({
    required IconData icon,
    required String title,
    required Color color,
    bool isFullWidth = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: isFullWidth
          ? Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Container(
                        width: 120,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.greyLight,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(icon, color: color, size: 22),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        title,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: 60,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.greyLight,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
              ],
            ),
      ),
    );
  }  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    bool isFullWidth = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isFullWidth ? AppSpacing.lg : AppSpacing.lg),
        child: isFullWidth 
          ? Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        value,
                        style: AppTextStyles.h2.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.trending_up_rounded,
                        size: 14,
                        color: color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'All time',
                        style: AppTextStyles.caption.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(icon, color: color, size: 22),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        title,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  value,
                  style: AppTextStyles.h2.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
      ),
    );
  }

  Widget _buildRequirementItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
