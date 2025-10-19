# Prescription Flow Debug Guide

## Complete Flow Check

### 1. Video Call → Create Prescription

**Steps:**

1. Start video call
2. Click "Create Prescription" button
3. Fill in prescription details
4. Save prescription
5. Return to video call
6. End call
7. Navigate to Prescriptions page

**What to Check in Logs:**

```
When creating prescription:
📝 Creating prescription...
   Consultation ID: [uuid]
   Patient ID: [uuid]
   Doctor ID: [uuid]
   Diagnosis: [text]
   Medications: [number]
   Tests: [number]
📝 Creating prescription in database...
   Consultation ID: [uuid]
   Patient ID: [uuid]
   Doctor ID: [uuid]
   Diagnosis: [text]
✅ Prescription inserted with ID: [uuid]
💊 Inserting X medications...
✅ Medications inserted
🧪 Inserting X tests...
✅ Tests inserted
✅ Prescription creation complete!
✅ Prescription created successfully!
```

### 2. Prescriptions Page Load

**When opening prescriptions page, check logs:**

```
🔄 PrescriptionsPage rebuilding...
   Status: Loading/Data/Error
✅ Current user auth_id: [uuid]
✅ User ID: [uuid]
✅ Doctor ID: [uuid]
✅ Prescriptions query response: [array]
✅ Number of prescriptions found: X
📋 Prescriptions loaded: X items
   - Diagnosis 1 (ID: [uuid])
   - Diagnosis 2 (ID: [uuid])
```

## Common Issues & Solutions

### Issue 1: "No Prescriptions Yet" but prescription was created

**Possible Causes:**

1. Doctor ID mismatch
2. Prescription created with wrong doctor_id
3. Database query not finding prescriptions
4. Provider not refreshing

**Debug Steps:**

1. Check if prescription exists in database:

```sql
SELECT * FROM prescriptions ORDER BY created_at DESC LIMIT 5;
```

2. Check doctor_id in prescription matches current doctor:

```sql
SELECT p.id, p.diagnosis, p.doctor_id, p.created_at
FROM prescriptions p
WHERE p.doctor_id = '[your-doctor-id]'
ORDER BY p.created_at DESC;
```

3. Get your doctor ID:

```sql
SELECT d.id, d.user_id, u.full_name, u.auth_id
FROM doctors d
JOIN users u ON d.user_id = u.id
WHERE u.auth_id = '[your-auth-id]';
```

### Issue 2: Prescription created but doctor_id is NULL

**Solution:** Check that doctor profile is loaded before creating prescription.

In logs, look for:

```
📝 Creating prescription...
   Doctor ID: null  ← PROBLEM!
```

If doctor ID is null, the CreatePrescriptionPage didn't receive the correct doctor ID.

### Issue 3: Provider not refreshing

**Solution:** Manual refresh button added to prescriptions page.

After creating prescription:

1. Go to Prescriptions page
2. Click refresh button (top right)
3. Check logs for refresh

### Issue 4: Database permissions (RLS)

**Check RLS policies:**

```sql
-- Check if doctor can read prescriptions
SELECT * FROM prescriptions WHERE doctor_id = '[your-doctor-id]';

-- Check RLS policies
SELECT * FROM pg_policies WHERE tablename = 'prescriptions';
```

## Quick Test Commands

### 1. Check if prescription was created:

```sql
SELECT
  p.id,
  p.diagnosis,
  p.doctor_id,
  p.consultation_id,
  p.created_at,
  d.user_id,
  u.full_name as doctor_name
FROM prescriptions p
LEFT JOIN doctors d ON p.doctor_id = d.id
LEFT JOIN users u ON d.user_id = u.id
ORDER BY p.created_at DESC
LIMIT 10;
```

### 2. Check doctor ID:

```sql
SELECT
  u.auth_id,
  u.id as user_id,
  u.full_name,
  d.id as doctor_id
FROM users u
LEFT JOIN doctors d ON u.id = d.user_id
WHERE u.auth_id = auth.uid();
```

### 3. Check prescriptions for current doctor:

```sql
WITH current_doctor AS (
  SELECT d.id as doctor_id
  FROM users u
  JOIN doctors d ON u.id = d.user_id
  WHERE u.auth_id = auth.uid()
)
SELECT
  p.*
FROM prescriptions p, current_doctor
WHERE p.doctor_id = current_doctor.doctor_id
ORDER BY p.created_at DESC;
```

## Expected Log Sequence

### Complete successful flow:

```
1. Video call starts:
📞 Starting call for consultation: [uuid]
✅ Successfully joined channel

2. Create prescription clicked:
[Navigation to CreatePrescriptionPage]

3. Prescription form filled and saved:
📝 Creating prescription...
   Consultation ID: [uuid]
   Patient ID: [uuid]
   Doctor ID: [uuid]  ← MUST NOT BE NULL!
   Diagnosis: Test diagnosis
   Medications: 2
   Tests: 1
📝 Creating prescription in database...
✅ Prescription inserted with ID: [uuid]
💊 Inserting 2 medications...
✅ Medications inserted
🧪 Inserting 1 tests...
✅ Tests inserted
✅ Prescription creation complete!
✅ Prescription created successfully!

4. Return to video call:
[Back button pressed]

5. End call:
📴 Left channel
✅ Consultation [uuid] marked as completed

6. Navigate to Prescriptions page:
🔄 PrescriptionsPage rebuilding...
   Status: Loading
✅ Current user auth_id: [uuid]
✅ User ID: [uuid]
✅ Doctor ID: [uuid]  ← MUST MATCH prescription.doctor_id!
✅ Prescriptions query response: [1 item]
✅ Number of prescriptions found: 1
📋 Prescriptions loaded: 1 items
   - Test diagnosis (ID: [uuid])
```

## Manual Testing Steps

1. **Clear all data and start fresh:**

   - Delete all prescriptions: `DELETE FROM prescriptions;`
   - Delete all consultations: `DELETE FROM consultations;`
   - Create a fresh consultation

2. **Test prescription creation:**

   - Start video call
   - Click "Create Prescription"
   - Fill minimal data (just diagnosis)
   - Save
   - Check logs for success message
   - Check database directly

3. **Test prescription display:**

   - Navigate to Prescriptions page
   - Check logs for query
   - If empty, click refresh button
   - Check logs again

4. **Verify doctor ID:**
   - Check logs for doctor_id when creating
   - Check logs for doctor_id when querying
   - They MUST match!

## Files with Logging

All these files now have comprehensive logging:

1. `create_prescription_page.dart` - Prescription creation
2. `prescription_remote_datasource.dart` - Database operations
3. `prescriptions_page.dart` - List display
4. `video_call_page.dart` - Call end and consultation completion

## If Still Not Working

1. **Share the complete log output** showing:

   - Prescription creation
   - Prescription page load
   - Doctor IDs

2. **Run these SQL queries** and share results:

   ```sql
   -- Your doctor ID
   SELECT d.id FROM doctors d
   JOIN users u ON d.user_id = u.id
   WHERE u.auth_id = auth.uid();

   -- All prescriptions
   SELECT id, diagnosis, doctor_id, created_at
   FROM prescriptions
   ORDER BY created_at DESC;

   -- Prescriptions for your doctor
   SELECT p.* FROM prescriptions p
   WHERE p.doctor_id IN (
     SELECT d.id FROM doctors d
     JOIN users u ON d.user_id = u.id
     WHERE u.auth_id = auth.uid()
   );
   ```

3. **Check RLS policies** in Supabase dashboard

---

**Last Updated:** October 19, 2025
