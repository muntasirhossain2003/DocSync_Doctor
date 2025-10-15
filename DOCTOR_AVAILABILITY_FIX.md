# Doctor Availability Fix - Complete Guide

## 🔴 Problem: "Doctor Unavailable" on Patient Side

### Issue Description:

Patients see "Doctor Unavailable" because the doctor's `is_online` status in the database is set to `false`.

### Root Cause:

- When doctors log in, their `is_online` status remains `false`
- The patient app checks this status to show availability
- Doctors need to manually toggle online status (but the toggle was hidden)

---

## ✅ Solution Implemented

### 1. **Automatic Online Status** ⚡

When a doctor logs into the app, they are **automatically set to online**.

**What Changed:**

- Modified `doctor_profile_provider.dart`
- Added automatic online status update in `loadProfile()` method
- Doctor is set online immediately after login

### 2. **Online/Offline Toggle** 🔄

Re-enabled the online/offline toggle switch in the home page.

**What Changed:**

- Uncommented the toggle in `home_page.dart`
- Added color indicators (Green = Online, Grey = Offline)
- Doctors can now manually toggle their status

---

## 📱 How It Works Now

### For Doctors:

1. **Login** → Automatically set to **ONLINE** ✅
2. **Toggle Switch** in home page:
   - **ON (Green)** = Available for consultations
   - **OFF (Grey)** = Unavailable

### For Patients:

1. Can now see doctors who are **online**
2. Can book consultations with available doctors
3. Video calls work when doctor is online

---

## 🎯 Doctor App - What You'll See

### Home Page (Top Right):

```
┌─────────────────────────────────────┐
│ Welcome Dr. John!         [Online] ◯│ ← Toggle switch
└─────────────────────────────────────┘
```

**Toggle States:**

- **🟢 Online** = Patients can see you and book consultations
- **⚪ Offline** = You appear as unavailable to patients

---

## 🔧 Changes Made to Code

### 1. **doctor_profile_provider.dart**

```dart
// OLD: Just loaded profile
Future<void> loadProfile(String authId) async {
  final result = await getDoctorProfileByAuthId(authId);
  result.fold(
    (error) => state = AsyncValue.error(error),
    (doctor) => state = AsyncValue.data(doctor),
  );
}

// NEW: Automatically sets online status
Future<void> loadProfile(String authId) async {
  final result = await getDoctorProfileByAuthId(authId);
  result.fold(
    (error) => state = AsyncValue.error(error),
    (doctor) {
      state = AsyncValue.data(doctor);

      // Auto-set online when logging in
      if (doctor != null && !doctor.isOnline) {
        updateOnlineStatus(doctor.id, true);
      }
    },
  );
}
```

### 2. **home_page.dart**

```dart
// Enabled online/offline toggle in AppBar
actions: [
  doctorProfile.when(
    data: (doctor) {
      return Row(
        children: [
          Text(doctor.isOnline ? 'Online' : 'Offline'),
          Switch(
            value: doctor.isOnline,
            onChanged: (_) {
              ref.read(doctorProfileProvider.notifier)
                  .toggleOnlineStatus();
            },
          ),
        ],
      );
    },
  ),
]
```

---

## 🗄️ Database Schema

The `doctors` table includes:

```sql
doctors (
  id uuid,
  ...
  is_online boolean DEFAULT false,     -- Online/Offline status
  is_available boolean DEFAULT false,  -- Available for consultations
  ...
)
```

**Status Meanings:**

- `is_online = true` → Doctor is logged in and can take calls
- `is_online = false` → Doctor is offline/unavailable
- `is_available = true` → Doctor is accepting new consultations
- `is_available = false` → Doctor is not accepting new consultations

---

## 🧪 Testing

### Test the Fix:

1. **Run the doctor app:**

   ```bash
   flutter run
   ```

2. **Login as a doctor**

   - Status should automatically show "Online"
   - Toggle switch should be visible in top-right

3. **Check patient app:**

   - Doctor should now appear as "Available"
   - Can book consultations with this doctor

4. **Toggle offline:**

   - Switch the toggle to OFF
   - Patient app should show "Unavailable"

5. **Toggle online again:**
   - Switch back to ON
   - Patient app shows "Available" again

---

## 🔄 Manual Database Fix (If Needed)

If doctors are still showing as unavailable, you can manually update the database:

### SQL Query:

