import 'dart:math';
import 'package:flutter/foundation.dart';
import '../core/interfaces/database_service_interface.dart';
import '../core/interfaces/nutritional_recommendation_service_interface.dart';
import '../models/daily_goals.dart';
import '../models/meal.dart';
import '../models/nutritional_recommendation.dart';
import 'database_service.dart';
import 'secure_storage_service.dart';

/// Intelligent recommendation engine evaluating macronutrient intake and suggesting meal strategies.
class NutritionalRecommendationService implements INutritionalRecommendationService {
  final IDatabaseService _db;
  final SecureStorageService _storage;

  static NutritionalRecommendationService? _mockInstance;
  static final NutritionalRecommendationService _defaultInstance =
      NutritionalRecommendationService();

  static NutritionalRecommendationService get instance =>
      _mockInstance ?? _defaultInstance;

  @visibleForTesting
  static void setMockInstance(NutritionalRecommendationService? mock) =>
      _mockInstance = mock;

  NutritionalRecommendationService({
    IDatabaseService? databaseService,
    SecureStorageService? storageService,
  })  : _db = databaseService ?? DatabaseService.instance,
        _storage = storageService ?? SecureStorageService.instance;

  Future<DailyGoals> _resolveGoals() async {
    try {
      final storedGoals = await _storage.getDailyGoals();
      if (storedGoals != null) return storedGoals;
      final profile = await _db.getUserProfile();
      if (profile != null) {
        return DailyGoals(
          calories: profile.targetCalories,
          protein: profile.targetProtein,
          carbs: profile.targetCarbs,
          fat: profile.targetFat,
        );
      }
    } catch (_) {}
    return const DailyGoals();
  }

