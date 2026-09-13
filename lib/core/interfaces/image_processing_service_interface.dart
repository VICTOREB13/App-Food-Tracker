import 'dart:io';
import 'dart:typed_data';
import '../errors/failures.dart';
import '../errors/result.dart';

/// Contract for Image Processing Service operations.
abstract interface class IImageProcessingService {
  Uint8List compressAndResize(
    Uint8List rawBytes, {
    int targetMaxDimension = 1024,
    int quality = 85,
  });

  Future<Uint8List> compressAndResizeAsync(
    Uint8List rawBytes, {
    int targetMaxDimension = 1024,
    int quality = 85,
  });

  Future<String> saveMealImage(
    Uint8List imageBytes, {
    String? mealType,
    DateTime? date,
    String? mealId,
    int? index,
    Directory? customDirectory,
  });

  Future<int> pruneOldMealPhotos({required int retentionDays});

  Future<void> deleteMealImage(String? filePath);

  Future<String> renameMealImage({
    required String currentPath,
    required String newMealType,
    DateTime? date,
  });

  // Functional Result APIs
  Future<Result<String, ImageProcessingFailure>> saveMealImageResult(
    Uint8List imageBytes, {
    String? mealType,
    DateTime? date,
    String? mealId,
    int? index,
    Directory? customDirectory,
  });

  Future<Result<Uint8List, ImageProcessingFailure>> compressAndResizeAsyncResult(
    Uint8List rawBytes, {
    int targetMaxDimension = 1024,
    int quality = 85,
  });
}
