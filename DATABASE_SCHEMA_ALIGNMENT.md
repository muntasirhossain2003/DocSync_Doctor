# 🎯 Database Schema Alignment - COMPLETED

## Changes Made to Match Your Supabase Schema

### Original Schema Issues

Your database schema uses:

- ✅ `consultation_status` (not `status`)
- ✅ `scheduled_time` (not `scheduled_at`)
- ✅ Values: `'scheduled', 'completed', 'canceled'`
- ❌ Missing: `'calling', 'in_progress', 'rejected'` statuses
- ❌ Missing columns: `agora_channel_name`, `agora_token`, `rejection_reason`

---

## 📋 Step 1: Run This SQL in Supabase

**File: `fix_consultations_schema.sql`**

This adds the required columns and status values for video calling:

```sql
-- Add missing columns
ALTER TABLE consultations
ADD COLUMN IF NOT EXISTS agora_channel_name TEXT,
ADD COLUMN IF NOT EXISTS agora_token TEXT,
ADD COLUMN IF NOT EXISTS rejection_reason TEXT;

-- Update status constraint to include video call statuses
ALTER TABLE consultations
DROP CONSTRAINT IF EXISTS consultations_consultation_status_check;

ALTER TABLE consultations
ADD CONSTRAINT consultations_consultation_status_check
CHECK (consultation_status IN (
    'scheduled',      -- Initial state
    'calling',        -- Patient is calling (INCOMING CALL)
    'in_progress',    -- Call is active
    'completed',      -- Call finished
    'canceled',       -- Canceled before call
    'rejected'        -- Doctor rejected call
));

-- Enable Realtime (CRITICAL for incoming calls!)
ALTER TABLE consultations REPLICA IDENTITY FULL;
```

---

## 🔧 Step 2: Enable Realtime in Supabase Dashboard

1. Go to **Database** → **Replication**
2. Find `consultations` table
3. Click **Enable replication**
4. Check ✅ **Insert** and ✅ **Update** events

**Without this, incoming calls won't work!**

---

## ✅ Code Changes Applied

### Updated `incoming_call_service.dart`

Changed all references to use correct column names:

| Old (Wrong)               | New (Correct)                          |
| ------------------------- | -------------------------------------- |
| `data['status']`          | `data['consultation_status']`          |
| `'cancelled'`             | `'canceled'` (single 'l')              |
| `scheduled_at`            | `scheduled_time`                       |
| `'status': 'in_progress'` | `'consultation_status': 'in_progress'` |

---

## 🎯 Status Flow for Video Calls

### Patient Side Flow

```
1. scheduled     → Patient books consultation
2. calling       → Patient presses "Call Doctor" button
3. in_progress   → Doctor accepts call (both join video)
4. completed     → Call ends successfully
```

OR

```
2. calling       → Patient calls
3. rejected      → Doctor declines call
```

OR

```
2. calling       → Patient calls
3. canceled      → Patient cancels before doctor answers
```

### What Patient App Should Do

```dart
// When patient wants to call doctor
await supabase
  .from('consultations')
  .update({
    'consultation_status': 'calling',  // ← Triggers incoming call on doctor side!
    'agora_channel_name': channelName,
    'agora_token': token,
    'updated_at': DateTime.now().toIso8601String(),
  })
  .eq('id', consultationId);
```

### What Doctor App Does (Automatic)

1. **Detects** `consultation_status = 'calling'` via Realtime
2. **Shows** full-screen incoming call dialog
3. **Updates to** `'in_progress'` when doctor accepts
4. **Updates to** `'rejected'` when doctor declines

---

## 🧪 Testing

### Quick Test - Simulate Incoming Call

Run this SQL in Supabase:

