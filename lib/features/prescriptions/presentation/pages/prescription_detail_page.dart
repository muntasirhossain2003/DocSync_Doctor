import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_theme.dart';
import '../../domain/entities/prescription.dart';

class PrescriptionDetailPage extends StatelessWidget {
  final Prescription prescription;

  const PrescriptionDetailPage({super.key, required this.prescription});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final secondaryTextColor = isDark
        ? Colors.grey[400]
        : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'Prescription Details',
          style: AppTextStyles.h3.copyWith(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
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
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient Information Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Patient Information',
                              style: AppTextStyles.h4.copyWith(
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              prescription.patientName ?? 'Unknown Patient',
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (prescription.patientEmail != null ||
                      prescription.patientPhone != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    const Divider(),
                    const SizedBox(height: AppSpacing.md),
                    if (prescription.patientEmail != null) ...[
                      _buildInfoRow(
                        Icons.email_outlined,
                        'Email',
                        prescription.patientEmail!,
                        textColor,
                        secondaryTextColor,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    if (prescription.patientPhone != null)
                      _buildInfoRow(
                        Icons.phone_outlined,
                        'Phone',
                        prescription.patientPhone!,
                        textColor,
                        secondaryTextColor,
                      ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Prescription Information Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: AppColors.success.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: const Icon(
                          Icons.medical_information,
                          color: AppColors.success,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Prescription Details',
                              style: AppTextStyles.h4.copyWith(
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              prescription.createdAt != null
                                  ? DateFormat(
                                      'MMMM d, yyyy \'at\' h:mm a',
                                    ).format(prescription.createdAt!)
                                  : 'Date not available',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Divider(),
                  const SizedBox(height: AppSpacing.md),

                  // Diagnosis
                  _buildInfoSection(
                    'Diagnosis',
                    prescription.diagnosis,
                    textColor,
                    secondaryTextColor,
                  ),

                  if (prescription.symptoms != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    _buildInfoSection(
                      'Symptoms',
                      prescription.symptoms!,
                      textColor,
                      secondaryTextColor,
                    ),
                  ],

                  if (prescription.medicalNotes != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    _buildInfoSection(
                      'Medical Notes',
                      prescription.medicalNotes!,
                      textColor,
                      secondaryTextColor,
                    ),
                  ],

                  if (prescription.followUpDate != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    _buildInfoSection(
                      'Follow-up Date',
                      DateFormat(
                        'MMMM d, yyyy',
                      ).format(prescription.followUpDate!),
                      textColor,
                      secondaryTextColor,
                    ),
                  ],
                ],
              ),
            ),

            // Medications Section
            if (prescription.medications.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: AppColors.warning.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.warning.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: const Icon(
                            Icons.medication,
                            color: AppColors.warning,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Text(
                          'Medications (${prescription.medications.length})',
                          style: AppTextStyles.h4.copyWith(
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Divider(),
                    const SizedBox(height: AppSpacing.md),
                    ...prescription.medications.asMap().entries.map((entry) {
                      final index = entry.key;
                      final medication = entry.value;
                      return Column(
                        children: [
                          if (index > 0) const SizedBox(height: AppSpacing.md),
                          _buildMedicationCard(
                            medication,
                            textColor,
                            secondaryTextColor,
                          ),
                          if (index < prescription.medications.length - 1)
                            const SizedBox(height: AppSpacing.md),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],

            // Medical Tests Section
            if (prescription.tests.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: AppColors.info.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.info.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColors.info.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: const Icon(
                            Icons.science,
                            color: AppColors.info,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Text(
                          'Medical Tests (${prescription.tests.length})',
                          style: AppTextStyles.h4.copyWith(
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Divider(),
                    const SizedBox(height: AppSpacing.md),
                    ...prescription.tests.asMap().entries.map((entry) {
                      final index = entry.key;
                      final test = entry.value;
                      return Column(
                        children: [
                          if (index > 0) const SizedBox(height: AppSpacing.md),
                          _buildTestCard(test, textColor, secondaryTextColor),
                          if (index < prescription.tests.length - 1)
                            const SizedBox(height: AppSpacing.md),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    Color textColor,
    Color? secondaryTextColor,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: secondaryTextColor),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Row(
            children: [
              Text(
                '$label: ',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: secondaryTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: AppTextStyles.bodyMedium.copyWith(color: textColor),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(
    String title,
    String content,
    Color textColor,
    Color? secondaryTextColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.bodyMedium.copyWith(
            color: secondaryTextColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          content,
          style: AppTextStyles.bodyLarge.copyWith(color: textColor),
        ),
      ],
    );
  }

  Widget _buildMedicationCard(
    Medication medication,
    Color textColor,
    Color? secondaryTextColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.warning.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            medication.medicationName,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildMedicationDetail(
            'Dosage',
            medication.dosage,
            textColor,
            secondaryTextColor,
          ),
          _buildMedicationDetail(
            'Frequency',
            medication.frequency,
            textColor,
            secondaryTextColor,
          ),
          _buildMedicationDetail(
            'Duration',
            medication.duration,
            textColor,
            secondaryTextColor,
          ),
          if (medication.instructions != null &&
              medication.instructions!.isNotEmpty)
            _buildMedicationDetail(
              'Instructions',
              medication.instructions!,
              textColor,
              secondaryTextColor,
            ),
        ],
      ),
    );
  }

  Widget _buildMedicationDetail(
    String label,
    String value,
    Color textColor,
    Color? secondaryTextColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: AppTextStyles.bodySmall.copyWith(
                color: secondaryTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(color: textColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestCard(
    MedicalTest test,
    Color textColor,
    Color? secondaryTextColor,
  ) {
    Color urgencyColor;
    switch (test.urgency.toLowerCase()) {
      case 'urgent':
        urgencyColor = AppColors.error;
        break;
      case 'routine':
        urgencyColor = AppColors.success;
        break;
      default:
        urgencyColor = AppColors.warning;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.info.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  test.testName,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: urgencyColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  test.urgency.toUpperCase(),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: urgencyColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (test.testReason != null && test.testReason!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Reason: ${test.testReason}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: secondaryTextColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
