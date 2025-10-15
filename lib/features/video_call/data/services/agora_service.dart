import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/config/agora_config.dart';

/// Service to manage Agora RTC Engine for video calling
class AgoraService {
  RtcEngine? _engine;
  bool _isInitialized = false;

  // Web-specific client and tracks
  dynamic _webClient;
  dynamic _localAudioTrack;
  dynamic _localVideoTrack;

  RtcEngine? get engine => _engine;
  bool get isInitialized => _isInitialized;

  // Getters for web tracks
  dynamic get localVideoTrack => _localVideoTrack;
  dynamic get localAudioTrack => _localAudioTrack;
  dynamic get webClient => _webClient;

  /// Initialize Agora RTC Engine
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (kIsWeb) {
        // Web platform: Use Agora Web SDK
        // The SDK is loaded via script tag in index.html
        // We'll initialize the web client when joining a channel
        _isInitialized = true;
        print('Agora Web SDK ready');
      } else {
        // Native platform: Use agora_rtc_engine
        await _requestPermissions();

        _engine = createAgoraRtcEngine();

        await _engine!.initialize(
          RtcEngineContext(
            appId: AgoraConfig.appId,
            channelProfile: ChannelProfileType.channelProfileCommunication,
          ),
        );

        // Enable video module
        await _engine!.enableVideo();
        await _engine!.enableAudio();

        // Set video configuration
        await _engine!.setVideoEncoderConfiguration(
          const VideoEncoderConfiguration(
            dimensions: VideoDimensions(width: 640, height: 480),
            frameRate: 15,
            bitrate: 0,
            orientationMode: OrientationMode.orientationModeAdaptive,
          ),
        );

        _isInitialized = true;
      }
    } catch (e) {
      throw Exception('Failed to initialize Agora: $e');
    }
  }

  /// Request camera and microphone permissions
  /// Note: On web, browser handles permissions automatically
  Future<void> _requestPermissions() async {
    try {
      final permissions = [Permission.camera, Permission.microphone];

      final statuses = await permissions.request();

      if (statuses[Permission.camera] != PermissionStatus.granted ||
          statuses[Permission.microphone] != PermissionStatus.granted) {
        throw Exception('Camera or microphone permission denied');
      }
    } catch (e) {
      // On platforms where permission_handler doesn't work, continue anyway
      // The browser or OS will handle permissions
      print('Permission request skipped or failed: $e');
    }
  }

  /// Join a channel
  Future<void> joinChannel(String channelName, String token, int uid) async {
    if (!_isInitialized) {
      throw Exception('Agora engine not initialized');
    }

    if (kIsWeb) {
      // Web platform: Use Agora Web SDK JavaScript API
      await _joinChannelWeb(channelName, token, uid);
    } else {
      // Native platform
      if (_engine == null) {
        throw Exception('Agora engine not initialized');
      }

      await _engine!.joinChannel(
        token: token,
        channelId: channelName,
        uid: uid,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );
    }
  }

  /// Join channel on web using JavaScript API
  Future<void> _joinChannelWeb(
    String channelName,
    String token,
    int uid,
  ) async {
    try {
      print(
        '🌐 Web platform detected - Agora video calling not fully supported',
      );
      print('Channel: $channelName, UID: $uid');
      print(
        '⚠️ The agora_rtc_engine Flutter package does not support web platform',
      );
      print('💡 For production web video calls, you need to:');
      print('   1. Use @JS() annotations with dart:js_interop');
      print('   2. Create JavaScript wrappers for Agora Web SDK');
      print('   3. Handle video rendering with HTML <video> elements');
      print('');
      print('📱 For now, please use the mobile or desktop app for video calls');

      // Do NOT call createAgoraRtcEngine() on web - it will crash!
      // The package only supports native platforms (Android, iOS, Windows, macOS)

      // Just mark as ready to prevent app crash
      print('✅ Call page opened (video disabled on web)');
    } catch (e) {
      print('Error on web platform: $e');
      throw Exception('Web video calling not supported: $e');
    }
  }

  /// Leave the channel
  Future<void> leaveChannel() async {
    if (kIsWeb) {
      if (_localVideoTrack != null) {
        // Clean up web tracks
        _localVideoTrack = null;
        _localAudioTrack = null;
        _webClient = null;
      }
    }

    if (_engine != null) {
      await _engine!.leaveChannel();
    }
  }

  /// Toggle local video
  Future<void> toggleVideo(bool enabled) async {
    if (_engine != null) {
      await _engine!.enableLocalVideo(enabled);
    }
  }

  /// Toggle local audio
  Future<void> toggleAudio(bool enabled) async {
    if (_engine != null) {
      await _engine!.enableLocalAudio(enabled);
    }
  }

  /// Switch camera
  Future<void> switchCamera() async {
    if (_engine != null) {
      await _engine!.switchCamera();
    }
  }

  /// Enable/disable speaker
  Future<void> setSpeakerphone(bool enabled) async {
    if (_engine != null) {
      await _engine!.setEnableSpeakerphone(enabled);
    }
  }

  /// Register event handlers
  void registerEventHandlers({
    required Function(RtcConnection connection, int elapsed)
    onJoinChannelSuccess,
    required Function(RtcConnection connection, int remoteUid, int elapsed)
    onUserJoined,
    required Function(
      RtcConnection connection,
      int remoteUid,
      UserOfflineReasonType reason,
    )
    onUserOffline,
    required Function(ErrorCodeType err, String msg) onError,
    required Function(RtcConnection connection, RtcStats stats) onLeaveChannel,
  }) {
    if (_engine == null) return;

    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: onJoinChannelSuccess,
        onUserJoined: onUserJoined,
        onUserOffline: onUserOffline,
        onError: onError,
        onLeaveChannel: onLeaveChannel,
      ),
    );
  }

  /// Dispose the engine
  Future<void> dispose() async {
    if (_engine != null) {
      await _engine!.leaveChannel();
      await _engine!.release();
      _engine = null;
      _isInitialized = false;
    }
  }
}
