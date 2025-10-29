import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../doctor/presentation/providers/doctor_profile_provider.dart';
import '../../domain/entities/prescription.dart';
import '../providers/prescription_provider.dart';

class CreatePrescriptionPage extends ConsumerStatefulWidget {
  final String consultationId;
  final String patientId;
  final String doctorId;
  final String? patientName;

  const CreatePrescriptionPage({
    super.key,
    required this.consultationId,
    required this.patientId,
    required this.doctorId,
    this.patientName,
  });

  @override
  ConsumerState<CreatePrescriptionPage> createState() =>
      _CreatePrescriptionPageState();
}

class _CreatePrescriptionPageState
    extends ConsumerState<CreatePrescriptionPage> {
  final _formKey = GlobalKey<FormState>();
  final _diagnosisController = TextEditingController();
  final _symptomsController = TextEditingController();
  final _notesController = TextEditingController();
  final _medicalNotesController = TextEditingController();

  DateTime? _followUpDate;
  final List<Medication> _medications = [];
  final List<MedicalTest> _tests = [];

  @override
  void dispose() {
    _diagnosisController.dispose();
    _symptomsController.dispose();
    _notesController.dispose();
    _medicalNotesController.dispose();
    super.dispose();
  }

  void _addMedication() {
    showDialog(
      context: context,
      builder: (context) => _MedicationDialog(
        onAdd: (medication) {
          setState(() => _medications.add(medication));
        },
      ),
    );
  }

  void _addTest() {
    showDialog(
      context: context,
      builder: (context) => _TestDialog(
        onAdd: (test) {
          setState(() => _tests.add(test));
        },
      ),
    );
  }

  void _savePrescription() async {
    if (!_formKey.currentState!.validate()) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final doctorState = ref.read(doctorProfileProvider);
    final providerDoctorId = doctorState.value?.id ?? '';
    final resolvedDoctorId = widget.doctorId.isNotEmpty
        ? widget.doctorId
        : providerDoctorId;
    final trimmedPatientId = widget.patientId.trim();

    // --- DETAILED LOGGING ---
    print('🩺 Attempting to save prescription...');
    print('   - Patient ID from widget: ${widget.patientId}');
    print('   - Doctor ID from widget: ${widget.doctorId}');
    print('   - Doctor ID from provider: $providerDoctorId');
    print('   - Resolved doctor ID: $resolvedDoctorId');
    // --- END LOGGING ---

    if (resolvedDoctorId.isEmpty || trimmedPatientId.isEmpty) {
      String errorMessage;
      if (resolvedDoctorId.isEmpty && trimmedPatientId.isEmpty) {
        errorMessage =
            'Cannot create prescription. Doctor and Patient ID are both missing.';
      } else if (resolvedDoctorId.isEmpty) {
        errorMessage = 'Cannot create prescription. Doctor ID is missing.';
      } else {
        errorMessage = 'Cannot create prescription. Patient ID is missing.';
      }
      print('❌ ERROR: $errorMessage');
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
      return;
    }

    final diagnosis = _diagnosisController.text.trim();
    final symptomsText = _symptomsController.text.trim();
    final notesText = _medicalNotesController.text.trim();

    final prescription = Prescription(
      consultationId: widget.consultationId,
      patientId: trimmedPatientId,
      doctorId: resolvedDoctorId,
      diagnosis: diagnosis,
      symptoms: symptomsText.isEmpty ? null : symptomsText,
      medicalNotes: notesText.isEmpty ? null : notesText,
      followUpDate: _followUpDate,
      medications: List<Medication>.from(_medications),
      tests: List<MedicalTest>.from(_tests),
    );

    try {
      await ref
          .read(prescriptionNotifierProvider.notifier)
          .createPrescription(prescription);

      ref.invalidate(prescriptionsProvider);

      if (mounted) {
        print('✅✅✅ Prescription created successfully! ✅✅✅');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prescription saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } on PostgrestException catch (e) {
      print('❌❌❌ UI CAUGHT PostgrestException ❌❌❌');
      print('   Message: ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e, st) {
      print('❌❌❌ UI CAUGHT Generic Exception ❌❌❌');
      print('   Error: $e');
      print('   Stack Trace: $st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final prescriptionState = ref.watch(prescriptionNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Create Prescription'), elevation: 0),
      body: prescriptionState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Patient info
                    if (widget.patientName != null)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(Icons.person, color: Colors.blue),
                              const SizedBox(width: 12),
                              Text(
                                'Patient: ${widget.patientName}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Diagnosis
                    TextFormField(
                      controller: _diagnosisController,
                      decoration: const InputDecoration(
                        labelText: 'Diagnosis *',
                        hintText: 'Enter primary diagnosis',
                        prefixIcon: Icon(Icons.medical_information),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter diagnosis';
                        }
                        return null;
                      },
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),

                    // Symptoms
                    TextFormField(
                      controller: _symptomsController,
                      decoration: const InputDecoration(
                        labelText: 'Symptoms',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _medicalNotesController,
                      decoration: const InputDecoration(
                        labelText: 'Medical Notes',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.event),
                      title: const Text('Follow-up Date'),
                      subtitle: _followUpDate != null
                          ? Text(
                              DateFormat('MMM d, yyyy').format(_followUpDate!),
                            )
                          : const Text('Not set'),
                      trailing: _followUpDate != null
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () =>
                                  setState(() => _followUpDate = null),
                            )
                          : null,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(
                            const Duration(days: 7),
                          ),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (date != null) {
                          setState(() => _followUpDate = date);
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    // Medications section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Medications',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _addMedication,
                          icon: const Icon(Icons.add),
                          label: const Text('Add'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_medications.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Text(
                              'No medications added',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        ),
                      )
                    else
                      ..._medications.asMap().entries.map((entry) {
                        final index = entry.key;
                        final med = entry.value;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(Icons.medication),
                            title: Text(med.medicationName),
                            subtitle: Text(
                              '${med.dosage} • ${med.frequency} • ${med.duration}',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() => _medications.removeAt(index));
                              },
                            ),
                          ),
                        );
                      }),

                    const SizedBox(height: 24),

                    // Medical tests section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recommended Tests',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _addTest,
                          icon: const Icon(Icons.add),
                          label: const Text('Add'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_tests.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Text(
                              'No tests added',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        ),
                      )
                    else
                      ..._tests.asMap().entries.map((entry) {
                        final index = entry.key;
                        final test = entry.value;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(Icons.science),
                            title: Text(test.testName),
                            subtitle: test.testReason != null
                                ? Text(test.testReason!)
                                : null,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getUrgencyColor(test.urgency),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    test.urgency.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    setState(() => _tests.removeAt(index));
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      }),

                    const SizedBox(height: 32),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: prescriptionState.isLoading
                            ? null
                            : _savePrescription,
                        icon: const Icon(Icons.save),
                        label: const Text(
                          'Save Prescription',
                          style: TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  Color _getUrgencyColor(String urgency) {
    switch (urgency) {
      case 'urgent':
        return Colors.red;
      case 'normal':
        return Colors.orange;
      case 'routine':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

class _MedicationDialog extends StatefulWidget {
  final Function(Medication) onAdd;

  const _MedicationDialog({required this.onAdd});

  @override
  State<_MedicationDialog> createState() => __MedicationDialogState();
}

class __MedicationDialogState extends State<_MedicationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _frequencyController = TextEditingController();
  final _durationController = TextEditingController();
  final _instructionsController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Medication'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Medication Name *',
                  hintText: 'e.g., Paracetamol',
                ),
                validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
              ),
              TextFormField(
                controller: _dosageController,
                decoration: const InputDecoration(
                  labelText: 'Dosage *',
                  hintText: 'e.g., 500mg',
                ),
                validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
              ),
              TextFormField(
                controller: _frequencyController,
                decoration: const InputDecoration(
                  labelText: 'Frequency *',
                  hintText: 'e.g., 3 times daily',
                ),
                validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
              ),
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(
                  labelText: 'Duration *',
                  hintText: 'e.g., 7 days',
                ),
                validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
              ),
              TextFormField(
                controller: _instructionsController,
                decoration: const InputDecoration(
                  labelText: 'Instructions',
                  hintText: 'e.g., Take after meals',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onAdd(
                Medication(
                  medicationName: _nameController.text.trim(),
                  dosage: _dosageController.text.trim(),
                  frequency: _frequencyController.text.trim(),
                  duration: _durationController.text.trim(),
                  instructions: _instructionsController.text.trim().isEmpty
                      ? null
                      : _instructionsController.text.trim(),
                ),
              );
              Navigator.pop(context);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class _TestDialog extends StatefulWidget {
  final Function(MedicalTest) onAdd;

  const _TestDialog({required this.onAdd});

  @override
  _TestDialogState createState() => _TestDialogState();
}

class _TestDialogState extends State<_TestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _reasonController = TextEditingController();
  String _urgency = 'normal';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Medical Test'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Test Name'),
              validator: (value) =>
                  value!.isEmpty ? 'Please enter a test name' : null,
            ),
            TextFormField(
              controller: _reasonController,
              decoration: const InputDecoration(labelText: 'Reason'),
            ),
            DropdownButtonFormField<String>(
              value: _urgency,
              decoration: const InputDecoration(labelText: 'Urgency'),
              items: const [
                DropdownMenuItem(value: 'routine', child: Text('Routine')),
                DropdownMenuItem(value: 'normal', child: Text('Normal')),
                DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _urgency = value);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onAdd(
                MedicalTest(
                  testName: _nameController.text.trim(),
                  testReason: _reasonController.text.trim().isEmpty
                      ? null
                      : _reasonController.text.trim(),
                  urgency: _urgency,
                ),
              );
              Navigator.pop(context);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
