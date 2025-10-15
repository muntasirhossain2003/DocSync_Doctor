# Web Platform Limitation - Video Calling

## ⚠️ Important Notice

**Video calling is NOT supported on web browsers.**

The `agora_rtc_engine` Flutter package (version 6.3.2) **only supports native platforms**:

- ✅ Android
- ✅ iOS
- ✅ Windows
- ✅ macOS
- ✅ Linux
- ❌ **Web (NOT supported)**

## Why Web Doesn't Work

The agora_rtc_engine package uses native platform code to interface with Agora's SDKs:

- **Android**: Uses Agora Android SDK (Java/Kotlin)
- **iOS**: Uses Agora iOS SDK (Objective-C/Swift)
- **Desktop**: Uses Agora C++ SDK
- **Web**: ❌ No implementation in the package

When you try to call `createAgoraRtcEngine()` on web, it attempts to access native code that doesn't exist, resulting in:

```
TypeError: Cannot read properties of undefined (reading 'createIrisApiEngine')
```

## What We've Implemented

### 1. **Graceful Degradation**

The app now detects when running on web and:

- ✅ Prevents crashes
- ✅ Shows a clear warning message
- ✅ Allows closing the call gracefully
- ✅ All other features work normally

### 2. **User-Friendly Message**

When a doctor tries to accept a call on web, they see:

```
⚠️ Video Calling Not Available on Web

The Agora video calling feature is only available
on mobile and desktop apps.

Please use the Android, iOS, Windows, or macOS app
for video consultations.

[Close Button]
```

### 3. **Code Protection**

```dart
if (kIsWeb) {
  // Skip Agora engine creation
  print('Web platform - video not supported');
} else {
  // Create engine for native platforms
  _engine = createAgoraRtcEngine();
}
```

## Recommended Solutions

### Option 1: Use Native Apps (Recommended)

Tell doctors to use:

- **Android App**: Full video calling support
- **iOS App**: Full video calling support
- **Windows App**: Full video calling support
- **macOS App**: Full video calling support

### Option 2: Implement Agora Web SDK (Advanced)

For production web support, you would need to:

1. **Add Agora Web SDK** (already done in index.html)

   ```html
   <script src="https://download.agora.io/sdk/release/AgoraRTC_N-4.20.0.js"></script>
   ```

2. **Create JavaScript Interop** with `dart:js_interop`

   ```dart
   @JS('AgoraRTC.createClient')
   external AgoraClient createClient(ClientConfig config);

   @JS()
   @anonymous
   class AgoraClient {
     external Future<void> join(String appId, String channel, String token);
     external Future<LocalVideoTrack> createCameraVideoTrack();
     external Future<LocalAudioTrack> createMicrophoneAudioTrack();
   }
   ```

3. **Implement Video Rendering** with HTML video elements

   ```dart
   HtmlElementView(
     viewType: 'agora-local-video',
     onPlatformViewCreated: (id) {
       // Inject video track into HTML element
       localVideoTrack.play('agora-local-video-${id}');
     },
   )
   ```

4. **Handle All Agora Web SDK APIs**
   - join/leave channel
   - publish/unpublish tracks
   - subscribe to remote users
   - mute/unmute controls
   - camera switching
   - network quality monitoring

**Complexity**: High  
**Development Time**: 2-3 weeks  
**Maintenance**: Ongoing (Agora updates)

### Option 3: Use WebRTC Directly (Very Advanced)

Implement your own video calling using:

- WebRTC APIs
- Signaling server (Socket.io, Firebase)
- STUN/TURN servers
- Custom video rendering

**Complexity**: Very High  
**Development Time**: 1-2 months  
**Cost**: TURN server hosting required

### Option 4: Alternative SDK

Use a different video calling SDK that supports web:

- **Zoom SDK** (has web support)
- **Twilio Video** (excellent web support)
- **LiveKit** (open source, web-first)
- **100ms** (Flutter + web support)

**Complexity**: Medium  
**Development Time**: 1-2 weeks  
**Cost**: Different pricing models

## Current Implementation Status

✅ **Working Perfectly:**

- Incoming call notifications (all platforms including web)
- Call status updates
- Database synchronization
- Supabase Realtime
- Doctor availability
- Consultation scheduling
- All UI/UX features

❌ **Not Working on Web:**

- Video streaming
- Audio streaming
- Camera controls
- Microphone controls

✅ **Working on Native (Android/iOS/Desktop):**

- Full video calling
- Audio calling
- All Agora features
- Camera/mic controls
- Speaker controls
- Camera switching

## Testing Instructions

### Test on Native Platforms:

```bash
# Android
flutter run -d <android-device-id>

# iOS (macOS only)
flutter run -d <ios-device-id>

# Windows
flutter run -d windows

# macOS
flutter run -d macos
```

### Test on Web (Limited):

```bash
flutter run -d chrome
```

- ✅ Login works
- ✅ Dashboard works
- ✅ Incoming call notification works
- ✅ Accept call shows warning message
- ❌ Video call doesn't work (expected)

## Deployment Recommendation

### For Production:

1. **Primary Deployment**: Mobile Apps

   - Release Android app on Google Play
   - Release iOS app on App Store
   - These have full video calling support

2. **Secondary Deployment**: Desktop Apps

   - Distribute Windows .exe
   - Distribute macOS .app
   - Full video calling works

3. **Web Deployment**: Limited Features
   - Deploy to web for non-video features
   - Show clear message: "Download the app for video calls"
   - Include download links to Play Store / App Store

## Summary

| Platform | Video Calls         | Why                    |
| -------- | ------------------- | ---------------------- |
| Android  | ✅ Works            | Native Agora SDK       |
| iOS      | ✅ Works            | Native Agora SDK       |
| Windows  | ✅ Works            | Native Agora SDK       |
| macOS    | ✅ Works            | Native Agora SDK       |
| Linux    | ✅ Works            | Native Agora SDK       |
| **Web**  | ❌ **Doesn't Work** | **Package limitation** |

## Next Steps

1. ✅ App works on web without crashes
2. ✅ Shows clear warning message
3. 📱 Focus on mobile app deployment
4. 💻 Optionally deploy desktop apps
5. 🌐 Web as supplementary (non-video features)

---

**Recommendation**: Deploy as **mobile-first** application. Web can be used for administrative tasks, but video consultations require the native mobile or desktop app.
