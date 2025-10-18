-- ================================================
-- SUPABASE STORAGE BUCKET POLICIES
-- Row Level Security for profile-images bucket
-- ================================================

-- Run these queries in your Supabase SQL Editor to fix the upload error

-- ================================================
-- STEP 1: Create the storage bucket (if not already created)
-- ================================================
-- You can also create this in Supabase Dashboard > Storage
-- Make sure the bucket name is 'profile-images' and it's PUBLIC

INSERT INTO storage.buckets (id, name, public)
VALUES ('profile-images', 'profile-images', true)
ON CONFLICT (id) DO NOTHING;

-- ================================================
-- STEP 2: Create RLS Policies for the bucket
-- ================================================

-- Policy 1: Allow authenticated users to upload their own profile images
CREATE POLICY "Users can upload their own profile images"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'profile-images' 
  AND (storage.foldername(name))[1] = 'profiles'
  AND auth.uid()::text = (
    SELECT auth_id::text 
    FROM users 
    WHERE id::text = (regexp_match(name, 'profiles/([a-f0-9\-]+)_'))[1]
  )
);

-- Policy 2: Allow users to update their own profile images
CREATE POLICY "Users can update their own profile images"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'profile-images' 
  AND (storage.foldername(name))[1] = 'profiles'
  AND auth.uid()::text = (
    SELECT auth_id::text 
    FROM users 
    WHERE id::text = (regexp_match(name, 'profiles/([a-f0-9\-]+)_'))[1]
  )
);

-- Policy 3: Allow users to delete their own profile images
CREATE POLICY "Users can delete their own profile images"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'profile-images' 
  AND (storage.foldername(name))[1] = 'profiles'
  AND auth.uid()::text = (
    SELECT auth_id::text 
    FROM users 
    WHERE id::text = (regexp_match(name, 'profiles/([a-f0-9\-]+)_'))[1]
  )
);

-- Policy 4: Allow everyone to view profile images (public bucket)
CREATE POLICY "Public can view profile images"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'profile-images');

-- ================================================
-- ALTERNATIVE: Simpler policies (if the above are too strict)
-- ================================================
-- If you get errors with the above policies, you can use these simpler ones instead:
-- (Uncomment the lines below and comment out the policies above)

-- -- Allow any authenticated user to upload to profile-images bucket
-- CREATE POLICY "Authenticated users can upload profile images"
-- ON storage.objects
-- FOR INSERT
-- TO authenticated
-- WITH CHECK (bucket_id = 'profile-images');

-- -- Allow any authenticated user to update files in profile-images bucket
-- CREATE POLICY "Authenticated users can update profile images"
-- ON storage.objects
-- FOR UPDATE
-- TO authenticated
-- USING (bucket_id = 'profile-images');

-- -- Allow any authenticated user to delete files in profile-images bucket
-- CREATE POLICY "Authenticated users can delete profile images"
-- ON storage.objects
-- FOR DELETE
-- TO authenticated
-- USING (bucket_id = 'profile-images');

-- -- Allow everyone to view files in profile-images bucket
-- CREATE POLICY "Public can view all profile images"
-- ON storage.objects
-- FOR SELECT
-- TO public
-- USING (bucket_id = 'profile-images');

-- ================================================
-- STEP 3: Verify the policies
-- ================================================
-- Run this query to see all policies on storage.objects:
-- SELECT * FROM pg_policies WHERE tablename = 'objects' AND schemaname = 'storage';

-- ================================================
-- TROUBLESHOOTING
-- ================================================
-- If you still get errors:
-- 1. Make sure you're logged in (auth.uid() returns a value)
-- 2. Check that the bucket exists and is public
-- 3. Verify the user record exists in the users table
-- 4. Try the simpler policies first, then tighten security later
-- 5. Check Supabase logs for detailed error messages

-- ================================================
-- NOTES:
-- ================================================
-- The file naming convention used by ImageUploadService is:
-- profiles/{userId}_{uuid}.{extension}
-- 
-- Example: profiles/123e4567-e89b-12d3-a456-426614174000_abc123.jpg
--
-- The policies above extract the userId from the filename and verify
-- it matches the authenticated user's ID in the users table.
