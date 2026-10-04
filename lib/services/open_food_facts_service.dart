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

      final calories = ModelSanitizer.clampDouble(
        nutriments['energy-kcal_100g'] ??
            nutriments['energy-kcal'] ??
            nutriments['energy-kcal_serving'],
      );

      final protein = ModelSanitizer.clampDouble(
        nutriments['proteins_100g'] ??
            nutriments['proteins'] ??
            nutriments['proteins_serving'],
      );

      final carbs = ModelSanitizer.clampDouble(
        nutriments['carbohydrates_100g'] ??
            nutriments['carbohydrates'] ??
            nutriments['carbohydrates_serving'],
      );

      final fat = ModelSanitizer.clampDouble(
        nutriments['fat_100g'] ??
            nutriments['fat'] ??
            nutriments['fat_serving'],
      );

      return PantryItem(
        name: ModelSanitizer.truncate(name, 255, fallback: 'Alimento escaneado'),
        brand: brand,
        category: category,
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
      );
    } catch (_) {
      return null;
    }
  }

  /// Searches products in Open Food Facts by text query.
  Future<List<PantryItem>> searchProductsByText(String query, {int pageSize = 8}) async {
    final sanitizedQuery = query.trim();
    if (sanitizedQuery.isEmpty) return const [];

    final uri = Uri.parse(
      'https://world.openfoodfacts.org/cgi/search.pl?search_terms=${Uri.encodeComponent(sanitizedQuery)}&search_simple=1&action=process&json=1&page_size=$pageSize',
    );

    try {
      final response = await _client
          .get(
            uri,
            headers: {
              'User-Agent': 'VictorEngineerFoodTracker - Flutter - Version 1.0',
            },
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return const [];

      final Map<String, dynamic> data = json.decode(response.body);
      final products = data['products'] as List<dynamic>?;
      if (products == null || products.isEmpty) return const [];

      final items = <PantryItem>[];
      for (final raw in products) {
        if (raw is! Map<String, dynamic>) continue;
        final nutriments = (raw['nutriments'] as Map<String, dynamic>?) ?? {};

        final name = (raw['product_name_es'] ??
                raw['product_name'] ??
                raw['generic_name_es'] ??
                raw['generic_name'] ??
                '')
            .toString()
            .trim();
        if (name.isEmpty) continue;

        final brand = raw['brands']?.toString();
        final category = raw['categories']?.toString().split(',').first.trim();

        final calories = ModelSanitizer.clampDouble(
          nutriments['energy-kcal_100g'] ??
              nutriments['energy-kcal'] ??
              nutriments['energy-kcal_serving'],
        );
        final protein = ModelSanitizer.clampDouble(
          nutriments['proteins_100g'] ??
              nutriments['proteins'] ??
              nutriments['proteins_serving'],
        );
        final carbs = ModelSanitizer.clampDouble(
          nutriments['carbohydrates_100g'] ??
              nutriments['carbohydrates'] ??
              nutriments['carbohydrates_serving'],
        );
        final fat = ModelSanitizer.clampDouble(
          nutriments['fat_100g'] ??
              nutriments['fat'] ??
              nutriments['fat_serving'],
        );
        final fiber = ModelSanitizer.clampDouble(
          nutriments['fiber_100g'] ?? nutriments['fiber'],
        );
        final sodium = ModelSanitizer.clampDouble(
          (nutriments['sodium_100g'] ?? nutriments['sodium']) != null
              ? (ModelSanitizer.clampDouble(nutriments['sodium_100g'] ?? nutriments['sodium']) * 1000.0)
              : (ModelSanitizer.clampDouble(nutriments['salt_100g'] ?? nutriments['salt']) * 400.0),
        );
        final sugar = ModelSanitizer.clampDouble(
          nutriments['sugars_100g'] ?? nutriments['sugars'],
        );

        items.add(PantryItem(
          name: ModelSanitizer.truncate(name, 255, fallback: 'Alimento escaneado'),
          brand: brand,
          category: category,
          calories: calories,
          protein: protein,
          carbs: carbs,
          fat: fat,
          fiber: fiber,
          sodium: sodium,
          sugar: sugar,
          barcode: raw['code']?.toString(),
        ));
      }
      return items;
    } catch (_) {
      return const [];
    }
  }
}
