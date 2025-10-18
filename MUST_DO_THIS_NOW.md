# 🚨 YOU MUST DO THIS NOW - Storage Bucket Setup

## The Problem

Your app CAN'T upload images because Supabase Storage has NO PERMISSIONS set up.

Error: `403 Unauthorized - new row violates row-level security policy`

This means: **The bucket policies don't exist in your Supabase project yet.**

---

## ✅ SOLUTION - Follow These EXACT Steps

### 🔴 STEP 1: Open Supabase Dashboard

1. Open your browser
2. Go to: **https://supabase.com/dashboard**
3. Click on your **DocSync** project
4. You should see the project dashboard

### 🔴 STEP 2: Open SQL Editor

1. Look at the LEFT SIDEBAR
2. Find and click: **SQL Editor** (icon looks like `</>`)
3. Click the **"New query"** button
4. You'll see an empty SQL editor

### 🔴 STEP 3: Copy the SQL

1. Open the file: **`RUN_THIS_IN_SUPABASE.sql`** (I just created it)
2. Select ALL the text (Ctrl+A)
3. Copy it (Ctrl+C)

### 🔴 STEP 4: Paste and Run

1. Go back to Supabase SQL Editor
2. Paste the SQL (Ctrl+V)
3. Click the **"RUN"** button (or press Ctrl+Enter)
4. Wait 2-3 seconds

### 🔴 STEP 5: Check the Result

You should see messages like:

```
Success. 1 row affected.
Success. No rows returned.
Success. No rows returned.
...
```

At the end, you should see:

- **1 row** showing the bucket details
- **4 rows** showing the policies

If you see **0 rows** in the policies query, the policies weren't created!

---

## 🔍 Verify It Worked

### Method 1: Check in Storage Tab

1. Click **Storage** in the left sidebar
2. You should see **profile-images** bucket
3. It should have a **"Public"** badge
4. Click on it
5. Click **"Policies"** tab at the top
6. You should see **4 policies** listed:
   - Allow authenticated uploads
   - Allow authenticated updates
   - Allow authenticated deletes
   - Allow public viewing

### Method 2: Run Verification Query

In SQL Editor, run this:

```sql
SELECT policyname FROM pg_policies
WHERE schemaname = 'storage'
AND tablename = 'objects'
AND policyname LIKE '%Allow%';
```

**Expected result:** 4 rows showing the 4 policy names

---

## 🎯 Test in Your App

**After running the SQL successfully:**

1. **Stop your app completely** (not just hot reload)
2. **Start it again**
3. **Go to Edit Profile**
4. **Tap profile picture**
5. **Select an image**
6. **Click Save**

You should see:

```
🔐 Current user: [some-id]
📁 Uploading for userId: [some-id]
🪣 Bucket: profile-images
📂 File path: profiles/[filename]
📊 File size: [bytes]
⬆️ Starting upload...
✅ Upload successful!
🔗 Public URL: https://...
```

---

## ❌ Common Mistakes

### Mistake 1: "I ran the SQL but still get 403"

**Problem:** You didn't hot restart the app
**Fix:** Stop app completely, then start again (not hot reload)

### Mistake 2: "I don't see the verification results"

**Problem:** You didn't scroll down after running SQL
**Fix:** Scroll down in the SQL Editor results panel

### Mistake 3: "SQL gave an error"

**Problem:** Could be syntax error or permissions issue
**Fix:** Share the EXACT error message you see

### Mistake 4: "Policies show 0 rows"

**Problem:** Policies weren't created
**Fix:**

1. Check if you have permission to create policies
2. Try running each CREATE POLICY statement one by one
3. Check for error messages after each one

---

## 🆘 Still Not Working?

If you've done ALL the steps above and it still doesn't work:

### Take these screenshots and share:

1. **SQL Editor after running the queries** (showing Success messages)
2. **Storage → profile-images → Policies tab** (showing the 4 policies)
3. **App logs when you try to upload** (showing the emoji logs)

### Tell me:

1. Did you see "Success" messages after running SQL? (Yes/No)
2. How many policies do you see in the verification query? (Number)
3. Do you see the 🔐 emoji logs in your app? (Yes/No)
4. What's the EXACT error message now?

---

## 📝 Important Notes

- You MUST do this in **Supabase Dashboard**, not in your app
- The SQL MUST be run in **SQL Editor**, not anywhere else
- You MUST **hot restart** the app after running SQL
- The bucket name MUST be exactly `profile-images` (with hyphen)
- All 4 policies MUST exist for it to work

---

## ⚡ Quick Checklist

Before asking for more help, verify:

- [ ] I opened Supabase Dashboard
- [ ] I clicked SQL Editor
- [ ] I pasted the SQL from RUN_THIS_IN_SUPABASE.sql
- [ ] I clicked RUN
- [ ] I saw "Success" messages
- [ ] I saw 1 bucket in verification
- [ ] I saw 4 policies in verification
- [ ] I can see profile-images bucket in Storage tab
- [ ] The bucket has "Public" badge
- [ ] I hot restarted the app (not just reload)
- [ ] I tried uploading again

If ALL boxes are checked and it still fails, then we have a different issue!
