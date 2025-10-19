import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../doctor/presentation/providers/doctor_profile_provider.dart';
import '../../../prescriptions/presentation/pages/create_prescription_page.dart';
import '../../domain/models/call_state.dart';
import '../providers/video_call_provider.dart';
import '../widgets/video_call_controls.dart';
import '../widgets/video_call_status.dart';
import '../widgets/web_video_view.dart';

/// Video call page for doctor consultations
class VideoCallPage extends ConsumerStatefulWidget {
  final String consultationId;
  final String? patientId;
  final String? patientName;
  final String? patientImageUrl;

  const VideoCallPage({
    super.key,
    required this.consultationId,
    this.patientId,
    this.patientName,
    this.patientImageUrl,
  });

  @override
  ConsumerState<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends ConsumerState<VideoCallPage> {
  bool _isInitialized = false;
  bool _isEnding = false;
  String? _resolvedPatientId;
  String? _resolvedPatientName;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable(); // Keep screen awake during call

    // Initialize call after the first frame to avoid modifying provider during build
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _fetchConsultationData();
      _initializeCall();

      // Listen for call state changes
      ref.listenManual(videoCallProvider, (previous, next) {
        // Handle call disconnected
        if (next.status == CallStatus.disconnected &&
            _isInitialized &&
            !_isEnding &&
            mounted) {
          _navigateBack();
        }
      });
    });
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  void _navigateBack() {
    if (mounted && Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _fetchConsultationData() async {
    try {
      print('🔍 Fetching consultation data for: ${widget.consultationId}');

      final response = await Supabase.instance.client
          .from('consultations')
          .select('patient_id')
          .eq('id', widget.consultationId)
          .maybeSingle();

      print('🔍 Raw consultation response: $response');

      if (response != null && mounted) {
        final patId = response['patient_id'] as String?;

        setState(() {
          _resolvedPatientId = patId;
        });
        print('✅ Resolved patient ID: $_resolvedPatientId');

        // Fetch patient name separately if needed
        if (patId != null) {
          try {
            final patientResponse = await Supabase.instance.client
                .from('patients')
                .select('full_name')
                .eq('id', patId)
                .maybeSingle();

            if (patientResponse != null && mounted) {
              setState(() {
                _resolvedPatientName = patientResponse['full_name'] as String?;
              });
              print('✅ Resolved patient name: $_resolvedPatientName');
            }
          } catch (e) {
            print('⚠️ Could not fetch patient name: $e');
            // Continue without patient name, it's optional
          }
        }
      } else {
        print('⚠️ Consultation response is null');
      }
    } catch (e, stackTrace) {
      print('❌ Failed to fetch consultation data: $e');
      print('Stack trace: $stackTrace');
    }
  }

  Future<void> _initializeCall() async {
    try {
      print('📞 Initializing call for consultation: ${widget.consultationId}');

      await ref
          .read(videoCallProvider.notifier)
          .startCall(
            consultationId: widget.consultationId,
            patientId: widget.patientId,
            patientName: widget.patientName,
            patientImageUrl: widget.patientImageUrl,
          );

      if (mounted) {
        setState(() => _isInitialized = true);
        print('✅ Call initialization complete');
      }
    } catch (e) {
      print('❌ Call initialization failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start call: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
        // Wait a moment before popping so user can see the error
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final callState = ref.watch(videoCallProvider);
    final agoraService = ref.watch(agoraServiceProvider);

    // Show ending screen
    if (_isEnding || callState.status == CallStatus.disconnected) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // Back button at top
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (mounted && Navigator.canPop(context)) {
                          Navigator.of(context).pop();
                        }
                      },
                      icon: const Icon(Icons.arrow_back),
                      tooltip: 'Go Back',
                    ),
                  ],
                ),
              ),
              // Centered content
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.call_end, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Call Ended',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Create Prescription button
                      ElevatedButton.icon(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          var doctor = ref.read(doctorProfileProvider).value;

                          if (doctor?.id == null) {
                            final authId =
                                Supabase.instance.client.auth.currentUser?.id;
                            if (authId != null) {
                              try {
                                await ref
                                    .read(doctorProfileProvider.notifier)
                                    .loadProfile(authId);
                              } catch (e, st) {
                                print(
                                  '❌ Failed to load doctor profile before prescription: $e',
                                );
                                print('Stack trace: $st');
                              }
                              doctor = ref.read(doctorProfileProvider).value;
                            }
                          }

                          // Use resolved patient ID if widget.patientId is missing
                          final patientId =
                              widget.patientId ?? _resolvedPatientId;
                          final patientName =
                              widget.patientName ?? _resolvedPatientName;

                          print('🩺 Prescription button pressed:');
                          print('   - widget.patientId: ${widget.patientId}');
                          print('   - _resolvedPatientId: $_resolvedPatientId');
                          print('   - final patientId: $patientId');
                          print('   - doctor ID: ${doctor?.id}');

                          if (doctor?.id == null ||
                              (patientId?.isEmpty ?? true)) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Cannot create prescription. Doctor or Patient ID is missing.',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          if (!mounted) return;

                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => CreatePrescriptionPage(
                                consultationId: widget.consultationId,
                                patientId: patientId!,
                                doctorId: doctor!.id,
                                patientName: patientName,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.medication),
                        label: const Text('Create Prescription'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Back button
                      OutlinedButton.icon(
                        onPressed: () {
                          if (mounted && Navigator.canPop(context)) {
                            Navigator.of(context).pop();
                          }
                        },
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Go Back'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && !_isEnding) {
          final shouldEnd = await _showEndCallDialog();
          if (shouldEnd == true && mounted) {
            await _handleEndCall();
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Video views or web warning
            if (_isInitialized)
              if (kIsWeb)
                // Web platform warning
                Center(
                  child: Container(
                    margin: const EdgeInsets.all(32),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 64,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Video Calling Not Available on Web',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'The Agora video calling feature is only available on mobile and desktop apps.',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Please use the Android, iOS, Windows, or macOS app for video consultations.',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        if (callState.patientName != null) ...[
                          Text(
                            'Patient: ${callState.patientName}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        ElevatedButton.icon(
                          onPressed: _handleEndCall,
                          icon: const Icon(Icons.close),
                          label: const Text('Close'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (agoraService.engine != null)
                // Native platform with working video
                _buildVideoViews(callState, agoraService.engine!),

            // Call status overlay
            if (!kIsWeb)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: VideoCallStatus(callState: callState),
              ),

            // Controls overlay (hide on web since video doesn't work)
            if (!kIsWeb)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: VideoCallControls(
                  isVideoEnabled: callState.isVideoEnabled,
                  isAudioEnabled: callState.isAudioEnabled,
                  isSpeakerEnabled: callState.isSpeakerEnabled,
                  onToggleVideo: () =>
                      ref.read(videoCallProvider.notifier).toggleVideo(),
                  onToggleAudio: () =>
                      ref.read(videoCallProvider.notifier).toggleAudio(),
                  onToggleSpeaker: () =>
                      ref.read(videoCallProvider.notifier).toggleSpeaker(),
                  onSwitchCamera: () =>
                      ref.read(videoCallProvider.notifier).switchCamera(),
                  onEndCall: _handleEndCall,
                ),
              ),

            // Loading indicator
            if (!_isInitialized || callState.status == CallStatus.connecting)
              const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Connecting...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoViews(CallState callState, RtcEngine engine) {
    return Stack(
      children: [
        // Remote video (full screen)
        if (callState.remoteUid != null)
          kIsWeb
              ? WebVideoView(uid: callState.remoteUid!, isLocal: false)
              : AgoraVideoView(
                  controller: VideoViewController.remote(
                    rtcEngine: engine,
                    canvas: VideoCanvas(uid: callState.remoteUid),
                    connection: RtcConnection(channelId: callState.channelName),
                  ),
                )
        else
          // Waiting for patient
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (callState.patientImageUrl != null)
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: NetworkImage(callState.patientImageUrl!),
                  )
                else if (callState.patientName != null)
                  CircleAvatar(
                    radius: 60,
                    child: Text(
                      callState.patientName![0].toUpperCase(),
                      style: const TextStyle(fontSize: 40),
                    ),
                  ),
                const SizedBox(height: 24),
                const Text(
                  'Waiting for patient to join...',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
            ),
          ),

        // Local video (picture-in-picture)
        if (callState.isVideoEnabled)
          Positioned(
            top: 100,
            right: 16,
            child: Container(
              width: 120,
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: kIsWeb
                    ? const WebVideoView(uid: 0, isLocal: true)
                    : AgoraVideoView(
                        controller: VideoViewController(
                          rtcEngine: engine,
                          canvas: const VideoCanvas(uid: 0),
                        ),
                      ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _handleEndCall() async {
    if (_isEnding) return; // Prevent multiple calls

    setState(() => _isEnding = true);

    try {
      // End call
      await ref.read(videoCallProvider.notifier).endCall();

      // Mark consultation as completed
      await _markConsultationCompleted();
    } catch (e) {
      print('Error ending call: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error ending call: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }

    // Navigation will be handled by the listener in initState
  }

  /// Mark consultation as completed in the database
  Future<void> _markConsultationCompleted() async {
    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from('consultations')
          .update({
            'consultation_status': 'completed',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', widget.consultationId);

      print('✅ Consultation ${widget.consultationId} marked as completed');
    } catch (e) {
      print('❌ Failed to mark consultation as completed: $e');
      // Don't throw - we still want to end the call even if this fails
    }
  }

  Future<bool?> _showEndCallDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Call'),
        content: const Text('Are you sure you want to end this call?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('End Call'),
          ),
        ],
      ),
    );
  }
}
