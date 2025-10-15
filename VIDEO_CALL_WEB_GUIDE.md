# Video Call on Web (Chrome) - Setup Guide

## 🌐 Camera/Microphone Permissions on Chrome

When running the DocSync Doctor app on **Chrome or any web browser**, you need to grant camera and microphone permissions through the browser, not through the app.

---

## ✅ How to Fix: "Camera or microphone permission denied"

### Step 1: Check Browser Permissions

1. **Click the lock icon** 🔒 or camera icon 🎥 in Chrome's address bar (left side)
2. **Allow camera and microphone access** for your app
3. **Refresh the page** (F5 or Ctrl+R)

### Step 2: Grant Permissions When Prompted

When you click "Join Call", Chrome will show a popup asking for permissions:

```
https://localhost wants to:
• Use your camera
• Use your microphone

[Block] [Allow]
```

**Click "Allow"** ✅

### Step 3: If Permissions Were Previously Blocked

If you accidentally clicked "Block", follow these steps:

1. **Click the lock/camera icon** in the address bar
2. Find **Camera** and **Microphone** settings
3. Change from "Blocked" to **"Allow"**
4. **Refresh the page**

---

## 🔧 Detailed Chrome Permission Settings

### Option 1: Site-Specific Permissions (Recommended)

1. Click the **lock icon** 🔒 in Chrome's address bar
2. Click **"Site settings"**
3. Find **Camera** and **Microphone**
4. Set both to **"Allow"**
5. Close settings and refresh the page

### Option 2: Global Chrome Settings

1. Open Chrome settings: `chrome://settings/content`
2. Or click **⋮** (three dots) → **Settings** → **Privacy and security** → **Site settings**
3. Click **"Camera"**
   - Make sure "Sites can ask to use your camera" is enabled
   - Check "Allowed" list includes your app's URL
4. Click **"Microphone"**
   - Make sure "Sites can ask to use your microphone" is enabled
   - Check "Allowed" list includes your app's URL

---

## 🚨 Common Issues on Web

### Issue 1: "Permission denied" Error

**Symptoms:**

```
Failed to start call: Exception: Failed to initialize Agora:
Exception: Camera or microphone permission denied
```

**Solutions:**

1. **Check if permissions are blocked:**

   - Look for a ⛔ or camera icon with an X in the address bar
   - Click it and change to "Allow"

2. **Clear blocked permissions:**

   ```
   Chrome Menu → Settings → Privacy and security
   → Site settings → View permissions and data stored across sites
   → Find your app → Remove
   ```

3. **Try incognito mode:**
   - Press `Ctrl + Shift + N`
   - Test the video call there (will ask for permissions again)

### Issue 2: Camera/Mic Already in Use

**Symptoms:**

- "Device is already in use" error
- Black screen on video call

**Solutions:**

1. Close other apps using camera (Zoom, Skype, Teams, etc.)
2. Close other browser tabs using camera
3. Refresh your app page

### Issue 3: No Permission Prompt Appears

**Symptoms:**

- Browser doesn't ask for permissions
- Call fails silently

**Solutions:**

1. Check if permissions are already blocked
2. Enable permissions manually via site settings
3. Use HTTPS (not HTTP) - browsers require secure connection for camera/mic
4. Check if browser supports WebRTC

---

## 🌐 Browser Requirements

### Supported Browsers:

✅ Chrome (recommended)  
✅ Edge  
✅ Firefox  
✅ Safari (macOS/iOS)  
✅ Opera

### Minimum Versions:

- Chrome: 74+
- Firefox: 66+
- Safari: 12.1+
- Edge: 79+

### Required:

- **HTTPS connection** (or localhost for development)
- **WebRTC support** enabled
- **JavaScript enabled**

---

## 🔐 For Development (localhost)

When running on **localhost** during development:

### Chrome Localhost Permissions

1. Chrome allows camera/mic on localhost without HTTPS
2. First time: Browser will ask for permissions
3. Grant permissions and they'll be saved
4. Refresh page if needed

### Testing on Local Network (192.168.x.x)

⚠️ **Important:** Accessing via IP address (not localhost) requires HTTPS!

**Option 1: Use localhost**

```bash
flutter run -d chrome --web-hostname=localhost --web-port=8080
```

