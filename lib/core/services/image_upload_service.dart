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
    } catch (e) {
      debugPrint('Error deleting image: $e');
      // Don't throw error on delete failure - log it instead
    }
  }

  /// Show image source selection dialog
  Future<XFile?> showImageSourceDialog() async {
    // This will be called from the UI layer with showModalBottomSheet
    // Just a placeholder for now
    throw UnimplementedError('Use showImageSourceDialog from UI');
  }
}
