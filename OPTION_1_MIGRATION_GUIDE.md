# 🎯 OPTION 1: Update Existing Prescriptions Table

## ✅ What This Does

This approach **updates your existing prescriptions table** instead of creating a new one. It:

- ✅ Keeps your existing `health_record_id` column
- ✅ Adds new columns needed for the prescription feature
- ✅ Creates the `medical_tests` table
- ✅ Updates all RLS policies
- ✅ **No data loss** - your existing data stays intact

## 📋 Step-by-Step Instructions

### Step 1: Run the Migration SQL

1. Open **Supabase Dashboard** → **SQL Editor**
2. Copy **ALL contents** from `update_existing_prescriptions_schema.sql`
3. Paste into SQL Editor
4. Click **Run** button

Expected output:

```
✅ Prescriptions table updated successfully!
✅ Medical tests table created!
✅ RLS policies updated!
✅ You can now use the prescription feature in your app!
```

### Step 2: Verify the Migration

Run this in SQL Editor to check:

```sql
-- Check new columns were added
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'prescriptions'
ORDER BY ordinal_position;

-- Should show:
-- id, health_record_id, created_at,
-- consultation_id, patient_id, doctor_id,
-- diagnosis, symptoms, medical_notes,
-- follow_up_date, updated_at
```

### Step 3: Hot Reload Your App

In your terminal where Flutter is running:

```bash
r  # Press 'r' for hot reload
```

Or restart the app:

```bash
R  # Press 'R' for hot restart
```

### Step 4: Test the Feature

1. Open the app
2. Go to **Prescriptions** tab
3. Should show "No Prescriptions Yet" (no error!)
4. Make a video call
5. End the call
6. Click **"Create Prescription"**
7. Fill the form and save
8. Check Prescriptions tab - your prescription appears!

## 📊 What Gets Updated

### Prescriptions Table - NEW COLUMNS:

- `consultation_id` - Links to consultation
- `patient_id` - Direct link to patient
- `doctor_id` - Direct link to doctor
- `diagnosis` - Primary diagnosis text
- `symptoms` - Patient symptoms
- `medical_notes` - Doctor's notes
- `follow_up_date` - When to follow up
- `updated_at` - Last update timestamp

### Prescription Medications Table - UPDATED:

- Added NOT NULL constraints
- Added length validation checks

### Medical Tests Table - NEW TABLE:

- `id` - Primary key
- `prescription_id` - Links to prescription
- `test_name` - Name of test
- `test_reason` - Why test is needed
- `urgency` - urgent/normal/routine
- `created_at` - Timestamp

## 🔐 Security (RLS Policies)

All new RLS policies ensure:

- ✅ Doctors can only see their own prescriptions
- ✅ Doctors can only create prescriptions for their consultations
- ✅ Doctors can update/delete their own prescriptions
- ✅ Doctors can manage medications and tests for their prescriptions

## 🎨 Benefits of This Approach

1. **No Data Loss**: Keeps existing `health_record_id` and data
2. **Backward Compatible**: Old features still work
3. **Flexible**: Can use prescriptions with OR without consultations
4. **Safe**: Uses `IF NOT EXISTS` - won't break if run twice

## 🔧 Troubleshooting

### Issue: "Column already exists"

**Solution**: This is fine! The migration uses `IF NOT EXISTS`, so it safely skips existing columns.

### Issue: "Cannot add NOT NULL constraint"

**Solution**: If you have existing records with null values in `diagnosis`, the commented section will fail. That's okay - just leave diagnosis nullable for now.

### Issue: Still seeing error in app

**Solution**:

1. Make sure migration completed successfully
2. Hot reload the app (press 'r')
3. Check that doctor profile exists in database

### Issue: "Doctor not found"

**Solution**: Run this in SQL Editor:

```sql
-- Check your doctor record exists
SELECT u.id as user_id, d.id as doctor_id
FROM users u
LEFT JOIN doctors d ON d.user_id = u.id
WHERE u.auth_id = auth.uid();
```

If doctor_id is NULL, you need to create your doctor profile first.

## ✨ What's Next

After running the migration:

1. **Test Creating Prescription**

   - Complete a video call
   - Create prescription with diagnosis, medications, tests
   - Check it appears in Prescriptions list

2. **Optional Enhancements** (Future)
   - View prescription details
   - Edit prescriptions
   - Print/PDF export
   - Prescription templates

## 📁 Files You Need

1. **Migration SQL**: `update_existing_prescriptions_schema.sql` ← **RUN THIS FIRST**
2. **Verification SQL**: `verify_prescriptions_tables.sql` ← Run after to check
3. **Flutter Code**: Already updated and ready!

## 🚀 Quick Start Checklist

- [ ] Open Supabase SQL Editor
- [ ] Copy `update_existing_prescriptions_schema.sql`
- [ ] Paste and Run in SQL Editor
- [ ] See success messages
- [ ] Hot reload Flutter app
- [ ] Go to Prescriptions tab
- [ ] No more error! ✅
- [ ] Test creating a prescription
- [ ] Success! 🎉

## 💡 Pro Tips

1. **Backup First** (Optional but recommended):

   ```sql
   -- Export current prescriptions
   SELECT * FROM prescriptions;
   ```

2. **Test with Sample Data**:
   After migration, you can manually insert a test prescription to verify everything works.

3. **Monitor Performance**:
   The migration adds indexes automatically for better query performance.

## ✅ Expected Result

After running this migration:

- ✅ App loads without errors
- ✅ Prescriptions tab shows empty state
- ✅ Can create prescriptions after video calls
- ✅ All data relationships work correctly
- ✅ RLS policies protect your data

---

**Status**: Ready to run!  
**Time to complete**: ~30 seconds  
**Risk level**: Low (non-destructive, adds columns only)

Just copy the SQL file contents and run in Supabase! 🚀
