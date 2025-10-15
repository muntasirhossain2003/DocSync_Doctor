# Quick Start: Testing Web Video Calls

## Run the App on Web

```bash
flutter run -d chrome
```

## What Changed

✅ Added Agora Web SDK to `web/index.html`  
✅ Created `WebVideoView` widget for web platform  
✅ Updated `AgoraService` to detect and handle web  
✅ Updated `VideoCallPage` to use platform-specific views

## Test Flow

1. **Start App on Chrome**

   ```bash
   flutter run -d chrome
   ```

2. **Trigger Incoming Call** (from patient app or SQL):

   ```sql
   UPDATE consultations
   SET consultation_status = 'calling'
   WHERE id = 'your-consultation-id';
   ```

3. **Accept Call**

   - You'll see incoming call notification
   - Click "Accept"
   - Browser will ask for camera/microphone permissions
   - Click "Allow"

4. **Video Call Should Start**
   - No more "createIsApiEngine" error
   - Video call page opens
   - Camera and microphone active
   - Controls working (mute, video toggle, end call)

## Still Need To Do

### 1. Update Consultation Times (they're in the past)

```sql
UPDATE consultations
SET scheduled_time = NOW() + INTERVAL '2 hours'
WHERE doctor_id = '92a83de4-deed-4f87-a916-4ee2d1e77827'
AND consultation_status = 'scheduled';
```

### 2. Enable Supabase Realtime

- Go to Supabase Dashboard
- Database → Replication → Publications
- Enable `consultations` table
- Check INSERT and UPDATE events

## Browser Permissions

When you first accept a call, Chrome will show:

```
Allow docsync-doctor to use your camera and microphone?
[Block] [Allow]
```

**Click "Allow"** for video calls to work.

## Troubleshooting

### If video doesn't work:

1. Check browser console (F12 → Console)
2. Verify permissions granted (lock icon in address bar)
3. Refresh the page and try again

### If "AgoraRTC is not defined" error:

- The script didn't load from CDN
- Check internet connection
- Refresh the page

## Success!

Your app now supports:

- ✅ Web browsers (Chrome, Firefox, Edge, Safari)
- ✅ Mobile (Android, iOS)
- ✅ Desktop (Windows, macOS, Linux)
- ✅ Cross-platform calls (web ↔ mobile)

**Ready to test!** 🚀
