-- ============================================
-- AUTO-INSERT TEST PRESCRIPTION
-- This script automatically gets the right IDs and inserts a test prescription
-- ============================================

-- Step 1: Verify columns exist
SELECT column_name 
FROM information_schema.columns 
WHERE table_name = 'prescriptions'
ORDER BY ordinal_position;

-- You should see 11 columns. If only 3, stop and run FIX_PRESCRIPTION_SCHEMA.sql first!

-- ============================================

-- Step 2: Get your consultation details automatically
WITH latest_consultation AS (
  SELECT 
    c.id as consultation_id,
    c.patient_id,
    c.doctor_id,
    c.scheduled_time,
    pu.full_name as patient_name
  FROM consultations c
  JOIN users pu ON c.patient_id = pu.id
  WHERE c.doctor_id = '92a83de4-deed-4f87-a916-4ee2d1e77827'
  ORDER BY c.created_at DESC
  LIMIT 1
)
SELECT * FROM latest_consultation;

-- This shows your latest consultation with all IDs
-- Copy the consultation_id and patient_id for next step

-- ============================================

-- Step 3: Insert test prescription using the IDs from Step 2
-- REPLACE the values in brackets with actual UUIDs from Step 2

WITH latest_consultation AS (
  SELECT 
    c.id as consultation_id,
    c.patient_id
  FROM consultations c
  WHERE c.doctor_id = '92a83de4-deed-4f87-a916-4ee2d1e77827'
  ORDER BY c.created_at DESC
  LIMIT 1
)
INSERT INTO prescriptions (
  consultation_id,
  patient_id,
  doctor_id,
  diagnosis,
  symptoms,
  medical_notes
)
SELECT 
  consultation_id,
  patient_id,
  '92a83de4-deed-4f87-a916-4ee2d1e77827' as doctor_id,
  'Manual Test Prescription - Auto Insert' as diagnosis,
  'Test symptoms for verification' as symptoms,
  'This prescription was inserted manually to test if schema works correctly' as medical_notes
FROM latest_consultation
RETURNING *;

-- This automatically gets your latest consultation and inserts a prescription
-- If it succeeds, you'll see the new prescription data!

-- ============================================

-- Step 4: Verify the prescription was created
SELECT 
  p.id,
  p.consultation_id,
  p.doctor_id,
  p.patient_id,
  p.diagnosis,
  p.created_at,
  c.prescription_id as consultation_has_prescription_id
FROM prescriptions p
LEFT JOIN consultations c ON p.consultation_id = c.id
WHERE p.doctor_id = '92a83de4-deed-4f87-a916-4ee2d1e77827'
ORDER BY p.created_at DESC
LIMIT 1;

-- This shows:
-- 1. The prescription you just created
-- 2. If the consultation.prescription_id was updated (should match p.id)

-- ============================================

-- Step 5: Check if trigger fired correctly
SELECT 
  c.id as consultation_id,
  c.prescription_id,
  p.id as actual_prescription_id,
  CASE 
    WHEN c.prescription_id = p.id THEN '✅ MATCHED - Trigger worked!'
    WHEN c.prescription_id IS NULL THEN '❌ NULL - Trigger did not fire'
    ELSE '⚠️ MISMATCH - Wrong prescription_id'
  END as status
FROM consultations c
LEFT JOIN prescriptions p ON p.consultation_id = c.id
WHERE c.doctor_id = '92a83de4-deed-4f87-a916-4ee2d1e77827'
  AND p.id IS NOT NULL
ORDER BY p.created_at DESC
LIMIT 1;

-- ============================================
-- ALTERNATIVE: Manual insert if you don't have consultations
-- ============================================

-- If Step 2 returns no rows, you don't have any consultations yet.
-- You need to create a consultation first, OR run this to create everything:

/*
-- First create a test patient (skip if you have one)
-- Then create a test consultation
-- Then create prescription

-- This is more complex, so it's better to create a consultation 
-- through your app first, then run the scripts above.
*/

-- ============================================
-- AFTER RUNNING THIS SCRIPT
-- ============================================

/*
1. If Step 3 succeeds:
   ✅ Prescription was created
   ✅ Go to your app
   ✅ Refresh Prescriptions tab (or restart app)
   ✅ You should see "Manual Test Prescription - Auto Insert"

2. If Step 3 fails with "column does not exist":
   ❌ Schema wasn't updated
   ❌ Run FIX_PRESCRIPTION_SCHEMA.sql again
   ❌ Then try this script again

3. If Step 5 shows "NULL - Trigger did not fire":
   ⚠️ Trigger not working
   ⚠️ Run the trigger creation part of FIX_PRESCRIPTION_SCHEMA.sql again

4. If everything succeeds but app still shows 0 prescriptions:
   ⚠️ RLS policy issue
   ⚠️ Run the RLS policy section of FIX_PRESCRIPTION_SCHEMA.sql again
   ⚠️ Or try restarting your app
*/
