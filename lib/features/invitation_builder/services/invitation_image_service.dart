import 'dart:io';

import 'package:image_picker/image_picker.dart';

import '../../../core/utils/image_optimizer.dart';

class InvitationImageService {
  InvitationImageService._();

  static final ImagePicker _picker = ImagePicker();

  /// Pick one image from the device gallery and optimize it.
  static Future<OptimizedImage?> pickFromGallery({
    required InvitationImageType type,
  }) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
    );

    if (pickedFile == null) {
      return null;
    }

    return ImageOptimizer.optimize(
      sourcePath: pickedFile.path,
      type: type,
    );
  }

  /// Open the camera and optimize the captured image.
  static Future<OptimizedImage?> captureFromCamera({
    required InvitationImageType type,
  }) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 100,
    );

    if (pickedFile == null) {
      return null;
    }

    return ImageOptimizer.optimize(
      sourcePath: pickedFile.path,
      type: type,
    );
  }

  /// Pick multiple gallery images.
  ///
  /// Every image is optimized individually before being returned.
  static Future<List<OptimizedImage>> pickMultipleFromGallery({
    required InvitationImageType type,
  }) async {
    final List<XFile> pickedFiles =
        await _picker.pickMultiImage(
      imageQuality: 100,
    );

    if (pickedFiles.isEmpty) {
      return [];
    }

    final List<OptimizedImage> optimizedImages = [];

    for (final pickedFile in pickedFiles) {
      final optimized =
          await ImageOptimizer.optimize(
        sourcePath: pickedFile.path,
        type: type,
      );

      if (optimized != null) {
        optimizedImages.add(optimized);
      }
    }

    return optimizedImages;
  }

  /// Delete a temporary optimized image.
  static Future<void> deleteOptimizedImage(
    OptimizedImage image,
  ) async {
    await ImageOptimizer.deleteTemporaryFile(image);
  }

  /// Returns the original file size before optimization.
  static Future<int> getFileSize(
    String path,
  ) async {
    final file = File(path);

    if (!await file.exists()) {
      return 0;
    }

    return file.length();
  }

  static String formatSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }

    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }

    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}