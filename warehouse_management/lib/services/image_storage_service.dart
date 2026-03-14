import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wavezly/config/supabase_config.dart';

class ImageStorageService {
  final _supabase = SupabaseConfig.client;
  static const String _productBucketName = 'product-images';
  static const String _profileBucketName = 'profile-images';
  static const int _maxFileSizeBytes = 5 * 1024 * 1024; // 5MB

  /// Uploads an image to Supabase Storage
  /// Returns the public URL of the uploaded image
  /// Throws exceptions on validation or upload failures
  Future<String> uploadProductImage(File imageFile) async {
    try {
      return _uploadImage(
        imageFile: imageFile,
        bucketName: _productBucketName,
        prefix: 'product',
      );
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Uploads a profile image to Supabase Storage.
  Future<String> uploadProfileImage(File imageFile) async {
    try {
      return _uploadImage(
        imageFile: imageFile,
        bucketName: _profileBucketName,
        prefix: 'profile',
      );
    } catch (e) {
      throw Exception('Failed to upload profile image: $e');
    }
  }

  /// Deletes an image from Supabase Storage
  /// Accepts either full URL or storage path
  Future<void> deleteProductImage(String imageUrlOrPath) async {
    try {
      if (imageUrlOrPath.isEmpty) return;

      final filePath = _extractFilePath(
        imageUrlOrPath: imageUrlOrPath,
        bucketName: _productBucketName,
      );

      await _supabase.storage.from(_productBucketName).remove([filePath]);
    } catch (e) {
      // Log error but don't throw - deletion failure shouldn't block operations
      print('Failed to delete image: $e');
    }
  }

  /// Deletes a profile image from Supabase Storage.
  Future<void> deleteProfileImage(String imageUrlOrPath) async {
    try {
      if (imageUrlOrPath.isEmpty) return;

      final filePath = _extractFilePath(
        imageUrlOrPath: imageUrlOrPath,
        bucketName: _profileBucketName,
      );

      await _supabase.storage.from(_profileBucketName).remove([filePath]);
    } catch (e) {
      print('Failed to delete profile image: $e');
    }
  }

  /// Replaces an existing image with a new one
  /// Deletes old image and uploads new one
  Future<String> replaceProductImage({
    required File newImageFile,
    String? oldImageUrl,
  }) async {
    try {
      // Upload new image first
      final newImageUrl = await uploadProductImage(newImageFile);

      // Delete old image if exists (non-blocking)
      if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
        deleteProductImage(oldImageUrl).catchError((error) {
          print('Warning: Could not delete old image: $error');
        });
      }

      return newImageUrl;
    } catch (e) {
      throw Exception('Failed to replace image: $e');
    }
  }

  /// Replaces an existing profile image with a new one.
  Future<String> replaceProfileImage({
    required File newImageFile,
    String? oldImageUrl,
  }) async {
    try {
      final newImageUrl = await uploadProfileImage(newImageFile);

      if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
        deleteProfileImage(oldImageUrl).catchError((error) {
          print('Warning: Could not delete old profile image: $error');
        });
      }

      return newImageUrl;
    } catch (e) {
      throw Exception('Failed to replace profile image: $e');
    }
  }

  Future<String> _uploadImage({
    required File imageFile,
    required String bucketName,
    required String prefix,
  }) async {
    await _validateImageFile(imageFile);

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final extension = path.extension(imageFile.path).toLowerCase();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '${prefix}_${timestamp}_${_generateUuid()}$extension';
    final filePath = '$userId/$fileName';

    await _supabase.storage.from(bucketName).upload(
          filePath,
          imageFile,
          fileOptions: const FileOptions(
            cacheControl: '3600',
            upsert: false,
          ),
        );

    return _supabase.storage.from(bucketName).getPublicUrl(filePath);
  }

  Future<void> _validateImageFile(File imageFile) async {
    final fileSize = await imageFile.length();
    if (fileSize > _maxFileSizeBytes) {
      throw Exception('Image size exceeds 5MB limit');
    }

    final extension = path.extension(imageFile.path).toLowerCase();
    final allowedExtensions = ['.jpg', '.jpeg', '.png', '.webp'];
    if (!allowedExtensions.contains(extension)) {
      throw Exception('Invalid file format. Use JPG, PNG, or WebP');
    }
  }

  String _extractFilePath({
    required String imageUrlOrPath,
    required String bucketName,
  }) {
    if (!imageUrlOrPath.contains('$bucketName/')) {
      return imageUrlOrPath;
    }

    final parts = imageUrlOrPath.split('$bucketName/');
    if (parts.length <= 1) {
      return imageUrlOrPath;
    }

    return parts[1].split('?')[0];
  }

  /// Simple UUID generator (sufficient for file naming)
  String _generateUuid() {
    final timestamp = DateTime.now().microsecondsSinceEpoch.toString();
    final random = (DateTime.now().millisecondsSinceEpoch % 10000).toString();
    return '$timestamp$random';
  }

  /// Validates if a file is within size limits without uploading
  Future<bool> validateFileSize(File file) async {
    final size = await file.length();
    return size <= _maxFileSizeBytes;
  }

  /// Gets formatted file size for display
  static String getFileSizeString(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
