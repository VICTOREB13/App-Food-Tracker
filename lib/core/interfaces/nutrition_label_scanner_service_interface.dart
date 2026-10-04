import 'dart:typed_data';
import '../../models/pantry_item.dart';

/// Contract for OCR Nutrition Facts Label scanning service.
abstract interface class INutritionLabelScannerService {
  Future<PantryItem?> scanNutritionLabel({
    required Uint8List imageBytes,
    String? brandHint,
  });
}
