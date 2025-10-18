-- ============================================
-- QUICK FIX: Create missing user record
-- ============================================
-- This will fix the "User not found for auth_id" error
-- Run this in Supabase SQL Editor

-- Option 1: Fix YOUR specific user (replace with your actual auth_id if different)
INSERT INTO public.users (auth_id, email, role, full_name, created_at, updated_at)
VALUES (
    'efd8e232-7dec-4875-94b3-9e842ae06424', -- Your auth_id from the error
    (SELECT email FROM auth.users WHERE id = 'efd8e232-7dec-4875-94b3-9e842ae06424'),
    'doctor',
    (SELECT COALESCE(raw_user_meta_data->>'full_name', email) FROM auth.users WHERE id = 'efd8e232-7dec-4875-94b3-9e842ae06424'),
    NOW(),
    NOW()
)
ON CONFLICT (auth_id) DO UPDATE SET
    updated_at = NOW();

-- Option 2: Fix ALL missing users (recommended)
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
WHERE u.id IS NULL
ON CONFLICT (auth_id) DO NOTHING;

-- Verify it worked
SELECT 
    u.id,
    u.auth_id,
    u.email,
    u.full_name,
    u.role,
    u.profile_picture_url
FROM public.users u
WHERE u.auth_id = 'efd8e232-7dec-4875-94b3-9e842ae06424';
