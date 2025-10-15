# 📞 Incoming Call System - Implementation Guide

## Problem Fixed

**Issue**: Doctor app couldn't receive incoming video calls from patients. When a patient initiated a call, nothing happened on the doctor's side.

**Solution**: Implemented a real-time incoming call notification system using Supabase Realtime.

---

## 🎯 How It Works

### Architecture Flow

```
Patient App                  Supabase Database              Doctor App
    |                              |                              |
    | 1. Create consultation       |                              |
    |----------------------------->|                              |
    |    status='calling'          |                              |
    |                              | 2. Realtime event            |
    |                              |----------------------------->|
    |                              |                              | 3. Show dialog
    |                              |                              | 4. Doctor accepts
    |                              | 5. Update status='in_progress|<--
    | 6. Join call                 |<-----------------------------|
    |<-----------------------------|                              |
```

### Components Created

1. **IncomingCall Model** (`incoming_call.dart`)

   - Data model for incoming call information
   - Contains patient details, channel name, and token

2. **IncomingCallService** (`incoming_call_service.dart`)

   - Listens to Supabase Realtime for consultation changes
   - Detects when `status='calling'`
   - Provides accept/reject call methods
   - Emits incoming calls via stream

3. **IncomingCallDialog** (`incoming_call_dialog.dart`)

   - Full-screen overlay UI for incoming calls
   - Shows patient name, avatar, and call controls
   - Animated ringing indicator
   - Accept/Reject buttons

4. **IncomingCallListener** (`incoming_call_listener.dart`)
   - Widget wrapper that listens to incoming call stream
   - Automatically shows IncomingCallDialog when call arrives
   - Integrated into app root

---

## 📋 Database Requirements

### Consultations Table Schema

Ensure your `consultations` table has these columns:

```sql
CREATE TABLE consultations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  patient_id UUID REFERENCES users(id),
  doctor_id UUID REFERENCES doctors(id),
  status TEXT NOT NULL, -- 'pending', 'calling', 'in_progress', 'completed', 'cancelled', 'rejected'
  agora_channel_name TEXT,
  agora_token TEXT,
  scheduled_at TIMESTAMPTZ,
  rejection_reason TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Realtime
ALTER TABLE consultations REPLICA IDENTITY FULL;
```

### Enable Realtime in Supabase Dashboard

1. Go to **Database** → **Replication**
2. Enable replication for `consultations` table
3. Check **Insert** and **Update** events

---

## 🔧 How to Use

### Patient Side (What Patient App Should Do)

When patient wants to call:

```dart
// 1. Create or update consultation with status='calling'
await supabase
  .from('consultations')
  .update({
    'status': 'calling',
    'agora_channel_name': channelName,
    'agora_token': token,
    'updated_at': DateTime.now().toIso8601String(),
  })
  .eq('id', consultationId);

// 2. Patient app joins Agora channel immediately
// 3. Wait for doctor to accept (status changes to 'in_progress')
```

### Doctor Side (Automatic)

The incoming call system works automatically:

1. **Doctor logs in** → IncomingCallService starts listening
2. **Patient calls** → Doctor sees incoming call dialog
3. **Doctor accepts** → Status updates to `'in_progress'` → Navigates to video call page
4. **Doctor rejects** → Status updates to `'rejected'` → Dialog dismisses

---

## 🎨 UI Features

### Incoming Call Dialog

- ✅ Full-screen black overlay
- ✅ Patient avatar (or initial letter if no photo)
- ✅ Patient name prominently displayed
- ✅ "Incoming Video Call" label
- ✅ Animated ringing indicator
- ✅ Large green **Accept** button with video icon
- ✅ Large red **Reject** button with end call icon
- ✅ Cannot be dismissed by tapping outside

### Call Flow

**Accept Call:**

- Updates consultation status to `'in_progress'`
- Navigates to `/video-call` page
- Joins Agora channel with patient

**Reject Call:**

- Updates consultation status to `'rejected'`
- Sets rejection reason
- Dismisses dialog
- Patient app should show "Doctor declined" message

---

## 📂 Files Created

