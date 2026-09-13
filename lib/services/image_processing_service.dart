import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../core/errors/failures.dart';
import '../core/errors/result.dart';
import '../core/interfaces/image_processing_service_interface.dart';
import 'database_service.dart';
import 'meal_image_file_namer.dart';
import 'meal_image_storage_resolver.dart';

export 'meal_image_file_namer.dart';
export 'meal_image_storage_resolver.dart';

/// Service responsible for image resizing, compression, file persistence, and cleanup.
class ImageProcessingService implements IImageProcessingService {
  static ImageProcessingService? _mockInstance;
  static final ImageProcessingService _defaultInstance = ImageProcessingService._();

  static ImageProcessingService get instance => _mockInstance ?? _defaultInstance;

  @visibleForTesting
  static void setMockInstance(ImageProcessingService mock) => _mockInstance = mock;

  @visibleForTesting
  static void resetInstance() => _mockInstance = null;

  ImageProcessingService._();
  ImageProcessingService();

  static const int maxDimension = 1024;
  static const int jpegQuality = 85;
  static const String androidPublicPicturesPath =
      MealImageStorageResolver.androidPublicPicturesPath;

  // Backwards compatibility aliases to MealImageFileNamer
  static RegExp get mealImageFileNamePattern => MealImageFileNamer.mealImageFileNamePattern;
  static String getMealTypeCode(String? mealType) => MealImageFileNamer.getMealTypeCode(mealType);
  static String getMealTypeFromCode(String code) => MealImageFileNamer.getMealTypeFromCode(code);
  static String inferMealTypeByTime([DateTime? time]) =>
      MealImageFileNamer.inferMealTypeByTime(time);
  static String normalizeFilePath(String pathOrUri) =>
      MealImageFileNamer.normalizeFilePath(pathOrUri);
  static MealImageFileInfo? parseMealImageFileName(String path) =>
      MealImageFileNamer.parseMealImageFileName(path);
  static bool isMealImageFileName(String path) => MealImageFileNamer.isMealImageFileName(path);
  static Future<int> getNextMealImageIndex({
    required Directory directory,
    required String year,
    required String month,
    required String day,
    required String typeCode,
  }) =>
      MealImageFileNamer.getNextMealImageIndex(
        directory: directory,
        year: year,
        month: month,
        day: day,
        typeCode: typeCode,
      );
  static Future<String> generateMealImageFileName({
    DateTime? date,
    String? mealType,
    Directory? directory,
    int? explicitIndex,
  }) =>
      MealImageFileNamer.generateMealImageFileName(
        date: date,
        mealType: mealType,
        directory: directory,
        explicitIndex: explicitIndex,
      );
  static List<MealImageFileInfo> filterMealImages(
    List<String> filePaths, {
    DateTime? date,
    int? year,
    int? month,
    int? day,
    String? mealType,
  }) =>
      MealImageFileNamer.filterMealImages(
        filePaths,
        date: date,
        year: year,
        month: month,
        day: day,
        mealType: mealType,
      );
  static Future<List<MealImageFileInfo>> listMealImages({
    required Directory directory,
    DateTime? date,
    int? year,
    int? month,
    int? day,
    String? mealType,
  }) =>
      MealImageFileNamer.listMealImages(
        directory: directory,
        date: date,
        year: year,
        month: month,
        day: day,
        mealType: mealType,
      );

  @override
  Uint8List compressAndResize(
    Uint8List rawBytes, {
    int targetMaxDimension = maxDimension,
    int quality = jpegQuality,
  }) {
    final decoded = img.decodeImage(rawBytes);
    if (decoded == null) return rawBytes;

    img.Image processed = decoded;
    if (decoded.width > targetMaxDimension || decoded.height > targetMaxDimension) {
      final isWider = decoded.width >= decoded.height;
      processed = img.copyResize(
        decoded,
        width: isWider ? targetMaxDimension : null,
        height: isWider ? null : targetMaxDimension,
        interpolation: img.Interpolation.linear,
      );
    }
    return Uint8List.fromList(img.encodeJpg(processed, quality: quality));
  }

  @override
  Future<Uint8List> compressAndResizeAsync(
    Uint8List rawBytes, {
    int targetMaxDimension = maxDimension,
    int quality = jpegQuality,
  }) async {
    return await Isolate.run(
      () => compressAndResize(
        rawBytes,
        targetMaxDimension: targetMaxDimension,
        quality: quality,
      ),
    );
  }

  @override
  Future<String> saveMealImage(
    Uint8List imageBytes, {
    String? mealType,
    DateTime? date,
    String? mealId,
    int? index,
    Directory? customDirectory,
  }) async {
    final effectiveDate = date ?? DateTime.now();
    final effectiveMealType =
        mealType ?? mealId ?? MealImageFileNamer.inferMealTypeByTime(effectiveDate);
    final typeCode = MealImageFileNamer.getMealTypeCode(effectiveMealType);

    return await MealImageStorageResolver.writeImageWithAntiCollision(
      imageBytes: imageBytes,
      date: effectiveDate,
      typeCode: typeCode,
      explicitIndex: index,
      customDirectory: customDirectory,
    );
  }

  @override
  Future<int> pruneOldMealPhotos({required int retentionDays}) async {
    if (retentionDays <= 0) return 0;
    final cutoffDate = DateTime.now().subtract(Duration(days: retentionDays));
    final meals = await DatabaseService.instance.getMealsOlderThanWithImages(cutoffDate);

    int deletedCount = 0;
    for (final meal in meals) {
      final path = meal.imagePath;
      if (path != null && path.trim().isNotEmpty) {
        try {
          final file = File(MealImageFileNamer.normalizeFilePath(path));
          if (await file.exists()) {
            await file.delete();
            deletedCount++;
          }
        } catch (_) {}
      }
      await DatabaseService.instance.clearMealImagePath(meal.id);
    }
    return deletedCount;
  }

  @override
  Future<void> deleteMealImage(String? filePath) async {
    if (filePath == null || filePath.trim().isEmpty) return;
    try {
      final file = File(MealImageFileNamer.normalizeFilePath(filePath));
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  @override
  Future<String> renameMealImage({
    required String currentPath,
    required String newMealType,
    DateTime? date,
  }) =>
      MealImageStorageResolver.renameImageFile(
        currentPath: currentPath,
        newMealType: newMealType,
        date: date,
      );

  @override
  Future<Result<String, ImageProcessingFailure>> saveMealImageResult(
    Uint8List imageBytes, {
    String? mealType,
    DateTime? date,
    String? mealId,
    int? index,
    Directory? customDirectory,
  }) async {
    try {
      final path = await saveMealImage(
        imageBytes,
        mealType: mealType,
        date: date,
        mealId: mealId,
        index: index,
        customDirectory: customDirectory,
      );
      return Result.ok(path);
    } catch (e, stack) {
      return Result.err(
        ImageProcessingFailure(
          message: 'Error al guardar imagen de comida: $e',
          cause: e,
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<Uint8List, ImageProcessingFailure>> compressAndResizeAsyncResult(
    Uint8List rawBytes, {
    int targetMaxDimension = maxDimension,
    int quality = jpegQuality,
  }) async {
    try {
      final bytes = await compressAndResizeAsync(
        rawBytes,
        targetMaxDimension: targetMaxDimension,
        quality: quality,
      );
      return Result.ok(bytes);
    } catch (e, stack) {
      return Result.err(
        ImageProcessingFailure(
          message: 'Error al procesar/comprimir imagen: $e',
          cause: e,
          stackTrace: stack,
        ),
      );
    }
  }
}
