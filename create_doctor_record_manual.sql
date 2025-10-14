-- Manual Doctor Record Creation Script
-- Use this if the app still doesn't create your doctor record

-- Step 1: Check your user data
SELECT 
  id as user_id,
  auth_id,
  email,
  full_name,
  phone,
  role
FROM users 
WHERE role = 'doctor'
ORDER BY created_at DESC
LIMIT 5;

-- Step 2: Check if doctor record already exists
-- Replace 'your-email@example.com' with your actual email
SELECT 
  d.*,
  u.email,
  u.full_name
FROM doctors d
JOIN users u ON u.id = d.user_id
WHERE u.email = 'your-email@example.com';

-- Step 3: If no doctor record exists, create one manually
-- IMPORTANT: Replace these values with your actual data

-- First, get your user_id (copy the 'user_id' from Step 1 result)
-- Then run this INSERT:

INSERT INTO doctors (
  user_id,
  bmcd_registration_number,
  specialization,
  qualification,
  consultation_fee,
  is_available,
  is_online,
  bio,
  experience,
  created_at,
  updated_at
) VALUES (
  'PASTE_YOUR_USER_ID_HERE',  -- From Step 1
  'BMDC-12345',                -- Your BMDC number
  'General Medicine',          -- Your specialization
  'MBBS, MD',                  -- Your qualification  
  500.00,                      -- Your consultation fee
  false,                       -- is_available
  false,                       -- is_online  
  'Experienced doctor...',     -- Your bio (optional)
  5,                           -- Years of experience (optional)
  NOW(),
  NOW()
);

-- Step 4: Verify the doctor record was created
SELECT 
  d.id,
  d.user_id,
  d.bmcd_registration_number,
  d.specialization,
  d.qualification,
  d.consultation_fee,
  u.email,
  u.full_name
FROM doctors d
JOIN users u ON u.id = d.user_id
WHERE u.email = 'your-email@example.com';

-- If successful, you should see your doctor record!
-- Now refresh the app and you should see your profile.
