import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

import '../../../core/utils/image_optimizer.dart';

class InvitationStorageService {
  InvitationStorageService._();

  static final FirebaseStorage _storage =
      FirebaseStorage.instance;

  /// Upload an already optimized invitation image.
  ///
  /// IMPORTANT:
  /// This method only accepts OptimizedImage.
  /// The original image should never be uploaded directly.
  static Future<String> uploadImage({
    required String userId,
    required String invitationId,
    required OptimizedImage image,
    required String fileName,
    String folder = 'photos',
  }) async {
    if (userId.trim().isEmpty) {
      throw ArgumentError('userId cannot be empty.');
    }

    if (invitationId.trim().isEmpty) {
      throw ArgumentError('invitationId cannot be empty.');
    }

    if (fileName.trim().isEmpty) {
      throw ArgumentError('fileName cannot be empty.');
    }

    final File optimizedFile = image.file;

    if (!await optimizedFile.exists()) {
      throw Exception(
        'Optimized image file no longer exists.',
      );
    }

    final storagePath =
        'invitations/'
        '$userId/'
        '$invitationId/'
        '$folder/'
        '$fileName.webp';

    final Reference reference =
        _storage.ref().child(storagePath);

    final metadata = SettableMetadata(
      contentType: 'image/webp',
      cacheControl: 'public,max-age=31536000',
      customMetadata: {
        'optimized': 'true',
        'originalSizeBytes':
            image.originalSizeBytes.toString(),
        'optimizedSizeBytes':
            image.sizeBytes.toString(),
      },
    );

    try {
      final UploadTask uploadTask =
          reference.putFile(
        optimizedFile,
        metadata,
      );

      final TaskSnapshot snapshot =
          await uploadTask;

      if (snapshot.state != TaskState.success) {
        throw Exception(
          'Image upload did not complete successfully.',
        );
      }

      final String downloadUrl =
          await reference.getDownloadURL();

      return downloadUrl;
    } on FirebaseException catch (e) {
      throw Exception(
        'Failed to upload invitation image: '
        '${e.message ?? e.code}',
      );
    }
  }

  /// Upload bride photo.
  static Future<String> uploadBridePhoto({
    required String userId,
    required String invitationId,
    required OptimizedImage image,
  }) {
    return uploadImage(
      userId: userId,
      invitationId: invitationId,
      image: image,
      fileName: 'bride',
    );
  }

  /// Upload groom photo.
  static Future<String> uploadGroomPhoto({
    required String userId,
    required String invitationId,
    required OptimizedImage image,
  }) {
    return uploadImage(
      userId: userId,
      invitationId: invitationId,
      image: image,
      fileName: 'groom',
    );
  }

  /// Upload couple photo.
  static Future<String> uploadCouplePhoto({
    required String userId,
    required String invitationId,
    required OptimizedImage image,
  }) {
    return uploadImage(
      userId: userId,
      invitationId: invitationId,
      image: image,
      fileName: 'couple',
    );
  }

  /// Upload venue photo.
  static Future<String> uploadVenuePhoto({
    required String userId,
    required String invitationId,
    required OptimizedImage image,
  }) {
    return uploadImage(
      userId: userId,
      invitationId: invitationId,
      image: image,
      fileName: 'venue',
    );
  }

  /// Upload story photo.
  static Future<String> uploadStoryPhoto({
    required String userId,
    required String invitationId,
    required OptimizedImage image,
    required int index,
  }) {
    return uploadImage(
      userId: userId,
      invitationId: invitationId,
      image: image,
      fileName: 'story_$index',
    );
  }

  /// Upload gallery photo.
  static Future<String> uploadGalleryPhoto({
    required String userId,
    required String invitationId,
    required OptimizedImage image,
    required int index,
  }) {
    return uploadImage(
      userId: userId,
      invitationId: invitationId,
      image: image,
      fileName: 'photo_$index',
      folder: 'photos/gallery',
    );
  }

  /// Delete an image using its Firebase Storage URL.
  static Future<void> deleteImageByUrl(
    String downloadUrl,
  ) async {
    if (downloadUrl.trim().isEmpty) {
      return;
    }

    try {
      final Reference reference =
          _storage.refFromURL(downloadUrl);

      await reference.delete();
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        return;
      }

      throw Exception(
        'Failed to delete invitation image: '
        '${e.message ?? e.code}',
      );
    }
  }

  /// Delete the complete invitation photo folder.
  static Future<void> deleteInvitationImages({
    required String userId,
    required String invitationId,
  }) async {
    final Reference invitationReference =
        _storage.ref().child(
              'invitations/$userId/$invitationId',
            );

    try {
      await _deleteFolderContents(
        invitationReference,
      );
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        return;
      }

      throw Exception(
        'Failed to delete invitation images: '
        '${e.message ?? e.code}',
      );
    }
  }

  static Future<void> _deleteFolderContents(
    Reference reference,
  ) async {
    final ListResult result =
        await reference.listAll();

    for (final item in result.items) {
      await item.delete();
    }

    for (final prefix in result.prefixes) {
      await _deleteFolderContents(prefix);
    }
  }
}