```sql
-- 1. Create a test consultation (or use existing)
INSERT INTO consultations (
  patient_id,
  doctor_id,
  consultation_type,
  scheduled_time,
  consultation_status,
  agora_channel_name,
  agora_token
) VALUES (
  '<PATIENT_UUID>',
  '<YOUR_DOCTOR_UUID>',
  'video',
  NOW(),
  'scheduled',
  'test_channel_123',
  'test_token_456'
) RETURNING id;

-- 2. Trigger incoming call
UPDATE consultations
SET
  consultation_status = 'calling',  -- ← This triggers incoming call dialog!
  updated_at = NOW()
WHERE doctor_id = '<YOUR_DOCTOR_UUID>'
AND id = '<CONSULTATION_ID_FROM_ABOVE>';
```

**Result**: Doctor app should immediately show incoming call dialog! 📞

---

## 📊 Database Schema Reference

### Your Consultations Table

```sql
CREATE TABLE consultations (
    id UUID PRIMARY KEY,
    patient_id UUID REFERENCES users(id),
    doctor_id UUID REFERENCES doctors(id),
    consultation_type VARCHAR(50) CHECK (consultation_type IN ('video', 'audio', 'chat')),
    scheduled_time TIMESTAMPTZ NOT NULL,
    consultation_status VARCHAR(50) CHECK (...),
    prescription_id UUID REFERENCES prescriptions(id),

    -- NEW COLUMNS (added by fix_consultations_schema.sql):
    agora_channel_name TEXT,
    agora_token TEXT,
    rejection_reason TEXT,

    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
);
```

### Status Values

| Status        | Meaning                | Who Sets It            |
| ------------- | ---------------------- | ---------------------- |
| `scheduled`   | Consultation booked    | Patient/System         |
| `calling`     | Patient calling doctor | Patient App            |
| `in_progress` | Call active            | Doctor App (on accept) |
| `completed`   | Call finished          | Patient/Doctor App     |
| `canceled`    | Canceled before call   | Patient/Doctor         |
| `rejected`    | Doctor declined call   | Doctor App             |

---

## ⚠️ Important Notes

### 1. Column Name Differences

Your schema uses **different naming** than typical:

- ✅ `consultation_status` (not `status`)
- ✅ `scheduled_time` (not `scheduled_at`)
- ✅ `canceled` with one 'l' (not `cancelled`)

**All code has been updated to match your schema!**

### 2. Doctor Reference

Your schema correctly uses:

```sql
doctor_id UUID REFERENCES doctors(id)
```

So the incoming call service filters by:

```dart
filter: PostgresChangeFilter(
  column: 'doctor_id',
  value: doctorId,  // From doctors table, not users table
)
```

### 3. User References

Your schema structure:

```
users (patient) → consultations ← doctors (doctor)
     ↑                                    ↑
  auth_id                             user_id
```

Patient info is fetched via:

```sql
patient:users!consultations_patient_id_fkey(
  id, full_name, profile_picture_url
)
```

---

## 🎊 Summary

### Files Modified

1. ✅ `incoming_call_service.dart` - Updated all column names
2. ✅ `fix_consultations_schema.sql` - New SQL script to run

### What You Need to Do

1. **Run SQL script** `fix_consultations_schema.sql` in Supabase
2. **Enable Realtime** for `consultations` table in dashboard
3. **Test incoming calls** using the SQL test above

### Expected Behavior

```
Patient updates status to 'calling'
         ↓
Supabase Realtime event
         ↓
Doctor app detects change
         ↓
Incoming call dialog appears! 🎉
         ↓
Doctor accepts → status = 'in_progress'
         ↓
Both join video call
```

---

## 🐛 Troubleshooting

### No incoming call dialog?

Check console for:

```
🎧 Starting to listen for incoming calls for doctor: <id>
📞 New consultation received: {...}
```

Verify:

- ✅ Realtime is enabled in Supabase
- ✅ `consultation_status` = `'calling'`
- ✅ Doctor is logged in
- ✅ SQL script was run successfully

### Can't accept call?

Check:

- ✅ `/video-call` route exists in router
- ✅ `agora_channel_name` and `agora_token` are set

---

## ✨ All Done!

Your incoming call system is now **fully aligned with your database schema**!

Run the SQL script and enable Realtime to start receiving calls. 📞🎉
