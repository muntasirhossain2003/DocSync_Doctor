-- ========================================
-- VERIFY PRESCRIPTION TABLES EXIST
-- Run this in Supabase SQL Editor to check if tables are created
-- ========================================

-- Check if prescriptions table exists
SELECT EXISTS (
  SELECT FROM information_schema.tables 
  WHERE table_schema = 'public' 
  AND table_name = 'prescriptions'
) as prescriptions_exists;

-- Check if prescription_medications table exists
SELECT EXISTS (
  SELECT FROM information_schema.tables 
  WHERE table_schema = 'public' 
  AND table_name = 'prescription_medications'
) as prescription_medications_exists;

-- Check if medical_tests table exists
SELECT EXISTS (
  SELECT FROM information_schema.tables 
  WHERE table_schema = 'public' 
  AND table_name = 'medical_tests'
) as medical_tests_exists;

-- If any return FALSE, you need to run create_prescriptions_schema.sql first!

-- ========================================
-- CHECK COLUMNS IN PRESCRIPTIONS TABLE
-- ========================================
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'prescriptions'
ORDER BY ordinal_position;

-- ========================================
-- CHECK RLS POLICIES
-- ========================================
SELECT schemaname, tablename, policyname, cmd
FROM pg_policies 
WHERE schemaname = 'public' 
  AND tablename IN ('prescriptions', 'prescription_medications', 'medical_tests')
ORDER BY tablename, policyname;

-- ========================================
-- TEST QUERY: Get prescriptions for a doctor
-- Replace with your actual auth user ID
-- ========================================
-- First, find your user_id from auth_id
SELECT u.id as user_id, d.id as doctor_id
FROM users u
LEFT JOIN doctors d ON d.user_id = u.id
WHERE u.auth_id = auth.uid(); -- This will show your current user

-- Then check if you have any prescriptions
SELECT COUNT(*) as prescription_count
FROM prescriptions;

-- Check sample data
SELECT id, diagnosis, created_at
FROM prescriptions
LIMIT 5;
