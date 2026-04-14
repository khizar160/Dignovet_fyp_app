import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase Payment Storage Service
/// 
/// This service handles uploading payment screenshots to Supabase Storage.
/// 
/// Storage Structure:
/// - Supabase Storage Bucket: "Payment" 
///   (Files stored here: payment_userId_appointmentId_timestamp.jpg)
/// 
/// The screenshot URL is then stored in:
/// 1. Firestore "appointments" collection -> paymentScreenshotUrl field
/// 2. Firestore "payments" collection -> paymentScreenshotUrl field
/// 
/// This allows admins to access screenshots from appointment details
/// and maintain complete payment records.
class SupabasePaymentStorage {
  final SupabaseClient _client = Supabase.instance.client;

  /// Upload Payment Screenshot to Supabase Storage
  Future<String?> uploadPaymentScreenshot({
    required File file,
    required String userId,
    required String appointmentId,
  }) async {
    try {
      // Check if file exists
      if (!await file.exists()) {
        print('❌ File does not exist: ${file.path}');
        throw Exception('Selected file does not exist. Please try selecting the image again.');
      }

      // Check file size
      final fileSize = await file.length();
      print('📤 File size: ${(fileSize / 1024).toStringAsFixed(2)} KB');
      
      if (fileSize == 0) {
        print('❌ File is empty');
        throw Exception('Selected file is empty. Please select a valid image.');
      }

      // Check if file size is too large (10MB limit)
      if (fileSize > 10 * 1024 * 1024) {
        print('❌ File too large: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');
        throw Exception('File is too large. Please select an image smaller than 10MB.');
      }

      final fileName =
          'payment_${userId}_${appointmentId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      print('📤 Uploading to Supabase...');
      print('   Bucket: Payment');
      print('   File: $fileName');
      print('   Path: ${file.path}');

      // Upload to Supabase 'Payment' bucket
      final uploadResponse = await _client.storage.from('Payment').upload(
            fileName,
            file,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );

      print('✅ Upload response: $uploadResponse');

      // Try to get public URL first (if bucket is public)
      String publicUrl = _client.storage.from('Payment').getPublicUrl(fileName);

      // If bucket is not public, this will still return a URL but it won't be accessible
      // So we also create a signed URL that works for private buckets (valid for 1 year)
      try {
        final signedUrl = await _client.storage
            .from('Payment')
            .createSignedUrl(fileName, 31536000); // 1 year expiry
        
        print('✅ Generated signed URL: $signedUrl');
        publicUrl = signedUrl;
      } catch (e) {
        print('⚠️ Could not create signed URL, using public URL: $e');
        // If signed URL fails, fall back to public URL
      }

      if (publicUrl.isEmpty) {
        print('❌ URL is empty');
        throw Exception('Failed to get URL for uploaded file');
      }

      print('✅ Payment screenshot uploaded to Supabase Payment bucket');
      print('   URL: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('❌ Error uploading payment screenshot to Supabase: $e');
      print('   Error type: ${e.runtimeType}');
      print('   Error details: ${e.toString()}');
      rethrow; // Re-throw to get detailed error in UI
    }
  }

  /// Upload Payment Receipt/Document
  Future<String?> uploadPaymentDocument({
    required File file,
    required String userId,
    required String documentName,
  }) async {
    try {
      final fileName =
          'receipt_${userId}_${DateTime.now().millisecondsSinceEpoch}_$documentName';

      await _client.storage.from('Payment').upload(
            fileName,
            file,
            fileOptions: const FileOptions(upsert: true),
          );

      final publicUrl = _client.storage.from('Payment').getPublicUrl(fileName);

      print('✅ Payment document uploaded to Supabase: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('❌ Error uploading payment document to Supabase: $e');
      return null;
    }
  }

  /// Delete Payment Screenshot (if needed for refund cleanup)
  Future<bool> deletePaymentScreenshot(String fileName) async {
    try {
      await _client.storage.from('Payment').remove([fileName]);
      print('✅ Payment screenshot deleted from Supabase: $fileName');
      return true;
    } catch (e) {
      print('❌ Error deleting payment screenshot: $e');
      return false;
    }
  }

  /// Get all payment screenshots for a user (for history)
  Future<List<FileObject>> getUserPaymentScreenshots(String userId) async {
    try {
      final files = await _client.storage.from('Payment').list(
            path: '',
            searchOptions: const SearchOptions(
              sortBy: SortBy(column: 'created_at', order: 'desc'),
            ),
          );

      // Filter files that belong to this user
      final userFiles = files.where((file) => file.name.contains(userId)).toList();

      print('✅ Found ${userFiles.length} payment screenshots for user $userId');
      return userFiles;
    } catch (e) {
      print('❌ Error getting user payment screenshots: $e');
      return [];
    }
  }

  /// Get signed URL for existing payment screenshot
  /// Use this to display images from Supabase storage
  /// Returns a signed URL valid for 1 year
  Future<String?> getSignedUrlForImage(String imageUrl) async {
    try {
      // Extract filename from URL
      // URL format: https://xxx.supabase.co/storage/v1/object/public/Payment/filename.jpg
      // or: https://xxx.supabase.co/storage/v1/object/sign/Payment/filename.jpg?token=xxx
      
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      
      // Find 'Payment' bucket in path and get filename after it
      int bucketIndex = pathSegments.indexOf('Payment');
      if (bucketIndex == -1) {
        print('❌ Could not find Payment bucket in URL: $imageUrl');
        return imageUrl; // Return original URL as fallback
      }
      
      final fileName = pathSegments.sublist(bucketIndex + 1).join('/');
      print('📎 Extracted filename: $fileName');
      
      // Create signed URL valid for 1 year
      final signedUrl = await _client.storage
          .from('Payment')
          .createSignedUrl(fileName, 31536000);
      
      print('✅ Generated signed URL for display');
      return signedUrl;
    } catch (e) {
      print('❌ Error creating signed URL: $e');
      print('   Returning original URL as fallback');
      return imageUrl; // Return original URL as fallback
    }
  }

  /// Check if Supabase storage is accessible
  Future<bool> checkStorageAccess() async {
    try {
      await _client.storage.from('Payment').list(path: '', searchOptions: const SearchOptions(limit: 1));
      print('✅ Supabase storage is accessible');
      return true;
    } catch (e) {
      print('❌ Supabase storage access error: $e');
      return false;
    }
  }
}
