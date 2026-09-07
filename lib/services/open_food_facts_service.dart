import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/model_sanitizer.dart';
import '../models/pantry_item.dart';

class OpenFoodFactsService {
  static final OpenFoodFactsService instance = OpenFoodFactsService._();
  OpenFoodFactsService._();

  final http.Client _client = http.Client();

  Future<PantryItem?> fetchProductByBarcode(String barcode) async {
    final sanitizedBarcode = barcode.trim();
    if (sanitizedBarcode.isEmpty) return null;

    final uri = Uri.parse(
      'https://world.openfoodfacts.org/api/v2/product/$sanitizedBarcode.json',
    );

    try {
      final response = await _client
          .get(
            uri,
            headers: {
              'User-Agent': 'VictorEngineerFoodTracker - Flutter - Version 1.0',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      final Map<String, dynamic> data = json.decode(response.body);
      if (data['status'] != 1 || data['product'] == null) {
        return null;
      }

      final product = data['product'] as Map<String, dynamic>;
      final nutriments = (product['nutriments'] as Map<String, dynamic>?) ?? {};

      final name = (product['product_name_es'] ??
              product['product_name'] ??
              product['generic_name_es'] ??
              product['generic_name'] ??
              'Alimento escaneado')
          .toString();

      final brand = product['brands']?.toString();
      final category = product['categories']?.toString().split(',').first.trim();

      final calories = (nutriments['energy-kcal_100g'] ??
              nutriments['energy-kcal'] ??
              nutriments['energy-kcal_serving'] ??
              0) as num?;

      final protein = (nutriments['proteins_100g'] ??
              nutriments['proteins'] ??
              nutriments['proteins_serving'] ??
              0) as num?;

      final carbs = (nutriments['carbohydrates_100g'] ??
              nutriments['carbohydrates'] ??
              nutriments['carbohydrates_serving'] ??
              0) as num?;

      final fat = (nutriments['fat_100g'] ??
              nutriments['fat'] ??
              nutriments['fat_serving'] ??
              0) as num?;

      return PantryItem(
        name: ModelSanitizer.truncate(name, 255, fallback: 'Alimento escaneado'),
        brand: brand,
        category: category,
        calories: ModelSanitizer.clampDouble(calories),
        protein: ModelSanitizer.clampDouble(protein),
        carbs: ModelSanitizer.clampDouble(carbs),
        fat: ModelSanitizer.clampDouble(fat),
      );
    } catch (_) {
      return null;
    }
  }
}
