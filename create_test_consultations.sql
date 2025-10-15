-- ==============================================================
-- Test Data Generator for Doctor App
-- ==============================================================
-- This script creates sample consultations to test the doctor app
-- Replace the UUIDs with your actual doctor and patient IDs
-- ==============================================================

-- ==============================================================
-- STEP 1: Get Your IDs
-- ==============================================================
-- Run this first to get your doctor_id and patient_id

-- Get your doctor ID
SELECT 
    d.id as doctor_id,
    d.user_id,
    u.full_name as doctor_name,
    u.email as doctor_email
FROM doctors d
JOIN users u ON d.user_id = u.id
WHERE u.role = 'doctor'
LIMIT 5;

-- Get patient IDs (create test patient if needed)
SELECT 
    id as patient_id,
    full_name as patient_name,
    email as patient_email
FROM users
WHERE role = 'patient'
LIMIT 5;

-- ==============================================================
-- STEP 2: Create Test Patient (if you don't have one)
-- ==============================================================
-- Uncomment and run this if you need a test patient

/*
INSERT INTO users (
    id,
    email,
    full_name,
    role,
    phone,
    gender,
    date_of_birth,
    created_at,
    updated_at
) VALUES (
    gen_random_uuid(),
    'test.patient@example.com',
    'Test Patient',
    'patient',
    '+1234567890',
    'male',
    '1990-01-01',
    NOW(),
    NOW()
) RETURNING id, full_name, email;
*/

-- ==============================================================
-- STEP 3: Create Test Consultations
-- ==============================================================
-- Replace <YOUR_DOCTOR_ID> and <YOUR_PATIENT_ID> with actual UUIDs

-- === UPCOMING CONSULTATIONS (These will show on home page) ===

-- 1. Scheduled consultation (30 minutes from now)
INSERT INTO consultations (
    id,
    patient_id,
    doctor_id,
    consultation_type,
    scheduled_time,
    consultation_status,
    created_at,
    updated_at
) VALUES (
    gen_random_uuid(),
    '<YOUR_PATIENT_ID>',  -- ← Replace this
    '<YOUR_DOCTOR_ID>',   -- ← Replace this
    'video',
    NOW() + INTERVAL '30 minutes',
    'scheduled',
    NOW(),
    NOW()
);

-- 2. Another scheduled consultation (2 hours from now)
INSERT INTO consultations (
    id,
    patient_id,
    doctor_id,
    consultation_type,
    scheduled_time,
    consultation_status,
    created_at,
    updated_at
) VALUES (
    gen_random_uuid(),
    '<YOUR_PATIENT_ID>',  -- ← Replace this
    '<YOUR_DOCTOR_ID>',   -- ← Replace this
    'video',
    NOW() + INTERVAL '2 hours',
    'scheduled',
    NOW(),
    NOW()
);

-- 3. Scheduled for tomorrow
INSERT INTO consultations (
    id,
    patient_id,
    doctor_id,
    consultation_type,
    scheduled_time,
    consultation_status,
    created_at,
    updated_at
) VALUES (
    gen_random_uuid(),
    '<YOUR_PATIENT_ID>',  -- ← Replace this
    '<YOUR_DOCTOR_ID>',   -- ← Replace this
    'audio',
    NOW() + INTERVAL '1 day',
    'scheduled',
    NOW(),
    NOW()
);

-- === COMPLETED CONSULTATIONS ===

-- 4. Completed consultation (yesterday)
INSERT INTO consultations (
    id,
    patient_id,
    doctor_id,
    consultation_type,
    scheduled_time,
    consultation_status,
    created_at,
    updated_at
) VALUES (
    gen_random_uuid(),
    '<YOUR_PATIENT_ID>',  -- ← Replace this
    '<YOUR_DOCTOR_ID>',   -- ← Replace this
    'video',
    NOW() - INTERVAL '1 day',
    'completed',
    NOW(),
    NOW()
);

-- 5. Another completed (last week)
INSERT INTO consultations (
    id,
    patient_id,
    doctor_id,
    consultation_type,
    scheduled_time,
    consultation_status,
    created_at,
    updated_at
) VALUES (
    gen_random_uuid(),
    '<YOUR_PATIENT_ID>',  -- ← Replace this
    '<YOUR_DOCTOR_ID>',   -- ← Replace this
    'chat',
    NOW() - INTERVAL '7 days',
    'completed',
    NOW(),
    NOW()
);

-- === CANCELED CONSULTATIONS ===

-- 6. Canceled consultation
INSERT INTO consultations (
    id,
    patient_id,
    doctor_id,
    consultation_type,
    scheduled_time,
    consultation_status,
    created_at,
    updated_at
) VALUES (
    gen_random_uuid(),
    '<YOUR_PATIENT_ID>',  -- ← Replace this
    '<YOUR_DOCTOR_ID>',   -- ← Replace this
    'video',
    NOW() - INTERVAL '2 days',
    'canceled',
    NOW(),
    NOW()
);

-- ==============================================================
-- STEP 4: Test Incoming Call
-- ==============================================================
-- This creates a consultation with 'calling' status to test incoming call dialog

INSERT INTO consultations (
    id,
    patient_id,
    doctor_id,
    consultation_type,
    scheduled_time,
    consultation_status,
    agora_channel_name,
    agora_token,
    created_at,
    updated_at
) VALUES (
    gen_random_uuid(),
    '<YOUR_PATIENT_ID>',  -- ← Replace this
    '<YOUR_DOCTOR_ID>',   -- ← Replace this
    'video',
    NOW(),
    'calling',  -- ← This triggers incoming call dialog!
    'test_channel_' || floor(random() * 10000)::text,
    'test_token_' || floor(random() * 10000)::text,
    NOW(),
    NOW()
) RETURNING id, consultation_status, agora_channel_name;

-- ==============================================================
-- STEP 5: Verify Test Data
-- ==============================================================

-- Check all consultations for your doctor
SELECT 
    c.id,
    p.full_name as patient_name,
    c.consultation_type,
    c.scheduled_time,
    c.consultation_status,
    c.agora_channel_name,
    CASE 
        WHEN c.consultation_status = 'calling' THEN '📞 INCOMING CALL'
        WHEN c.consultation_status = 'in_progress' THEN '📹 ACTIVE CALL'
        WHEN c.scheduled_time > NOW() THEN '⏰ UPCOMING'
        WHEN c.consultation_status = 'completed' THEN '✅ COMPLETED'
        WHEN c.consultation_status = 'canceled' THEN '❌ CANCELED'
        WHEN c.consultation_status = 'rejected' THEN '🚫 REJECTED'
        ELSE c.consultation_status
    END as status_icon
FROM consultations c
JOIN users p ON c.patient_id = p.id
WHERE c.doctor_id = '<YOUR_DOCTOR_ID>'  -- ← Replace this
ORDER BY c.scheduled_time DESC;

-- Count by status
SELECT 
    consultation_status,
    COUNT(*) as count
FROM consultations
WHERE doctor_id = '<YOUR_DOCTOR_ID>'  -- ← Replace this
GROUP BY consultation_status;

-- ==============================================================
-- CLEANUP (Optional)
-- ==============================================================
-- Uncomment to delete all test consultations

/*
DELETE FROM consultations
WHERE doctor_id = '<YOUR_DOCTOR_ID>'  -- ← Replace this
AND consultation_status IN ('scheduled', 'calling');
*/
