# 📅 Availability Schedule Feature - Complete Guide

## 🎯 Overview

The availability schedule feature allows doctors to set their available working hours for each day of the week. This information is used to show patients when doctors are available for consultations.

---

## ✨ Features Added

### 1. **Weekly Availability Schedule** 📆

- Set different hours for each day of the week
- Toggle availability on/off for each day
- Use time picker for start and end times
- Default schedule: Mon-Fri 9-5, Sat 9-1, Sun closed

### 2. **Automatic Availability Management** ⚡

- Auto-set `is_available = true` when doctor has schedule
- Auto-set `is_online = true` on login
- Track `availability_start` when going online
- Track `availability_end` when going offline

### 3. **Smart Profile Completion** 🎓

- Availability schedule saved during profile creation
- Schedule saved when editing profile
- Default schedule generated if not provided

---

## 📁 Files Modified

### 1. `edit_doctor_profile_page.dart`

**Location**: `lib/features/doctor/presentation/pages/edit_doctor_profile_page.dart`

**Changes**:

- ✅ Added `_availabilitySchedule` state variable
- ✅ Added availability schedule UI section
- ✅ Added time picker functionality
- ✅ Updated save methods to include availability
- ✅ Load existing schedule when editing

**New State Variable**:

```dart
Map<String, Map<String, dynamic>> _availabilitySchedule = {
  'monday': {'start': '09:00', 'end': '17:00', 'available': true},
  'tuesday': {'start': '09:00', 'end': '17:00', 'available': true},
  'wednesday': {'start': '09:00', 'end': '17:00', 'available': true},
  'thursday': {'start': '09:00', 'end': '17:00', 'available': true},
  'friday': {'start': '09:00', 'end': '17:00', 'available': true},
  'saturday': {'start': '09:00', 'end': '13:00', 'available': true},
  'sunday': {'start': '00:00', 'end': '00:00', 'available': false},
};
```

**New Methods**:

```dart
// Build availability schedule UI
List<Widget> _buildAvailabilitySchedule()

// Select time with picker
Future<void> _selectTime(String dayKey, String timeType)
```

---

## 🎨 UI Components

### Availability Schedule Section

**Location**: After "Bio" field, before "Save" button

**Components**:

1. **Section Header**: "Availability Schedule"
2. **Description**: "Set your available hours for each day"
3. **Day Cards**: One card per day with:
   - Day name (e.g., "Monday")
   - Status indicator ("Available" / "Closed")
   - Toggle switch
   - Start time picker (when available)
   - End time picker (when available)

**Screenshot Description**:

```
┌─────────────────────────────────────────┐
│ Availability Schedule                    │
│ Set your available hours for each day   │
├─────────────────────────────────────────┤
│ ┌─────────────────────────────────────┐ │
│ │ Monday        Available    [Switch] │ │
│ │ ┌──────────────┐ ┌──────────────┐  │ │
│ │ │ Start: 09:00 │ │ End: 17:00   │  │ │
│ │ └──────────────┘ └──────────────┘  │ │
│ └─────────────────────────────────────┘ │
│                                          │
│ ┌─────────────────────────────────────┐ │
│ │ Tuesday       Available    [Switch] │ │
│ │ ┌──────────────┐ ┌──────────────┐  │ │
│ │ │ Start: 09:00 │ │ End: 17:00   │  │ │
│ │ └──────────────┘ └──────────────┘  │ │
│ └─────────────────────────────────────┘ │
│ ... (repeat for other days)             │
└─────────────────────────────────────────┘
```

---

## 🔄 Data Flow

### Profile Creation Flow:

```
User fills form
     ↓
Sets availability schedule
     ↓
Clicks "Save Profile"
     ↓
availability = schedule data
is_available = true
is_online = true
availability_start = current time
     ↓
Profile saved to database
     ↓
Doctor redirected to home
```

### Profile Update Flow:

```
User opens edit profile
     ↓
Existing schedule loaded
     ↓
User modifies schedule
     ↓
Clicks "Save Profile"
     ↓
availability updated
     ↓
Profile updated in database
     ↓
User redirected back
```

---

## 🗄️ Database Schema

### Doctor Table Fields Used:

```sql
CREATE TABLE doctors (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid REFERENCES users(id) ON DELETE CASCADE,

  -- Basic Info
  bmcd_registration_number varchar(100) UNIQUE NOT NULL,
  specialization varchar(255),
  qualification text,
  consultation_fee decimal NOT NULL,
  bio text,
  experience integer,

  -- Availability Fields
  availability_start timestamptz,        -- When went online
  availability_end timestamptz,          -- When went offline
  availability jsonb,                    -- Weekly schedule
  is_available boolean DEFAULT false,    -- Ready for consultations
  is_online boolean DEFAULT false,       -- Currently online

  -- Timestamps
  created_at timestamptz DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamptz DEFAULT CURRENT_TIMESTAMP
);
```

