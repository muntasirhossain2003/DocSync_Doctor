import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../doctor/presentation/providers/doctor_profile_provider.dart';

class ConsultationsPage extends ConsumerStatefulWidget {
  const ConsultationsPage({super.key});

  @override
  ConsumerState<ConsultationsPage> createState() => _ConsultationsPageState();
}

class _ConsultationsPageState extends ConsumerState<ConsultationsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Load consultations after first frame when doctor is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final doctor = ref.read(doctorProfileProvider).value;
      if (doctor != null) {
        ref.read(upcomingConsultationsProvider.notifier).load(doctor.id);
        ref.read(completedConsultationsProvider.notifier).load(doctor.id);
        ref.read(cancelledConsultationsProvider.notifier).load(doctor.id);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppColors.border.withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  TabBar(
                    controller: _tabController,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicatorColor: AppColors.primary,
                    indicatorWeight: 3,
                    labelStyle: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.schedule_rounded, size: 20),
                        text: 'Upcoming',
                      ),
                      Tab(
                        icon: Icon(Icons.check_circle_rounded, size: 20),
                        text: 'Completed',
                      ),
                      Tab(
                        icon: Icon(Icons.cancel_rounded, size: 20),
                        text: 'Cancelled',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildConsultationList('upcoming'),
                _buildConsultationList('completed'),
                _buildConsultationList('cancelled'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationList(String status) {
    return Consumer(
      builder: (context, ref, _) {
        final doctor = ref.watch(doctorProfileProvider).value;

        // Select the right provider based on status
        final consultationsAsync = switch (status) {
          'upcoming' => ref.watch(upcomingConsultationsProvider),
          'completed' => ref.watch(completedConsultationsProvider),
          'cancelled' => ref.watch(cancelledConsultationsProvider),
          _ => ref.watch(upcomingConsultationsProvider),
        };

        return consultationsAsync.when(
          data: (consultations) {
            if (consultations.isEmpty) {
              return _buildEmptyState(status);
            }

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                if (doctor?.id != null) {
                  switch (status) {
                    case 'upcoming':
                      await ref
                          .read(upcomingConsultationsProvider.notifier)
                          .load(doctor!.id);
                      break;
                    case 'completed':
                      await ref
                          .read(completedConsultationsProvider.notifier)
                          .load(doctor!.id);
                      break;
                    case 'cancelled':
                      await ref
                          .read(cancelledConsultationsProvider.notifier)
                          .load(doctor!.id);
                      break;
                  }
                }
              },
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: consultations.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) {
                  final consultation = consultations[index];
                  return _buildConsultationCard(
                    consultation: consultation,
                    status: status,
                    context: context,
                  );
                },
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (error, stack) => _buildErrorState(error.toString()),
        );
      },
    );
  }

  Widget _buildEmptyState(String status) {
    final config = _getStatusConfig(status);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.xxl),
            boxShadow: [
              BoxShadow(
                color: config['color'].withOpacity(0.1),
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
                  color: config['color'].withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(config['icon'], size: 64, color: config['color']),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'No ${status.capitalize()} Consultations',
                style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                config['emptyMessage'],
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.xxl),
            boxShadow: [
              BoxShadow(
                color: AppColors.error.withOpacity(0.1),
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
                  color: AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 64,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Error Loading Data',
                style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                error,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConsultationCard({
    required Map<String, dynamic> consultation,
    required String status,
    required BuildContext context,
  }) {
    final patient = consultation['patient'];
    // Parse as UTC and convert to local time
    final dateTime = DateTime.parse(consultation['scheduled_time']).toLocal();
    final consultationType = consultation['consultation_type'];
    final consultationStatus = consultation['consultation_status'];

    // Format date and time
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final formattedDate =
        '${dateTime.day} ${months[dateTime.month - 1]}, ${dateTime.year}';

    // Format time with AM/PM
    final hour = dateTime.hour;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final formattedTime =
        '${displayHour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} $period';

    final statusConfig = _getStatusConfig(status);
    final typeConfig = _getTypeConfig(consultationType);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: statusConfig['color'].withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: statusConfig['color'].withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          onTap: status == 'upcoming' && consultationType == 'video'
              ? () {
                  context.push(
                    '/video-call/${consultation['id']}',
                    extra: {
                      'patientId': patient['id'],
                      'patientName': patient['full_name'],
                      'patientImageUrl': patient['profile_picture_url'],
                    },
                  );
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                // Patient info row
                Row(
                  children: [
                    // Avatar with border
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: statusConfig['color'],
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: statusConfig['color'].withOpacity(0.1),
                        backgroundImage: patient['profile_picture_url'] != null
                            ? NetworkImage(patient['profile_picture_url'])
                            : null,
                        child: patient['profile_picture_url'] == null
                            ? Text(
                                patient['full_name'][0].toUpperCase(),
                                style: AppTextStyles.h3.copyWith(
                                  color: statusConfig['color'],
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    // Patient name and status
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
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: statusConfig['color'].withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.sm,
                                  ),
                                ),
                                child: Text(
                                  consultationStatus.toString().toUpperCase(),
                                  style: AppTextStyles.caption.copyWith(
                                    color: statusConfig['color'],
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: typeConfig['color'].withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.sm,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      typeConfig['icon'],
                                      size: 10,
                                      color: typeConfig['color'],
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      consultationType.toString().toUpperCase(),
                                      style: AppTextStyles.caption.copyWith(
                                        color: typeConfig['color'],
                                        fontWeight: FontWeight.w600,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Action button for upcoming video calls
                    if (status == 'upcoming' && consultationType == 'video')
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.video_call_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          onPressed: () {
                            context.push(
                              '/video-call/${consultation['id']}',
                              extra: {
                                'patientId': patient['id'],
                                'patientName': patient['full_name'],
                                'patientImageUrl':
                                    patient['profile_picture_url'],
                              },
                            );
                          },
                          tooltip: 'Join Video Call',
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                // Divider
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppColors.border.withOpacity(0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // Date and time row
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoChip(
                        icon: Icons.calendar_today_rounded,
                        label: 'Date',
                        value: formattedDate,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _buildInfoChip(
                        icon: Icons.access_time_rounded,
                        label: 'Time',
                        value: formattedTime,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.greyLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getStatusConfig(String status) {
    switch (status) {
      case 'upcoming':
        return {
          'color': AppColors.primary,
          'icon': Icons.schedule_rounded,
          'emptyMessage':
              'No upcoming appointments scheduled.\nNew consultations will appear here.',
        };
      case 'completed':
        return {
          'color': AppColors.success,
          'icon': Icons.check_circle_rounded,
          'emptyMessage':
              'No completed consultations yet.\nCompleted appointments will appear here.',
        };
      case 'cancelled':
        return {
          'color': AppColors.error,
          'icon': Icons.cancel_rounded,
          'emptyMessage':
              'No cancelled consultations.\nCancelled appointments will appear here.',
        };
      default:
        return {
          'color': AppColors.grey,
          'icon': Icons.info_rounded,
          'emptyMessage': 'No consultations found.',
        };
    }
  }

  Map<String, dynamic> _getTypeConfig(String type) {
    switch (type) {
      case 'video':
        return {'color': AppColors.primary, 'icon': Icons.videocam_rounded};
      case 'audio':
        return {'color': AppColors.secondary, 'icon': Icons.phone_rounded};
      case 'chat':
        return {'color': AppColors.info, 'icon': Icons.chat_rounded};
      default:
        return {'color': AppColors.grey, 'icon': Icons.help_rounded};
    }
  }
}

// Extension to capitalize strings
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
