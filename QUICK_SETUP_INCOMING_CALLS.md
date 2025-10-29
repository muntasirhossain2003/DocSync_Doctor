# 🚀 Quick Setup Guide - Incoming Call System

## ⚡ 3 Steps to Get Incoming Calls Working

### Step 1️⃣: Run SQL Script

Open **Supabase SQL Editor** and run `fix_consultations_schema.sql`:

```sql
-- Adds missing columns and status values
ALTER TABLE consultations
ADD COLUMN IF NOT EXISTS agora_channel_name TEXT,
ADD COLUMN IF NOT EXISTS agora_token TEXT,
ADD COLUMN IF NOT EXISTS rejection_reason TEXT;

-- Update status values to include calling/in_progress/rejected
ALTER TABLE consultations
DROP CONSTRAINT IF EXISTS consultations_consultation_status_check;

ALTER TABLE consultations
ADD CONSTRAINT consultations_consultation_status_check
CHECK (consultation_status IN (
    'scheduled', 'calling', 'in_progress',
    'completed', 'canceled', 'rejected'
));

-- Enable Realtime
ALTER TABLE consultations REPLICA IDENTITY FULL;
```

### Step 2️⃣: Enable Realtime in Dashboard

1. **Database** → **Replication**
2. Find `consultations` table
3. Click **Enable replication**
4. Check ✅ Insert and ✅ Update

### Step 3️⃣: Test Incoming Call

Run this SQL to simulate a call:

```sql
UPDATE consultations
SET
  consultation_status = 'calling',
  agora_channel_name = 'test_123',
  agora_token = 'test_token',
  updated_at = NOW()
WHERE doctor_id = '<YOUR_DOCTOR_ID>'
LIMIT 1;
```

**Result**: Incoming call dialog should appear! 📞

---

## 📱 Patient App Integration

When patient wants to call:

```dart
await supabase
  .from('consultations')
  .update({
    'consultation_status': 'calling',  // ← Triggers doctor's incoming call
    'agora_channel_name': channelName,
    'agora_token': token,
    'updated_at': DateTime.now().toIso8601String(),
  })
  .eq('id', consultationId);
```

---

## ✅ What's Fixed

- ✅ Updated to use `consultation_status` (your column name)
- ✅ Updated to use `scheduled_time` (your column name)
- ✅ Fixed status value: `'canceled'` (single 'l')
- ✅ Added support for `'calling'`, `'in_progress'`, `'rejected'` statuses
- ✅ Incoming call service now matches your exact database schema

---

## 🎯 Status Flow

```
scheduled → calling → in_progress → completed
              ↓
           rejected
           canceled
```

---

## ⚠️ Important

**Must run SQL script FIRST** before testing!

The script adds required columns:

- `agora_channel_name` (for Agora channel)
- `agora_token` (for Agora authentication)
- `rejection_reason` (when doctor declines)

Without these, incoming calls won't work.

---

## 🐛 Troubleshooting

**No dialog appears?**

- Check Realtime is enabled
- Check doctor is logged in
- Check `consultation_status = 'calling'`

**Can't join call?**

- Check `agora_channel_name` is set
- Check `agora_token` is set
- Check `/video-call` route exists

---

## 📄 Full Documentation

See `DATABASE_SCHEMA_ALIGNMENT.md` for complete details.

---

**That's it! You're ready to receive video calls! 🎉**
