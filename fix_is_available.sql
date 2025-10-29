-- Fix is_available based on OR condition:
-- is_available = true IF (is_online = true) OR (has availability schedule)

-- Update is_available = true for doctors who are EITHER online OR have availability schedule
UPDATE doctors
SET is_available = true,
    updated_at = NOW()
WHERE (
    is_online = true  -- Doctor is currently online
    OR 
    (availability IS NOT NULL AND availability != '{}'::jsonb)  -- Doctor has availability schedule
)
AND is_available = false;  -- Only update if currently false

-- Set is_available = false for doctors who are BOTH offline AND have no schedule
UPDATE doctors
SET is_available = false,
    updated_at = NOW()
WHERE is_online = false
  AND (availability IS NULL OR availability = '{}'::jsonb)
  AND is_available = true;  -- Only update if currently true

-- Verify the update
SELECT 
    id,
    bmcd_registration_number,
    is_available,
    is_online,
    CASE 
        WHEN availability IS NOT NULL AND availability != '{}'::jsonb THEN 'Has Schedule'
        ELSE 'No Schedule'
    END as schedule_status,
    CASE 
        WHEN is_online = true THEN '✓ Should be available (online)'
        WHEN availability IS NOT NULL AND availability != '{}'::jsonb THEN '✓ Should be available (has schedule)'
        ELSE '✗ Should NOT be available'
    END as expected_status
FROM doctors
ORDER BY is_available DESC, is_online DESC;
