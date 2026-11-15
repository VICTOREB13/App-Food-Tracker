import 'dart:typed_data';
import 'package:food_tracker/features/pantry_inventory/models/pantry_item.dart';

/// Contract for OCR Nutrition Facts Label scanning service.
abstract interface class INutritionLabelScannerService {
  Future<PantryItem?> scanNutritionLabel({
    required Uint8List imageBytes,
    String? brandHint,
  });
}
