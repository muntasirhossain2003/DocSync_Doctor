import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_theme.dart';

class SchedulePage extends ConsumerStatefulWidget {
  const SchedulePage({super.key});

  @override
  ConsumerState<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends ConsumerState<SchedulePage> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Navigate to schedule settings
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Schedule settings coming soon!')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Calendar header
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            color: AppColors.primary.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _selectedDate = _selectedDate.subtract(
                        const Duration(days: 1),
                      );
                    });
                  },
                ),
                Text(
                  DateFormat('EEEE, MMMM d, y').format(_selectedDate),
                  style: AppTextStyles.h4,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _selectedDate = _selectedDate.add(
                        const Duration(days: 1),
                      );
                    });
                  },
                ),
              ],
            ),
          ),

          // Appointments list
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                // TODO: Refresh appointments
                await Future.delayed(const Duration(seconds: 1));
              },
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'No appointments scheduled',
                        style: AppTextStyles.h4.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const Text(
                        'Your appointments for this day will appear here',
                        style: TextStyle(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Add time slot
          _showAddTimeSlotDialog();
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Time Slot'),
      ),
    );
  }

  void _showAddTimeSlotDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Time Slot'),
        content: const Text('Time slot management coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
