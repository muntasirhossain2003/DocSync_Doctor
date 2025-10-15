-- ===================================================
-- UPDATE ALL CONSULTATIONS TO START IN 2 HOURS
-- ===================================================
-- This will set all consultations to be 2 hours from now
-- So you can test them immediately
-- ===================================================

-- Update all scheduled consultations to 2 hours from now
UPDATE consultations
SET scheduled_time = NOW() + INTERVAL '2 hours'
WHERE doctor_id = '92a83de4-deed-4f87-a916-4ee2d1e77827'
AND consultation_status = 'scheduled'
AND id IN (
  '8f7424f2-71bc-449a-9927-d80f06744ff8',
  '1cb3f4a7-3e61-46df-83af-85ca90730495',
  'fd5ce097-b9e5-4bce-8658-dffd76e4a3ae',
  '6f41d01a-4198-495e-bfef-b19c917de72b',
  '910b2fc8-d18b-49ce-95fb-9993fef479fa'
);

-- Keep 2 for different times
UPDATE consultations
SET scheduled_time = NOW() + INTERVAL '4 hours'
WHERE doctor_id = '92a83de4-deed-4f87-a916-4ee2d1e77827'
AND consultation_status = 'scheduled'
AND id IN (
  '5231cac2-51e1-4741-82c3-aadcaedd88e1',
  'dbc4a842-e7e4-4e90-82ec-833a998a4df9'
);

-- Verify the update
SELECT 
    id,
    scheduled_time,
    NOW() as current_utc_time,
    scheduled_time - NOW() as time_until_consultation
FROM consultations
WHERE doctor_id = '92a83de4-deed-4f87-a916-4ee2d1e77827'
AND consultation_status = 'scheduled'
ORDER BY scheduled_time;
