# Doctor Availability System - Complete Guide

## 📋 Overview

This guide explains how the doctor availability system works, including online/offline status, availability schedules, and automatic time tracking.

---

## 🗄️ Database Schema

### Doctor Table Fields:

```sql
doctors (
  id uuid primary key,
  user_id uuid references users(id),
  bmcd_registration_number varchar(100),
  specialization varchar(255),
  qualification text,
  consultation_fee decimal not null,

  -- Availability Time Tracking
  availability_start timestamptz,    -- When doctor went online
  availability_end timestamptz,      -- When doctor went offline

  -- Availability Schedule (JSON)
  availability jsonb,                -- Weekly schedule

  -- Status Flags
  is_available boolean default false, -- Available for consultations
  is_online boolean default false,    -- Currently online

  bio text,
  experience integer,
  created_at timestamptz default current_timestamp,
  updated_at timestamptz default current_timestamp
);
```

---

## 🔑 Key Fields Explained

### 1. **`is_online`** (boolean)

- **Purpose**: Indicates if the doctor is currently logged in and active
- **Default**: `false`
- **When set to `true`**: Doctor logs in or toggles online
- **When set to `false`**: Doctor logs out or toggles offline

### 2. **`is_available`** (boolean)

- **Purpose**: Indicates if the doctor is accepting new consultations
- **Default**: `false`
- **When set to `true`**: Doctor profile is complete and has availability schedule
- **When set to `false`**: Doctor is not accepting consultations

### 3. **`availability`** (jsonb)

- **Purpose**: Stores the doctor's weekly availability schedule
- **Format**: JSON object with days of week and time slots
- **Example**:

```json
{
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
```

### 4. **`availability_start`** (timestamptz)

- **Purpose**: Records the exact time when doctor went online
- **Auto-set**: When `is_online` changes from `false` to `true`
- **Example**: `2025-10-15T09:30:00Z`

### 5. **`availability_end`** (timestamptz)

- **Purpose**: Records the exact time when doctor went offline
- **Auto-set**: When `is_online` changes from `true` to `false`
- **Cleared**: Set to `null` when doctor goes online again

---

## 🔄 Availability Flow

### 1. **Doctor Registration & Profile Completion**

```
User Signs Up
     ↓
Complete Profile Form
     ↓
Save Profile
     ↓
System generates default availability schedule
     ↓
is_available = true
is_online = true
availability = { weekly schedule }
availability_start = current timestamp
```

**Code Implementation**:

```dart
// In completeDoctorProfile() method
final doctorData = {
  'availability': _generateDefaultAvailability(), // Auto-generate schedule
  'is_available': true,  // Ready for consultations
  'is_online': true,     // Set online immediately
  'availability_start': DateTime.now().toIso8601String(),
  ...
};
```

### 2. **Doctor Login (Subsequent Logins)**

```
Doctor Logs In
     ↓
loadProfile() called
     ↓
Check if is_online = false
     ↓
Set is_online = true
     ↓
Set availability_start = current time
     ↓
If has availability schedule:
  Set is_available = true
```

**Code Implementation**:

```dart
// In loadProfile() method
if (doctor != null && !doctor.isOnline) {
  updateOnlineStatus(doctor.id, true); // Sets online and availability_start
}

if (doctor != null && doctor.hasAvailability && !doctor.isAvailable) {
  updateAvailability(doctor.id, true); // Sets available for consultations
}
```

### 3. **Doctor Goes Offline (Toggle or Logout)**

```
Doctor Toggles OFF or Logs Out
     ↓
Set is_online = false
     ↓
Set availability_end = current time
     ↓
Doctor appears as "Unavailable" to patients
```

**Code Implementation**:

```dart
// In updateOnlineStatus() method
if (!isOnline) {
  updateData['availability_end'] = now.toIso8601String();
}
```

---

## 📱 UI Components

### Home Page - Online Toggle

**Location**: `lib/features/doctor/presentation/pages/home_page.dart`

**Features**:

- Green indicator when online
- Grey indicator when offline
- Toggle switch in app bar (top-right)
- Auto-enabled on login

**Code**:

```dart
Row(
  children: [
    Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: doctor.isOnline ? Colors.green : Colors.grey,
        shape: BoxShape.circle,
      ),
    ),
    SizedBox(width: 8),
    Text(doctor.isOnline ? 'Online' : 'Offline'),
    Switch(
      value: doctor.isOnline,
      onChanged: (_) {
        ref.read(doctorProfileProvider.notifier).toggleOnlineStatus();
      },
    ),
  ],
)
```

### Profile Page - Status Indicator

**Location**: `lib/features/doctor/presentation/pages/profile_page.dart`

**Features**:

- Shows online/offline status with colored dot
- Displays current status text

---

## ⚙️ Backend Implementation

### 1. **Default Availability Generation**

**Method**: `_generateDefaultAvailability()`

**Location**: `lib/features/doctor/data/datasources/doctor_remote_datasource.dart`

**Generated Schedule**:

- **Monday - Friday**: 9:00 AM - 5:00 PM
- **Saturday**: 9:00 AM - 1:00 PM
- **Sunday**: Unavailable

### 2. **Update Online Status with Time Tracking**

**Method**: `updateOnlineStatus(String doctorId, bool isOnline)`

**Behavior**:

```dart
if (isOnline) {
  // Going online
  availability_start = current_time
  availability_end = null
  is_online = true
} else {
  // Going offline
  availability_end = current_time
  is_online = false
}
```

### 3. **Update Profile with Auto-Availability**

**Method**: `updateDoctorProfile(DoctorModel doctor)`

**Behavior**:

- If `availability` is not set, generates default schedule
- Updates all fields including availability
- Maintains online/offline status

---

## 🎯 Patient Side Integration

### Query Available Doctors

**SQL Query Example**:

```sql
SELECT
  d.*,
  u.full_name,
  u.profile_picture_url
FROM doctors d
JOIN users u ON d.user_id = u.id
WHERE d.is_online = true
  AND d.is_available = true
ORDER BY d.updated_at DESC;
```

### Show Doctor Status

**Display Logic**:

```dart
if (doctor.isOnline && doctor.isAvailable) {
  return 'Available Now';
} else if (!doctor.isOnline) {
  return 'Offline';
} else if (!doctor.isAvailable) {
  return 'Not Accepting Consultations';
}
```

---

## 📊 Availability Analytics

### Track Online Time

**SQL Query**:

```sql
-- Get today's online duration
SELECT
  id,
  full_name,
  availability_start,
  availability_end,
  CASE
    WHEN availability_end IS NOT NULL
    THEN availability_end - availability_start
    ELSE NOW() - availability_start
  END as online_duration
FROM doctors
WHERE availability_start >= CURRENT_DATE;
```

### Get Availability History

**SQL Query**:

```sql
-- Get last 7 days availability
SELECT
  DATE(availability_start) as date,
  COUNT(*) as sessions,
  SUM(
    EXTRACT(EPOCH FROM (availability_end - availability_start)) / 3600
  ) as total_hours
FROM doctors
WHERE doctor_id = 'doctor-id-here'
  AND availability_start >= NOW() - INTERVAL '7 days'
GROUP BY DATE(availability_start)
ORDER BY date DESC;
```

---

## 🔧 Configuration

### Update Default Availability Times

**File**: `lib/features/doctor/data/datasources/doctor_remote_datasource.dart`

**Method**: `_generateDefaultAvailability()`

**Customize**:

```dart
Map<String, dynamic> _generateDefaultAvailability() {
  return {
    'monday': {
      'start': '10:00',  // Change start time
      'end': '18:00',    // Change end time
      'available': true
    },
    // ... other days
  };
}
```

---

## 🧪 Testing

### Test Availability System

1. **Test Profile Completion**:

   ```bash
   flutter run
   ```

   - Complete profile as new doctor
   - Check database: `is_online`, `is_available`, and `availability` should be set
   - Verify `availability_start` has current timestamp

