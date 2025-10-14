-- Row Level Security (RLS) Policies for DocSync Doctor App
-- Run these queries in your Supabase SQL Editor

-- ================================================
-- USERS TABLE POLICIES
-- ================================================

-- Enable RLS on users table
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Policy: Doctors can view their own user record
CREATE POLICY "Doctors can view own user record"
ON users FOR SELECT
USING (auth.uid() = auth_id);

-- Policy: Doctors can update their own user record
CREATE POLICY "Doctors can update own user record"
ON users FOR UPDATE
USING (auth.uid() = auth_id);

-- Policy: Allow insert during registration (needed for signup)
CREATE POLICY "Allow user creation during registration"
ON users FOR INSERT
WITH CHECK (auth.uid() = auth_id);

-- ================================================
-- DOCTORS TABLE POLICIES
-- ================================================

-- Enable RLS on doctors table
ALTER TABLE doctors ENABLE ROW LEVEL SECURITY;

-- Policy: Doctors can view their own doctor record
CREATE POLICY "Doctors can view own doctor record"
ON doctors FOR SELECT
USING (
  user_id IN (
    SELECT id FROM users WHERE auth_id = auth.uid()
  )
);

-- Policy: Doctors can insert their own doctor record (during registration or profile completion)
CREATE POLICY "Doctors can insert own doctor record"
ON doctors FOR INSERT
WITH CHECK (
  user_id IN (
    SELECT id FROM users WHERE auth_id = auth.uid()
  )
);

-- Policy: Doctors can update their own doctor record
CREATE POLICY "Doctors can update own doctor record"
ON doctors FOR UPDATE
USING (
  user_id IN (
    SELECT id FROM users WHERE auth_id = auth.uid()
  )
);

-- ================================================
-- HEALTH RECORDS TABLE POLICIES (for future use)
-- ================================================

-- Enable RLS on health_records table
ALTER TABLE health_records ENABLE ROW LEVEL SECURITY;

-- Policy: Doctors can view health records where they are the assigned doctor
CREATE POLICY "Doctors can view their patient health records"
ON health_records FOR SELECT
USING (
  doctor_id IN (
    SELECT d.id FROM doctors d
    INNER JOIN users u ON u.id = d.user_id
    WHERE u.auth_id = auth.uid()
  )
);

-- Policy: Doctors can insert health records for their patients
CREATE POLICY "Doctors can create health records"
ON health_records FOR INSERT
WITH CHECK (
  doctor_id IN (
    SELECT d.id FROM doctors d
    INNER JOIN users u ON u.id = d.user_id
    WHERE u.auth_id = auth.uid()
  )
);

-- Policy: Doctors can update their own health records
CREATE POLICY "Doctors can update their health records"
ON health_records FOR UPDATE
USING (
  doctor_id IN (
    SELECT d.id FROM doctors d
    INNER JOIN users u ON u.id = d.user_id
    WHERE u.auth_id = auth.uid()
  )
);

-- ================================================
-- CONSULTATIONS TABLE POLICIES
-- ================================================

-- Enable RLS on consultations table
ALTER TABLE consultations ENABLE ROW LEVEL SECURITY;

-- Policy: Doctors can view their consultations
CREATE POLICY "Doctors can view their consultations"
ON consultations FOR SELECT
USING (
  doctor_id IN (
    SELECT d.id FROM doctors d
    INNER JOIN users u ON u.id = d.user_id
    WHERE u.auth_id = auth.uid()
  )
);

-- Policy: Doctors can update their consultations
CREATE POLICY "Doctors can update their consultations"
ON consultations FOR UPDATE
USING (
  doctor_id IN (
    SELECT d.id FROM doctors d
    INNER JOIN users u ON u.id = d.user_id
    WHERE u.auth_id = auth.uid()
  )
);

-- ================================================
-- PRESCRIPTIONS TABLE POLICIES
-- ================================================

-- Enable RLS on prescriptions table
ALTER TABLE prescriptions ENABLE ROW LEVEL SECURITY;

-- Policy: Doctors can view prescriptions for their health records
CREATE POLICY "Doctors can view their prescriptions"
ON prescriptions FOR SELECT
USING (
  health_record_id IN (
    SELECT hr.id FROM health_records hr
    INNER JOIN doctors d ON d.id = hr.doctor_id
    INNER JOIN users u ON u.id = d.user_id
    WHERE u.auth_id = auth.uid()
  )
);

-- Policy: Doctors can create prescriptions
CREATE POLICY "Doctors can create prescriptions"
ON prescriptions FOR INSERT
WITH CHECK (
  health_record_id IN (
    SELECT hr.id FROM health_records hr
    INNER JOIN doctors d ON d.id = hr.doctor_id
    INNER JOIN users u ON u.id = d.user_id
    WHERE u.auth_id = auth.uid()
  )
);

