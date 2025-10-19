-- ============================================
-- CHECK DATABASE STATE - Run this first!
-- ============================================

-- Step 1: Check if prescriptions table has the required columns
SELECT 
  column_name, 
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'prescriptions'
ORDER BY ordinal_position;

-- Expected result: Should show 11 columns
-- If you only see 3 columns (id, health_record_id, created_at), 
-- then you HAVEN'T run the FIX_PRESCRIPTION_SCHEMA.sql yet!

-- ============================================

-- Step 2: Check if any prescriptions exist at all
SELECT COUNT(*) as total_prescriptions FROM prescriptions;

-- Step 3: See all prescriptions (if any)
SELECT * FROM prescriptions ORDER BY created_at DESC LIMIT 10;

-- ============================================

-- Step 4: Check your doctor ID
SELECT 
  u.auth_id,
  u.id as user_id,
  u.full_name,
  u.role,
  d.id as doctor_id,
  d.specialization
FROM users u
LEFT JOIN doctors d ON u.id = d.user_id
WHERE u.auth_id = auth.uid();

-- ============================================

-- Step 5: Check recent consultations
SELECT 
  c.id as consultation_id,
  c.consultation_status,
  c.prescription_id,
  c.scheduled_time,
  c.created_at,
  d.id as doctor_id,
  du.full_name as doctor_name,
  pu.full_name as patient_name
FROM consultations c
LEFT JOIN doctors d ON c.doctor_id = d.id
LEFT JOIN users du ON d.user_id = du.id
LEFT JOIN users pu ON c.patient_id = pu.id
WHERE du.auth_id = auth.uid()
ORDER BY c.created_at DESC
LIMIT 5;

-- ============================================

-- Step 6: Check if trigger exists
SELECT 
  tgname as trigger_name,
  tgenabled as is_enabled
FROM pg_trigger 
WHERE tgrelid = 'prescriptions'::regclass;

-- If this returns no rows, the trigger wasn't created
-- Meaning you haven't run the FIX_PRESCRIPTION_SCHEMA.sql yet

-- ============================================

-- Step 7: Check RLS policies on prescriptions
SELECT 
  policyname as policy_name,
  cmd as command_type
FROM pg_policies 
WHERE tablename = 'prescriptions';

-- If this returns no rows, RLS policies weren't created
-- Meaning you haven't run the FIX_PRESCRIPTION_SCHEMA.sql yet

-- ============================================
-- INSTRUCTIONS:
-- ============================================

/*
Run each query above in order and share the results.

CRITICAL QUESTION:
Did you run the FIX_PRESCRIPTION_SCHEMA.sql file in Supabase SQL Editor?

If NO:
  → That's why prescriptions don't appear!
  → Go run FIX_PRESCRIPTION_SCHEMA.sql NOW
  → Then test again

If YES:
  → Share the results of queries above
  → We'll debug based on what you see
*/
