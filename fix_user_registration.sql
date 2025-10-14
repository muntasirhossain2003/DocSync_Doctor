-- ============================================
-- CRITICAL FIX: Auto-create user records
-- ============================================
-- This trigger automatically creates a record in the users table
-- whenever someone registers via Supabase Auth

-- Step 1: Create the trigger function
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.users (auth_id, email, role, full_name, created_at, updated_at)
  VALUES (
    NEW.id,
    NEW.email,
    'doctor', -- Default role, can be updated later
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email), -- Use full_name from metadata or email
    NOW(),
    NOW()
  )
  ON CONFLICT (auth_id) DO NOTHING; -- Prevent duplicate entries
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 2: Create the trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Step 3: Verify the trigger exists
SELECT 
    trigger_name, 
    event_manipulation, 
    event_object_table, 
    action_statement
FROM information_schema.triggers
WHERE trigger_name = 'on_auth_user_created';

-- ============================================
-- Fix existing users (if any)
-- ============================================
-- This will create user records for any auth users that don't have one

INSERT INTO public.users (auth_id, email, role, full_name, created_at, updated_at)
SELECT 
    au.id as auth_id,
    au.email,
    'doctor' as role,
    COALESCE(au.raw_user_meta_data->>'full_name', au.email) as full_name,
    au.created_at,
    NOW() as updated_at
FROM auth.users au
LEFT JOIN public.users u ON au.id = u.auth_id
WHERE u.id IS NULL -- Only insert if user record doesn't exist
ON CONFLICT (auth_id) DO NOTHING;

-- ============================================
-- Verify everything is working
-- ============================================

-- Check if trigger exists
SELECT tgname, tgtype, tgenabled 
FROM pg_trigger 
WHERE tgname = 'on_auth_user_created';

-- Check auth users
SELECT id, email, created_at FROM auth.users ORDER BY created_at DESC LIMIT 5;

-- Check users table
SELECT id, auth_id, email, role, full_name FROM users ORDER BY created_at DESC LIMIT 5;

-- Check if there are any auth users without user records
SELECT 
    au.id as auth_id,
    au.email,
    CASE WHEN u.id IS NULL THEN 'MISSING' ELSE 'EXISTS' END as user_record_status
FROM auth.users au
LEFT JOIN public.users u ON au.id = u.auth_id
ORDER BY au.created_at DESC;
