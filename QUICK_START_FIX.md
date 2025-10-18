# ⚡ IMMEDIATE FIX - Copy & Paste These Steps

## 🎯 Your Problem

```
StorageException: new row violates row-level security policy, 403, Unauthorized
```

## ✅ Solution (5 Minutes)

### STEP 1: Open Supabase

1. Go to: https://supabase.com/dashboard
2. Open your DocSync project
3. Click "SQL Editor" (left sidebar)

### STEP 2: Copy This SQL (ALL OF IT)

```sql
-- Create bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('profile-images', 'profile-images', true)
ON CONFLICT (id) DO NOTHING;

-- Drop old policies if they exist
DROP POLICY IF EXISTS "Allow authenticated uploads" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated updates" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated deletes" ON storage.objects;
DROP POLICY IF EXISTS "Allow public viewing" ON storage.objects;

-- Create new policies
CREATE POLICY "Allow authenticated uploads"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'profile-images');

CREATE POLICY "Allow authenticated updates"
ON storage.objects FOR UPDATE TO authenticated
USING (bucket_id = 'profile-images');

CREATE POLICY "Allow authenticated deletes"
ON storage.objects FOR DELETE TO authenticated
USING (bucket_id = 'profile-images');

CREATE POLICY "Allow public viewing"
ON storage.objects FOR SELECT TO public
USING (bucket_id = 'profile-images');
```

### STEP 3: Run It

1. Paste into SQL Editor
2. Click "RUN" button
3. Should say "Success"

### STEP 4: Verify

Run this to check:

```sql
SELECT policyname FROM pg_policies
WHERE schemaname = 'storage' AND tablename = 'objects';
```

You should see 4 policies listed.

### STEP 5: Test in App

1. Hot restart app (stop and start, not just reload)
2. Try uploading profile image again
3. Should work now!

---

## ✅ What You Should See After Fix

When you try to upload again, you should see these logs:

```
🔐 Current user: [some-id]
📁 Uploading for userId: [some-id]
🪣 Bucket: profile-images
📂 File path: profiles/[filename]
📊 File size: [number] bytes
⬆️ Starting upload...
✅ Upload successful!
🔗 Public URL: https://...
```

If you see ❌ instead of ✅, share those logs with me!

---

## 🐛 Still Not Working?

### Check 1: Is bucket public?

- Go to Storage → profile-images
- Should see "Public" badge
- If not: Click settings ⚙️ → Check "Public bucket" → Save

### Check 2: Are you logged in?

Look for this in logs:

```
🔐 Current user: null
```

If you see `null`, log out and back in.

### Check 3: Did SQL actually run?

- Should have seen "Success" message
- If you saw an error, share it with me

---

## 📞 Quick Help

If still broken, tell me:

1. What did you see after running the SQL? (Success or Error?)
2. Do you see the 🔐 emoji logs when you try to upload?
3. What's the exact error message now?
