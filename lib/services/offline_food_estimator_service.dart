import '../core/interfaces/offline_food_estimator_service_interface.dart';
import '../models/food_item.dart';

/// Embedded reference nutritional profile per 100g of edible portion.
class _BaseFoodProfile {
  final String name;
  final List<String> keywords;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sodium;
  final double sugar;

  const _BaseFoodProfile({
    required this.name,
    required this.keywords,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber = 0.0,
    this.sodium = 0.0,
    this.sugar = 0.0,
  });
}

/// Zero-tokens offline food estimator service with embedded catalog of 50+ base items.
class OfflineFoodEstimatorService implements IOfflineFoodEstimatorService {
  static final OfflineFoodEstimatorService instance = OfflineFoodEstimatorService._();
  OfflineFoodEstimatorService._();
  factory OfflineFoodEstimatorService() => instance;

  static const List<_BaseFoodProfile> _catalog = [
    // --- Carnes y Proteínas ---
    _BaseFoodProfile(name: 'Pechuga de pollo cocida', keywords: ['pollo', 'pechuga'], calories: 165.0, protein: 31.0, carbs: 0.0, fat: 3.6, sodium: 74.0),
    _BaseFoodProfile(name: 'Muslo de pollo asado', keywords: ['muslo', 'pierna', 'pollo'], calories: 177.0, protein: 24.0, carbs: 0.0, fat: 8.5, sodium: 85.0),
    _BaseFoodProfile(name: 'Carne de res molida (magra)', keywords: ['carne', 'molida', 'res'], calories: 215.0, protein: 26.0, carbs: 0.0, fat: 12.0, sodium: 68.0),
    _BaseFoodProfile(name: 'Bistec de res a la plancha', keywords: ['bistec', 'res', 'carne', 'bife'], calories: 210.0, protein: 28.0, carbs: 0.0, fat: 10.5, sodium: 60.0),
    _BaseFoodProfile(name: 'Salmón a la plancha', keywords: ['salmon'], calories: 206.0, protein: 22.0, carbs: 0.0, fat: 12.3, sodium: 61.0),
    _BaseFoodProfile(name: 'Atún en lata (en agua)', keywords: ['atun'], calories: 116.0, protein: 26.0, carbs: 0.0, fat: 1.0, sodium: 350.0),
    _BaseFoodProfile(name: 'Filete de pescado blanco (merluza)', keywords: ['pescado', 'merluza', 'tilapia'], calories: 96.0, protein: 20.0, carbs: 0.0, fat: 1.7, sodium: 80.0),
    _BaseFoodProfile(name: 'Chuleta de cerdo asada', keywords: ['cerdo', 'chuleta', 'lomo'], calories: 196.0, protein: 25.0, carbs: 0.0, fat: 10.2, sodium: 62.0),
    _BaseFoodProfile(name: 'Huevo entero cocido', keywords: ['huevo', 'huevos', 'hervido'], calories: 155.0, protein: 13.0, carbs: 1.1, fat: 11.0, sodium: 124.0, sugar: 1.1),
    _BaseFoodProfile(name: 'Clara de huevo', keywords: ['clara'], calories: 52.0, protein: 11.0, carbs: 0.7, fat: 0.2, sodium: 166.0, sugar: 0.7),
    _BaseFoodProfile(name: 'Tofu firme', keywords: ['tofu', 'soya'], calories: 76.0, protein: 8.0, carbs: 1.9, fat: 4.8, fiber: 0.3, sodium: 7.0),

    // --- Cereales, Granos y Pastas ---
    _BaseFoodProfile(name: 'Arroz blanco cocido', keywords: ['arroz', 'blanco'], calories: 130.0, protein: 2.7, carbs: 28.2, fat: 0.3, fiber: 0.4, sodium: 1.0, sugar: 0.1),
    _BaseFoodProfile(name: 'Arroz integral cocido', keywords: ['arroz', 'integral'], calories: 112.0, protein: 2.6, carbs: 23.5, fat: 0.9, fiber: 1.8, sodium: 1.0),
    _BaseFoodProfile(name: 'Avena en hojuelas cocida', keywords: ['avena'], calories: 71.0, protein: 2.5, carbs: 12.0, fat: 1.5, fiber: 1.7, sodium: 49.0, sugar: 0.3),
    _BaseFoodProfile(name: 'Pasta cocida (espagueti)', keywords: ['pasta', 'espagueti', 'fideos'], calories: 158.0, protein: 5.8, carbs: 30.9, fat: 0.9, fiber: 1.8, sodium: 1.0, sugar: 0.6),
    _BaseFoodProfile(name: 'Pan blanco de molde', keywords: ['pan', 'blanco', 'molde'], calories: 265.0, protein: 9.0, carbs: 49.0, fat: 3.2, fiber: 2.7, sodium: 490.0, sugar: 5.0),
    _BaseFoodProfile(name: 'Pan integral', keywords: ['pan', 'integral'], calories: 247.0, protein: 13.0, carbs: 41.0, fat: 3.4, fiber: 7.0, sodium: 450.0, sugar: 6.0),
    _BaseFoodProfile(name: 'Arepa de maíz blanco', keywords: ['arepa'], calories: 180.0, protein: 3.8, carbs: 37.0, fat: 1.5, fiber: 2.4, sodium: 220.0),
    _BaseFoodProfile(name: 'Tortilla de maíz', keywords: ['tortilla', 'maiz'], calories: 218.0, protein: 5.7, carbs: 45.0, fat: 2.8, fiber: 6.3, sodium: 35.0, sugar: 0.9),
    _BaseFoodProfile(name: 'Quinoa cocida', keywords: ['quinoa', 'quinua'], calories: 120.0, protein: 4.4, carbs: 21.3, fat: 1.9, fiber: 2.8, sodium: 7.0, sugar: 0.9),

    // --- Tubérculos y Legumbres ---
    _BaseFoodProfile(name: 'Papa cocida', keywords: ['papa', 'patata'], calories: 87.0, protein: 1.9, carbs: 20.1, fat: 0.1, fiber: 1.8, sodium: 6.0, sugar: 0.9),
    _BaseFoodProfile(name: 'Plátano maduro hervido', keywords: ['platano', 'maduro'], calories: 116.0, protein: 1.3, carbs: 31.0, fat: 0.2, fiber: 2.3, sodium: 4.0, sugar: 15.0),
    _BaseFoodProfile(name: 'Plátano verde hervido', keywords: ['platano', 'verde'], calories: 122.0, protein: 1.3, carbs: 32.0, fat: 0.4, fiber: 2.3, sodium: 4.0, sugar: 3.0),
    _BaseFoodProfile(name: 'Yuca cocida', keywords: ['yuca', 'mandioca'], calories: 160.0, protein: 1.4, carbs: 38.0, fat: 0.3, fiber: 1.8, sodium: 14.0, sugar: 1.7),
    _BaseFoodProfile(name: 'Frijoles negros cocidos', keywords: ['frijol', 'frijoles', 'caraota'], calories: 132.0, protein: 8.9, carbs: 23.7, fat: 0.5, fiber: 8.7, sodium: 1.0, sugar: 0.3),
    _BaseFoodProfile(name: 'Lentejas cocidas', keywords: ['lenteja', 'lentejas'], calories: 116.0, protein: 9.0, carbs: 20.1, fat: 0.4, fiber: 7.9, sodium: 2.0, sugar: 1.8),
    _BaseFoodProfile(name: 'Garbanzos cocidos', keywords: ['garbanzo', 'garbanzos'], calories: 164.0, protein: 8.9, carbs: 27.4, fat: 2.6, fiber: 7.6, sodium: 7.0, sugar: 4.8),

    // --- Grasas, Aceites y Semillas ---
    _BaseFoodProfile(name: 'Aguacate Hass', keywords: ['aguacate', 'palta'], calories: 160.0, protein: 2.0, carbs: 8.5, fat: 14.7, fiber: 6.7, sodium: 7.0, sugar: 0.7),
    _BaseFoodProfile(name: 'Aceite de oliva extra virgen', keywords: ['aceite', 'oliva'], calories: 884.0, protein: 0.0, carbs: 0.0, fat: 100.0, sodium: 2.0),
    _BaseFoodProfile(name: 'Aceite vegetal / girasol', keywords: ['aceite', 'vegetal', 'girasol'], calories: 884.0, protein: 0.0, carbs: 0.0, fat: 100.0),
    _BaseFoodProfile(name: 'Mantequilla sin sal', keywords: ['mantequilla'], calories: 717.0, protein: 0.9, carbs: 0.1, fat: 81.1, sodium: 11.0, sugar: 0.1),
    _BaseFoodProfile(name: 'Mantequilla de maní', keywords: ['mani', 'cacahuate'], calories: 588.0, protein: 25.0, carbs: 20.0, fat: 50.0, fiber: 6.0, sodium: 17.0, sugar: 9.0),
    _BaseFoodProfile(name: 'Almendras naturales', keywords: ['almendra', 'almendras'], calories: 579.0, protein: 21.2, carbs: 21.6, fat: 49.9, fiber: 12.5, sodium: 1.0, sugar: 4.4),
    _BaseFoodProfile(name: 'Nueces', keywords: ['nuez', 'nueces'], calories: 654.0, protein: 15.2, carbs: 13.7, fat: 65.2, fiber: 6.7, sodium: 2.0, sugar: 2.6),

    // --- Lácteos y Derivados ---
    _BaseFoodProfile(name: 'Leche entera', keywords: ['leche', 'entera'], calories: 61.0, protein: 3.2, carbs: 4.8, fat: 3.3, sodium: 43.0, sugar: 5.1),
    _BaseFoodProfile(name: 'Leche descremada', keywords: ['leche', 'descremada'], calories: 34.0, protein: 3.4, carbs: 5.0, fat: 0.1, sodium: 42.0, sugar: 5.0),
    _BaseFoodProfile(name: 'Queso blanco fresco', keywords: ['queso', 'blanco', 'fresco'], calories: 260.0, protein: 18.0, carbs: 2.5, fat: 20.0, sodium: 520.0, sugar: 1.5),
    _BaseFoodProfile(name: 'Queso mozzarella', keywords: ['queso', 'mozzarella'], calories: 280.0, protein: 22.2, carbs: 2.2, fat: 20.7, sodium: 627.0, sugar: 1.0),
    _BaseFoodProfile(name: 'Yogur griego natural', keywords: ['yogur', 'griego'], calories: 59.0, protein: 10.0, carbs: 3.6, fat: 0.4, sodium: 36.0, sugar: 3.2),

    // --- Frutas ---
    _BaseFoodProfile(name: 'Plátano / Banana', keywords: ['banana', 'cambur'], calories: 89.0, protein: 1.1, carbs: 22.8, fat: 0.3, fiber: 2.6, sodium: 1.0, sugar: 12.2),
    _BaseFoodProfile(name: 'Manzana roja', keywords: ['manzana'], calories: 52.0, protein: 0.3, carbs: 13.8, fat: 0.2, fiber: 2.4, sodium: 1.0, sugar: 10.4),
    _BaseFoodProfile(name: 'Naranja fresca', keywords: ['naranja'], calories: 47.0, protein: 0.9, carbs: 11.8, fat: 0.1, fiber: 2.4, sodium: 0.0, sugar: 9.4),
    _BaseFoodProfile(name: 'Fresas frescas', keywords: ['fresa', 'frutilla'], calories: 32.0, protein: 0.7, carbs: 7.7, fat: 0.3, fiber: 2.0, sodium: 1.0, sugar: 4.9),
    _BaseFoodProfile(name: 'Mango maduro', keywords: ['mango'], calories: 60.0, protein: 0.8, carbs: 15.0, fat: 0.4, fiber: 1.6, sodium: 1.0, sugar: 13.7),
    _BaseFoodProfile(name: 'Papaya / Lechosa', keywords: ['papaya', 'lechosa'], calories: 43.0, protein: 0.5, carbs: 10.8, fat: 0.3, fiber: 1.7, sodium: 8.0, sugar: 7.8),
    _BaseFoodProfile(name: 'Sandía / Patilla', keywords: ['sandia', 'patilla'], calories: 30.0, protein: 0.6, carbs: 7.6, fat: 0.2, fiber: 0.4, sodium: 1.0, sugar: 6.2),

    // --- Verduras y Vegetales ---
    _BaseFoodProfile(name: 'Tomate fresco', keywords: ['tomate'], calories: 18.0, protein: 0.9, carbs: 3.9, fat: 0.2, fiber: 1.2, sodium: 5.0, sugar: 2.6),
    _BaseFoodProfile(name: 'Cebolla blanca/roja', keywords: ['cebolla'], calories: 40.0, protein: 1.1, carbs: 9.3, fat: 0.1, fiber: 1.7, sodium: 4.0, sugar: 4.2),
    _BaseFoodProfile(name: 'Zanahoria cruda', keywords: ['zanahoria'], calories: 41.0, protein: 0.9, carbs: 9.6, fat: 0.2, fiber: 2.8, sodium: 69.0, sugar: 4.7),
    _BaseFoodProfile(name: 'Brócoli cocido', keywords: ['brocoli'], calories: 35.0, protein: 2.4, carbs: 7.2, fat: 0.4, fiber: 3.3, sodium: 41.0, sugar: 1.4),
    _BaseFoodProfile(name: 'Espinacas crudas', keywords: ['espinaca', 'espinacas'], calories: 23.0, protein: 2.9, carbs: 3.6, fat: 0.4, fiber: 2.2, sodium: 79.0, sugar: 0.4),
    _BaseFoodProfile(name: 'Lechuga romana/fresca', keywords: ['lechuga'], calories: 15.0, protein: 1.4, carbs: 2.9, fat: 0.2, fiber: 1.3, sodium: 28.0, sugar: 0.8),
    _BaseFoodProfile(name: 'Pepino con cáscara', keywords: ['pepino'], calories: 15.0, protein: 0.7, carbs: 3.6, fat: 0.1, fiber: 0.5, sodium: 2.0, sugar: 1.7),
  ];

