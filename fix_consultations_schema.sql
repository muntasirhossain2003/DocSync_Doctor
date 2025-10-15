-- ------------------------------
-- Fix Consultations Table for Video Calling
-- ------------------------------

-- Add missing columns for video calling functionality
ALTER TABLE consultations 
ADD COLUMN IF NOT EXISTS agora_channel_name TEXT,
ADD COLUMN IF NOT EXISTS agora_token TEXT,
ADD COLUMN IF NOT EXISTS rejection_reason TEXT;

-- Update consultation_status check constraint to include new statuses
ALTER TABLE consultations 
DROP CONSTRAINT IF EXISTS consultations_consultation_status_check;

ALTER TABLE consultations 
ADD CONSTRAINT consultations_consultation_status_check 
CHECK (consultation_status IN (
    'scheduled',      -- Initial state when consultation is booked
    'calling',        -- Patient is calling doctor (incoming call)
    'in_progress',    -- Call is active
    'completed',      -- Call finished successfully
    'canceled',       -- Canceled by patient/doctor before starting
    'rejected'        -- Doctor rejected the incoming call
));

-- Enable Realtime for incoming call notifications
ALTER TABLE consultations REPLICA IDENTITY FULL;

-- Add index for faster queries
CREATE INDEX IF NOT EXISTS idx_consultations_doctor_status 
ON consultations(doctor_id, consultation_status);

CREATE INDEX IF NOT EXISTS idx_consultations_patient_status 
ON consultations(patient_id, consultation_status);

-- Verify the changes
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'consultations'
ORDER BY ordinal_position;

-- Check current constraint
SELECT conname, pg_get_constraintdef(oid)
FROM pg_constraint
WHERE conrelid = 'consultations'::regclass
AND conname LIKE '%status%';
