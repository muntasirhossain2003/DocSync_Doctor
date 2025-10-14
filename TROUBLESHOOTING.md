# Troubleshooting - Doctor Profile Not Found

## Problem

After logging in, you see "No Profile Found" or "Error loading profile" even though you registered with data.

## Cause

This happens when:

1. You registered BEFORE the doctor record creation was added to registration
2. The doctor record creation failed during registration due to RLS policies
3. There's a mismatch between auth_id and user_id

## Solution

### Step 1: Create Your Doctor Profile

1. Log in to the app
2. You'll see "No Profile Found" message
3. Click the **"Create Profile"** button
4. Fill in all required information:
   - BMDC Registration Number (Required)
   - Specialization (Required)
   - Qualification (Required)
   - Consultation Fee (Required)
   - Bio (Optional but recommended)
   - Experience in years (Optional)
5. Click the **check mark (✓)** in the top right corner
6. You should see "Profile completed successfully!"
7. You'll be redirected to the home page with your profile loaded

### Step 2: Verify Your Profile

1. Navigate to the **Profile** tab
2. You should now see all your information
3. You can edit it anytime by clicking the edit icon

### Step 3: Go Online

1. On the **Home** tab, toggle the switch in the app bar to go online
2. This makes you available for consultations

## If You Still Have Issues

### Check Supabase RLS Policies

Make sure you've run all the SQL policies from `supabase_rls_policies.sql`:

```sql
-- Most important policies for profile creation:

-- Allow doctors to insert their own doctor record
CREATE POLICY "Doctors can insert own doctor record"
ON doctors FOR INSERT
WITH CHECK (
  user_id IN (
    SELECT id FROM users WHERE auth_id = auth.uid()
  )
);

-- Allow doctors to view their own doctor record
CREATE POLICY "Doctors can view own doctor record"
ON doctors FOR SELECT
USING (
  user_id IN (
    SELECT id FROM users WHERE auth_id = auth.uid()
  )
);
```

### Check Console for Errors

1. Open Browser Developer Tools (F12)
2. Go to Console tab
3. Look for any red error messages
4. Common errors:
   - **RLS policy violation**: Run the RLS policies SQL
   - **User not found**: Check if user exists in users table
   - **Connection error**: Check Supabase credentials in .env file

### Verify Database Records

In Supabase Dashboard:

1. **Check users table**:

   - Go to Table Editor > users
   - Find your record by email
   - Note the `id` and `auth_id` values
   - Make sure `role` is 'doctor'

2. **Check doctors table**:

   - Go to Table Editor > doctors
   - Look for a record with `user_id` matching your user.id
   - If it doesn't exist, use the Create Profile button in the app

3. **Check auth.users**:
   - Go to Authentication > Users
   - Verify your account exists
   - Copy the User UID (this is your auth_id)

### Manual Fix (Last Resort)

If the app still doesn't work, you can manually create a doctor record in Supabase:

1. Go to Supabase Dashboard > SQL Editor
2. Run this query (replace values with your actual data):

```sql
-- First, get your user_id
SELECT id, email FROM users WHERE auth_id = 'your-auth-id-here';

-- Then insert doctor record
INSERT INTO doctors (
  user_id,
  bmcd_registration_number,
  specialization,
  qualification,
  consultation_fee,
  is_available,
  is_online
) VALUES (
  'your-user-id-from-above',
  'your-bmdc-number',
  'your-specialization',
  'your-qualification',
  500.00, -- your consultation fee
  false,
  false
);
```

## Prevention

### For New Registrations

The registration flow now automatically creates a doctor record, so new users won't face this issue.

### For Existing Users

If you registered before the fix, just follow Step 1 above to create your profile.

## Still Need Help?

1. Check the browser console for specific error messages
2. Verify your Supabase credentials in the `.env` file
3. Make sure all RLS policies are applied
4. Check that your internet connection is stable
5. Try logging out and logging back in

## Quick Checklist

- [ ] Logged in successfully
- [ ] Clicked "Create Profile" button
- [ ] Filled all required fields
- [ ] Saved the profile (check mark button)
- [ ] Saw success message
- [ ] Can see profile information on Profile tab
- [ ] Can toggle online/offline status
- [ ] All RLS policies applied in Supabase
- [ ] .env file has correct credentials
