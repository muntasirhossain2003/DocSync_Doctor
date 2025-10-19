-- ========================================
-- PRESCRIPTION SYSTEM SCHEMA
-- Run this in Supabase SQL Editor
-- ========================================

-- Create prescriptions table
CREATE TABLE IF NOT EXISTS prescriptions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  consultation_id UUID NOT NULL REFERENCES consultations(id) ON DELETE CASCADE,
  patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
  doctor_id UUID NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
  
  -- Prescription details
  diagnosis TEXT NOT NULL,
  symptoms TEXT,
  medical_notes TEXT,
  follow_up_date TIMESTAMP WITH TIME ZONE,
  
  -- Metadata
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT unique_consultation_prescription UNIQUE(consultation_id)
);

-- Create prescription_medications table (for multiple medications per prescription)
CREATE TABLE IF NOT EXISTS prescription_medications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  prescription_id UUID NOT NULL REFERENCES prescriptions(id) ON DELETE CASCADE,
  
  -- Medication details
  medication_name TEXT NOT NULL,
  dosage TEXT NOT NULL,
  frequency TEXT NOT NULL,
  duration TEXT NOT NULL,
  instructions TEXT,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT check_medication_name CHECK (length(medication_name) > 0),
  CONSTRAINT check_dosage CHECK (length(dosage) > 0)
);

