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
      appBar: AppBar(
        title: const Text('Consultations'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildConsultationList('upcoming'),
          _buildConsultationList('completed'),
          _buildConsultationList('cancelled'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Instant consultation coming soon!')),
          );
        },
        icon: const Icon(Icons.video_call),
        label: const Text('Start Consultation'),
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
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        status == 'upcoming'
                            ? Icons.schedule
                            : status == 'completed'
                            ? Icons.check_circle_outline
                            : Icons.cancel_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text('No $status consultations'),
                      const SizedBox(height: AppSpacing.sm),
                      const Text(
                        'Your consultations will appear here',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
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
                  final patient = consultation['patient'];
                  final dateTime = DateTime.parse(
                    consultation['scheduled_time'],
                  );
                  final formattedTime =
                      '${dateTime.day}/${dateTime.month} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: patient['profile_picture_url'] != null
                            ? NetworkImage(patient['profile_picture_url'])
                            : null,
                        child: patient['profile_picture_url'] == null
                            ? Text(
                                patient['full_name'][0].toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      title: Text(patient['full_name']),
                      subtitle: Text(
                        'Time: $formattedTime\n'
                        'Type: ${consultation['consultation_type']}\n'
                        'Status: ${consultation['consultation_status']}',
                      ),
                      trailing:
                          status == 'upcoming' &&
                              consultation['consultation_type'] == 'video'
                          ? IconButton(
                              icon: const Icon(
                                Icons.video_call,
                                color: AppColors.primary,
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
                            )
                          : const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        // Navigate to consultation details
                        if (consultation['consultation_type'] == 'video' &&
                            status == 'upcoming') {
                          context.push(
                            '/video-call/${consultation['id']}',
                            extra: {
                              'patientId': patient['id'],
                              'patientName': patient['full_name'],
                              'patientImageUrl': patient['profile_picture_url'],
                            },
                          );
                        }
                      },
                    ),
                  );
                },
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
                  Text('Error loading consultations', style: AppTextStyles.h3),
                  const SizedBox(height: AppSpacing.sm),
                  Text(error.toString(), textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
