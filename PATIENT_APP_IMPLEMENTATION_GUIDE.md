# 📸 Add Profile Image Upload to Patient App (DocSync)

## Overview

This guide will help you add the same profile image upload feature from the Doctor app to the Patient app.

---

## 📋 Files to Create/Modify

### 1. Create Image Upload Service

**File:** `lib/core/services/image_upload_service.dart`

```dart
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Service for uploading profile images to Supabase Storage
class ImageUploadService {
  final SupabaseClient _supabase;
  final ImagePicker _imagePicker = ImagePicker();
  static const String bucketName = 'profile-images';

  ImageUploadService(this._supabase);

  /// Pick image from gallery
  Future<XFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      debugPrint('Error picking image from gallery: $e');
      rethrow;
    }
  }

  /// Pick image from camera
  Future<XFile?> pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      debugPrint('Error picking image from camera: $e');
      rethrow;
    }
  }

  /// Upload image to Supabase Storage
  /// Returns the public URL of the uploaded image
  Future<String> uploadProfileImage(XFile imageFile, String userId) async {
    try {
      // Debug logging
      final currentUser = _supabase.auth.currentUser;
      debugPrint('🔐 Current user: ${currentUser?.id}');
      debugPrint('📁 Uploading for userId: $userId');
      debugPrint('🪣 Bucket: $bucketName');

      // Generate unique filename
      final fileExtension = imageFile.path.split('.').last;
      final fileName = '${userId}_${const Uuid().v4()}.$fileExtension';
      final filePath = 'profiles/$fileName';

      debugPrint('📂 File path: $filePath');

      // Read file bytes
      final bytes = await imageFile.readAsBytes();
      debugPrint('📊 File size: ${bytes.length} bytes');

      // Upload to Supabase Storage
      debugPrint('⬆️ Starting upload...');
      await _supabase.storage
          .from(bucketName)
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(
              contentType: 'image/$fileExtension',
              upsert: false,
            ),
          );

      debugPrint('✅ Upload successful!');

      // Get public URL
      final publicUrl = _supabase.storage
          .from(bucketName)
          .getPublicUrl(filePath);

      debugPrint('🔗 Public URL: $publicUrl');

      return publicUrl;
    } catch (e) {
      debugPrint('❌ Error uploading image: $e');
      debugPrint('🔍 Error type: ${e.runtimeType}');
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Delete image from Supabase Storage
  Future<void> deleteProfileImage(String imageUrl) async {
    try {
      // Extract file path from URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;

      // Find the path after the bucket name
      final bucketIndex = pathSegments.indexOf(bucketName);
      if (bucketIndex == -1) {
        throw Exception('Invalid image URL');
      }

      final filePath = pathSegments.sublist(bucketIndex + 1).join('/');

      // Delete from storage
      await _supabase.storage.from(bucketName).remove([filePath]);
      debugPrint('🗑️ Deleted old image: $filePath');
    } catch (e) {
      debugPrint('Error deleting image: $e');
      // Don't throw error on delete failure - log it instead
    }
  }
}
```

---

### 2. Update Profile Page (Edit Profile)

**File:** `lib/features/profile/presentation/pages/edit_profile_page.dart` (or similar)

**Add imports:**

```dart
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/services/image_upload_service.dart';
```

**Add state variables:**

```dart
class _EditProfilePageState extends State<EditProfilePage> {
  // Existing variables...

  // Image upload
  XFile? _selectedImage;
  String? _currentProfilePictureUrl;
  late ImageUploadService _imageUploadService;
  bool _isUploadingImage = false;

  // ... rest of your state
}
```

**Initialize in initState:**

```dart
@override
void initState() {
  super.initState();

  // Initialize image upload service
  _imageUploadService = ImageUploadService(Supabase.instance.client);

  // Load existing profile picture
  // Adjust this based on your user data structure
  _currentProfilePictureUrl = widget.user?.profilePictureUrl;

  // ... rest of your init code
}
```

**Add image picker method:**

```dart
Future<void> _pickImage() async {
  showModalBottomSheet(
    context: context,
    builder: (context) => SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Choose from Gallery'),
            onTap: () async {
              Navigator.pop(context);
              final image = await _imageUploadService.pickImageFromGallery();
              if (image != null) {
                setState(() => _selectedImage = image);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Take Photo'),
            onTap: () async {
              Navigator.pop(context);
              final image = await _imageUploadService.pickImageFromCamera();
              if (image != null) {
                setState(() => _selectedImage = image);
              }
            },
          ),
        ],
      ),
    ),
  );
}
```

**Update save profile method:**

```dart
Future<void> _saveProfile() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);

  try {
    String? uploadedImageUrl;

    // Upload profile image if selected
    if (_selectedImage != null) {
      setState(() => _isUploadingImage = true);
      try {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId != null) {
          uploadedImageUrl = await _imageUploadService.uploadProfileImage(
            _selectedImage!,
            userId,
          );

          // Delete old image if exists
          if (_currentProfilePictureUrl != null &&
              _currentProfilePictureUrl!.isNotEmpty) {
            await _imageUploadService.deleteProfileImage(
              _currentProfilePictureUrl!,
            );
          }
        }
      } catch (e) {
        print('Error uploading image: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Image upload failed: ${e.toString()}')),
          );
        }
      } finally {
        setState(() => _isUploadingImage = false);
      }
    }

    // Update user profile with new image URL
    final updatedData = {
      'full_name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      // Add other fields...
      if (uploadedImageUrl != null) 'profile_picture_url': uploadedImageUrl,
    };

    await Supabase.instance.client
        .from('users')
        .update(updatedData)
        .eq('id', Supabase.instance.client.auth.currentUser!.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
      Navigator.pop(context);
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}
```