-- ================================================
-- PRESCRIPTION MEDICATIONS TABLE POLICIES
-- ================================================

-- Enable RLS on prescription_medications table
ALTER TABLE prescription_medications ENABLE ROW LEVEL SECURITY;

-- Policy: Doctors can view medications for their prescriptions
CREATE POLICY "Doctors can view prescription medications"
ON prescription_medications FOR SELECT
USING (
  prescription_id IN (
    SELECT p.id FROM prescriptions p
    INNER JOIN health_records hr ON hr.id = p.health_record_id
    INNER JOIN doctors d ON d.id = hr.doctor_id
    INNER JOIN users u ON u.id = d.user_id
    WHERE u.auth_id = auth.uid()
  )
);

-- Policy: Doctors can add medications to their prescriptions
CREATE POLICY "Doctors can add prescription medications"
ON prescription_medications FOR INSERT
WITH CHECK (
  prescription_id IN (
    SELECT p.id FROM prescriptions p
    INNER JOIN health_records hr ON hr.id = p.health_record_id
    INNER JOIN doctors d ON d.id = hr.doctor_id
    INNER JOIN users u ON u.id = d.user_id
    WHERE u.auth_id = auth.uid()
  )
);

-- Policy: Doctors can update medications in their prescriptions
CREATE POLICY "Doctors can update prescription medications"
ON prescription_medications FOR UPDATE
USING (
  prescription_id IN (
    SELECT p.id FROM prescriptions p
    INNER JOIN health_records hr ON hr.id = p.health_record_id
    INNER JOIN doctors d ON d.id = hr.doctor_id
    INNER JOIN users u ON u.id = d.user_id
    WHERE u.auth_id = auth.uid()
  )
);

-- ================================================
-- RATINGS TABLE POLICIES
-- ================================================

-- Enable RLS on ratings table
ALTER TABLE ratings ENABLE ROW LEVEL SECURITY;

-- Policy: Doctors can view ratings for themselves
CREATE POLICY "Doctors can view their ratings"
ON ratings FOR SELECT
USING (
  doctor_id IN (
    SELECT d.id FROM doctors d
    INNER JOIN users u ON u.id = d.user_id
    WHERE u.auth_id = auth.uid()
  )
);

-- ================================================
-- NOTIFICATIONS TABLE POLICIES
-- ================================================

-- Enable RLS on notifications table
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Policy: Doctors can view their own notifications
CREATE POLICY "Doctors can view their notifications"
ON notifications FOR SELECT
USING (
  user_id IN (
    SELECT id FROM users WHERE auth_id = auth.uid()
  )
);

-- Policy: Doctors can update their own notifications (mark as read)
CREATE POLICY "Doctors can update their notifications"
ON notifications FOR UPDATE
USING (
  user_id IN (
    SELECT id FROM users WHERE auth_id = auth.uid()
  )
);

-- ================================================
-- OPTIONAL: Add indexes for better performance
-- ================================================

-- Index on users.auth_id for faster lookups
CREATE INDEX IF NOT EXISTS idx_users_auth_id ON users(auth_id);

-- Index on doctors.user_id for faster joins
CREATE INDEX IF NOT EXISTS idx_doctors_user_id ON doctors(user_id);

-- Index on health_records.doctor_id
CREATE INDEX IF NOT EXISTS idx_health_records_doctor_id ON health_records(doctor_id);

-- Index on consultations.doctor_id
CREATE INDEX IF NOT EXISTS idx_consultations_doctor_id ON consultations(doctor_id);

-- Index on consultations.scheduled_time for date queries
CREATE INDEX IF NOT EXISTS idx_consultations_scheduled_time ON consultations(scheduled_time);

-- ================================================
-- OPTIONAL: Create function to automatically update updated_at
-- ================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Add triggers to automatically update updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_doctors_updated_at BEFORE UPDATE ON doctors
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_consultations_updated_at BEFORE UPDATE ON consultations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_subscriptions_updated_at BEFORE UPDATE ON subscriptions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ================================================
-- NOTES:
-- ================================================
-- 1. Make sure to run these policies in your Supabase SQL Editor
-- 2. Test each policy after creation to ensure it works as expected
-- 3. If you get permission errors, check the RLS policies first
-- 4. You can view active policies in Supabase Dashboard > Authentication > Policies
-- 5. For debugging, you can temporarily disable RLS on a table:
--    ALTER TABLE table_name DISABLE ROW LEVEL SECURITY;
--    (Don't forget to re-enable it after debugging!)
