-- ============================================
-- SIMPLE ONE-CLICK TEST
-- Copy this entire script and run in Supabase SQL Editor
-- ============================================

-- This will automatically:
-- 1. Get your latest consultation
-- 2. Insert a test prescription
-- 3. Show the result

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
  '92a83de4-deed-4f87-a916-4ee2d1e77827',
  'AUTO TEST: Prescription created via SQL',
  'Test symptoms',
  'If you see this in your app, the fix worked!'
FROM latest_consultation
RETURNING 
  id as prescription_id,
  diagnosis,
  doctor_id,
  created_at;

-- ============================================
-- After running this:
-- 1. Check the output - should show the new prescription
-- 2. Open your Flutter app
-- 3. Go to Prescriptions tab (or click refresh button)
-- 4. You should see: "AUTO TEST: Prescription created via SQL"
-- ============================================
