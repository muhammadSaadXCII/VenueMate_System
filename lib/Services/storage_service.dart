import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

/// Handles ALL Firebase Storage operations for VenueMate.
///
/// Web-safe upload pattern: use putData(bytes) instead of putFile()
/// so the same code works on Flutter Web, Android, and iOS.
class StorageService {
  static final _storage = FirebaseStorage.instance;
  static const _uuid = Uuid();

  // ════════════════════════════════════════════════════════════════════════════
  //  USER PROFILE IMAGE
  // ════════════════════════════════════════════════════════════════════════════

  static Future<String?> uploadProfileImage({
    required String uid,
    required File imageFile,
  }) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final ref = _storage.ref().child('users/avatars/$uid.jpg');
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  /// Web-safe variant: upload profile image from XFile (works on all platforms).
  static Future<String?> uploadProfileImageXFile({
    required String uid,
    required XFile xFile,
  }) async {
    try {
      final bytes = await xFile.readAsBytes();
      final ref = _storage.ref().child('users/avatars/$uid.jpg');
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  HALL IMAGES
  // ════════════════════════════════════════════════════════════════════════════

  static Future<String?> uploadHallImage({
    required String hallId,
    required File imageFile,
  }) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final String fileName = '${_uuid.v4()}.jpg';
      final ref = _storage.ref().child('halls/$hallId/images/$fileName');
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  /// Web-safe: upload a single hall image from XFile.
  static Future<String?> uploadHallImageXFile({
    required String hallId,
    required XFile xFile,
  }) async {
    try {
      final bytes = await xFile.readAsBytes();
      final String fileName = '${_uuid.v4()}.jpg';
      final ref = _storage.ref().child('halls/$hallId/images/$fileName');
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      return await ref.getDownloadURL();
    } catch (e) {
      print('❌ uploadHallImageXFile error: $e');
      return null;
    }
  }

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

  /// Web-safe: upload multiple hall images from XFile list.
  static Future<List<String>> uploadMultipleHallImagesXFile({
    required String hallId,
    required List<XFile> xFiles,
  }) async {
    final List<String> urls = [];
    for (final xf in xFiles) {
      final url = await uploadHallImageXFile(hallId: hallId, xFile: xf);
      if (url != null) urls.add(url);
    }
    return urls;
  }

  static Future<void> deleteHallImage(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } catch (e) {
      // Silently fail
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  HALL DOCUMENTS
  // ════════════════════════════════════════════════════════════════════════════

  static Future<String?> uploadHallDocument({
    required String hallId,
    required File documentFile,
    required String docType,
  }) async {
    try {
      final bytes = await documentFile.readAsBytes();
      final String ext = documentFile.path.split('.').last.toLowerCase();
      final String fileName = '${docType}_${_uuid.v4()}.$ext';
      final ref = _storage.ref().child('halls/$hallId/documents/$fileName');
      final contentType = ext == 'pdf' ? 'application/pdf' : 'image/jpeg';
      await ref.putData(bytes, SettableMetadata(contentType: contentType));
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  /// Web-safe: upload a hall document from XFile.
  static Future<String?> uploadHallDocumentXFile({
    required String hallId,
    required XFile xFile,
    required String docType,
  }) async {
    try {
      final bytes = await xFile.readAsBytes();
      final String ext = xFile.name.split('.').last.toLowerCase();
      final String fileName = '${docType}_${_uuid.v4()}.$ext';
      final ref = _storage.ref().child('halls/$hallId/documents/$fileName');
      final contentType = ext == 'pdf' ? 'application/pdf' : 'image/jpeg';
      await ref.putData(bytes, SettableMetadata(contentType: contentType));
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  PAYMENT RECEIPTS
  // ════════════════════════════════════════════════════════════════════════════

  static Future<String?> uploadPaymentReceipt({
    required String bookingId,
    required File receiptFile,
  }) async {
    try {
      final bytes = await receiptFile.readAsBytes();
      final String fileName = 'receipt_${_uuid.v4()}.jpg';
      final ref = _storage.ref().child('payments/$bookingId/$fileName');
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  IMAGE PICKER HELPERS
  // ════════════════════════════════════════════════════════════════════════════

  /// Opens the gallery. Returns dart:io File for backward compat (mobile only).
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

  /// Web-safe gallery picker — returns XFile (works on web + mobile).
  static Future<XFile?> pickImageXFile() async {
    final picker = ImagePicker();
    return picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1800,
      maxHeight: 1800,
      imageQuality: 85,
    );
  }

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

  static Future<List<File>> pickMultipleImages() async {
    final picker = ImagePicker();
    final List<XFile> picked = await picker.pickMultiImage(
      maxWidth: 1800,
      maxHeight: 1800,
      imageQuality: 85,
    );
    return picked.map((xf) => File(xf.path)).toList();
  }

  /// Web-safe multi-pick — returns List<XFile>.
  static Future<List<XFile>> pickMultipleImagesXFile() async {
    final picker = ImagePicker();
    return picker.pickMultiImage(
      maxWidth: 1800,
      maxHeight: 1800,
      imageQuality: 85,
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  UPLOAD WITH PROGRESS
  // ════════════════════════════════════════════════════════════════════════════

  static Future<String?> uploadWithProgress({
    required String storagePath,
    required File file,
    required String contentType,
    Function(double progress)? onProgress,
  }) async {
    try {
      final bytes = await file.readAsBytes();
      final ref = _storage.ref().child(storagePath);
      final UploadTask task = ref.putData(
        bytes,
        SettableMetadata(contentType: contentType),
      );
      task.snapshotEvents.listen((TaskSnapshot snapshot) {
        if (onProgress != null && snapshot.totalBytes > 0) {
          onProgress(snapshot.bytesTransferred / snapshot.totalBytes);
        }
      });
      final TaskSnapshot result = await task;
      return await result.ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }
}