-- Create medical_tests table (for recommended tests)
CREATE TABLE IF NOT EXISTS medical_tests (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  prescription_id UUID NOT NULL REFERENCES prescriptions(id) ON DELETE CASCADE,
  
  -- Test details
  test_name TEXT NOT NULL,
  test_reason TEXT,
  urgency TEXT CHECK (urgency IN ('urgent', 'normal', 'routine')) DEFAULT 'normal',
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_prescriptions_consultation 
  ON prescriptions(consultation_id);

CREATE INDEX IF NOT EXISTS idx_prescriptions_patient 
  ON prescriptions(patient_id);

CREATE INDEX IF NOT EXISTS idx_prescriptions_doctor 
  ON prescriptions(doctor_id);

CREATE INDEX IF NOT EXISTS idx_prescription_medications_prescription 
  ON prescription_medications(prescription_id);

CREATE INDEX IF NOT EXISTS idx_medical_tests_prescription 
  ON medical_tests(prescription_id);

-- Enable Row Level Security
ALTER TABLE prescriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE prescription_medications ENABLE ROW LEVEL SECURITY;
ALTER TABLE medical_tests ENABLE ROW LEVEL SECURITY;

-- ========================================
-- RLS POLICIES FOR PRESCRIPTIONS
-- ========================================

-- Doctors can view their own prescriptions
CREATE POLICY "Doctors can view their prescriptions"
ON prescriptions FOR SELECT
USING (
  doctor_id IN (
    SELECT d.id FROM doctors d
    INNER JOIN users u ON u.id = d.user_id
    WHERE u.auth_id = auth.uid()
  )
);

-- Doctors can create prescriptions for their consultations
CREATE POLICY "Doctors can create prescriptions"
ON prescriptions FOR INSERT
WITH CHECK (
  doctor_id IN (
    SELECT d.id FROM doctors d
    INNER JOIN users u ON u.id = d.user_id
    WHERE u.auth_id = auth.uid()
  )
  AND consultation_id IN (
    SELECT c.id FROM consultations c WHERE c.doctor_id = doctor_id
  )
);

-- Doctors can update their own prescriptions
CREATE POLICY "Doctors can update their prescriptions"
ON prescriptions FOR UPDATE
USING (
  doctor_id IN (
    SELECT d.id FROM doctors d
    INNER JOIN users u ON u.id = d.user_id
    WHERE u.auth_id = auth.uid()
  )
);

-- Doctors can delete their own prescriptions
CREATE POLICY "Doctors can delete their prescriptions"
ON prescriptions FOR DELETE
USING (
  doctor_id IN (
    SELECT d.id FROM doctors d
    INNER JOIN users u ON u.id = d.user_id
    WHERE u.auth_id = auth.uid()
  )
);

-- ========================================
-- RLS POLICIES FOR PRESCRIPTION MEDICATIONS
-- ========================================

-- Doctors can view medications for their prescriptions
CREATE POLICY "Doctors can view prescription medications"
ON prescription_medications FOR SELECT
USING (
  prescription_id IN (
    SELECT p.id FROM prescriptions p
    INNER JOIN doctors d ON d.id = p.doctor_id
    INNER JOIN users u ON u.id = d.user_id
    WHERE u.auth_id = auth.uid()
  )
);

-- Doctors can add medications to their prescriptions
CREATE POLICY "Doctors can add prescription medications"
ON prescription_medications FOR INSERT
WITH CHECK (
  prescription_id IN (
    SELECT p.id FROM prescriptions p
    INNER JOIN doctors d ON d.id = p.doctor_id
    INNER JOIN users u ON u.id = d.user_id
    WHERE u.auth_id = auth.uid()
  )
);

-- Doctors can update medications in their prescriptions
CREATE POLICY "Doctors can update prescription medications"
ON prescription_medications FOR UPDATE
USING (
  prescription_id IN (
    SELECT p.id FROM prescriptions p
    INNER JOIN doctors d ON d.id = p.doctor_id
    INNER JOIN users u ON u.id = d.user_id
    WHERE u.auth_id = auth.uid()
  )
);

-- Doctors can delete medications from their prescriptions
CREATE POLICY "Doctors can delete prescription medications"
ON prescription_medications FOR DELETE
USING (
  prescription_id IN (
    SELECT p.id FROM prescriptions p
    INNER JOIN doctors d ON d.id = p.doctor_id
    INNER JOIN users u ON u.id = d.user_id
    WHERE u.auth_id = auth.uid()
  )
);

-- ========================================
-- RLS POLICIES FOR MEDICAL TESTS
-- ========================================

-- Doctors can view tests for their prescriptions
CREATE POLICY "Doctors can view medical tests"
ON medical_tests FOR SELECT
USING (
  prescription_id IN (
    SELECT p.id FROM prescriptions p
    INNER JOIN doctors d ON d.id = p.doctor_id
    INNER JOIN users u ON u.id = d.user_id
    WHERE u.auth_id = auth.uid()
  )
);

-- Doctors can add tests to their prescriptions
CREATE POLICY "Doctors can add medical tests"
ON medical_tests FOR INSERT
WITH CHECK (
  prescription_id IN (
    SELECT p.id FROM prescriptions p
    INNER JOIN doctors d ON d.id = p.doctor_id
    INNER JOIN users u ON u.id = d.user_id
    WHERE u.auth_id = auth.uid()
  )
);

-- Doctors can delete tests from their prescriptions
CREATE POLICY "Doctors can delete medical tests"
ON medical_tests FOR DELETE
USING (
  prescription_id IN (
    SELECT p.id FROM prescriptions p
    INNER JOIN doctors d ON d.id = p.doctor_id
    INNER JOIN users u ON u.id = d.user_id
    WHERE u.auth_id = auth.uid()
  )
);

-- ========================================
-- TRIGGER: Update updated_at timestamp
-- ========================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_prescriptions_updated_at
    BEFORE UPDATE ON prescriptions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ========================================
-- VERIFICATION QUERIES
-- ========================================

-- Check if tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN ('prescriptions', 'prescription_medications', 'medical_tests');

-- Check RLS is enabled
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN ('prescriptions', 'prescription_medications', 'medical_tests');

-- Check policies
SELECT schemaname, tablename, policyname
FROM pg_policies 
WHERE schemaname = 'public' 
  AND tablename IN ('prescriptions', 'prescription_medications', 'medical_tests')
ORDER BY tablename, policyname;
