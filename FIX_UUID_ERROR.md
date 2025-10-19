# 🚀 QUICK FIX - Copy & Paste This

## The Error You Got

```
ERROR: 22P02: invalid input syntax for type uuid: "[consultation-id-from-above]"
```

**Cause:** You tried to insert the literal text `[consultation-id-from-above]` instead of an actual UUID.

---

## ✅ The Easy Fix

### Option 1: Use the Auto-Insert Script (RECOMMENDED)

**File:** `SIMPLE_TEST_INSERT.sql`

**Steps:**

1. Open Supabase SQL Editor
2. Copy the ENTIRE contents of `SIMPLE_TEST_INSERT.sql`
3. Paste into SQL Editor
4. Click **Run**
5. Should see output with prescription_id, diagnosis, etc.
6. Open your Flutter app
7. Go to Prescriptions tab
8. **Should see:** "AUTO TEST: Prescription created via SQL" 🎉

---

### Option 2: Create Prescription in Your App

**Steps:**

1. Open your Flutter app
2. Go to **Consultations** tab
3. Find a consultation with status "scheduled" or "in_progress"
4. Click to start/join the consultation
5. Once in video call, click **"Create Prescription"** button
6. Fill in the form:
   - **Diagnosis:** Type anything (e.g., "Test prescription")
   - **Medications:** Click + to add one medication
     - Name: "Paracetamol"
     - Dosage: "500mg"
     - Frequency: "Twice daily"
     - Duration: "3 days"
   - **Tests:** Click + to add one test (optional)
   - **Instructions:** Type anything (e.g., "Rest and hydrate")
7. Click **Save**

**Watch Terminal Logs:**

```
📝 Creating prescription...
   Doctor ID: 92a83de4-deed-4f87-a916-4ee2d1e77827  ← Check this is NOT null
   Diagnosis: Test prescription
   Medications: 1

📝 Creating prescription in database...
✅ Prescription inserted with ID: [some-uuid]  ← Must see this!
💊 Inserting 1 medications...
✅ Medications inserted
✅ Prescription creation complete!
✅ Prescription created successfully!
```

8. Navigate to **Prescriptions** tab
9. Should see your prescription!

---

## 🔍 If Option 1 Fails

### Error: "relation 'consultations' does not exist"

**Solution:** Your database structure is completely different. Contact me with your full schema.

### Error: "column 'doctor_id' does not exist"

**Solution:** SQL script wasn't run correctly. Run `FIX_PRESCRIPTION_SCHEMA.sql` again.

### Error: "no rows returned"

**Solution:** You don't have any consultations yet. Use Option 2 instead (create in app).

### Success but app shows 0 prescriptions

**Solution:**

1. Restart your Flutter app completely
2. Or click the refresh button on Prescriptions page
3. Check RLS policies:
   ```sql
   SELECT policyname FROM pg_policies WHERE tablename = 'prescriptions';
   ```
   Should show 4 policies. If 0, run FIX_PRESCRIPTION_SCHEMA.sql again.

---

## 🔍 Verify It Worked

After running SIMPLE_TEST_INSERT.sql, check database:

```sql
SELECT
  id,
  doctor_id,
  diagnosis,
  created_at
FROM prescriptions
WHERE doctor_id = '92a83de4-deed-4f87-a916-4ee2d1e77827'
ORDER BY created_at DESC
LIMIT 1;
```

**Expected result:**

- `id`: Some UUID
- `doctor_id`: 92a83de4-deed-4f87-a916-4ee2d1e77827
- `diagnosis`: AUTO TEST: Prescription created via SQL
- `created_at`: Recent timestamp

If you see this, **the prescription exists in database!**

Now check your app:

1. Open Flutter app
2. Go to Prescriptions tab
3. Click refresh button (top-right)
4. Should see the prescription!

---

## 📱 App Still Shows 0?

### Check 1: RLS Policies

```sql
SELECT * FROM pg_policies WHERE tablename = 'prescriptions';
```

**If 0 rows:** Policies missing! Run this:

```sql
ALTER TABLE public.prescriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Doctors can view their own prescriptions"
ON public.prescriptions
FOR SELECT
USING (
  doctor_id IN (
    SELECT d.id FROM doctors d
    JOIN users u ON d.user_id = u.id
    WHERE u.auth_id = auth.uid()
  )
);
```

### Check 2: Restart App

Sometimes Flutter caches data. Close and reopen the app completely.

### Check 3: Check Auth

Your app might be logged in as a different user:

```sql
-- In Supabase SQL Editor, this shows YOUR current user
SELECT auth.uid() as my_auth_id;

-- Check if this matches your app
-- Your app uses: b4ae6ab4-f5ff-42ac-a337-83e1530396e7
```

If they don't match, you're logged in as different users in app vs database.

---

## 🎯 Summary

**Easiest path:**

1. ✅ Run `SIMPLE_TEST_INSERT.sql` in Supabase
2. ✅ Check it succeeded (should show prescription data)
3. ✅ Refresh Prescriptions tab in app
4. ✅ Should see "AUTO TEST: Prescription created via SQL"

If that works, your schema is correct and app is working!

Then just create prescriptions normally through the app. 🎉

---

## 🆘 Still Not Working?

Share these results:

1. **Result of SIMPLE_TEST_INSERT.sql** (copy the output or screenshot)

2. **Result of this query:**

   ```sql
   SELECT COUNT(*) FROM prescriptions;
   SELECT column_name FROM information_schema.columns WHERE table_name = 'prescriptions';
   SELECT policyname FROM pg_policies WHERE tablename = 'prescriptions';
   ```

3. **Complete Flutter terminal logs** when you:

   - Open app
   - Navigate to Prescriptions tab
   - Click refresh button

4. **Screenshot** of Prescriptions page in app

Then I can tell you exactly what's wrong! 🔧
