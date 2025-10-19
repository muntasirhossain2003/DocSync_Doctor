-- ========================================
-- UPDATE EXISTING PRESCRIPTIONS TABLE
-- This adds columns to your existing schema
-- Run this in Supabase SQL Editor
-- ========================================

-- Step 1: Add missing columns to prescriptions table
ALTER TABLE public.prescriptions
ADD COLUMN IF NOT EXISTS consultation_id uuid REFERENCES public.consultations(id) ON DELETE CASCADE,
ADD COLUMN IF NOT EXISTS patient_id uuid REFERENCES public.users(id) ON DELETE CASCADE,
ADD COLUMN IF NOT EXISTS doctor_id uuid REFERENCES public.doctors(id) ON DELETE CASCADE,
ADD COLUMN IF NOT EXISTS diagnosis text,
ADD COLUMN IF NOT EXISTS symptoms text,
ADD COLUMN IF NOT EXISTS medical_notes text,
ADD COLUMN IF NOT EXISTS follow_up_date timestamp with time zone,
ADD COLUMN IF NOT EXISTS updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP;

-- Step 2: Add constraints
-- Make diagnosis required (after adding the column)
-- Note: This will fail if you have existing null values
-- ALTER TABLE public.prescriptions
-- ALTER COLUMN diagnosis SET NOT NULL;

-- Add unique constraint for consultation_id (one prescription per consultation)
ALTER TABLE public.prescriptions
DROP CONSTRAINT IF EXISTS unique_consultation_prescription;

ALTER TABLE public.prescriptions
ADD CONSTRAINT unique_consultation_prescription UNIQUE(consultation_id);

-- Step 3: Update prescription_medications table constraints
ALTER TABLE public.prescription_medications
DROP CONSTRAINT IF EXISTS check_medication_name;

ALTER TABLE public.prescription_medications
DROP CONSTRAINT IF EXISTS check_dosage;

ALTER TABLE public.prescription_medications
ADD CONSTRAINT check_medication_name CHECK (length(medication_name) > 0),
ADD CONSTRAINT check_dosage CHECK (length(dosage) > 0);

-- Make required fields NOT NULL
ALTER TABLE public.prescription_medications
ALTER COLUMN medication_name SET NOT NULL,
ALTER COLUMN dosage SET NOT NULL,
ALTER COLUMN frequency SET NOT NULL,
ALTER COLUMN duration SET NOT NULL;

