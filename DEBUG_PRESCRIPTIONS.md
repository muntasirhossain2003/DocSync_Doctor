# 🔍 Debug Prescription Issue

## ✅ What We Know

1. ✅ Database migration ran successfully
2. ✅ Prescription creation shows "success" message
3. ❌ Prescriptions not showing in list

## 🎯 Debugging Steps

### Step 1: Hot Reload with Debug Logs

I've added debug logs to see what's happening. Hot reload the app:

1. In terminal (where Flutter is running), press: **`r`**
2. Go to **Prescriptions** tab
3. Check terminal output for these messages:

Expected output:

```
✅ Current user auth_id: xxx-xxx-xxx
✅ User ID: xxx-xxx-xxx
✅ Doctor ID: xxx-xxx-xxx
✅ Prescriptions query response: [...]
✅ Number of prescriptions found: X
```

If you see errors like:

- `❌ User not authenticated` → You're not logged in
- `❌ User not found in users table` → Your user record is missing
- `❌ Doctor profile not found` → You don't have a doctor profile

### Step 2: Check Database Directly

Run this in Supabase SQL Editor:

```sql
-- 1. Check if prescription was created
SELECT id, doctor_id, patient_id, diagnosis, created_at
FROM prescriptions
ORDER BY created_at DESC
LIMIT 5;

-- 2. Check your doctor ID
SELECT
  u.id as user_id,
  u.auth_id,
  u.full_name,
  d.id as doctor_id
FROM users u
LEFT JOIN doctors d ON d.user_id = u.id
WHERE u.auth_id = auth.uid();

-- 3. If prescriptions exist, check if doctor_id matches
SELECT
  p.id,
  p.doctor_id as prescription_doctor_id,
  d.id as your_doctor_id,
  p.diagnosis
FROM prescriptions p
CROSS JOIN (
  SELECT d.id
  FROM users u
  JOIN doctors d ON d.user_id = u.id
  WHERE u.auth_id = auth.uid()
) d;
```

### Step 3: Common Issues & Fixes

#### Issue 1: Prescription created without doctor_id

**Check:**

```sql
SELECT id, doctor_id, diagnosis
FROM prescriptions
WHERE doctor_id IS NULL;
```

**If found:** Old prescriptions created before migration. Update them:

```sql
UPDATE prescriptions
SET doctor_id = (
  SELECT d.id
  FROM users u
  JOIN doctors d ON d.user_id = u.id
  WHERE u.auth_id = auth.uid()
)
WHERE doctor_id IS NULL;
```

#### Issue 2: RLS Policy blocking SELECT

**Check policies:**

```sql
SELECT policyname, cmd, qual
FROM pg_policies
WHERE tablename = 'prescriptions'
  AND cmd = 'SELECT';
```

**Expected:** `Doctors can view their prescriptions`

**If missing, recreate:**

```sql
DROP POLICY IF EXISTS "Doctors can view their prescriptions" ON prescriptions;

CREATE POLICY "Doctors can view their prescriptions"
ON prescriptions FOR SELECT
USING (
  doctor_id IN (
    SELECT d.id FROM doctors d
    INNER JOIN users u ON u.id = d.user_id
    WHERE u.auth_id = auth.uid()
  )
);
```

#### Issue 3: Doctor profile doesn't exist

**Check:**

```sql
SELECT u.id, u.full_name, d.id as doctor_id
FROM users u
LEFT JOIN doctors d ON d.user_id = u.id
WHERE u.auth_id = auth.uid();
```

**If doctor_id is NULL:** You need to create a doctor profile first.

### Step 4: Create Test Prescription in Database

Let's manually insert a prescription to test:

```sql
-- First, get your doctor_id
WITH doctor_info AS (
  SELECT d.id as doctor_id, u.id as user_id
  FROM users u
  JOIN doctors d ON d.user_id = u.id
  WHERE u.auth_id = auth.uid()
)
-- Insert test prescription
INSERT INTO prescriptions (
  doctor_id,
  patient_id,
  diagnosis,
  symptoms,
  medical_notes,
  created_at
)
SELECT
  doctor_id,
  user_id, -- using user_id as patient_id for test
  'Test Diagnosis',
  'Test symptoms',
  'Test notes',
  NOW()
FROM doctor_info
RETURNING *;
```

Then refresh the app and see if it appears.

### Step 5: Check App Logs

After hot reload, go to Prescriptions tab and look for:

**In terminal output:**

```
I/flutter: ✅ Current user auth_id: ...
I/flutter: ✅ User ID: ...
I/flutter: ✅ Doctor ID: ...
I/flutter: ✅ Number of prescriptions found: ...
```

**If you see:**

- `Number of prescriptions found: 0` → Database has no matching prescriptions
- Error messages → There's an exception being thrown

### Step 6: Force Refresh

In the app:

1. Go to **Prescriptions** tab
2. **Pull down** to refresh
3. Check terminal for debug logs

## 🚀 Quick Fix Checklist

- [ ] Hot reload app (press `r`)
- [ ] Go to Prescriptions tab
- [ ] Check terminal for debug logs
- [ ] Run SQL queries in Supabase to verify data
- [ ] Check if doctor_id matches between your profile and prescriptions
- [ ] Try creating a new prescription after migration
- [ ] Pull to refresh in Prescriptions tab

## 📊 Most Likely Issues

### 1. Prescription created before migration (no doctor_id)

**Fix:** Update old prescriptions with doctor_id (see SQL above)

### 2. Doctor ID mismatch

**Fix:** Verify your doctor ID matches prescriptions doctor_id

### 3. RLS Policy issue

**Fix:** Recreate SELECT policy (see SQL above)

### 4. No doctor profile

**Fix:** Create doctor profile in app

## 🎯 Next Steps

1. **Hot reload** (press `r`)
2. **Go to Prescriptions tab**
3. **Check terminal output** - send me the logs
4. **Run SQL queries** - send me the results
5. I'll tell you exactly what's wrong!

---

**Send me:**

1. Terminal output after going to Prescriptions tab
2. Result of this SQL:

```sql
SELECT id, doctor_id, diagnosis FROM prescriptions ORDER BY created_at DESC LIMIT 3;
```

3. Result of this SQL:

```sql
SELECT d.id as doctor_id FROM users u JOIN doctors d ON d.user_id = u.id WHERE u.auth_id = auth.uid();
```

Then I can pinpoint the exact issue! 🔍
