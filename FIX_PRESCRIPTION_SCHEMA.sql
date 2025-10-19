-- ============================================
-- FIX PRESCRIPTION SCHEMA AND CONSULTATION LINK
-- ============================================

-- Step 1: Check current prescriptions table structure
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'prescriptions'
ORDER BY ordinal_position;

-- Step 2: The prescriptions table needs these columns based on your code:
-- Current schema only has: id, health_record_id, created_at
-- Your code expects: consultation_id, patient_id, doctor_id, diagnosis, symptoms, medical_notes, follow_up_date

-- Option A: ALTER existing prescriptions table to add missing columns
ALTER TABLE public.prescriptions
ADD COLUMN IF NOT EXISTS consultation_id uuid REFERENCES public.consultations(id),
ADD COLUMN IF NOT EXISTS patient_id uuid REFERENCES public.users(id),
ADD COLUMN IF NOT EXISTS doctor_id uuid REFERENCES public.doctors(id),
ADD COLUMN IF NOT EXISTS diagnosis text NOT NULL DEFAULT '',
ADD COLUMN IF NOT EXISTS symptoms text,
ADD COLUMN IF NOT EXISTS medical_notes text,
ADD COLUMN IF NOT EXISTS follow_up_date timestamp with time zone,
ADD COLUMN IF NOT EXISTS updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP;

-- Step 3: Remove the default from diagnosis after adding the column
ALTER TABLE public.prescriptions
ALTER COLUMN diagnosis DROP DEFAULT;

-- Step 4: Create index on consultation_id for better query performance
CREATE INDEX IF NOT EXISTS idx_prescriptions_consultation_id ON public.prescriptions(consultation_id);
CREATE INDEX IF NOT EXISTS idx_prescriptions_doctor_id ON public.prescriptions(doctor_id);
CREATE INDEX IF NOT EXISTS idx_prescriptions_patient_id ON public.prescriptions(patient_id);

-- Step 5: Add trigger to update consultations.prescription_id after prescription creation
CREATE OR REPLACE FUNCTION update_consultation_prescription_id()
RETURNS TRIGGER AS $$
BEGIN
  -- Update the consultation with the new prescription ID
  UPDATE public.consultations
  SET prescription_id = NEW.id,
      updated_at = CURRENT_TIMESTAMP
  WHERE id = NEW.consultation_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS trigger_update_consultation_prescription ON public.prescriptions;
CREATE TRIGGER trigger_update_consultation_prescription
AFTER INSERT ON public.prescriptions
FOR EACH ROW
EXECUTE FUNCTION update_consultation_prescription_id();

-- Step 6: Verify the changes
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'prescriptions'
ORDER BY ordinal_position;

-- Step 7: Test query (should work after running above)
-- Get all prescriptions for a doctor
SELECT 
  p.id,
  p.consultation_id,
  p.patient_id,
  p.doctor_id,
  p.diagnosis,
  p.symptoms,
  p.medical_notes,
  p.follow_up_date,
  p.created_at,
  c.scheduled_time as consultation_time,
  u.full_name as patient_name
FROM prescriptions p
LEFT JOIN consultations c ON p.consultation_id = c.id
LEFT JOIN users u ON p.patient_id = u.id
WHERE p.doctor_id = '[your-doctor-id]'
ORDER BY p.created_at DESC;

-- ============================================
-- EXPLANATION
-- ============================================

/*
PROBLEM:
Your prescriptions table schema only has:
- id
- health_record_id (foreign key to health_records)
- created_at

But your Flutter code is trying to insert:
- consultation_id
- patient_id  
- doctor_id
- diagnosis
- symptoms
- medical_notes
- follow_up_date

SOLUTION:
1. Add the missing columns to prescriptions table
2. Create a trigger to automatically update consultations.prescription_id
3. Add indexes for better query performance

WHY THIS FIXES YOUR ISSUE:
- After creating prescription, consultation will automatically get the prescription_id
- Doctors can query their prescriptions directly without joining through health_records
- Prescriptions are linked to consultations, making the relationship clear

ALTERNATIVE APPROACH (if you want to keep health_records):
Instead of adding columns to prescriptions, you could:
1. Create health_record first (in health_records table)
2. Create prescription with health_record_id
3. Update consultation with prescription_id

But the current approach (adding columns) is simpler and matches your code structure.
*/

-- ============================================
-- RLS POLICIES FOR PRESCRIPTIONS
-- ============================================

-- Enable RLS
ALTER TABLE public.prescriptions ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "Doctors can view their own prescriptions" ON public.prescriptions;
DROP POLICY IF EXISTS "Doctors can create prescriptions" ON public.prescriptions;
DROP POLICY IF EXISTS "Doctors can update their own prescriptions" ON public.prescriptions;
DROP POLICY IF EXISTS "Patients can view their own prescriptions" ON public.prescriptions;

-- Doctors can view their own prescriptions
CREATE POLICY "Doctors can view their own prescriptions"
ON public.prescriptions
FOR SELECT
USING (
  doctor_id IN (
    SELECT d.id FROM doctors d
    JOIN users u ON d.user_id = u.id
    WHERE u.auth_id = auth.uid()
  )
);

-- Doctors can create prescriptions
CREATE POLICY "Doctors can create prescriptions"
ON public.prescriptions
FOR INSERT
WITH CHECK (
  doctor_id IN (
    SELECT d.id FROM doctors d
    JOIN users u ON d.user_id = u.id
    WHERE u.auth_id = auth.uid()
  )
);

-- Doctors can update their own prescriptions
CREATE POLICY "Doctors can update their own prescriptions"
ON public.prescriptions
FOR UPDATE
USING (
  doctor_id IN (
    SELECT d.id FROM doctors d
    JOIN users u ON d.user_id = u.id
    WHERE u.auth_id = auth.uid()
  )
);

-- Patients can view their own prescriptions
CREATE POLICY "Patients can view their own prescriptions"
ON public.prescriptions
FOR SELECT
USING (
  patient_id IN (
    SELECT u.id FROM users u
    WHERE u.auth_id = auth.uid()
  )
);

-- ============================================
-- VERIFY EVERYTHING WORKS
-- ============================================

-- Test 1: Check table structure
\d prescriptions

-- Test 2: Check RLS policies
SELECT * FROM pg_policies WHERE tablename = 'prescriptions';

-- Test 3: Check trigger exists
SELECT tgname, tgtype, tgenabled 
FROM pg_trigger 
WHERE tgrelid = 'prescriptions'::regclass;

-- Done! Your prescriptions should now work correctly.
