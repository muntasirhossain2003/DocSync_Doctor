# 🐛 Fixed: Consultations Not Showing + Incoming Calls Not Working

## Issues Found & Fixed

### Issue 1: Consultations Not Showing on Home Page ❌

**Problem**: Doctor home page shows "No upcoming consultations" even though patient side has data.

**Root Cause**:

1. Query only fetched `consultation_status = 'scheduled'`
2. Didn't include `'calling'` or `'in_progress'` statuses
3. Missed consultations that are currently active

**Fix Applied**: ✅

```dart
// OLD (Wrong):
.eq('consultation_status', 'scheduled')

// NEW (Fixed):
.inFilter('consultation_status', ['scheduled', 'calling', 'in_progress'])
```

### Issue 2: Wrong Status Value for Canceled ❌

**Problem**: Used `'cancelled'` (double 'l') but your database has `'canceled'` (single 'l')

**Fix Applied**: ✅

```dart
// OLD (Wrong):
.eq('consultation_status', 'cancelled')

// NEW (Fixed):
.inFilter('consultation_status', ['canceled', 'rejected'])
```

### Issue 3: Incoming Calls Don't Show Anything ❌

**Problem**:

1. Missing `agora_channel_name`, `agora_token`, `rejection_reason` columns
2. Missing status values: `'calling'`, `'in_progress'`, `'rejected'`
3. Realtime not enabled

**Fix Required**: Run SQL scripts! ⚠️

---

## 🔧 What You MUST Do Now

### Step 1: Run SQL Scripts in Supabase

#### A) Fix Consultations Table

Run `fix_consultations_schema.sql`:

```sql
-- Add missing columns
ALTER TABLE consultations
ADD COLUMN IF NOT EXISTS agora_channel_name TEXT,
ADD COLUMN IF NOT EXISTS agora_token TEXT,
ADD COLUMN IF NOT EXISTS rejection_reason TEXT;

-- Add new status values
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

#### B) Create Test Data

Run `create_test_consultations.sql`:

1. First, get your IDs:

```sql
-- Get doctor_id
SELECT d.id as doctor_id, u.full_name
FROM doctors d
JOIN users u ON d.user_id = u.id;

-- Get patient_id
SELECT id as patient_id, full_name
FROM users
WHERE role = 'patient';
```

2. Edit the file and replace `<YOUR_DOCTOR_ID>` and `<YOUR_PATIENT_ID>`

3. Run the script to create test consultations

### Step 2: Enable Realtime in Supabase Dashboard

1. Go to **Database** → **Replication**
2. Find `consultations` table
3. **Enable replication**
4. Check ✅ **Insert** and ✅ **Update**

### Step 3: Test Incoming Call

Run this SQL to trigger incoming call:

```sql
UPDATE consultations
SET
  consultation_status = 'calling',
  agora_channel_name = 'test_channel_123',
  agora_token = 'test_token_456',
  updated_at = NOW()
WHERE doctor_id = '<YOUR_DOCTOR_ID>'
AND consultation_status = 'scheduled'
LIMIT 1;
```

Expected: Incoming call dialog appears! 📞

### Step 4: Refresh Your App

1. Stop the app
2. Run `flutter pub get`
3. Run `flutter run -d chrome` (or your device)
4. Check home page → Should see upcoming consultations now!

---

## ✅ What's Fixed in Code

### File: `doctor_remote_datasource.dart`

#### 1. getUpcomingConsultations()

```dart
// Now includes: scheduled, calling, in_progress
.inFilter('consultation_status', ['scheduled', 'calling', 'in_progress'])
```

#### 2. getCancelledConsultations()

```dart
// Fixed: canceled (single 'l') + added rejected
.inFilter('consultation_status', ['canceled', 'rejected'])
```

---

## 🎯 Expected Results After Fix

### Home Page

✅ Shows upcoming consultations (scheduled + calling + in_progress)
✅ Shows patient names and scheduled times
✅ Horizontal scrollable consultation cards

### Consultations Tab

✅ **Upcoming**: All future consultations
✅ **Completed**: Past finished consultations
✅ **Canceled**: Includes rejected consultations

### Incoming Calls

✅ Shows full-screen dialog when status = 'calling'
✅ Displays patient name and avatar
✅ Accept/Reject buttons work
✅ Updates status to 'in_progress' on accept
✅ Updates status to 'rejected' on decline

---

## 📊 Database Status Values

| Status        | Meaning              | Shows In                            |
| ------------- | -------------------- | ----------------------------------- |
| `scheduled`   | Booked, not started  | Upcoming Tab                        |
| `calling`     | Patient calling NOW  | Upcoming Tab + Incoming Call Dialog |
| `in_progress` | Call is active       | Upcoming Tab                        |
| `completed`   | Call finished        | Completed Tab                       |
| `canceled`    | Canceled before call | Canceled Tab                        |
| `rejected`    | Doctor declined      | Canceled Tab                        |

---

## 🐛 Troubleshooting

### Still no consultations showing?

1. **Check database**:

```sql
SELECT * FROM consultations
WHERE doctor_id = '<YOUR_DOCTOR_ID>';
```

2. **Check scheduled_time**:

```sql
SELECT
    consultation_status,
    scheduled_time,
    scheduled_time > NOW() as is_future
FROM consultations
WHERE doctor_id = '<YOUR_DOCTOR_ID>';
```

3. **Verify doctor_id matches**:

```sql
SELECT d.id, d.user_id, u.email
FROM doctors d
JOIN users u ON d.user_id = u.id;
```

### Incoming call dialog not appearing?

1. **Check Realtime is enabled**
2. **Check consultation has 'calling' status**
3. **Check agora_channel_name and agora_token are set**
4. **Check console for "Starting to listen for incoming calls"**

### Wrong patient/doctor connection?

Check foreign keys:

```sql
SELECT
    c.id,
    c.patient_id,
    p.full_name as patient,
    c.doctor_id,
    d.user_id
FROM consultations c
JOIN users p ON c.patient_id = p.id
JOIN doctors d ON c.doctor_id = d.id
WHERE c.doctor_id = '<YOUR_DOCTOR_ID>';
```

---

## 📄 Files Modified

1. ✅ `doctor_remote_datasource.dart` - Fixed consultation queries
2. ✅ `fix_consultations_schema.sql` - Database schema updates
3. ✅ `create_test_consultations.sql` - Test data generator

---

## 🎊 Summary

**What was wrong:**

- Consultation queries didn't include all status values
- Used wrong spelling for 'canceled'
- Database missing columns for video calling
- Realtime not configured

**What's fixed:**

- ✅ Updated queries to fetch all active consultations
- ✅ Fixed 'canceled' vs 'cancelled' typo
- ✅ Created SQL scripts to add missing columns
- ✅ Added test data generator

**What you need to do:**

1. Run `fix_consultations_schema.sql`
2. Run `create_test_consultations.sql` (after replacing IDs)
3. Enable Realtime in Supabase Dashboard
4. Restart app

**Then you'll see:**

- ✅ Consultations on home page
- ✅ Incoming call dialogs
- ✅ All consultation tabs working
- ✅ Accept/reject calls functional

---

🎉 **Everything is ready! Just run the SQL scripts and enable Realtime!**
