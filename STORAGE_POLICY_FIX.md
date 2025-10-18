# 🔧 Fix Profile Image Upload Error

## Problem

You're getting this error when trying to upload profile images:

```
Image upload failed: Exception: Failed to upload image:
StorageException(message: new row violates row-level security policy,
statusCode: 403, error: Unauthorized)
```

## Root Cause

The Supabase Storage bucket `profile-images` has Row Level Security (RLS) enabled, but there are **no policies** allowing authenticated users to upload files.

---

## ✅ SOLUTION: Add Storage Policies

### **Option 1: Quick Fix (Recommended for Testing)**

1. **Open Supabase Dashboard**

   - Go to your Supabase project: https://supabase.com/dashboard
   - Navigate to: **SQL Editor** (left sidebar)

2. **Run the Quick Fix SQL**

   - Copy the contents of `quick_fix_storage_policies.sql`
   - Paste it into the SQL Editor
   - Click **RUN** button

3. **Test the Upload**
   - Go back to your app
   - Try uploading a profile image again
   - It should work now! ✅

---

### **Option 2: Secure Policies (Recommended for Production)**

If you want more secure policies that only allow users to upload their own images:

1. **Open Supabase SQL Editor**

2. **Run the Secure Policies**

   - Copy the contents of `supabase_storage_policies.sql`
   - Use the **main policies** (not the alternative ones)
   - Paste and run in SQL Editor

3. **Verify**
   - The policies will ensure users can only upload/update/delete their own profile images
   - Public viewing is still allowed for profile pictures

---

## 📋 What the Policies Do

### Quick Fix Policies:

- ✅ Any **authenticated user** can upload files to `profile-images`
- ✅ Any **authenticated user** can update their uploaded files
- ✅ Any **authenticated user** can delete their uploaded files
- ✅ **Everyone** (including unauthenticated) can view/download images

### Secure Policies:

- ✅ Users can only upload images with their own **userId** in the filename
- ✅ Users can only update/delete their own images
- ✅ **Everyone** can view images (for profile picture display)
- ✅ Filename validation: `profiles/{userId}_{uuid}.{ext}`

---

## 🔍 Verification Steps

After running the SQL policies:

1. **Check Policies Exist:**

   ```sql
   SELECT * FROM pg_policies
   WHERE tablename = 'objects'
   AND schemaname = 'storage';
   ```

   You should see 4-5 policies listed.

2. **Check Bucket Exists:**

   - Go to **Storage** in Supabase Dashboard
   - You should see `profile-images` bucket
   - Make sure it's marked as **Public**

3. **Test Upload:**
   - Try uploading a profile image in your app
   - Check Storage > profile-images > profiles folder
   - You should see the uploaded file

---

## 🐛 Still Getting Errors?

### Error: "Bucket does not exist"

**Fix:** Run this in SQL Editor:

```sql
INSERT INTO storage.buckets (id, name, public)
VALUES ('profile-images', 'profile-images', true)
ON CONFLICT (id) DO NOTHING;
```

### Error: "Policy already exists"

**Fix:** Drop existing policies first:

```sql
DROP POLICY IF EXISTS "Allow authenticated uploads" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated updates" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated deletes" ON storage.objects;
DROP POLICY IF EXISTS "Allow public viewing" ON storage.objects;
```

Then re-run the policy creation queries.

### Error: "Not authenticated"

**Fix:**

- Make sure you're logged in to the app
- Check that `Supabase.instance.client.auth.currentUser` is not null
- Try logging out and logging back in

---

## 📸 Next Steps After Fix

Once the policies are in place:

1. **Test Image Upload:**

   - Open your app
   - Go to Edit Profile
   - Tap the profile picture/camera icon
   - Select an image from gallery or take a photo
   - Save the profile
   - ✅ Upload should succeed!

2. **Verify Image Display:**

   - Check that the image appears on Edit Profile page
   - Check that the image appears on Profile page
   - Refresh the app to verify it loads from Supabase Storage

3. **Test Update:**
   - Upload a different image
   - Old image should be deleted automatically
   - New image should appear

---

## 🎯 Summary

**Quick Action:**

1. Copy `quick_fix_storage_policies.sql`
2. Run in Supabase SQL Editor
3. Try upload again
4. Done! 🎉

**Files Created:**

- `quick_fix_storage_policies.sql` - Simple policies for immediate fix
- `supabase_storage_policies.sql` - Secure policies with user validation
- `STORAGE_POLICY_FIX.md` - This guide

---

Need more help? Check the Supabase docs:
https://supabase.com/docs/guides/storage/security/access-control