**Add profile picture UI:**

```dart
// In your build method
Center(
  child: Stack(
    children: [
      GestureDetector(
        onTap: _pickImage,
        child: CircleAvatar(
          radius: 60,
          backgroundColor: Colors.grey[300],
          backgroundImage: _selectedImage != null
              ? FileImage(File(_selectedImage!.path))
              : (_currentProfilePictureUrl != null &&
                      _currentProfilePictureUrl!.isNotEmpty
                  ? CachedNetworkImageProvider(_currentProfilePictureUrl!)
                  : null),
          child: _selectedImage == null &&
                  (_currentProfilePictureUrl == null ||
                      _currentProfilePictureUrl!.isEmpty)
              ? Icon(Icons.person, size: 60, color: Colors.grey[600])
              : null,
        ),
      ),
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(8),
          child: Icon(
            Icons.camera_alt,
            size: 20,
            color: Colors.white,
          ),
        ),
      ),
      if (_isUploadingImage)
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
        ),
    ],
  ),
),
const SizedBox(height: 16),
Text(
  'Tap to change photo',
  style: TextStyle(color: Colors.grey[600]),
),
```

---

### 3. Update Profile View Page

**File:** `lib/features/profile/presentation/pages/profile_page.dart`

**Add import:**

```dart
import 'package:cached_network_image/cached_network_image.dart';
```

**Update CircleAvatar:**

```dart
CircleAvatar(
  radius: 50,
  backgroundColor: Colors.grey[300],
  backgroundImage: user.profilePictureUrl != null &&
          user.profilePictureUrl!.isNotEmpty
      ? CachedNetworkImageProvider(user.profilePictureUrl!)
      : null,
  child: user.profilePictureUrl == null || user.profilePictureUrl!.isEmpty
      ? Text(
          user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        )
      : null,
),
```

---

### 4. Update pubspec.yaml

**File:** `pubspec.yaml`

Make sure these packages are added:

```yaml
dependencies:
  image_picker: ^1.0.7
  cached_network_image: ^3.3.1
  uuid: ^4.3.3
```

Run:

```bash
flutter pub get
```

---

### 5. Supabase Setup (IMPORTANT!)

**Create the same SQL file for patient app's Supabase project:**

Copy the `RUN_THIS_IN_SUPABASE.sql` file and run it in your **patient app's Supabase project** (if it's a different project).

If both apps use the **same Supabase project**, you only need to run the SQL once.

---

## 🔧 Supabase Database Update

Make sure your `users` table has a `profile_picture_url` column:

```sql
-- Add column if it doesn't exist
ALTER TABLE users
ADD COLUMN IF NOT EXISTS profile_picture_url TEXT;
```

---

## ✅ Testing Checklist

### 1. Supabase Setup

- [ ] Run `RUN_THIS_IN_SUPABASE.sql` in Supabase SQL Editor
- [ ] Verify `profile-images` bucket exists and is public
- [ ] Verify 4 RLS policies exist
- [ ] Verify `users` table has `profile_picture_url` column

### 2. Code Implementation

- [ ] Create `image_upload_service.dart`
- [ ] Update edit profile page with image picker
- [ ] Update profile view page to display image
- [ ] Add required imports
- [ ] Add packages to pubspec.yaml

### 3. Test Flow

- [ ] Open edit profile page
- [ ] Tap profile picture
- [ ] Select image from gallery or camera
- [ ] See image preview
- [ ] Save profile
- [ ] Check logs for 🔐 📁 🪣 emojis
- [ ] Verify upload successful (✅ in logs)
- [ ] Go back to profile page
- [ ] See uploaded image displayed
- [ ] Hot restart app
- [ ] Image should still be there

---

## 🐛 Troubleshooting

### Issue: 403 Unauthorized Error

**Fix:** Run the SQL in Supabase (see `RUN_THIS_IN_SUPABASE.sql`)

### Issue: Image not showing

**Fix:**

- Check if URL is saved in database
- Verify bucket is public
- Check network connection

### Issue: Can't select image

**Fix:**

- Check camera/storage permissions in AndroidManifest.xml
- Check Info.plist for iOS

---

## 📱 Platform-Specific Setup

### Android

**File:** `android/app/src/main/AndroidManifest.xml`

Add permissions:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

### iOS

**File:** `ios/Runner/Info.plist`

Add:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to your photo library to upload profile pictures</string>
<key>NSCameraUsageDescription</key>
<string>We need access to your camera to take profile pictures</string>
```

---

## 🎯 Summary

This implementation will give your patient app the same profile image upload functionality as the doctor app, including:

- ✅ Image selection from gallery or camera
- ✅ Image preview before upload
- ✅ Automatic upload to Supabase Storage
- ✅ Delete old images when updating
- ✅ Display profile pictures throughout the app
- ✅ Cached loading for better performance
- ✅ Detailed logging for debugging

Follow the steps in order, test after each major change, and refer to the doctor app code as a reference!
