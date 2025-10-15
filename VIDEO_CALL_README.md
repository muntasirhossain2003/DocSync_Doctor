# Video Call Feature Documentation

## Overview

This feature implements real-time video calling for doctor-patient consultations using Agora RTC SDK.

## Architecture

### Directory Structure

```
lib/features/video_call/
├── data/
│   └── services/
│       └── agora_service.dart          # Agora RTC engine wrapper
├── domain/
│   └── models/
│       └── call_state.dart             # Call state model
├── presentation/
│   ├── pages/
│   │   └── video_call_page.dart        # Main video call UI
│   ├── providers/
│   │   └── video_call_provider.dart    # State management
│   └── widgets/
│       ├── video_call_controls.dart    # Call control buttons
│       └── video_call_status.dart      # Status display widget
└── example/
    └── video_call_example.dart         # Usage examples
```

### Core Components

#### 1. AgoraConfig (`lib/core/config/agora_config.dart`)

- Manages Agora configuration from environment variables
- Validates required settings
- Provides app ID, channel name, and token

#### 2. AgoraService (`data/services/agora_service.dart`)

- Initializes Agora RTC Engine
- Handles permissions (camera, microphone)
- Manages channel join/leave operations
- Controls audio/video settings
- Registers event handlers

#### 3. CallState Model (`domain/models/call_state.dart`)

- Represents the current state of a video call
- Includes call status, participant info, and settings
- Immutable with copyWith pattern

#### 4. VideoCallProvider (`presentation/providers/video_call_provider.dart`)

- Manages call state using Riverpod
- Handles call lifecycle (start, end)
- Controls media settings (audio/video toggle)
- Tracks call duration
- Responds to Agora events

#### 5. VideoCallPage (`presentation/pages/video_call_page.dart`)

- Full-screen video call UI
- Displays local and remote video streams
- Shows call status and duration
- Provides call controls
- Handles back button with confirmation
- Keeps screen awake during call

## Setup Instructions

### 1. Dependencies

Already added to `pubspec.yaml`:

```yaml
dependencies:
  agora_rtc_engine: ^6.3.2
  permission_handler: ^11.3.0
  wakelock_plus: ^1.2.5
```

### 2. Environment Configuration

Update `.env` file with Agora credentials:

```env
AGORA_APP_ID=1b4252ea1e424682b0e7af5d512b2c8f
AGORA_CHANNEL_NAME=DocSync
AGORA_TOKEN=007eJxTYKi5MIdz8rYuz1SRY+lXDnOtdf0xf6lzptcpgdcrqhqt7DgVGAyTTIxMjVITDVNNjEzMLIySDFLNE9NMU0wNjZKMki3S/k54n9EQyMigqnOUkZEBAkF8dgaX/OTgyrxkBgYAs3ggsA==
```

### 3. Android Permissions

Added to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
```

### 4. iOS Permissions (if targeting iOS)

Add to `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access for video consultations</string>
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access for video consultations</string>
```

## Usage

### Starting a Video Call

From any widget in your app:

```dart
import 'package:go_router/go_router.dart';

// Navigate to video call page
context.push(
  '/video-call/$consultationId',
  extra: {
    'patientId': 'patient-uuid',
    'patientName': 'John Doe',
    'patientImageUrl': 'https://example.com/image.jpg',
  },
);
```

### Integration Points

#### 1. Home Page

- Consultation cards show "Join Call" button for video consultations
- Located in upcoming consultations section
- Automatically filters video-type consultations

#### 2. Consultations Page

- Video call icon button on upcoming video consultations
- Tap list item or icon to join call
- Shows consultation type in details

### Call Features

#### During a Call:

- **Video Toggle**: Turn camera on/off
- **Audio Toggle**: Mute/unmute microphone
- **Speaker Toggle**: Enable/disable speaker
- **Camera Switch**: Switch between front/back camera
- **End Call**: End the consultation
- **Call Duration**: Real-time call timer
- **Connection Status**: Visual indicators for connection state

#### UI Elements:

1. **Full-screen remote video**: Patient's video feed
2. **Picture-in-picture local video**: Doctor's video preview (top-right)
3. **Top status bar**: Patient info, call duration, connection status
4. **Bottom control bar**: Media control buttons
5. **Waiting screen**: Shown when patient hasn't joined yet

## State Management

### CallState Properties

```dart
class CallState {
  final String callId;              // Consultation ID
  final String channelName;          // Agora channel name
  final String? patientId;           // Patient's user ID
  final String? patientName;         // Patient's display name
  final String? patientImageUrl;     // Patient's profile picture
  final CallStatus status;           // Current call status
  final bool isVideoEnabled;         // Camera state
  final bool isAudioEnabled;         // Microphone state
  final bool isSpeakerEnabled;       // Speaker state
  final DateTime? startTime;         // Call start time
  final Duration? duration;          // Call duration
  final int? remoteUid;             // Remote user's Agora UID
}
```

### CallStatus Enum

- `idle`: Not in a call
- `connecting`: Joining the channel
- `connected`: Successfully connected
- `reconnecting`: Attempting to reconnect
- `disconnected`: Call ended
- `failed`: Connection failed

## API Integration

### Database Schema

The consultation must have these fields in Supabase:

```sql
consultations (
  id uuid,
  patient_id uuid,
  doctor_id uuid,
  consultation_type varchar(50),  -- 'video', 'audio', 'chat'
  scheduled_time timestamptz,
  consultation_status varchar(50)  -- 'scheduled', 'completed', 'canceled'
)
```

### Fetching Consultations

```dart
// Example query for upcoming video consultations
final consultations = await supabase
  .from('consultations')
  .select('*, patient:users!patient_id(*)')
  .eq('doctor_id', doctorId)
  .eq('consultation_type', 'video')
  .eq('consultation_status', 'scheduled')
  .gte('scheduled_time', DateTime.now().toIso8601String())
  .order('scheduled_time');
