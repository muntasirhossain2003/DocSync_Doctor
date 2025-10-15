# Video Call Feature - Troubleshooting Guide

## Common Issues and Solutions

### ✅ FIXED: Provider Modification Error

**Error Message:**

```
Tried to modify a provider while the widget tree was building.
The exceptions thrown are: [_debugCanModifyProviders]
```

**Cause:**
Attempting to modify a Riverpod provider state during the widget build phase (e.g., in `initState()` without proper delay).

**Solution:**
Use `WidgetsBinding.instance.addPostFrameCallback()` to defer the provider modification until after the first frame:

```dart
@override
void initState() {
  super.initState();

  // Initialize after first frame
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _initializeCall();
  });
}

Future<void> _initializeCall() async {
  await ref.read(videoCallProvider.notifier).startCall(...);
}
```

**Status:** ✅ Fixed in `video_call_page.dart`

---

## Other Common Issues

### 1. Black Screen During Call

**Symptoms:**

- Video call page opens but shows black screen
- No local or remote video visible

**Possible Causes:**

- Camera permissions not granted
- Invalid Agora credentials
- Device camera in use by another app

**Solutions:**

```dart
// Check permissions
await Permission.camera.request();
await Permission.microphone.request();

// Verify Agora config
print('App ID: ${AgoraConfig.appId}');
print('Token: ${AgoraConfig.token}');
```

**Checklist:**

- [ ] Camera permission granted in system settings
- [ ] `.env` file exists and is loaded
- [ ] Agora credentials are correct
- [ ] Close other camera apps

### 2. Permission Denied Errors

**Symptoms:**

- App crashes when starting video call
- "Permission denied" messages

**Solution:**
Ensure permissions are in `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS"/>
```

For iOS, add to `Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Camera access for video consultations</string>
<key>NSMicrophoneUsageDescription</key>
<string>Microphone access for video consultations</string>
```

### 3. Connection Failed / Token Invalid

**Symptoms:**

- Call connects but immediately disconnects
- "Token expired" or "Invalid token" errors

**Possible Causes:**

- Agora token expired
- Wrong channel name
- Network issues

**Solutions:**

1. **Check token validity:**

   ```dart
   // Token format: 007eJxT...
   // Ensure it's not expired
   ```

2. **Verify channel name matches:**

   ```dart
   // Both doctor and patient must use same channel
   print('Channel: ${AgoraConfig.channelName}');
   ```

3. **Test network connection:**
   ```bash
   # Check if you can reach Agora servers
   ping agora.io
   ```

### 4. No Audio During Call

**Symptoms:**

- Video works but no sound
- Can see but can't hear patient

**Solutions:**

1. **Check microphone permission:**

   ```dart
   final micStatus = await Permission.microphone.status;
   if (!micStatus.isGranted) {
     await Permission.microphone.request();
   }
   ```

2. **Verify audio is not muted:**

   - Check device volume
   - Check app audio toggle
   - Test with headphones

3. **Enable audio in Agora:**
   ```dart
   await _engine.enableAudio();
   await _engine.enableLocalAudio(true);
   ```

### 5. App Crashes on Call Start

**Symptoms:**

- App crashes when clicking "Join Call"
- Error in native code

**Solutions:**

1. **Clean and rebuild:**

   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Check Agora SDK version:**

   ```yaml
   # pubspec.yaml
   agora_rtc_engine: ^6.3.2
   ```

3. **Verify Android minSdkVersion:**
   ```gradle
   // android/app/build.gradle
   minSdkVersion 21 // or higher
   ```

### 6. Remote User Not Visible

**Symptoms:**

- Local video shows but patient video doesn't appear
- "Waiting for patient..." stays on screen

**Possible Causes:**

- Patient hasn't joined the channel
- Patient's camera is off
- Different channel names

**Solutions:**

1. **Verify both users are in same channel:**

   ```dart
   print('Doctor channel: ${callState.channelName}');
   // Patient must use same channel name
   ```

2. **Check remote UID:**

   ```dart
   print('Remote UID: ${callState.remoteUid}');
   // Should show patient's UID when they join
   ```

3. **Wait for patient to join:**
   - Patient needs to click "Join Call" too
   - Check patient app is running

### 7. Screen Doesn't Stay Awake

**Symptoms:**

- Screen dims/locks during call
- Call continues in background

**Solution:**
Wakelock should be enabled automatically, but verify:

```dart
// Should be in video_call_page.dart
@override
void initState() {
  super.initState();
  WakelockPlus.enable();
}

@override
void dispose() {
  WakelockPlus.disable();
  super.dispose();
}
```

