# Video Call Feature Installation Guide

## ✅ Completed Setup

### 1. Dependencies Added

The following packages have been added to `pubspec.yaml`:

- ✅ `agora_rtc_engine: ^6.3.2` - Agora video calling SDK
- ✅ `permission_handler: ^11.3.0` - Handle camera/microphone permissions
- ✅ `wakelock_plus: ^1.2.5` - Keep screen awake during calls

### 2. Environment Variables

The `.env` file has been updated with Agora credentials:

```env
AGORA_APP_ID=1b4252ea1e424682b0e7af5d512b2c8f
AGORA_CHANNEL_NAME=DocSync
AGORA_TOKEN=007eJxTYKi5MIdz8rYuz1SRY+lXDnOtdf0xf6lzptcpgdcrqhqt7DgVGAyTTIxMjVITDVNNjEzMLIySDFLNE9NMU0wNjZKMki3S/k54n9EQyMigqnOUkZEBAkF8dgaX/OTgyrxkBgYAs3ggsA==
```

### 3. Android Permissions

Required permissions have been added to `android/app/src/main/AndroidManifest.xml`:

- ✅ Camera access
- ✅ Microphone access
- ✅ Audio settings modification
- ✅ Network access
- ✅ Wake lock

### 4. Feature Structure Created

```
lib/features/video_call/
├── data/services/agora_service.dart
├── domain/models/call_state.dart
├── presentation/
│   ├── pages/video_call_page.dart
│   ├── providers/video_call_provider.dart
│   └── widgets/
│       ├── video_call_controls.dart
│       └── video_call_status.dart
└── example/video_call_example.dart
```

### 5. Core Configuration

- ✅ `lib/core/config/agora_config.dart` - Agora configuration manager
- ✅ Router updated with video call route
- ✅ Home page integrated with "Join Call" buttons
- ✅ Consultations page integrated with video call access

## 📱 Next Steps

### For iOS (if targeting iOS):

1. **Add permissions to Info.plist**

   Open `ios/Runner/Info.plist` and add:

   ```xml
   <key>NSCameraUsageDescription</key>
   <string>DocSync needs camera access for video consultations with patients</string>
   <key>NSMicrophoneUsageDescription</key>
   <string>DocSync needs microphone access for video consultations with patients</string>
   ```

2. **Update minimum iOS version**

   In `ios/Podfile`, ensure:

   ```ruby
   platform :ios, '12.0'
   ```

### Testing the Feature:

1. **Run on a physical device** (required for camera/microphone):

   ```bash
   flutter run
   ```

2. **Test video call flow**:
   - Log in as a doctor
   - Navigate to Home page
   - Look for upcoming video consultations
   - Click "Join Call" button
   - Grant camera and microphone permissions
   - Test call controls (video, audio, speaker, camera switch)

### Creating Test Data:

To test video calls, you need consultations in the database. Use this SQL:

```sql
-- Insert a test video consultation
INSERT INTO consultations (
  id,
  patient_id,
  doctor_id,
  consultation_type,
  scheduled_time,
  consultation_status,
  created_at
) VALUES (
  uuid_generate_v4(),
  'patient-uuid-here',  -- Replace with actual patient ID
  'doctor-uuid-here',   -- Replace with actual doctor ID
  'video',
  NOW() + interval '5 minutes',  -- Schedule for 5 minutes from now
  'scheduled',
  NOW()
);
```

## 🎯 Usage Examples

### 1. From Home Page

The home page automatically shows "Join Call" buttons on video consultation cards.

### 2. From Consultations Page

Video consultations in the "Upcoming" tab show a video call icon. Click it to join.

### 3. Programmatically

```dart
import 'package:go_router/go_router.dart';

// Start a video call
context.push(
  '/video-call/$consultationId',
  extra: {
    'patientId': patient.id,
    'patientName': patient.fullName,
    'patientImageUrl': patient.profilePictureUrl,
  },
);
```

## 🔧 Configuration Options

### Agora Settings

Edit `lib/core/config/agora_config.dart` if you need to:

- Change channel naming convention
- Implement dynamic token generation
- Add additional validation

### Video Quality

Adjust in `lib/features/video_call/data/services/agora_service.dart`:

```dart
await _engine!.setVideoEncoderConfiguration(
  const VideoEncoderConfiguration(
    dimensions: VideoDimensions(width: 640, height: 480), // Change resolution
    frameRate: 15,  // Change frame rate
    bitrate: 0,     // 0 = auto, or set specific bitrate
  ),
);
```

### UI Customization

Widgets are located in `lib/features/video_call/presentation/widgets/`:

- `video_call_controls.dart` - Control buttons styling
- `video_call_status.dart` - Status bar and info display

## 🔐 Security Notes

### ⚠️ IMPORTANT: Token Management

The current implementation uses a **static token** from the `.env` file. This is suitable for:

- ✅ Development
- ✅ Testing
- ✅ Demo purposes

For **production**, you MUST:

1. Implement a token server
2. Generate tokens dynamically per call
3. Set appropriate token expiration
4. Validate user permissions server-side

### Recommended Production Setup:

```dart
// Instead of using static token from .env
// Call your backend API to generate token
final response = await http.post(
  Uri.parse('$YOUR_API_URL/generate-agora-token'),
  body: {
    'channelName': channelName,
    'uid': userId,
    'role': 'publisher',
  },
);
final token = response.body['token'];
```

## 📚 Additional Resources

- **Full Documentation**: See `VIDEO_CALL_README.md`
- **Agora Docs**: https://docs.agora.io/en/video-calling/get-started/get-started-sdk?platform=flutter
- **Example Code**: `lib/features/video_call/example/video_call_example.dart`

## 🐛 Troubleshooting

### Black screen on call

- Ensure camera permissions are granted
- Check `.env` file is loaded properly
- Verify Agora credentials are correct

### No audio

- Check microphone permissions
- Ensure device is not on silent mode
- Test with headphones

### Build errors

```bash
flutter clean
flutter pub get
flutter run
```

### Permission errors on Android

Make sure you have Android SDK 21+ (Android 5.0 Lollipop or higher).

## ✨ Features Included

- ✅ Real-time video calling
- ✅ Audio/video controls
- ✅ Camera switching (front/back)
- ✅ Speaker toggle
- ✅ Call duration tracking
- ✅ Connection status indicators
- ✅ Waiting screen for patients
- ✅ Picture-in-picture local video
- ✅ Screen wake lock during calls
- ✅ Confirmation dialog on exit
- ✅ Integration with consultation system

## 🎉 You're Ready!

The video call feature is now fully integrated into your DocSync Doctor app.

Run the app and test it out! 🚀
