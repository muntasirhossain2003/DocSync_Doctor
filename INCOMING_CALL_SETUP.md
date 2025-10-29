# 🚨 INCOMING CALL SYSTEM - QUICK SETUP

## What Was Wrong

Your doctor app had **NO WAY to receive calls** from patients. It could only initiate calls but not receive them.

## What I Fixed

✅ Added **Supabase Realtime listener** to detect incoming calls
✅ Created **incoming call dialog** UI (full-screen with accept/reject)
✅ Integrated **call notification system** into your app
✅ Added **accept/reject call** functionality

---

## 🔥 REQUIRED: Enable Realtime in Supabase

### Step 1: Enable Replication

1. Open **Supabase Dashboard**
2. Go to **Database** → **Replication**
3. Find `consultations` table
4. Click **Enable replication**
5. Make sure **Insert** and **Update** are checked

### Step 2: Run This SQL

```sql
-- Enable realtime for consultations table
ALTER TABLE consultations REPLICA IDENTITY FULL;

-- Verify your consultations table has these columns
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'consultations';

-- Should have:
-- id (uuid)
-- patient_id (uuid)
-- doctor_id (uuid)
-- status (text)
-- agora_channel_name (text)
-- agora_token (text)
-- rejection_reason (text)
-- created_at (timestamptz)
-- updated_at (timestamptz)
```

---

## 🎯 How It Works Now

### When Patient Calls:

**Patient App** does this:

```dart
// Update consultation to 'calling' status
await supabase
  .from('consultations')
  .update({
    'status': 'calling',  // ← This triggers the incoming call!
    'agora_channel_name': channelName,
    'agora_token': token,
    'updated_at': DateTime.now().toIso8601String(),
  })
  .eq('id', consultationId);
```

**Doctor App** automatically:

1. ✅ Detects status change via Realtime
2. ✅ Shows full-screen incoming call dialog
3. ✅ Displays patient name and avatar
4. ✅ Waits for doctor to accept/reject

### When Doctor Accepts:

- Status → `'in_progress'`
- Navigates to video call page
- Both join Agora channel

### When Doctor Rejects:

- Status → `'rejected'`
- Dialog closes
- Patient sees "Doctor declined"

---

## 📂 Files Created

| File                          | Purpose                             |
| ----------------------------- | ----------------------------------- |
| `incoming_call.dart`          | Data model for incoming calls       |
| `incoming_call_service.dart`  | Realtime listener & call management |
| `incoming_call_dialog.dart`   | Full-screen incoming call UI        |
| `incoming_call_listener.dart` | App-wide listener widget            |

**Modified:** `app.dart` - wrapped in `IncomingCallListener`

---

## ✅ Testing

### Quick Test (Manual)

1. **Get your doctor ID** from database
2. **Run this SQL** in Supabase:

```sql
-- Replace with your actual IDs
UPDATE consultations
SET
  status = 'calling',
  updated_at = NOW()
WHERE doctor_id = 'YOUR_DOCTOR_ID_HERE'
LIMIT 1;
```

3. **Watch doctor app** - incoming call dialog should appear!

### Real Test (Patient + Doctor)

1. ✅ Patient creates consultation
2. ✅ Patient clicks "Call Doctor"
3. ✅ Patient app updates status to `'calling'`
4. ✅ Doctor sees incoming call dialog
5. ✅ Doctor clicks Accept
6. ✅ Both join video call

---

## 🐛 Troubleshooting

### No dialog appears?

**Check Realtime is enabled:**

```bash
# Should see in doctor app console:
🎧 Starting to listen for incoming calls for doctor: <id>
```

**Check doctor is logged in:**

- IncomingCallService needs doctorId
- Make sure doctor profile loaded

**Check Supabase Realtime:**

- Dashboard → Database → Replication
- `consultations` must be enabled

### Dialog appears but can't accept?

Check your router has `/video-call` route configured.

### Multiple dialogs?

The listener might be emitting duplicates. This is handled in the code.

---

## 🎊 What's Different Now

### BEFORE (Broken):

```
Patient calls → Database updates → Doctor app: ❌ Nothing happens
```

### AFTER (Fixed):

```
Patient calls → Database updates → Realtime event → Doctor app: ✅ RING RING! 📞
```

---

## 🚀 Next Steps

1. **Run SQL script** (`fix_is_available.sql`) to fix doctor availability
2. **Enable Realtime** in Supabase for `consultations` table
3. **Test incoming calls** between patient and doctor
4. **Deploy and celebrate!** 🎉

---

## 📞 Summary

You can now receive incoming video calls! The system:

- ✅ Listens to Supabase Realtime 24/7
- ✅ Shows beautiful full-screen call dialog
- ✅ Handles accept/reject with proper status updates
- ✅ Automatically navigates to video call page
- ✅ Works for multiple concurrent calls

**No more missed calls!** 🎯