**Option 2: Use HTTPS**
Generate a self-signed certificate for development

---

## 🧪 Testing Permissions

### Check if Permissions Work:

1. **Test camera access:**

   - Open Chrome
   - Go to: https://webcamtests.com/
   - Click "Test my cam"
   - If your camera works here, permissions are OK

2. **Test microphone:**
   - Go to: https://webcammictest.com/check-mic.html
   - Click "Check mic"
   - Speak and see if levels move

If these work but your app doesn't, the issue is with Agora configuration, not permissions.

---

## 📱 Mobile Web (Chrome on Android/iOS)

### Android Chrome:

1. Settings → Site Settings → Camera/Microphone
2. Grant permissions to your app's URL

### iOS Safari:

1. Settings → Safari → Camera/Microphone
2. Allow for your app's website

---

## 🐛 Debugging on Web

### Enable Console Logs:

1. Open Chrome DevTools: `F12` or `Ctrl + Shift + I`
2. Go to **Console** tab
3. Look for error messages when starting call
4. Common errors:
   ```
   NotAllowedError: Permission denied
   NotFoundError: No camera/microphone found
   NotReadableError: Device is already in use
   ```

### Check Network:

1. Go to **Network** tab in DevTools
2. Start the call
3. Look for failed requests to Agora servers
4. Check if WebSocket connections are established

### Check WebRTC:

1. Open: `chrome://webrtc-internals/`
2. Start your video call
3. You'll see detailed WebRTC stats and connection info

---

## ⚙️ Code Changes Made

The following files were updated to support web:

### 1. `agora_service.dart`

```dart
// Skip permission request on web (browser handles it)
if (!kIsWeb) {
  await _requestPermissions();
}
```

### 2. Permission Handling

- Mobile: Uses `permission_handler` package
- Web: Browser's built-in permission system
- Automatic fallback if permission request fails

---

## 🎯 Quick Fix Checklist

When video call fails on Chrome:

- [ ] Grant camera permission via address bar icon
- [ ] Grant microphone permission via address bar icon
- [ ] Refresh the page (F5)
- [ ] Close other apps using camera
- [ ] Check camera works on webcamtests.com
- [ ] Use HTTPS or localhost (not IP address)
- [ ] Check browser console for errors (F12)
- [ ] Try incognito mode
- [ ] Clear site permissions and grant again
- [ ] Restart browser

---

## 🚀 Production Deployment

### For Production Web App:

1. **Use HTTPS** (required for camera/mic access)

   ```
   https://yourdomain.com
   ```

2. **SSL Certificate** (Let's Encrypt, Cloudflare, etc.)

3. **Update Agora Token**

   - Don't use static tokens in production
   - Implement dynamic token generation

4. **CORS Configuration**

   - Allow your domain in Agora project settings
   - Configure proper CORS headers

5. **PWA Manifest** (optional but recommended)
   ```json
   {
     "permissions": ["camera", "microphone"]
   }
   ```

---

## 📞 Still Not Working?

### Fallback Options:

1. **Test on mobile app** instead of web

   ```bash
   flutter run -d <device-id>
   ```

2. **Use different browser** (try Firefox or Edge)

3. **Check Agora credentials:**

   - App ID correct?
   - Token valid?
   - Channel name consistent?

4. **Verify `.env` file loaded:**
   ```dart
   print('App ID: ${AgoraConfig.appId}');
   print('Token: ${AgoraConfig.token}');
   ```

---

## ✅ Success Indicators

Video call is working on web when:

✅ Browser asks for camera/microphone permissions  
✅ You can see yourself in the video preview  
✅ No error messages in console  
✅ Control buttons respond properly  
✅ Call duration timer increments

---

## 📚 Additional Resources

- **Chrome Camera/Mic Help:** https://support.google.com/chrome/answer/2693767
- **Agora Web SDK:** https://docs.agora.io/en/video-calling/get-started/get-started-sdk?platform=web
- **WebRTC Troubleshooting:** https://webrtc.github.io/samples/

---

**Platform:** Web (Chrome/Firefox/Safari)  
**Last Updated:** October 15, 2025  
**Status:** ✅ Web support added  
**Note:** For best experience, use native mobile app
