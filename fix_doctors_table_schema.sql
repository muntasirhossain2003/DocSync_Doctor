-- Fix for "availability column not found" error
-- Run this in Supabase SQL Editor

-- Option 1: Add the missing columns to doctors table
ALTER TABLE doctors 
ADD COLUMN IF NOT EXISTS availability jsonb,
ADD COLUMN IF NOT EXISTS is_available boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS is_online boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS experience integer;

-- Option 2: If you want to keep availability_start and availability_end,
-- you can drop the availability column requirement from the code instead.
-- But for now, let's add the missing columns.

-- Update existing records to have default values
UPDATE doctors 
SET 
  is_available = COALESCE(is_available, false),
  is_online = COALESCE(is_online, false)
WHERE is_available IS NULL OR is_online IS NULL;

-- Verify the changes
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'doctors'
ORDER BY ordinal_position;
