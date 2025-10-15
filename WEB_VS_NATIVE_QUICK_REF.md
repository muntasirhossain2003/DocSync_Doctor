# Quick Reference: Web vs Native

## TL;DR

✅ **Android/iOS/Desktop**: Full video calling works  
⚠️ **Web**: All features work EXCEPT video calls (shows warning instead)

## The Issue

The `agora_rtc_engine` Flutter package doesn't support web browsers. This is a limitation of the package, not a bug.

## What We Did

Made the app handle web gracefully:

- ✅ No crashes on web
- ✅ Shows clear warning message
- ✅ All other features work normally
- ✅ Video calls work perfectly on mobile/desktop

## Quick Test

### Test on Web (Chrome):

```bash
flutter run -d chrome
```

- Login ✅
- Dashboard ✅
- Accept call → Shows warning (not video) ⚠️
- No crash ✅

### Test on Android:

```bash
flutter run -d <android-device>
```

- Login ✅
- Dashboard ✅
- Accept call → Video call works ✅
- Full features ✅

## Deployment

**Primary**: Android + iOS apps (full features)  
**Secondary**: Windows/macOS apps (full features)  
**Tertiary**: Web (limited, no video)

## User Message on Web

When trying to start a video call on web:

```
⚠️ Video Calling Not Available on Web

Please use the Android, iOS, Windows, or macOS app
for video consultations.

[Close]
```

## Files Changed

1. `agora_service.dart` - Detects web, skips engine creation
2. `video_call_page.dart` - Shows warning on web, video on native

## Status

✅ **COMPLETE** - Ready for deployment

---

**Bottom Line**: Deploy to mobile app stores for full functionality. Web is bonus for non-video features.
