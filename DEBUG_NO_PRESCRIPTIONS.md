# 🔍 DEBUG CHECKLIST - No Prescriptions Appearing

## First, Answer These Questions:

### ❓ Question 1: Did you run the SQL script?

**File:** `FIX_PRESCRIPTION_SCHEMA.sql`

- [ ] YES - I ran it in Supabase SQL Editor
- [ ] NO - I haven't run it yet
- [ ] UNSURE - I don't know if I ran it

**If NO or UNSURE:** That's the problem! Run the SQL script first, then test again.

---

### ❓ Question 2: What do you see in Flutter logs?

When you create a prescription, check the terminal. Do you see:

**Option A - Nothing saved:**

```
📝 Creating prescription...
❌ Failed to create prescription: [error message]
```

**Option B - Saved but not appearing:**

```
📝 Creating prescription...
✅ Prescription inserted with ID: [uuid]
✅ Prescription creation complete!
🔄 PrescriptionsPage rebuilding...
📋 Prescriptions loaded: 0 items  ← PROBLEM!
```

**Option C - No logs at all:**

```
[No output when creating prescription]
```

**Which one do you see?** Share the exact log output.

---

### ❓ Question 3: Database State Check

**Run this in Supabase SQL Editor:**

```sql
SELECT column_name FROM information_schema.columns
WHERE table_name = 'prescriptions'
ORDER BY ordinal_position;
```

**How many rows returned?**

- [ ] 3 rows (id, health_record_id, created_at) → **SQL script NOT run yet!**
- [ ] 11 rows (includes consultation_id, doctor_id, etc.) → **SQL script was run ✅**

---

## Debugging Steps Based on Your Answers

### If SQL Script NOT Run (3 columns only):

**STOP EVERYTHING and do this:**

1. Open Supabase Dashboard
2. Go to SQL Editor
3. Open `FIX_PRESCRIPTION_SCHEMA.sql`
4. Copy the ENTIRE file
5. Paste into SQL Editor
6. Click RUN
7. Wait for "Success" message
8. Then test prescription creation again

**Nothing else will work until you run this SQL script!**

---

### If SQL Script WAS Run (11 columns):

Let's check what's happening:

#### Step 1: Check if prescriptions are being saved

```sql
SELECT * FROM prescriptions ORDER BY created_at DESC LIMIT 5;
```

**Result:**

- **0 rows:** Prescriptions aren't being saved to database at all
- **Has rows:** Prescriptions ARE saved, but query/display issue

#### Step 2: If prescriptions exist, check doctor_id

```sql
-- Get your doctor ID
SELECT d.id as my_doctor_id FROM doctors d
JOIN users u ON d.user_id = u.id
WHERE u.auth_id = auth.uid();

-- Check prescriptions for your doctor
SELECT
  p.id,
  p.doctor_id,
  p.diagnosis,
  p.created_at
FROM prescriptions p
WHERE p.doctor_id = '[paste-your-doctor-id-here]'
ORDER BY p.created_at DESC;
```

**Result:**

- **0 rows:** Your doctor_id doesn't match prescriptions
- **Has rows:** Prescriptions exist but app query is wrong

#### Step 3: Check Flutter logs in detail

Share the COMPLETE log sequence:

1. When you click "Create Prescription"
2. When you fill the form
3. When you click Save
4. When you navigate to Prescriptions tab

---

## Common Issues & Solutions

### Issue 1: SQL Script Not Run

**Symptom:** Only 3 columns in prescriptions table  
**Solution:** Run `FIX_PRESCRIPTION_SCHEMA.sql` NOW

### Issue 2: Doctor ID is NULL

**Symptom:** Logs show `Doctor ID: null`  
**Solution:** Check doctor profile loads correctly

### Issue 3: Insert Fails Silently

**Symptom:** No error but no success log either  
**Solution:** Check RLS policies with:

```sql
SELECT * FROM pg_policies WHERE tablename = 'prescriptions';
```

### Issue 4: Prescriptions Saved but Not Queried

**Symptom:** Database has prescriptions but app shows 0  
**Solution:** Doctor ID mismatch - check query in datasource

### Issue 5: No Logs at All

**Symptom:** Terminal shows nothing  
**Solution:** App not running or logs not visible - restart app

---

## Quick Test to Isolate Issue

### Test 1: Manual Database Insert

Run this in Supabase SQL Editor (replace with your IDs):

```sql
-- Get your IDs first
SELECT
  u.id as patient_id,
  d.id as doctor_id,
  c.id as consultation_id
FROM consultations c
JOIN doctors d ON c.doctor_id = d.id
JOIN users u ON c.patient_id = u.id
JOIN users du ON d.user_id = du.id
WHERE du.auth_id = auth.uid()
ORDER BY c.created_at DESC
LIMIT 1;

-- Then insert manually (replace [xxx] with actual IDs from above)
INSERT INTO prescriptions (
  consultation_id,
  patient_id,
  doctor_id,
  diagnosis,
  symptoms,
  medical_notes
) VALUES (
  '[consultation-id]',
  '[patient-id]',
  '[doctor-id]',
  'Manual test prescription',
  'Test symptoms',
  'This is a manual test'
) RETURNING *;
```

**If this fails:**

- SQL script wasn't run correctly
- RLS policies blocking insert

**If this succeeds:**

- Check Prescriptions tab in app
- Should see "Manual test prescription"
- If you see it: App query works, creation logic is the issue
- If you don't see it: App query is the issue

---

## What I Need From You

Please provide:

1. **Answer to Question 1:** Did you run SQL script? YES/NO/UNSURE

2. **Database column check result:**

   ```sql
   SELECT column_name FROM information_schema.columns
   WHERE table_name = 'prescriptions';
   ```

   How many rows? What are they?

3. **Complete Flutter logs** from:

   - Create prescription
   - Navigate to Prescriptions tab

4. **Database check:**

   ```sql
   SELECT COUNT(*) FROM prescriptions;
   ```

   What number?

5. **Trigger check:**
   ```sql
   SELECT tgname FROM pg_trigger
   WHERE tgrelid = 'prescriptions'::regclass;
   ```
   Any results?

---

## Most Likely Cause

**90% chance:** You haven't run `FIX_PRESCRIPTION_SCHEMA.sql` yet.

**10% chance:** SQL script ran but there's another issue (RLS, doctor_id, etc.)

**To confirm:** Run the first query above and share how many columns you see.

---

## Next Steps

1. **Run** `CHECK_DATABASE_STATE.sql` (just created)
2. **Share** results of all queries
3. **Share** Flutter terminal logs
4. I'll tell you exactly what's wrong and how to fix it

**Don't try anything else until we verify the database state!**