```

## Security Considerations

### Token Management

- **Current**: Static token in .env (for development)
- **Production**: Implement token server
  - Generate tokens dynamically
  - Set appropriate expiration times
  - Validate user permissions

### Best Practices

1. Never commit `.env` file to version control
2. Use different tokens for dev/staging/prod
3. Implement server-side token generation
4. Add role-based access control
5. Log all video call sessions

## Troubleshooting

### Common Issues

#### 1. Black Screen / No Video

- Check camera permissions are granted
- Ensure `.env` file is loaded
- Verify Agora credentials are correct
- Check device camera is not in use by another app

#### 2. No Audio

- Check microphone permissions
- Verify speaker is not muted
- Test device audio with other apps

#### 3. Connection Failed

- Verify internet connection
- Check Agora token is valid and not expired
- Ensure channel name matches between users

#### 4. App Crashes on Call Start

- Run `flutter clean && flutter pub get`
- Verify all dependencies are installed
- Check Android/iOS minimum SDK versions

### Debug Mode

Enable Agora SDK logs:

```dart
await _engine!.setLogLevel(LogLevel.logLevelInfo);
await _engine!.setLogFile('/path/to/log/file');
```

## Performance Optimization

### Recommendations

1. **Video Quality**: Adjust based on network conditions

   ```dart
   await _engine.setVideoEncoderConfiguration(
     VideoEncoderConfiguration(
       dimensions: VideoDimensions(width: 640, height: 480),
       frameRate: 15,
       bitrate: 0, // Auto
     ),
   );
   ```

2. **Battery Usage**:

   - Lower frame rate for longer calls
   - Reduce video resolution if needed
   - Disable video when not needed

3. **Network Usage**:
   - Monitor bandwidth
   - Implement adaptive bitrate
   - Show network quality indicators

## Future Enhancements

### Planned Features

- [ ] Screen sharing capability
- [ ] Chat during video call
- [ ] Call recording (with consent)
- [ ] Virtual backgrounds
- [ ] Beauty filters
- [ ] Multi-party video calls
- [ ] Call quality metrics
- [ ] Network quality indicators
- [ ] Picture-in-picture mode
- [ ] Call history and analytics

### Integration Opportunities

- Push notifications for incoming calls
- Calendar integration for scheduled calls
- Payment integration for consultation fees
- Prescription sharing during call
- Medical record access during consultation

## Testing

### Manual Testing Checklist

- [ ] Start video call successfully
- [ ] Toggle camera on/off
- [ ] Toggle microphone on/off
- [ ] Switch between cameras
- [ ] Toggle speaker
- [ ] End call properly
- [ ] Handle back button press
- [ ] Test with poor network conditions
- [ ] Verify call duration tracking
- [ ] Test with/without patient profile picture

### Test Scenarios

1. Doctor joins before patient
2. Patient joins before doctor
3. Network interruption during call
4. Phone call interruption
5. App backgrounded during call
6. Permission denied scenarios

## Support

For issues or questions:

1. Check Agora documentation: https://docs.agora.io
2. Review Flutter integration guide: https://docs.agora.io/en/video-calling/get-started/get-started-sdk?platform=flutter
3. Check project issues on GitHub
4. Contact development team

## License

This feature is part of DocSync Doctor application.
