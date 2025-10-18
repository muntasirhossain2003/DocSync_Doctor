-- ========================================
-- RUN THIS IN SUPABASE SQL EDITOR
-- Copy line by line if needed
-- ========================================

-- STEP 1: Create the bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'profile-images', 
  'profile-images', 
  true, 
  52428800, 
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
  public = true,
  file_size_limit = 52428800,
  allowed_mime_types = ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp'];

-- STEP 2: Remove any existing policies (to avoid conflicts)
DROP POLICY IF EXISTS "Allow authenticated uploads" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated updates" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated deletes" ON storage.objects;
DROP POLICY IF EXISTS "Allow public viewing" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can update" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can delete" ON storage.objects;
DROP POLICY IF EXISTS "Public can view" ON storage.objects;

-- STEP 3: Create INSERT policy (allows uploads)
CREATE POLICY "Allow authenticated uploads"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'profile-images'
);

-- STEP 4: Create UPDATE policy (allows updates)
CREATE POLICY "Allow authenticated updates"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'profile-images'
);

-- STEP 5: Create DELETE policy (allows deletes)
CREATE POLICY "Allow authenticated deletes"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'profile-images'
);

-- STEP 6: Create SELECT policy (allows public viewing)
CREATE POLICY "Allow public viewing"
ON storage.objects
FOR SELECT
TO public
USING (
  bucket_id = 'profile-images'
);

-- ========================================
-- VERIFICATION QUERIES
-- Run these to check if it worked
-- ========================================

-- Check if bucket exists
SELECT * FROM storage.buckets WHERE id = 'profile-images';

-- Check if policies exist (should return 4 rows)
SELECT 
  schemaname,
  tablename,
  policyname,
  cmd as operation,
  roles
FROM pg_policies 
WHERE schemaname = 'storage' 
  AND tablename = 'objects'
  AND (
    policyname = 'Allow authenticated uploads' OR
    policyname = 'Allow authenticated updates' OR
    policyname = 'Allow authenticated deletes' OR
    policyname = 'Allow public viewing'
  )
ORDER BY policyname;
