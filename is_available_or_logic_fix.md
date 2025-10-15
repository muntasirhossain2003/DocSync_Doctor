# Doctor Availability OR Logic Fix

## Problem

The `is_available` field was not being set correctly. It was staying `FALSE` even when doctors had availability schedules saved.

## Business Logic Requirement

**is_available = true** when **EITHER**:

- `is_online = true` **OR**
- Doctor has an availability schedule (at least one day is available)

## Changes Made

### 1. Database Fix (SQL Script)

**File**: `fix_is_available.sql`

Updates existing doctors in the database:

```sql
-- Set is_available = true for doctors who are online OR have availability schedule
UPDATE doctors
SET is_available = true
WHERE (is_online = true OR (availability IS NOT NULL AND availability != '{}'::jsonb))
  AND is_available = false;

-- Set is_available = false for doctors who are offline AND have no schedule
UPDATE doctors
SET is_available = false
WHERE is_online = false
  AND (availability IS NULL OR availability = '{}'::jsonb)
  AND is_available = true;
```

### 2. Application Code Fix (Dart)

**File**: `lib/features/doctor/data/datasources/doctor_remote_datasource.dart`

#### Updated Methods:

**a) `updateDoctorProfile()`** (Lines 88-95)

```dart
// Check if doctor has at least one available day
bool hasAvailableDay = availability.values.any((day) {
  if (day is Map) {
    return day['available'] == true;
  }
  return false;
});

// is_available uses OR condition: true if EITHER is_online OR has availability schedule
bool isAvailable = doctor.isOnline || hasAvailableDay;

final doctorData = {
  // ...
  'is_available': isAvailable, // OR condition: is_online OR has_schedule
  'is_online': doctor.isOnline,
  // ...
};
```

**b) `completeDoctorProfile()`** (Lines 148-161)

```dart
// Note: is_online is set to true on profile completion, so is_available will also be true
// (using OR condition: is_online OR has_schedule)
final doctorData = {
  // ...
  'is_available': true, // Always true on completion (is_online is true)
  'is_online': true, // Set to true when profile is complete
  // ...
};
```

**c) `updateOnlineStatus()`** (Lines 203-248)

```dart
// Get current doctor data to check availability schedule
final doctorData = await supabaseClient
    .from('doctors')
    .select('availability')
    .eq('id', doctorId)
    .single();

// Check if doctor has availability schedule
final availability = doctorData['availability'] as Map<String, dynamic>?;
bool hasAvailableDay = false;
if (availability != null && availability.isNotEmpty) {
  hasAvailableDay = availability.values.any((day) {
    if (day is Map) {
      return day['available'] == true;
    }
    return false;
  });
}

// is_available uses OR condition: true if EITHER is_online OR has availability schedule
bool isAvailable = isOnline || hasAvailableDay;

final updateData = <String, dynamic>{
  'is_online': isOnline,
  'is_available': isAvailable, // Update based on OR condition
  // ...
};
```

## How It Works Now

### Scenario 1: Doctor Goes Online

- `is_online` = true
- `is_available` = true (regardless of schedule)
- **Result**: Patients can see doctor as available

### Scenario 2: Doctor Goes Offline BUT Has Schedule

- `is_online` = false
- `availability` = { Monday: {available: true, ...}, ... }
- `is_available` = true (because has schedule)
- **Result**: Patients can see doctor as available for scheduled appointments

### Scenario 3: Doctor Goes Offline AND No Schedule

- `is_online` = false
- `availability` = null or empty
- `is_available` = false
- **Result**: Patients see doctor as unavailable

### Scenario 4: Doctor Updates Profile with Schedule

- Saves profile with availability schedule (Mon-Fri 9-5)
- `is_available` = true (because either online OR has schedule)
- **Result**: Doctor becomes available to patients

## Testing Steps

1. **Run SQL Script** to fix existing doctors:

   ```bash
   # In Supabase SQL Editor, run fix_is_available.sql
   ```

2. **Test Profile Update**:

   - Edit doctor profile
   - Add/modify availability schedule
   - Save profile
   - Check database: `is_available` should be `true`

3. **Test Online Toggle**:

   - Toggle online status OFF
   - If doctor has schedule: `is_available` stays `true`
   - If doctor has NO schedule: `is_available` becomes `false`

4. **Test Patient View**:
   - Patient app should show doctor as "Available" when `is_available = true`
   - Patient should be able to book appointments

## Files Modified

1. `fix_is_available.sql` - Database update script
2. `lib/features/doctor/data/datasources/doctor_remote_datasource.dart` - Application logic
   - `updateDoctorProfile()` method
   - `completeDoctorProfile()` method
   - `updateOnlineStatus()` method

## Database Schema

```sql
doctors table:
- is_online: boolean (default false) - Doctor currently online?
- is_available: boolean (default false) - Doctor available for appointments? (OR condition)
- availability: jsonb - Weekly schedule with time slots
- availability_start: timestamptz - When doctor went online
- availability_end: timestamptz - When doctor went offline
```

## Next Steps

1. Run the SQL script on Supabase to fix existing doctors
2. Test the changes in the app
3. Verify patients can see doctors as available
4. Monitor for any edge cases

## Notes

- The OR logic ensures doctors are visible to patients if they're EITHER actively online OR have set their availability schedule
- This matches the business requirement where doctors can be available through scheduled appointments even when not currently online
- The SQL script includes verification queries to check which doctors will be affected
