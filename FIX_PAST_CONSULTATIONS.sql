-- ===================================================
-- FIX: UPDATE PAST CONSULTATIONS TO FUTURE TIMES
-- ===================================================
-- Your consultations are all in the past!
-- Current UTC time: ~22:59
-- All consultations are before 22:30
--
-- This will move them to tomorrow at the same times
-- ===================================================

-- Update all past scheduled consultations to tomorrow
UPDATE consultations
SET scheduled_time = scheduled_time + INTERVAL '1 day'
WHERE doctor_id = '92a83de4-deed-4f87-a916-4ee2d1e77827'
AND consultation_status = 'scheduled'
AND scheduled_time < NOW();

-- Verify the update
SELECT 
    id,
    consultation_status,
    scheduled_time,
    NOW() as current_time,
    scheduled_time > NOW() as is_future,
    scheduled_time - NOW() as time_until
FROM consultations
WHERE doctor_id = '92a83de4-deed-4f87-a916-4ee2d1e77827'
AND consultation_status = 'scheduled'
ORDER BY scheduled_time;