2. **Test Login**:

   - Logout and login again
   - Check `is_online` changes to `true`
   - Check `availability_start` updates to new login time

3. **Test Toggle**:

   - Use toggle switch in home page
   - Check status changes in UI
   - Verify database updates

4. **Test Patient View**:
   - Open patient app
   - Check if doctor appears as available
   - Toggle doctor offline
   - Verify doctor disappears from available list

---

## 📝 Database Queries

### Set Doctor Online Manually

```sql
UPDATE doctors
SET
  is_online = true,
  is_available = true,
  availability_start = NOW(),
  availability_end = NULL,
  updated_at = NOW()
WHERE id = 'doctor-id-here';
```

### Set Doctor Offline Manually

```sql
UPDATE doctors
SET
  is_online = false,
  availability_end = NOW(),
  updated_at = NOW()
WHERE id = 'doctor-id-here';
```

### View Doctor Availability

```sql
SELECT
  id,
  bmcd_registration_number,
  specialization,
  is_online,
  is_available,
  availability_start,
  availability_end,
  availability,
  CASE
    WHEN is_online THEN 'Online'
    ELSE 'Offline'
  END as status,
  CASE
    WHEN availability_end IS NULL AND is_online
    THEN EXTRACT(EPOCH FROM (NOW() - availability_start)) / 60
    ELSE NULL
  END as minutes_online
FROM doctors
WHERE id = 'doctor-id-here';
```

### Get All Online Doctors

```sql
SELECT
  d.id,
  u.full_name,
  d.specialization,
  d.is_online,
  d.is_available,
  d.availability_start,
  d.consultation_fee
FROM doctors d
JOIN users u ON d.user_id = u.id
WHERE d.is_online = true
  AND d.is_available = true
ORDER BY d.availability_start DESC;
```

---

## 🔒 Security & RLS Policies

### Allow Doctors to Update Their Status

```sql
CREATE POLICY "Doctors can update their own availability"
ON doctors FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);
```

### Allow Patients to View Online Doctors

```sql
CREATE POLICY "Patients can view available doctors"
ON doctors FOR SELECT
USING (is_online = true AND is_available = true);
```

### Allow Admins Full Access

```sql
CREATE POLICY "Admins have full access"
ON doctors FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE users.id = auth.uid()
    AND users.role = 'admin'
  )
);
```

---

## 🚀 Future Enhancements

### 1. **Custom Availability Editor**

- UI to edit weekly schedule
- Set different times for each day
- Mark specific dates as unavailable

### 2. **Break Management**

- Add "On Break" status
- Temporary unavailability without going offline

### 3. **Automatic Offline**

- Auto-logout after inactivity
- Session timeout handling

### 4. **Notifications**

- Notify patients when favorite doctor comes online
- Remind doctor to go online at scheduled times

### 5. **Analytics Dashboard**

- Total online time per day/week/month
- Peak availability hours
- Consultation acceptance rate

---

## ✅ Summary

### What Happens When:

| Event              | is_online | is_available             | availability_start | availability_end |
| ------------------ | --------- | ------------------------ | ------------------ | ---------------- |
| Profile Completion | `true`    | `true`                   | Current time       | `null`           |
| Login              | `true`    | `true` (if has schedule) | Current time       | `null`           |
| Toggle Online      | `true`    | No change                | Current time       | `null`           |
| Toggle Offline     | `false`   | No change                | No change          | Current time     |
| Logout             | `false`   | No change                | No change          | Current time     |

### Default Availability Schedule:

- **Weekdays**: 9:00 AM - 5:00 PM
- **Saturday**: 9:00 AM - 1:00 PM
- **Sunday**: Closed

### Patient Visibility:

- Patients see doctors where `is_online = true` AND `is_available = true`
- Offline doctors don't appear in available doctor lists

---

**Status**: ✅ **IMPLEMENTED**  
**Date**: October 15, 2025  
**Version**: 1.0.0  
**Impact**: Doctors now have automatic availability management with time tracking