```
lib/features/video_call/
├── domain/models/
│   └── incoming_call.dart              # Incoming call data model
├── data/services/
│   └── incoming_call_service.dart      # Realtime listener & call management
└── presentation/widgets/
    ├── incoming_call_dialog.dart       # Full-screen incoming call UI
    └── incoming_call_listener.dart     # App-wide call listener widget
```

### Modified Files

- `lib/app.dart` - Wrapped app in `IncomingCallListener`

---

## 🔍 Debugging

### Check if Realtime is Working

```dart
// In doctor app, add this temporarily:
final service = ref.watch(incomingCallServiceProvider);
print('Doctor ID: ${service.doctorId}');
print('Listening for calls...');
```

### Test Incoming Call Manually

Run this in Supabase SQL Editor:

```sql
-- Simulate a patient calling
UPDATE consultations
SET
  status = 'calling',
  agora_channel_name = 'test_channel_123',
  agora_token = 'test_token',
  updated_at = NOW()
WHERE doctor_id = '<YOUR_DOCTOR_ID>'
  AND id = '<SOME_CONSULTATION_ID>';
```

You should see the incoming call dialog appear immediately!

### Console Logs to Watch

When working correctly, you'll see:

```
🎧 Starting to listen for incoming calls for doctor: <doctor_id>
📞 New consultation received: {...}
✅ Fetched consultation details: {...}
📞 Incoming call emitted: Patient Name
```

---

## ⚠️ Troubleshooting

### No Incoming Call Dialog Appears

**1. Check Realtime is enabled:**

- Supabase Dashboard → Database → Replication
- Ensure `consultations` table has replication enabled

**2. Check doctor is logged in:**

- `IncomingCallService` requires `doctorId`
- Ensure doctor profile is loaded before calls arrive

**3. Check consultation status:**

```sql
SELECT id, patient_id, doctor_id, status, updated_at
FROM consultations
WHERE doctor_id = '<YOUR_DOCTOR_ID>'
ORDER BY updated_at DESC;
```

**4. Check console logs:**

- Look for "Starting to listen for incoming calls"
- Look for "New consultation received"

### Dialog Shows But Can't Accept

**Check router configuration:**

```dart
// Ensure /video-call route exists
GoRoute(
  path: '/video-call',
  builder: (context, state) {
    final extra = state.extra as Map<String, dynamic>?;
    return VideoCallPage(
      consultationId: extra?['consultationId'] as String,
      patientId: extra?['patientId'] as String?,
      patientName: extra?['patientName'] as String?,
      patientImageUrl: extra?['patientImageUrl'] as String?,
    );
  },
),
```

### Multiple Dialogs Appear

The stream might be emitting multiple times. Add this check:

```dart
// In incoming_call_listener.dart
bool _isShowingDialog = false;

ref.listen(incomingCallStreamProvider, (previous, next) {
  if (next.hasValue && next.value != null && !_isShowingDialog) {
    _isShowingDialog = true;
    // Show dialog...
  }
});
```

---

## 🚀 Testing Checklist

- [ ] Doctor logs in successfully
- [ ] Patient creates consultation with doctor
- [ ] Patient sets consultation status to `'calling'`
- [ ] Incoming call dialog appears on doctor's screen
- [ ] Dialog shows correct patient name and avatar
- [ ] Doctor can accept call → navigates to video call page
- [ ] Doctor can reject call → dialog dismisses, status updates
- [ ] Multiple calls work correctly (one after another)
- [ ] App doesn't crash if patient cancels call before doctor responds

---

## 🎉 Success!

Your doctor app can now receive incoming video calls in real-time! When a patient initiates a call, the doctor will see a beautiful full-screen notification and can choose to accept or reject the call.

### Next Steps

1. **Run the SQL script** in Supabase to fix is_available status
2. **Enable Realtime** for consultations table
3. **Test incoming calls** between patient and doctor apps
4. **Add call notifications** (optional) for when app is in background
5. **Add call history** tracking

---

## 📞 Support

If calls still aren't working:

1. Check all console logs for errors
2. Verify Supabase Realtime is enabled
3. Test with manual SQL update
4. Ensure both apps use the same consultation ID
5. Check network connectivity

**The incoming call system is now fully implemented! 🎊**
