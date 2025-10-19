-- Check if prescriptions exist in database
SELECT 
  p.id,
  p.doctor_id,
  p.patient_id,
  p.consultation_id,
  p.diagnosis,
  p.symptoms,
  p.created_at,
  d.id as doctor_table_id,
  u.id as user_id,
  u.auth_id,
  u.full_name as doctor_name
FROM prescriptions p
LEFT JOIN doctors d ON d.id = p.doctor_id
LEFT JOIN users u ON u.id = d.user_id
ORDER BY p.created_at DESC
LIMIT 5;

-- Check current user's doctor ID
SELECT 
  u.id as user_id,
  u.auth_id,
  u.full_name,
  d.id as doctor_id
FROM users u
LEFT JOIN doctors d ON d.user_id = u.id
WHERE u.auth_id = auth.uid();

-- Check if doctor_id column exists
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'prescriptions' 
  AND column_name IN ('doctor_id', 'consultation_id', 'diagnosis', 'patient_id');

-- Check RLS policies
SELECT policyname, cmd, qual, with_check
FROM pg_policies 
WHERE schemaname = 'public' 
  AND tablename = 'prescriptions';
