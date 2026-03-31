import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

/// Handles ALL Firebase Storage operations for VenueMate.
///
/// Storage bucket structure:
///   users/avatars/{uid}.jpg
///   halls/{hallId}/images/{uuid}.jpg
///   halls/{hallId}/documents/{uuid}.pdf
///   payments/{bookingId}/receipt_{uuid}.jpg
class StorageService {
  static final _storage = FirebaseStorage.instance;
  static const _uuid = Uuid();

  // ════════════════════════════════════════════════════════════════════════════
  //  USER PROFILE IMAGE
  // ════════════════════════════════════════════════════════════════════════════

  /// Upload a profile picture to `users/avatars/{uid}.jpg`.
  /// Always overwrites the existing file for the same user.
  /// Returns the public download URL, or null on failure.
  static Future<String?> uploadProfileImage({
    required String uid,
    required File imageFile,
  }) async {
    try {
      final ref = _storage.ref().child('users/avatars/$uid.jpg');
      await ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  HALL IMAGES (multiple photos per hall)
  // ════════════════════════════════════════════════════════════════════════════

  /// Upload a single hall image.
  /// Path: `halls/{hallId}/images/{uuid}.jpg`
  /// Returns the download URL, or null on failure.
  static Future<String?> uploadHallImage({
    required String hallId,
    required File imageFile,
  }) async {
    try {
      final String fileName = '${_uuid.v4()}.jpg';
      final ref = _storage.ref().child('halls/$hallId/images/$fileName');
      await ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  /// Upload multiple hall images at once (used in HallRegistration step 3).
  /// Returns a list of download URLs. Skips any file that fails.
  static Future<List<String>> uploadMultipleHallImages({
    required String hallId,
    required List<File> imageFiles,
  }) async {
    final List<String> urls = [];
    for (final file in imageFiles) {
      final url = await uploadHallImage(hallId: hallId, imageFile: file);
      if (url != null) urls.add(url);
    }
    return urls;
  }

  /// Delete a specific hall image by its download URL.
  static Future<void> deleteHallImage(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } catch (e) {
      // Silently fail — image may already be deleted
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  HALL DOCUMENTS (CNIC, ownership proof — for HallRegistration step 3)
  // ════════════════════════════════════════════════════════════════════════════

  /// Upload a hall document (PDF or image).
  /// Path: `halls/{hallId}/documents/{docType}_{uuid}.{ext}`
  /// Returns the download URL, or null on failure.
  static Future<String?> uploadHallDocument({
    required String hallId,
    required File documentFile,
    required String docType, // e.g. 'cnic', 'ownership_proof'
  }) async {
    try {
      final String ext = documentFile.path.split('.').last;
      final String fileName = '${docType}_${_uuid.v4()}.$ext';
      final ref = _storage.ref().child('halls/$hallId/documents/$fileName');

      final String contentType =
          ext.toLowerCase() == 'pdf' ? 'application/pdf' : 'image/jpeg';

      await ref.putFile(
        documentFile,
        SettableMetadata(contentType: contentType),
      );
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  PAYMENT RECEIPTS
  // ════════════════════════════════════════════════════════════════════════════

  /// Upload the customer's 25% advance payment receipt.
  /// Path: `payments/{bookingId}/receipt_{uuid}.jpg`
  /// Returns the download URL, or null on failure.
  static Future<String?> uploadPaymentReceipt({
    required String bookingId,
    required File receiptFile,
  }) async {
    try {
      final String fileName = 'receipt_${_uuid.v4()}.jpg';
      final ref =
          _storage.ref().child('payments/$bookingId/$fileName');
      await ref.putFile(
        receiptFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  IMAGE PICKER HELPERS
  // ════════════════════════════════════════════════════════════════════════════

  /// Opens the gallery and returns the picked file, or null if cancelled.
  static Future<File?> pickImageFromGallery() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1800,
      maxHeight: 1800,
      imageQuality: 85,
    );
    if (picked == null) return null;
    return File(picked.path);
  }

  /// Opens the camera and returns the captured file, or null if cancelled.
  static Future<File?> pickImageFromCamera() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1800,
      maxHeight: 1800,
      imageQuality: 85,
    );
    if (picked == null) return null;
    return File(picked.path);
  }

  /// Pick multiple images from the gallery (for hall photo upload).
  static Future<List<File>> pickMultipleImages() async {
    final picker = ImagePicker();
    final List<XFile> picked = await picker.pickMultiImage(
      maxWidth: 1800,
      maxHeight: 1800,
      imageQuality: 85,
    );
    return picked.map((xf) => File(xf.path)).toList();
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  UPLOAD WITH PROGRESS (optional — for showing progress bar)
  // ════════════════════════════════════════════════════════════════════════════

  /// Upload a file and report progress via [onProgress] callback (0.0–1.0).
  /// Returns the download URL, or null on failure.
  static Future<String?> uploadWithProgress({
    required String storagePath,
    required File file,
    required String contentType,
    Function(double progress)? onProgress,
  }) async {
    try {
      final ref = _storage.ref().child(storagePath);
      final UploadTask task = ref.putFile(
        file,
        SettableMetadata(contentType: contentType),
      );

      // Listen to progress events
      task.snapshotEvents.listen((TaskSnapshot snapshot) {
        if (onProgress != null && snapshot.totalBytes > 0) {
          final double progress =
              snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        }
      });

      final TaskSnapshot result = await task;
      return await result.ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }
}