### Sample Data:

```json
{
  "id": "uuid-here",
  "user_id": "uuid-here",
  "is_online": true,
  "is_available": true,
  "availability_start": "2025-10-15T09:00:00Z",
  "availability_end": null,
  "availability": {
    "monday": {
      "start": "09:00",
      "end": "17:00",
      "available": true
    },
    "tuesday": {
      "start": "09:00",
      "end": "17:00",
      "available": true
    },
    "wednesday": {
      "start": "09:00",
      "end": "17:00",
      "available": true
    },
    "thursday": {
      "start": "09:00",
      "end": "17:00",
      "available": true
    },
    "friday": {
      "start": "09:00",
      "end": "17:00",
      "available": true
    },
    "saturday": {
      "start": "09:00",
      "end": "13:00",
      "available": true
    },
    "sunday": {
      "start": "00:00",
      "end": "00:00",
      "available": false
    }
  }
}
```

---

## 🧪 Testing Guide

### Test 1: New Doctor Registration with Schedule

```bash
1. Open doctor app
2. Sign up as new doctor
3. Fill profile form (name, BMDC, etc.)
4. Scroll to "Availability Schedule" section
5. ✅ Verify default schedule is shown
6. Modify Monday: Set 10:00-18:00
7. Toggle Sunday to available, set 09:00-13:00
8. Click "Save Profile"
9. ✅ Check database: availability has schedule
10. ✅ Check: is_available = true
11. ✅ Check: is_online = true
12. ✅ Check: availability_start has timestamp
```

### Test 2: Edit Existing Schedule

```bash
1. Login as doctor
2. Go to Profile page
3. Click edit icon
4. Scroll to "Availability Schedule"
5. ✅ Verify current schedule is loaded
6. Change Tuesday: 10:00-16:00
7. Toggle Wednesday to closed
8. Click "Save Profile"
9. ✅ Check database: availability updated
10. ✅ Verify changes persisted
```

### Test 3: Time Picker Functionality

```bash
1. Edit profile
2. Go to availability section
3. Click on "Start Time" for Monday
4. ✅ Time picker appears
5. Select 08:00
6. ✅ Time updates in UI
7. Click on "End Time"
8. Select 16:00
9. ✅ Time updates in UI
10. Save profile
11. ✅ Verify times saved correctly
```

### Test 4: Toggle Availability

```bash
1. Edit profile
2. Go to availability section
3. Toggle Friday to OFF
4. ✅ Time fields disappear
5. ✅ Status shows "Closed"
6. Toggle Friday to ON
7. ✅ Time fields reappear
8. ✅ Status shows "Available"
9. Save profile
10. ✅ Verify availability saved
```

---

## 💡 User Experience

### For Doctors:

**During Profile Creation**:

1. Fill basic information
2. Set availability schedule (default provided)
3. Customize times per day
4. Toggle days on/off as needed
5. Save profile

**During Profile Edit**:

1. Open profile edit page
2. Current schedule pre-loaded
3. Modify any day's times
4. Toggle days on/off
5. Save changes

**Visual Feedback**:

- 🟢 Green "Available" text for working days
- ⚪ Grey "Closed" text for off days
- Time pickers with clear labels
- Card-based layout for clarity

### For Patients:

**Doctor Availability Check**:

- See if doctor is online now
- See doctor's weekly schedule
- Check specific day availability
- View working hours

---

## 📊 Business Logic

### When is Doctor Available?

Doctor is marked as **available** (`is_available = true`) when:

1. ✅ Doctor has set availability schedule
2. ✅ Doctor is currently online (`is_online = true`)
3. ✅ Current day is marked as available in schedule
4. ✅ Current time is within schedule hours

### Automatic Status Updates:

**On Profile Save**:

```dart
if (availability != null && availability.isNotEmpty) {
  is_available = true;  // Has schedule
}
```

**On Login**:

```dart
if (doctor.hasAvailability && !doctor.isOnline) {
  is_online = true;
  availability_start = DateTime.now();
  is_available = true;
}
```

**On Logout/Offline**:

```dart
is_online = false;
availability_end = DateTime.now();
// is_available stays true (has schedule)
```

---

## 🔍 Database Queries

### Get Doctor's Weekly Schedule:

```sql
SELECT
  id,
  bmcd_registration_number,
  specialization,
  is_online,
  is_available,
  availability,
  availability_start,
  availability_end
FROM doctors
WHERE id = 'doctor-id';
```

### Get Available Doctors for Today:

