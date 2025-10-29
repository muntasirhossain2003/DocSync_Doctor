-- ===================================================
-- QUICK DATABASE DEBUG QUERIES
-- ===================================================
-- Run these in Supabase SQL Editor to see what data exists
-- ===================================================

-- 1. Check your doctor ID
SELECT d.id as doctor_id, u.email, u.full_name
FROM doctors d
JOIN users u ON d.user_id = u.id;

-- 2. See ALL consultations for your doctor
SELECT 
    c.id,
    c.consultation_status,
    c.scheduled_time,
    c.consultation_type,
    p.full_name as patient_name,
    p.email as patient_email,
    c.scheduled_time > NOW() as is_future,
    c.created_at
FROM consultations c
JOIN users p ON c.patient_id = p.id
WHERE c.doctor_id = '<REPLACE_WITH_YOUR_DOCTOR_ID>'  -- Get this from query #1
ORDER BY c.scheduled_time DESC;

-- 3. Check upcoming consultations (what doctor app should show)
SELECT 
    c.id,
    c.consultation_status,
    c.scheduled_time,
    c.consultation_type,
    p.full_name as patient_name
FROM consultations c
JOIN users p ON c.patient_id = p.id
WHERE c.doctor_id = '<REPLACE_WITH_YOUR_DOCTOR_ID>'
AND c.consultation_status IN ('scheduled', 'calling', 'in_progress')
AND c.scheduled_time >= NOW()
ORDER BY c.scheduled_time ASC;

-- 4. Count consultations by status
SELECT 
    consultation_status,
    COUNT(*) as count
FROM consultations
WHERE doctor_id = '<REPLACE_WITH_YOUR_DOCTOR_ID>'
GROUP BY consultation_status;

-- 5. Check if scheduled times are in the future
SELECT 
    consultation_status,
    scheduled_time,
    NOW() as current_time,
    scheduled_time >= NOW() as is_upcoming,
    scheduled_time - NOW() as time_until
FROM consultations
WHERE doctor_id = '<REPLACE_WITH_YOUR_DOCTOR_ID>'
ORDER BY scheduled_time;

-- ===================================================
-- QUICK FIX QUERIES (if needed)
-- ===================================================

-- If consultations have passed times, update them to future:
-- UPDATE consultations
-- SET scheduled_time = NOW() + INTERVAL '2 hours'
-- WHERE doctor_id = '<YOUR_DOCTOR_ID>'
-- AND consultation_status = 'scheduled'
-- AND scheduled_time < NOW();

-- To test incoming call, update a consultation:
-- UPDATE consultations
-- SET 
--   consultation_status = 'calling',
--   agora_channel_name = 'test_channel_' || id::text,
--   agora_token = 'test_token_123',
--   updated_at = NOW()
-- WHERE id = '<CONSULTATION_ID>'
-- AND doctor_id = '<YOUR_DOCTOR_ID>';