-- Step 4: Create medical_tests table (if it doesn't exist)
CREATE TABLE IF NOT EXISTS public.medical_tests (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  prescription_id uuid NOT NULL REFERENCES public.prescriptions(id) ON DELETE CASCADE,
  test_name text NOT NULL,
  test_reason text,
  urgency text CHECK (urgency IN ('urgent', 'normal', 'routine')) DEFAULT 'normal',
  created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);

-- Step 5: Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_prescriptions_consultation 
  ON public.prescriptions(consultation_id);

CREATE INDEX IF NOT EXISTS idx_prescriptions_patient 
  ON public.prescriptions(patient_id);

CREATE INDEX IF NOT EXISTS idx_prescriptions_doctor 
  ON public.prescriptions(doctor_id);

CREATE INDEX IF NOT EXISTS idx_prescription_medications_prescription 
  ON public.prescription_medications(prescription_id);

CREATE INDEX IF NOT EXISTS idx_medical_tests_prescription 
  ON public.medical_tests(prescription_id);

-- Step 6: Enable Row Level Security on medical_tests
ALTER TABLE IF EXISTS public.medical_tests ENABLE ROW LEVEL SECURITY;

-- Step 7: Create RLS policies for medical_tests
DROP POLICY IF EXISTS "Doctors can view medical tests" ON public.medical_tests;
CREATE POLICY "Doctors can view medical tests"
ON public.medical_tests FOR SELECT
USING (
  prescription_id IN (
    SELECT p.id FROM public.prescriptions p
    INNER JOIN public.doctors d ON d.id = p.doctor_id
    INNER JOIN public.users u ON u.id = d.user_id
    WHERE u.auth_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "Doctors can add medical tests" ON public.medical_tests;
CREATE POLICY "Doctors can add medical tests"
ON public.medical_tests FOR INSERT
WITH CHECK (
  prescription_id IN (
    SELECT p.id FROM public.prescriptions p
    INNER JOIN public.doctors d ON d.id = p.doctor_id
    INNER JOIN public.users u ON u.id = d.user_id
    WHERE u.auth_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "Doctors can delete medical tests" ON public.medical_tests;
CREATE POLICY "Doctors can delete medical tests"
ON public.medical_tests FOR DELETE
USING (
  prescription_id IN (
    SELECT p.id FROM public.prescriptions p
    INNER JOIN public.doctors d ON d.id = p.doctor_id
    INNER JOIN public.users u ON u.id = d.user_id
    WHERE u.auth_id = auth.uid()
  )
);

-- Step 8: Update RLS policies for prescriptions table
-- Drop old policies that might reference health_record_id
DROP POLICY IF EXISTS "Doctors can view their prescriptions" ON public.prescriptions;
DROP POLICY IF EXISTS "Doctors can create prescriptions" ON public.prescriptions;
DROP POLICY IF EXISTS "Doctors can update their prescriptions" ON public.prescriptions;
DROP POLICY IF EXISTS "Doctors can delete their prescriptions" ON public.prescriptions;

-- Create new policies
CREATE POLICY "Doctors can view their prescriptions"
ON public.prescriptions FOR SELECT
USING (
  doctor_id IN (
    SELECT d.id FROM public.doctors d
    INNER JOIN public.users u ON u.id = d.user_id
    WHERE u.auth_id = auth.uid()
  )
);

CREATE POLICY "Doctors can create prescriptions"
ON public.prescriptions FOR INSERT
WITH CHECK (
  doctor_id IN (
    SELECT d.id FROM public.doctors d
    INNER JOIN public.users u ON u.id = d.user_id
    WHERE u.auth_id = auth.uid()
  )
  AND (consultation_id IS NULL OR consultation_id IN (
    SELECT c.id FROM public.consultations c WHERE c.doctor_id = doctor_id
  ))
);

CREATE POLICY "Doctors can update their prescriptions"
ON public.prescriptions FOR UPDATE
USING (
  doctor_id IN (
    SELECT d.id FROM public.doctors d
    INNER JOIN public.users u ON u.id = d.user_id
    WHERE u.auth_id = auth.uid()
  )
);

CREATE POLICY "Doctors can delete their prescriptions"
ON public.prescriptions FOR DELETE
USING (
  doctor_id IN (
    SELECT d.id FROM public.doctors d
    INNER JOIN public.users u ON u.id = d.user_id
    WHERE u.auth_id = auth.uid()
  )
);

-- Step 9: Create trigger for updated_at
DROP TRIGGER IF EXISTS update_prescriptions_updated_at ON public.prescriptions;

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_prescriptions_updated_at
    BEFORE UPDATE ON public.prescriptions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ========================================
-- VERIFICATION
-- ========================================

-- Check new columns exist
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'prescriptions'
ORDER BY ordinal_position;

-- Check medical_tests table exists
SELECT EXISTS (
  SELECT FROM information_schema.tables 
  WHERE table_schema = 'public' 
  AND table_name = 'medical_tests'
) as medical_tests_exists;

-- Check RLS policies
SELECT schemaname, tablename, policyname, cmd
FROM pg_policies 
WHERE schemaname = 'public' 
  AND tablename IN ('prescriptions', 'prescription_medications', 'medical_tests')
ORDER BY tablename, policyname;

-- ========================================
-- SUCCESS MESSAGE
-- ========================================
DO $$
BEGIN
  RAISE NOTICE '✅ Prescriptions table updated successfully!';
  RAISE NOTICE '✅ Medical tests table created!';
  RAISE NOTICE '✅ RLS policies updated!';
  RAISE NOTICE '✅ You can now use the prescription feature in your app!';
END $$;