  static String _normalize(String input) {
    var s = input.trim().toLowerCase();
    s = s.replaceAll(RegExp(r'[áàäâ]'), 'a');
    s = s.replaceAll(RegExp(r'[éèëê]'), 'e');
    s = s.replaceAll(RegExp(r'[íìïî]'), 'i');
    s = s.replaceAll(RegExp(r'[óòöô]'), 'o');
    s = s.replaceAll(RegExp(r'[úùüû]'), 'u');
    s = s.replaceAll(RegExp(r'[ñ]'), 'n');
    return s;
  }

  @override
  FoodItem? estimateNutrients({required String query, required double grams}) {
    final cleanQuery = _normalize(query);
    if (cleanQuery.isEmpty || grams <= 0) return null;

    final tokens = cleanQuery.split(RegExp(r'[\s,.;:()/\-]+')).where((t) => t.isNotEmpty).toList();
    if (tokens.isEmpty) return null;

    _BaseFoodProfile? bestMatch;
    int maxScore = 0;

    for (final food in _catalog) {
      int score = 0;
      final normName = _normalize(food.name);

      if (normName == cleanQuery) {
        score += 100;
      } else if (normName.contains(cleanQuery)) {
        score += 50;
      }

      for (final kw in food.keywords) {
        final normKw = _normalize(kw);
        if (tokens.contains(normKw)) {
          score += 20;
        } else if (tokens.any((t) => t.contains(normKw) || normKw.contains(t))) {
          score += 10;
        }
      }

      if (score > maxScore) {
        maxScore = score;
        bestMatch = food;
      }
    }

    if (bestMatch == null || maxScore < 10) return null;

    final ratio = grams / 100.0;
    return FoodItem(
      name: query.trim(),
      estimatedGrams: grams,
      calories: bestMatch.calories * ratio,
      protein: bestMatch.protein * ratio,
      carbs: bestMatch.carbs * ratio,
      fat: bestMatch.fat * ratio,
      fiber: bestMatch.fiber * ratio,
      sodium: bestMatch.sodium * ratio,
      sugar: bestMatch.sugar * ratio,
      visualJustification: 'Estimado offline con catálogo base: ${bestMatch.name}',
    );
  }

  @override
  List<FoodItem> searchCatalog({required String query, int limit = 10}) {
    final cleanQuery = _normalize(query);
    if (cleanQuery.isEmpty) return const [];

    final matches = <_BaseFoodProfile>[];
    for (final food in _catalog) {
      final normName = _normalize(food.name);
      final hasKw = food.keywords.any((kw) => _normalize(kw).contains(cleanQuery));
      if (normName.contains(cleanQuery) || hasKw) {
        matches.add(food);
        if (matches.length >= limit) break;
      }
    }

    return matches.map((m) => FoodItem(
      name: m.name,
      estimatedGrams: 100.0,
      calories: m.calories,
      protein: m.protein,
      carbs: m.carbs,
      fat: m.fat,
      fiber: m.fiber,
      sodium: m.sodium,
      sugar: m.sugar,
    )).toList();
  }
}