  @override
  Future<NutritionalAnalysisReport> analyzeHistory({int days = 7}) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).subtract(Duration(days: days));
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final meals = await _db.getMealsByRange(start, end);
    final goals = await _resolveGoals();

    final datesLogged = <String>{};
    double sumCal = 0, sumProt = 0, sumCarbs = 0, sumFat = 0;

    for (final m in meals) {
      datesLogged.add(m.date.toIso8601String().substring(0, 10));
      sumCal += m.calories;
      sumProt += m.protein;
      sumCarbs += m.carbs;
      sumFat += m.fat;
    }

    final divisor = max(1, datesLogged.isNotEmpty ? datesLogged.length : days);
    final avgCal = sumCal / divisor;
    final avgProt = sumProt / divisor;
    final avgCarbs = sumCarbs / divisor;
    final avgFat = sumFat / divisor;

    final fatDelta = avgFat - goals.fat;
    final protDelta = avgProt - goals.protein;
    final carbsDelta = avgCarbs - goals.carbs;
    final calDelta = avgCal - goals.calories;

    final fatDiag = fatDelta > 5
        ? 'Tu consumo de grasas supera tu meta en +${fatDelta.toStringAsFixed(1)}g/día. Reducir aceites de freír y salsas ultraprocesadas facilitará tu déficit.'
        : fatDelta < -15
            ? 'Ingesta de grasas baja (-${(-fatDelta).toStringAsFixed(1)}g/día). Añade grasas monoinsaturadas (aguacate, aceite de oliva, frutos secos) para salud hormonal.'
            : 'Consumo de grasas perfectamente balanceado con tu meta diaria.';

    final protDiag = protDelta < -10
        ? 'Déficit proteico de ${(-protDelta).toStringAsFixed(1)}g/día frente a tu meta (${goals.protein.round()}g). Aumentar fuentes magras preservará tu masa muscular.'
        : protDelta > 15
            ? 'Excelente aporte proteico (+${protDelta.toStringAsFixed(1)}g/día), ideal para saciedad y recuperación muscular.'
            : 'Aporte de proteínas dentro del rango óptimo para tus requerimientos.';

    final carbsDiag = carbsDelta > 20
        ? 'Carbohidratos por encima de la meta (+${carbsDelta.toStringAsFixed(1)}g). Modera azúcares añadidos y opta por carbohidratos complejos altos en fibra.'
        : carbsDelta < -25
            ? 'Consumo de carbohidratos bajo (-${(-carbsDelta).toStringAsFixed(1)}g). Asegura suficiente energía para tu actividad física diaria.'
            : 'Balance de carbohidratos adecuado para mantener energía constante.';

    final calDiag = calDelta.abs() < 100
        ? 'Balance calórico en punto exacto: promedio de ${avgCal.round()} kcal frente a meta de ${goals.calories.round()} kcal.'
        : calDelta > 0
            ? 'Superávit calórico promedio de +${calDelta.round()} kcal/día respecto a tu presupuesto metabólico.'
            : 'Déficit calórico promedio de -${(-calDelta).round()} kcal/día.';

    final fatSwaps = [
      const FoodSwapSuggestion(
        originalFood: 'Carnes grasas o frituras',
        substituteFood: 'Pechuga de pollo, pavo o lomo de atún a la plancha',
        rationale: 'Reduce hasta 14g de grasa saturada y aporta 35g de proteína magra.',
        fatSavedGrams: 14.0,
        proteinGainedGrams: 10.0,
      ),
      const FoodSwapSuggestion(
        originalFood: 'Salsas cremosas y mayonesa',
        substituteFood: 'Yogur griego natural con especias, mostaza Dijon o limón',
        rationale: 'Ahorro de ~10g de grasa por porción manteniendo textura y sabor.',
        fatSavedGrams: 10.0,
        proteinGainedGrams: 4.0,
      ),
    ];

    final protSwaps = [
      const FoodSwapSuggestion(
        originalFood: 'Snacks procesados o bollería',
        substituteFood: 'Queso fresco batido / requesón con un puñado de nueces',
        rationale: 'Añade 20g de proteína de absorción lenta y grasas cardioprotectoras.',
        fatSavedGrams: 5.0,
        proteinGainedGrams: 18.0,
      ),
      const FoodSwapSuggestion(
        originalFood: 'Huevos enteros en exceso',
        substituteFood: '1 huevo entero + 3 claras pasteurizadas',
        rationale: 'Maximiza el volumen proteico (20g) eliminando 10g de grasa saturada.',
        fatSavedGrams: 10.0,
        proteinGainedGrams: 8.0,
      ),
    ];

    return NutritionalAnalysisReport(
      daysAnalyzed: days,
      mealsLogged: meals.length,
      averageDailyCalories: avgCal,
      averageDailyProtein: avgProt,
      averageDailyCarbs: avgCarbs,
      averageDailyFat: avgFat,
      targetCalories: goals.calories,
      targetProtein: goals.protein,
      targetCarbs: goals.carbs,
      targetFat: goals.fat,
      fatDiagnosis: fatDiag,
      proteinDiagnosis: protDiag,
      carbsDiagnosis: carbsDiag,
      calorieDiagnosis: calDiag,
      fatReductionSwaps: fatSwaps,
      proteinIncreaseSuggestions: protSwaps,
      suggestedPlates: _generateCandidateDishes(goals.calories * 0.35, goals.protein * 0.35),
    );
  }

  @override
  Future<TodayRecommendationPlan> getWhatShouldIEatToday({DateTime? date}) async {
    final targetDate = date ?? DateTime.now();
    final todayMeals = await _db.getMealsForDay(targetDate);
    final goals = await _resolveGoals();

    double cUsed = 0, pUsed = 0, carbUsed = 0, fUsed = 0;
    for (final m in todayMeals) {
      cUsed += m.calories;
      pUsed += m.protein;
      carbUsed += m.carbs;
      fUsed += m.fat;
    }

    final remCal = max(0.0, goals.calories - cUsed);
    final remProt = max(0.0, goals.protein - pUsed);
    final remCarbs = max(0.0, goals.carbs - carbUsed);
    final remFat = max(0.0, goals.fat - fUsed);

    // Determine logical next meal type
    final hour = DateTime.now().hour;
    final loggedTypes = todayMeals.map((m) => m.mealType).toSet();
    final String nextMeal;
    if (!loggedTypes.contains('Desayuno') && hour < 11) {
      nextMeal = 'Desayuno';
    } else if (!loggedTypes.contains('Almuerzo') && hour < 16) {
      nextMeal = 'Almuerzo';
    } else if (!loggedTypes.contains('Cena') && hour >= 18) {
      nextMeal = 'Cena';
    } else {
      nextMeal = 'Snack / Merienda';
    }

    final advice = remProt > 30 && remFat < 15
        ? 'Te faltan ${remProt.round()}g de proteína y poco margen de grasas (${remFat.round()}g). Enfócate en proteínas magras y claras.'
        : remCal < 350
            ? 'Te quedan solo ${remCal.round()} kcal. Elige opciones voluminosas de baja densidad como ensaladas con proteína.'
            : 'Tienes un margen de ${remCal.round()} kcal y ${remProt.round()}g de proteína. Distribúyelos con carbohidratos complejos.';

    final candidates = _generateCandidateDishes(remCal, remProt);

    return TodayRecommendationPlan(
      remainingCalories: remCal,
      remainingProtein: remProt,
      remainingCarbs: remCarbs,
      remainingFat: remFat,
      nextMealType: nextMeal,
      generalAdvice: advice,
      recommendedOptions: candidates,
    );
  }

  List<RecommendedDish> _generateCandidateDishes(double targetCal, double targetProt) {
    final catalog = [
      const RecommendedDish(
        id: 'rec_chicken_quinoa',
        name: 'Pechuga de Pollo con Quinoa y Espárragos',
        mealType: 'Almuerzo',
        calories: 420.0,
        protein: 44.0,
        carbs: 38.0,
        fat: 7.0,
        description: 'Pechuga a la plancha aderezada con hierbas, quinoa cocida y espárragos.',
        ingredients: ['Pechuga de pollo (160g)', 'Quinoa cocida (120g)', 'Espárragos verdes (100g)', 'Aceite de oliva (3g)'],
        whyRecommended: 'Alta densidad proteica con mínimo contenido graso, ideal para cerrar la brecha de proteína.',
        fitScore: 98,
      ),
      const RecommendedDish(
        id: 'rec_egg_whites_spinach',
        name: 'Omelette de Claras con Espinacas y Tostada Integral',
        mealType: 'Cena',
        calories: 285.0,
        protein: 30.0,
        carbs: 22.0,
        fat: 5.0,
        description: '4 claras y 1 huevo entero con espinacas baby y pan de centeno integral.',
        ingredients: ['Claras de huevo (120g)', 'Huevo entero (1 ud)', 'Espinacas frescas (80g)', 'Pan integral (40g)'],
        whyRecommended: 'Muy bajo en grasa (5g) y digestión ligera, perfecto para cenar y saciarte.',
        fitScore: 94,
      ),
      const RecommendedDish(
        id: 'rec_greek_yogurt_berries',
        name: 'Bowl Proteico de Yogur Griego y Arándanos',
        mealType: 'Snack / Merienda',
        calories: 210.0,
        protein: 23.0,
        carbs: 20.0,
        fat: 3.0,
        description: 'Yogur griego 0% materia grasa con frutos rojos antioxidantes y canela.',
        ingredients: ['Yogur griego desnatado (200g)', 'Arándanos frescos (70g)', 'Semillas de chía (5g)', 'Canela al gusto'],
        whyRecommended: 'Aporte rápido de proteína sin grasas saturadas con antioxidantes.',
        fitScore: 92,
      ),
      const RecommendedDish(
        id: 'rec_tuna_salad',
        name: 'Ensalada Mediterránea de Atún al Natural y Lentejas',
        mealType: 'Almuerzo',
        calories: 380.0,
        protein: 38.0,
        carbs: 35.0,
        fat: 6.0,
        description: 'Lentejas cocidas, atún al natural, tomate cherry, pepino y vinagreta suave.',
        ingredients: ['Atún al natural (120g)', 'Lentejas cocidas (100g)', 'Tomate cherry (80g)', 'Pepino (60g)', 'Aceite de oliva (4g)'],
        whyRecommended: 'Excelente combinación de proteína limpia y fibra saciante para control de glucemia.',
        fitScore: 96,
      ),
    ];

    return catalog;
  }
}