```sql
SELECT
  d.id,
  u.full_name,
  d.specialization,
  d.is_online,
  d.availability
FROM doctors d
JOIN users u ON d.user_id = u.id
WHERE d.is_online = true
  AND d.is_available = true
  AND d.availability->>LOWER(TO_CHAR(CURRENT_DATE, 'Day'))::jsonb->>'available' = 'true'
ORDER BY d.availability_start DESC;
```

### Check Doctor Availability for Specific Day:

```sql
SELECT
  id,
  full_name,
  availability->>'monday' as monday_schedule,
  availability->>'tuesday' as tuesday_schedule
FROM doctors d
JOIN users u ON d.user_id = u.id
WHERE d.is_available = true;
```

---

## 🎯 Key Features Summary

### ✅ Implemented:

1. **Weekly Schedule UI**

   - 7 days with individual cards
   - Toggle on/off per day
   - Time pickers for start/end
   - Visual status indicators

2. **Data Persistence**

   - Save schedule on profile creation
   - Update schedule on profile edit
   - Load existing schedule
   - Store as JSONB in database

3. **Auto-Availability**

   - Auto-set `is_available` when schedule exists
   - Auto-set `is_online` on login
   - Track online/offline times

4. **Default Schedule**
   - Mon-Fri: 9 AM - 5 PM
   - Saturday: 9 AM - 1 PM
   - Sunday: Closed

---

## 🚀 Future Enhancements

### 1. **Recurring Breaks**

```dart
// Add break times within the day
'monday': {
  'start': '09:00',
  'end': '17:00',
  'breaks': [
    {'start': '12:00', 'end': '13:00', 'name': 'Lunch'}
  ],
  'available': true
}
```

### 2. **Special Dates**

```dart
// Mark specific dates as unavailable
'specialDates': {
  '2025-12-25': {'available': false, 'reason': 'Holiday'},
  '2025-10-20': {'available': true, 'hours': '10:00-14:00'}
}
```

### 3. **Slot-Based Booking**

```dart
// Define consultation slots
'monday': {
  'start': '09:00',
  'end': '17:00',
  'slotDuration': 30,  // minutes
  'maxBookingsPerSlot': 1,
  'available': true
}
```

### 4. **Timezone Support**

```dart
// Store timezone with schedule
'timezone': 'Asia/Dhaka',
'availability': { ... }
```

---

## ✅ Checklist

After implementing this feature:

- [x] Availability schedule UI in edit profile
- [x] Time picker for start/end times
- [x] Toggle for each day
- [x] Save schedule on profile creation
- [x] Save schedule on profile update
- [x] Load existing schedule when editing
- [x] Auto-set `is_available` when has schedule
- [x] Auto-set `is_online` on login
- [x] Track `availability_start` when online
- [x] Track `availability_end` when offline
- [x] Default schedule provided
- [x] Visual indicators for status
- [x] No compilation errors

---

## 📱 Screenshots Guide

### Edit Profile - Availability Section:

**Location**: Below Bio field

**Components Visible**:

1. Section title: "Availability Schedule"
2. Description text
3. 7 day cards (Monday - Sunday)
4. Each card shows:
   - Day name
   - Status (Available/Closed)
   - Toggle switch
   - Start time (if available)
   - End time (if available)

**Interaction**:

- Tap time field → Time picker opens
- Toggle switch → Enables/disables day
- Scroll to see all days

---

## 🔧 Customization

### Change Default Hours:

**File**: `edit_doctor_profile_page.dart`

**Location**: `_availabilitySchedule` initialization

**Change**:

```dart
// From 9-5 to 10-6
'monday': {'start': '10:00', 'end': '18:00', 'available': true},
```

### Add Validation:

**File**: `edit_doctor_profile_page.dart`

**Method**: `_saveProfile()`

**Add**:

```dart
// Validate at least one day is available
bool hasAvailableDay = _availabilitySchedule.values
    .any((schedule) => schedule['available'] == true);

if (!hasAvailableDay) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Please set at least one available day')),
  );
  return;
}
```

---

## 📖 Related Documentation

- `AVAILABILITY_SYSTEM_GUIDE.md` - Complete system documentation
- `AVAILABILITY_QUICK_REFERENCE.md` - Quick reference guide
- `DOCTOR_AVAILABILITY_FIX.md` - Original availability fix
- `IMPLEMENTATION_COMPLETE.md` - Implementation summary

---

**Status**: ✅ **COMPLETE**  
**Date**: October 15, 2025  
**Version**: 1.0.0  
**Testing**: Ready for manual testing  
**Compilation**: ✅ No errors

---

## 🎉 Success!

The availability schedule feature is now fully integrated into the doctor profile form. Doctors can:

✅ Set custom hours for each day  
✅ Toggle days on/off  
✅ Use time pickers for easy time selection  
✅ View default schedule  
✅ Edit existing schedules  
✅ Automatically become available when schedule is set

**Ready to test!** 🚀
