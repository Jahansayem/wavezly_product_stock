import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class ImageStorageService {
  final _supabase = SupabaseConfig.client;
  static const String _bucketName = 'product-images';
  static const int _maxFileSizeBytes = 5 * 1024 * 1024; // 5MB

  /// Uploads an image to Supabase Storage
  /// Returns the public URL of the uploaded image
  /// Throws exceptions on validation or upload failures
  Future<String> uploadProductImage(File imageFile) async {
    try {
      // Validate file size
      final fileSize = await imageFile.length();
      if (fileSize > _maxFileSizeBytes) {
        throw Exception('Image size exceeds 5MB limit');
      }

      // Validate file format
      final extension = path.extension(imageFile.path).toLowerCase();
      final allowedExtensions = ['.jpg', '.jpeg', '.png', '.webp'];
      if (!allowedExtensions.contains(extension)) {
        throw Exception('Invalid file format. Use JPG, PNG, or WebP');
      }

      // Get current user ID
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Generate unique filename with UUID
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'product_${timestamp}_${_generateUuid()}$extension';
      final filePath = '$userId/$fileName';

      // Upload to Supabase Storage
      await _supabase.storage
          .from(_bucketName)
          .upload(
            filePath,
            imageFile,
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );

      // Get public URL
      final publicUrl = _supabase.storage
          .from(_bucketName)
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Deletes an image from Supabase Storage
  /// Accepts either full URL or storage path
  Future<void> deleteProductImage(String imageUrlOrPath) async {
    try {
      if (imageUrlOrPath.isEmpty) return;

      // Extract file path from URL if needed
      String filePath = imageUrlOrPath;
      if (imageUrlOrPath.contains('product-images/')) {
        final parts = imageUrlOrPath.split('product-images/');
        if (parts.length > 1) {
          filePath = parts[1].split('?')[0]; // Remove query params if present
        }
      }

      // Delete from storage
      await _supabase.storage
          .from(_bucketName)
          .remove([filePath]);
    } catch (e) {
      // Log error but don't throw - deletion failure shouldn't block operations
      print('Failed to delete image: $e');
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
