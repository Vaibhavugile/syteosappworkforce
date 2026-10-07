import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

enum InvitationImageType {
  bride,
  groom,
  couple,
  story,
  gallery,
  venue,
  thumbnail,
}

class OptimizedImage {
  final File file;
  final Uint8List bytes;
  final int sizeBytes;

  const OptimizedImage({
    required this.file,
    required this.bytes,
    required this.sizeBytes,
  });

  double get sizeInKb => sizeBytes / 1024;

  double get sizeInMb => sizeBytes / (1024 * 1024);
}

class ImageOptimizationConfig {
  final int maxWidth;
  final int maxHeight;
  final int quality;
  final int maxSizeBytes;

  const ImageOptimizationConfig({
    required this.maxWidth,
    required this.maxHeight,
    required this.quality,
    required this.maxSizeBytes,
  });
}

class ImageOptimizer {
  ImageOptimizer._();

  static ImageOptimizationConfig configFor(
    InvitationImageType type,
  ) {
    switch (type) {
      case InvitationImageType.bride:
      case InvitationImageType.groom:
      case InvitationImageType.couple:
        return const ImageOptimizationConfig(
          maxWidth: 1600,
          maxHeight: 1600,
          quality: 82,
          maxSizeBytes: 500 * 1024,
        );

      case InvitationImageType.story:
        return const ImageOptimizationConfig(
          maxWidth: 1400,
          maxHeight: 1400,
          quality: 80,
          maxSizeBytes: 400 * 1024,
        );

      case InvitationImageType.gallery:
        return const ImageOptimizationConfig(
          maxWidth: 1200,
          maxHeight: 1200,
          quality: 78,
          maxSizeBytes: 350 * 1024,
        );

      case InvitationImageType.venue:
        return const ImageOptimizationConfig(
          maxWidth: 1400,
          maxHeight: 1400,
          quality: 80,
          maxSizeBytes: 400 * 1024,
        );

      case InvitationImageType.thumbnail:
        return const ImageOptimizationConfig(
          maxWidth: 500,
          maxHeight: 500,
          quality: 75,
          maxSizeBytes: 100 * 1024,
        );
    }
  }

  static Future<OptimizedImage?> optimize({
    required String sourcePath,
    required InvitationImageType type,
  }) async {
    final sourceFile = File(sourcePath);

    if (!await sourceFile.exists()) {
      return null;
    }

    final config = configFor(type);

    final temporaryDirectory = await getTemporaryDirectory();

    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final outputPath =
        '${temporaryDirectory.path}/invitation_$timestamp.webp';

    Uint8List? compressedBytes;

    int quality = config.quality;

    // First compression.
    compressedBytes = await _compress(
      sourcePath: sourcePath,
      maxWidth: config.maxWidth,
      maxHeight: config.maxHeight,
      quality: quality,
    );

    if (compressedBytes == null || compressedBytes.isEmpty) {
      return null;
    }

    // If the image is still too large,
    // progressively reduce quality.
    while (
        compressedBytes.length > config.maxSizeBytes &&
        quality > 40) {
      quality -= 8;

      compressedBytes = await _compress(
        sourcePath: sourcePath,
        maxWidth: config.maxWidth,
        maxHeight: config.maxHeight,
        quality: quality,
      );

      if (compressedBytes == null || compressedBytes.isEmpty) {
        return null;
      }
    }

    // If the image is still too large after
    // quality reduction, reduce dimensions.
    if (compressedBytes.length > config.maxSizeBytes) {
      final reducedWidth =
          (config.maxWidth * 0.75).round();

      final reducedHeight =
          (config.maxHeight * 0.75).round();

      compressedBytes = await _compress(
        sourcePath: sourcePath,
        maxWidth: reducedWidth,
        maxHeight: reducedHeight,
        quality: 65,
      );

      if (compressedBytes == null || compressedBytes.isEmpty) {
        return null;
      }
    }

    final outputFile = File(outputPath);

    await outputFile.writeAsBytes(
      compressedBytes,
      flush: true,
    );

    return OptimizedImage(
      file: outputFile,
      bytes: compressedBytes,
      sizeBytes: compressedBytes.length,
    );
  }

  static Future<Uint8List?> _compress({
    required String sourcePath,
    required int maxWidth,
    required int maxHeight,
    required int quality,
  }) async {
    return FlutterImageCompress.compressWithFile(
      sourcePath,
      minWidth: maxWidth,
      minHeight: maxHeight,
      quality: quality,
      format: CompressFormat.webp,
      keepExif: false,
    );
  }

  static Future<void> deleteTemporaryFile(
    OptimizedImage image,
  ) async {
    try {
      if (await image.file.exists()) {
        await image.file.delete();
      }
    } catch (_) {
      // Temporary cleanup failure should not
      // break the invitation flow.
    }
  }
}