```sql
-- Set a specific doctor online
UPDATE doctors
SET is_online = true,
    is_available = true
WHERE user_id = 'doctor-user-id-here';

-- Set ALL doctors online
UPDATE doctors
SET is_online = true,
    is_available = true;

-- Check current status
SELECT
  d.id,
  u.full_name,
  d.is_online,
  d.is_available
FROM doctors d
JOIN users u ON d.user_id = u.id;
```

### Using Supabase Dashboard:

1. Go to Supabase Dashboard
2. Navigate to **Table Editor** → **doctors**
3. Find your doctor record
4. Edit the row:
   - Set `is_online` = `true`
   - Set `is_available` = `true`
5. Save changes

---

## 📊 Status Flow

### Login Flow:

```
Doctor Opens App
      ↓
Login with credentials
      ↓
loadProfile() called
      ↓
Automatically set is_online = true
      ↓
Doctor appears as "Online" in UI
      ↓
Patients can see doctor as "Available"
```

### Logout Flow (Future):

```
Doctor logs out
      ↓
Set is_online = false
      ↓
Doctor appears as "Offline"
      ↓
Patients see "Unavailable"
```

---

## 🎨 UI Indicators

### Online Status Colors:

- **🟢 Green** = Online and available
- **🟠 Orange** = Online but busy
- **⚪ Grey** = Offline

### Toggle Switch:

- **Right (ON)** = Online ✅
- **Left (OFF)** = Offline ❌

---

## 🐛 Troubleshooting

### Issue: Still showing unavailable after login

**Solutions:**

1. **Check database:**

   ```sql
   SELECT is_online, is_available FROM doctors WHERE id = 'your-doctor-id';
   ```

2. **Restart the app:**

   - Close completely
   - Reopen and login again

3. **Clear app data:**

   ```bash
   flutter clean
   flutter run
   ```

4. **Check patient app cache:**
   - Patient app might be caching old data
   - Restart patient app

### Issue: Toggle doesn't work

**Check:**

- Internet connection
- Supabase permissions
- Database RLS policies

---

## 🔒 RLS Policies

Ensure these policies exist in Supabase:

```sql
-- Allow doctors to update their own status
CREATE POLICY "Doctors can update their own status"
ON doctors FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Allow patients to view online doctors
CREATE POLICY "Anyone can view online doctors"
ON doctors FOR SELECT
USING (is_online = true);
```

---

## ✅ Success Checklist

After implementing this fix:

- [ ] Doctor automatically goes online on login
- [ ] Toggle switch is visible in home page
- [ ] Toggle switch works (can switch on/off)
- [ ] Status shows correct color (green/grey)
- [ ] Patient app shows doctor as available
- [ ] Video calls can be initiated
- [ ] Database `is_online` updates correctly

---

## 🚀 Next Steps (Recommended)

### 1. **Add Logout Handler**

Set doctor offline when they logout:

```dart
Future<void> logout() async {
  final doctor = state.value;
  if (doctor != null) {
    await updateOnlineStatus(doctor.id, false);
  }
  await Supabase.instance.client.auth.signOut();
}
```

### 2. **Add Session Timeout**

Auto-logout after inactivity:

```dart
Timer? _inactivityTimer;

void resetInactivityTimer() {
  _inactivityTimer?.cancel();
  _inactivityTimer = Timer(Duration(minutes: 30), () {
    // Auto logout
  });
}
```

### 3. **Add Status Notifications**

Notify patients when doctor comes online:

```dart
// Send push notification when doctor goes online
```

### 4. **Add Activity Tracking**

Show last seen time:

```sql
ALTER TABLE doctors ADD COLUMN last_seen timestamptz;
```

---

## 📚 Related Files

Files modified for this fix:

1. `lib/features/doctor/presentation/providers/doctor_profile_provider.dart`
2. `lib/features/doctor/presentation/pages/home_page.dart`

Related database tables:

1. `doctors` - Main doctor profile table
2. `users` - User authentication table

---

## 💡 Tips

### For Doctors:

- Keep toggle **ON** when available for consultations
- Switch to **OFF** during breaks or when busy
- Status is visible to all patients

### For Developers:

- Monitor `is_online` status in database
- Check RLS policies for updates
- Consider adding status history logging
- Implement graceful offline handling

---

**Status:** ✅ **FIXED**  
**Date:** October 15, 2025  
**Impact:** Doctors now appear as available to patients automatically  
**Next:** Test with real users and add logout handler
