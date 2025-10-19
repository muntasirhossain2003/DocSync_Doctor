-- ============================================
-- URGENT: Check Why No Prescriptions Found
-- ============================================

-- Your Doctor ID from logs: 92a83de4-deed-4f87-a916-4ee2d1e77827

-- Step 1: Check if prescriptions table has the new columns
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'prescriptions'
ORDER BY ordinal_position;

-- You should see: consultation_id, patient_id, doctor_id, diagnosis, etc.
-- If you only see: id, health_record_id, created_at
-- Then the SQL script didn't work properly!

-- ============================================

-- Step 2: Check ALL prescriptions in the table
SELECT 
  id,
  consultation_id,
  patient_id,
  doctor_id,
  diagnosis,
  created_at
FROM prescriptions
ORDER BY created_at DESC
LIMIT 10;

-- This shows if ANY prescriptions exist at all

-- ============================================

-- Step 3: Check prescriptions for YOUR doctor ID specifically
SELECT 
  id,
  consultation_id,
  patient_id,
  doctor_id,
  diagnosis,
  created_at
FROM prescriptions
WHERE doctor_id = '92a83de4-deed-4f87-a916-4ee2d1e77827'
ORDER BY created_at DESC;

-- If this returns 0 rows, it means:
-- 1. You haven't created any prescriptions yet (most likely)
-- 2. OR prescriptions were created with a different doctor_id
-- 3. OR prescriptions were created before running SQL script (so they don't have doctor_id)

-- ============================================

-- Step 4: Check your recent consultations
SELECT 
  c.id as consultation_id,
  c.consultation_status,
  c.prescription_id,
  c.doctor_id,
  c.scheduled_time,
  c.created_at
FROM consultations c
WHERE c.doctor_id = '92a83de4-deed-4f87-a916-4ee2d1e77827'
ORDER BY c.created_at DESC
LIMIT 5;

-- This shows your consultations and if they have prescription_id set

-- ============================================

-- Step 5: Check if trigger exists and is enabled
SELECT 
  tgname as trigger_name,
  tgenabled as is_enabled,
  tgtype as trigger_type
FROM pg_trigger 
WHERE tgrelid = 'prescriptions'::regclass;

-- Should show: trigger_update_consultation_prescription

-- ============================================

-- Step 6: Try to create a TEST prescription manually
-- (Replace the IDs with your actual IDs from Step 4)

-- First, get a consultation ID from Step 4, then:

/*
INSERT INTO prescriptions (
  consultation_id,
  patient_id,
  doctor_id,
  diagnosis,
  symptoms,
  medical_notes
) VALUES (
  '[paste-consultation-id-here]',
  '[paste-patient-id-from-consultation]',
  '92a83de4-deed-4f87-a916-4ee2d1e77827',
  'TEST: Manual prescription to verify schema',
  'Test symptoms',
  'This is a test to see if schema is correct'
) RETURNING *;
*/

-- If this INSERT fails, the schema wasn't updated correctly
-- If it succeeds, check your app - should see this prescription!

-- ============================================

-- Step 7: Check RLS policies
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE tablename = 'prescriptions';

-- Should show policies for doctors to view/create/update prescriptions

-- ============================================
-- MOST LIKELY SCENARIOS:
-- ============================================

/*
SCENARIO 1: No prescriptions created yet
- Step 2 shows 0 rows
- Step 3 shows 0 rows
- Solution: Create a prescription in the app and test again

SCENARIO 2: Schema not updated correctly
- Step 1 shows only 3 columns (id, health_record_id, created_at)
- Step 6 INSERT fails
- Solution: Run FIX_PRESCRIPTION_SCHEMA.sql again

SCENARIO 3: Old prescriptions don't have doctor_id
- Step 2 shows prescriptions with NULL doctor_id
- Step 3 shows 0 rows
- Solution: Delete old prescriptions or update them manually

SCENARIO 4: Prescriptions created but not linked
- Step 2 shows prescriptions
- Step 3 shows 0 rows (doctor_id doesn't match)
- Solution: Check what doctor_id was used during creation

SCENARIO 5: RLS policies blocking
- Step 7 shows no policies
- Solution: Run the RLS policy section of FIX_PRESCRIPTION_SCHEMA.sql
*/

-- ============================================
-- ACTION PLAN:
-- ============================================

/*
1. Run Step 1 - Check columns
   → If only 3 columns: Run FIX_PRESCRIPTION_SCHEMA.sql again
   → If 11 columns: Continue to step 2

2. Run Step 2 - Check all prescriptions
   → If 0 rows: You need to CREATE a prescription first!
   → If has rows: Continue to step 3

3. Run Step 3 - Check your prescriptions
   → If 0 rows but Step 2 had rows: doctor_id mismatch issue
   → If has rows: Prescriptions exist, but app might have caching issue

4. If Step 3 shows prescriptions exist:
   → Restart your Flutter app
   → Navigate to Prescriptions tab
   → Should appear!

5. If Step 2 shows 0 prescriptions:
   → Create a NEW prescription in the app
   → Watch the logs for:
     "📝 Creating prescription in database..."
     "✅ Prescription inserted with ID: [uuid]"
   → Then check Prescriptions tab
*/
