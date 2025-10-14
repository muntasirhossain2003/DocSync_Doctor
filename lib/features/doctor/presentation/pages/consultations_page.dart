import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_theme.dart';

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
          // TODO: Start instant consultation
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
    // TODO: Fetch consultations from Supabase
    return RefreshIndicator(
      onRefresh: () async {
        // TODO: Implement refresh
        await Future.delayed(const Duration(seconds: 1));
      },
      child: Center(
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
              Text(
                'No ${status} consultations',
                style: AppTextStyles.h4.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Your consultations will appear here',
                style: TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
