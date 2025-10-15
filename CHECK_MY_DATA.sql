-- ===================================================
-- YOUR DOCTOR DATA CHECK
-- Doctor ID: 92a83de4-deed-4f87-a916-4ee2d1e77827
-- ===================================================

-- 1. See ALL your consultations
SELECT 
    c.id,
    c.consultation_status,
    c.scheduled_time,
    c.consultation_type,
    p.full_name as patient_name,
    p.email as patient_email,
    c.scheduled_time > NOW() as is_future,
    AGE(c.scheduled_time, NOW()) as time_difference
FROM consultations c
JOIN users p ON c.patient_id = p.id
WHERE c.doctor_id = '92a83de4-deed-4f87-a916-4ee2d1e77827'
ORDER BY c.scheduled_time DESC;

-- 2. Check upcoming consultations (what should show on home page)
SELECT 
    c.id,
    c.consultation_status,
    c.scheduled_time,
    c.consultation_type,
    p.full_name as patient_name,
    p.profile_picture_url
FROM consultations c
JOIN users p ON c.patient_id = p.id
WHERE c.doctor_id = '92a83de4-deed-4f87-a916-4ee2d1e77827'
AND c.consultation_status IN ('scheduled', 'calling', 'in_progress')
AND c.scheduled_time >= NOW()
ORDER BY c.scheduled_time ASC;If it's currently around 11 PM - midnight Dhaka time (Oct 15)

That's ~17:00-18:00 UTC (Oct 15)
So consultations at 16:33, 16:35, 16:40, 17:30, 17:37 UTC would be recently past or very soon
And 22:10, 22:30 UTC would be tomorrow morning 4 AM Dhaka time

-- 3. Count by status
SELECT 
    consultation_status,
    COUNT(*) as count,
    COUNT(*) FILTER (WHERE scheduled_time >= NOW()) as upcoming_count,
    COUNT(*) FILTER (WHERE scheduled_time < NOW()) as past_count
FROM consultations
WHERE doctor_id = '92a83de4-deed-4f87-a916-4ee2d1e77827'
GROUP BY consultation_status;

-- 4. Check if times are in past (common issue!)
SELECT 
    id,
    consultation_status,
    scheduled_time,
    NOW() as current_time,
    scheduled_time < NOW() as is_in_past,
    NOW() - scheduled_time as how_long_ago
FROM consultations
WHERE doctor_id = '92a83de4-deed-4f87-a916-4ee2d1e77827'
ORDER BY scheduled_time DESC;

-- ===================================================
-- QUICK FIXES (if needed)
-- ===================================================

-- If all consultations are in the past, update them to future:
-- UPDATE consultations
-- SET scheduled_time = NOW() + INTERVAL '2 hours'
-- WHERE doctor_id = '92a83de4-deed-4f87-a916-4ee2d1e77827'
-- AND consultation_status = 'scheduled'
-- AND scheduled_time < NOW();

-- Create a test consultation for NOW:
-- INSERT INTO consultations (
--   patient_id,
--   doctor_id,
--   scheduled_time,
--   consultation_type,
--   consultation_status,
--   consultation_fee
-- )
-- SELECT 
--   (SELECT id FROM users WHERE role = 'patient' LIMIT 1),
--   '92a83de4-deed-4f87-a916-4ee2d1e77827',
--   NOW() + INTERVAL '1 hour',
--   'video_call',
--   'scheduled',
--   50.00
-- WHERE EXISTS (SELECT 1 FROM users WHERE role = 'patient');

-- Test incoming call:
-- UPDATE consultations
-- SET 
--   consultation_status = 'calling',
--   agora_channel_name = 'test_channel_' || id::text,
--   agora_token = 'test_token_123',
--   updated_at = NOW()
-- WHERE doctor_id = '92a83de4-deed-4f87-a916-4ee2d1e77827'
-- AND consultation_status = 'scheduled'
-- AND scheduled_time >= NOW()
-- LIMIT 1;