### 8. Can't Switch Camera

**Symptoms:**

- Camera switch button doesn't work
- App crashes when switching camera

**Solution:**
Ensure device has multiple cameras:

```dart
try {
  await _engine.switchCamera();
} catch (e) {
  print('Camera switch failed: $e');
  // Device might have only one camera
}
```

### 9. Call Duration Not Updating

**Symptoms:**

- Timer shows 00:00 and doesn't increment
- Duration stuck

**Check:**

```dart
// In video_call_provider.dart
void _startDurationTimer() {
  _durationTimer?.cancel();
  _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
    if (state.startTime != null) {
      final duration = DateTime.now().difference(state.startTime!);
      state = state.copyWith(duration: duration);
    }
  });
}
```

### 10. Multiple Calls Interfere

**Symptoms:**

- Starting a new call fails
- Previous call still active

**Solution:**
Ensure proper cleanup:

```dart
@override
void dispose() {
  ref.read(videoCallProvider.notifier).endCall();
  WakelockPlus.disable();
  super.dispose();
}
```

---

## Debugging Tips

### Enable Verbose Logging

In `agora_service.dart`, add:

```dart
await _engine!.setLogLevel(LogLevel.logLevelInfo);
```

### Check Provider State

```dart
// In any widget
final callState = ref.watch(videoCallProvider);
print('Call Status: ${callState.status}');
print('Video Enabled: ${callState.isVideoEnabled}');
print('Audio Enabled: ${callState.isAudioEnabled}');
```

### Monitor Network Quality

Add to `agora_service.dart`:

```dart
onNetworkQuality: (connection, remoteUid, txQuality, rxQuality) {
  print('TX Quality: $txQuality, RX Quality: $rxQuality');
},
```

### Test on Real Device

⚠️ **Always test on physical device** - Emulator camera/microphone support is limited.

```bash
# Connect device via USB
flutter devices

# Run on device
flutter run
```

---

## Quick Fixes Checklist

When video call fails, check in this order:

1. [ ] Physical device connected (not emulator)
2. [ ] Camera permission granted
3. [ ] Microphone permission granted
4. [ ] `.env` file exists with correct credentials
5. [ ] Internet connection active
6. [ ] No other app using camera
7. [ ] Agora token is valid (not expired)
8. [ ] Both users using same channel name
9. [ ] Device has camera and microphone
10. [ ] Clean build: `flutter clean && flutter pub get`

---

## Error Code Reference

| Error Code | Meaning              | Solution                            |
| ---------- | -------------------- | ----------------------------------- |
| 2          | Invalid argument     | Check App ID, token, channel name   |
| 3          | SDK not ready        | Initialize before joining channel   |
| 5          | SDK not initialized  | Call `initialize()` first           |
| 17         | No permission        | Grant camera/microphone permissions |
| 101        | Invalid channel name | Use same channel for all users      |
| 109        | Token expired        | Generate new token                  |

---

## Getting Help

1. **Check logs:**

   ```bash
   flutter logs
   ```

2. **Agora documentation:**
   https://docs.agora.io/en/video-calling/get-started/get-started-sdk?platform=flutter

3. **Project documentation:**

   - `VIDEO_CALL_README.md` - Full documentation
   - `VIDEO_CALL_SETUP.md` - Setup guide
   - `VIDEO_CALL_CHECKLIST.md` - Testing checklist

4. **Debug mode:**
   Run with verbose output:
   ```bash
   flutter run -v
   ```

---

## Prevention

### Best Practices

1. **Always use WidgetsBinding for async init:**

   ```dart
   WidgetsBinding.instance.addPostFrameCallback((_) {
     // Safe to modify providers here
   });
   ```

2. **Check mounted before setState:**

   ```dart
   if (mounted) {
     setState(() => _isInitialized = true);
   }
   ```

3. **Handle errors gracefully:**

   ```dart
   try {
     await startCall();
   } catch (e) {
     if (mounted) {
       showErrorDialog();
     }
   }
   ```

4. **Clean up resources:**
   ```dart
   @override
   void dispose() {
     _timer?.cancel();
     _engine?.release();
     super.dispose();
   }
   ```

---

## Success Indicators

✅ Video call is working correctly when:

- Local video appears in picture-in-picture
- Remote video shows when patient joins
- All control buttons respond (video, audio, speaker, switch)
- Call duration timer increments every second
- Screen stays awake during call
- Back button shows confirmation dialog
- Call ends cleanly without errors
- Can start multiple calls in sequence

---

**Last Updated:** October 15, 2025  
**Version:** 1.0.0  
**Status:** ✅ All known issues documented and fixed
