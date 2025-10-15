# Availability System - Quick Reference

## 🎯 What Was Changed

### Files Modified:

1. ✅ `lib/features/doctor/data/datasources/doctor_remote_datasource.dart`

   - Added `_generateDefaultAvailability()` method
   - Updated `updateOnlineStatus()` to track availability_start/end times
   - Updated `completeDoctorProfile()` to auto-generate availability and set online
   - Updated `updateDoctorProfile()` to include default availability

2. ✅ `lib/features/doctor/presentation/providers/doctor_profile_provider.dart`
   - Enhanced `loadProfile()` to auto-set availability when doctor has schedule

---

## 🔄 New Behavior

### When Doctor Completes Profile (First Time):

```
✅ is_online = true
✅ is_available = true
✅ availability = { default weekly schedule }
✅ availability_start = current timestamp
```

### When Doctor Logs In:

```
✅ is_online = true
✅ availability_start = current timestamp
✅ availability_end = null
✅ is_available = true (if has schedule)
```

### When Doctor Toggles Online:

```
✅ is_online = true
✅ availability_start = current timestamp
✅ availability_end = null
```

### When Doctor Toggles Offline:

```
✅ is_online = false
✅ availability_end = current timestamp
```

---

## 📅 Default Availability Schedule

```json
{
  "monday": { "start": "09:00", "end": "17:00", "available": true },
  "tuesday": { "start": "09:00", "end": "17:00", "available": true },
  "wednesday": { "start": "09:00", "end": "17:00", "available": true },
  "thursday": { "start": "09:00", "end": "17:00", "available": true },
  "friday": { "start": "09:00", "end": "17:00", "available": true },
  "saturday": { "start": "09:00", "end": "13:00", "available": true },
  "sunday": { "start": "00:00", "end": "00:00", "available": false }
}
```

**Times**: Monday-Friday: 9 AM - 5 PM, Saturday: 9 AM - 1 PM, Sunday: Closed

---

## 🗄️ Database Fields Updated

| Field                | Type        | Purpose                 | Auto-Updated?                     |
| -------------------- | ----------- | ----------------------- | --------------------------------- |
| `availability`       | jsonb       | Weekly schedule         | ✅ Yes (on profile save)          |
| `is_available`       | boolean     | Accepting consultations | ✅ Yes (on login if has schedule) |
| `is_online`          | boolean     | Currently online        | ✅ Yes (on login/toggle)          |
| `availability_start` | timestamptz | When went online        | ✅ Yes (on going online)          |
| `availability_end`   | timestamptz | When went offline       | ✅ Yes (on going offline)         |

---

## 🧪 How to Test

### Test 1: New Doctor Registration

```bash
1. flutter run
2. Sign up as new doctor
3. Complete profile form
4. Save profile
5. Check database:
   - is_online = true ✅
   - is_available = true ✅
   - availability has schedule ✅
   - availability_start has timestamp ✅
```

### Test 2: Existing Doctor Login

```bash
1. Logout from doctor app
2. Login again
3. Check database:
   - is_online = true ✅
   - availability_start updated to new time ✅
4. Check patient app:
   - Doctor shows as "Available" ✅
```

### Test 3: Toggle Online/Offline

```bash
1. Login to doctor app
2. Go to home page
3. Toggle switch to OFF
4. Check database:
   - is_online = false ✅
   - availability_end has timestamp ✅
5. Check patient app:
   - Doctor shows as "Unavailable" ✅
6. Toggle switch to ON
7. Check database:
   - is_online = true ✅
   - availability_start updated ✅
   - availability_end = null ✅
```

---

## 📱 User Experience

### Doctor App:

- ✅ Auto-online on login
- ✅ Green/grey status indicator
- ✅ Manual toggle in home page
- ✅ Availability schedule auto-generated

### Patient App:

- ✅ Only sees online doctors
- ✅ Can book with available doctors
- ✅ Real-time status updates

---

## 🔍 SQL Queries for Testing

### Check Doctor Status:

```sql
SELECT
  id,
  is_online,
  is_available,
  availability_start,
  availability_end,
  availability
FROM doctors
WHERE user_id = 'your-user-id';
```

### Get All Online Doctors:

```sql
SELECT
  d.id,
  u.full_name,
  d.is_online,
  d.is_available,
  d.availability_start
FROM doctors d
JOIN users u ON d.user_id = u.id
WHERE d.is_online = true AND d.is_available = true;
```

### Calculate Online Duration:

```sql
SELECT
  id,
  availability_start,
  CASE
    WHEN availability_end IS NULL
    THEN EXTRACT(EPOCH FROM (NOW() - availability_start)) / 60
    ELSE EXTRACT(EPOCH FROM (availability_end - availability_start)) / 60
  END as minutes_online
FROM doctors
WHERE id = 'doctor-id';
```

---

## 🎨 UI Changes

### Home Page (`home_page.dart`):

```dart
// Toggle already exists, now enhanced with:
- Auto-online on login
- Green color for online status
- Availability auto-set when has schedule
```

### Profile Page (`profile_page.dart`):

```dart
// Shows status with colored dot:
- 🟢 Green = Online
- ⚪ Grey = Offline
```

---

## 🚨 Important Notes

1. **Auto-Online**: Doctors are automatically set online when they:
   - Complete their profile (first time)
   - Login to the app
2. **Auto-Available**: `is_available` is set to `true` when:

   - Profile has availability schedule
   - Doctor is online

3. **Time Tracking**:

   - `availability_start` = timestamp when going online
   - `availability_end` = timestamp when going offline
   - Used for analytics and tracking

4. **Default Schedule**:
   - Auto-generated if not provided
   - 9-5 PM weekdays, 9-1 PM Saturday, closed Sunday

---

## 📋 Checklist

After implementing these changes:

- [x] Doctor auto-set online on profile completion
- [x] Doctor auto-set online on login
- [x] Availability schedule auto-generated
- [x] availability_start tracked when going online
- [x] availability_end tracked when going offline
- [x] is_available auto-set when has schedule
- [x] Toggle works in home page
- [x] Status visible in profile page
- [x] Patient app shows available doctors

---

## 🔧 Customization

### Change Default Times:

**File**: `lib/features/doctor/data/datasources/doctor_remote_datasource.dart`

**Method**: `_generateDefaultAvailability()`

```dart
// Change from 9-5 to 10-6
'monday': {'start': '10:00', 'end': '18:00', 'available': true},
```

### Change Auto-Availability Logic:

**File**: `lib/features/doctor/presentation/providers/doctor_profile_provider.dart`

**Method**: `loadProfile()`

```dart
// Remove auto-availability on login
// Comment out this section:
// if (doctor != null && doctor.hasAvailability && !doctor.isAvailable) {
//   updateAvailability(doctor.id, true);
// }
```

---

## ✅ Summary

### Problem Solved:

❌ **Before**: Doctors showed as "unavailable" to patients  
✅ **After**: Doctors automatically online and available

### Key Features Added:

1. ✅ Auto-online on login
2. ✅ Auto-availability when profile complete
3. ✅ Default weekly schedule
4. ✅ Time tracking (start/end)
5. ✅ Patient visibility

### Database Updates:

- `availability` → Auto-generated weekly schedule
- `is_available` → Auto-set to true when online
- `is_online` → Auto-set to true on login
- `availability_start` → Timestamp when online
- `availability_end` → Timestamp when offline

---

**Status**: ✅ **READY TO USE**  
**Version**: 1.0.0  
**Date**: October 15, 2025

For detailed documentation, see: `AVAILABILITY_SYSTEM_GUIDE.md`
