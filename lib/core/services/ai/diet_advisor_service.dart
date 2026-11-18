import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:food_tracker/core/database/database_service.dart';
import 'package:food_tracker/core/interfaces/database_service_interface.dart';
import 'package:food_tracker/core/interfaces/diet_advisor_service_interface.dart';
import 'package:food_tracker/core/models/models.dart';
import 'package:food_tracker/core/services/ai/gemini_rest_client.dart';
import 'package:food_tracker/core/services/storage/secure_storage_service.dart';

/// Clinical Diet Pattern Recommendation Engine powered by Gemini AI.
/// Analyzes longitudinal nutritional patterns (7, 14, 30 days) from SQLite and generates
/// actionable diagnostics, visual hand menus, and practical food swaps.
class DietAdvisorService implements IDietAdvisorService {
  final IDatabaseService _db;
  final SecureStorageService _storage;
  final GeminiRestClient _restClient;

  static DietAdvisorService? _mockInstance;
  static final DietAdvisorService _defaultInstance = DietAdvisorService();
  static DietAdvisorService get instance => _mockInstance ?? _defaultInstance;

  @visibleForTesting
  static void setMockInstance(DietAdvisorService? mock) => _mockInstance = mock;

  DietAdvisorService({
    IDatabaseService? dbService,
    SecureStorageService? storageService,
    GeminiRestClient? restClient,
  })  : _db = dbService ?? DatabaseService.instance,
        _storage = storageService ?? SecureStorageService.instance,
        _restClient = restClient ?? GeminiRestClient.instance;

  final Map<int, ({DietPatternInsight insight, DateTime time})> _cacheMap = {};

  @override
  Future<DietPatternInsight> getDietPatternInsights({
    int days = 7,
    bool forceRefresh = false,
  }) async {
    final now = DateTime.now();
    final cached = _cacheMap[days];
    if (!forceRefresh &&
        cached != null &&
        now.difference(cached.time).inMinutes < 60) {
      return cached.insight;
    }

    try {
      final start = DateTime(now.year, now.month, now.day).subtract(Duration(days: days));
      final end = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final meals = await _db.getMealsByRange(start, end);
      final profile = await _db.getUserProfile();

      if (meals.isEmpty) {
        final fallback = DietPatternInsight.fallback(days: days);
        _cache(fallback, days);
        return fallback;
      }

      final apiKey = await _storage.getGeminiApiKey();
      if (apiKey == null || apiKey.trim().isEmpty) {
        final fallback = DietPatternInsight.fallback(days: days);
        _cache(fallback, days);
        return fallback;
      }

      final model = await _storage.getSelectedGeminiModel() ?? 'gemini-3.8-flash';
      final summary = _computeMetricsSummary(meals, days, profile);
      final prompt = _buildAdvisorPrompt(summary, days, profile);

      final responseText = await _restClient.generateContent(
        apiKey: apiKey.trim(),
        model: model,
        contents: [
          {
            'role': 'user',
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        generationConfig: {
          'temperature': 0.3,
          'maxOutputTokens': 4096,
          'responseMimeType': 'application/json',
        },
        timeout: const Duration(seconds: 40),
      );

      final insight = _parseInsightResponse(responseText, days);
      _cache(insight, days);
      return insight;
    } catch (e) {
      debugPrint('DietAdvisorService: Error analyzing patterns ($e), using deterministic fallback');
      final fallback = DietPatternInsight.fallback(days: days);
      _cache(fallback, days);
      return fallback;
    }
  }

  void _cache(DietPatternInsight insight, int days) {
    _cacheMap[days] = (insight: insight, time: DateTime.now());
  }

  String _computeMetricsSummary(List<Meal> meals, int days, UserProfile? profile) {
    double totalCal = 0, totalProt = 0, totalCarbs = 0, totalFat = 0;
    double totalFiber = 0, totalSodium = 0, totalSugar = 0;
    final dishFrequencies = <String, int>{};
    final loggedDates = <String>{};

    for (final m in meals) {
      loggedDates.add(m.date.toIso8601String().substring(0, 10));
      totalCal += m.calories;
      totalProt += m.protein;
      totalCarbs += m.carbs;
      totalFat += m.fat;
      totalFiber += m.fiber;
      totalSodium += m.sodium;
      totalSugar += m.sugar;
      dishFrequencies[m.name] = (dishFrequencies[m.name] ?? 0) + 1;
    }

    final divisor = loggedDates.isNotEmpty ? loggedDates.length : days;
    final topDishes = dishFrequencies.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final dishListStr = topDishes.take(5).map((e) => '${e.key} (${e.value}x)').join(', ');

    return '''
Días con registros: ${loggedDates.length} de $days días.
Promedios diarios:
- Calorías: ${(totalCal / divisor).toStringAsFixed(0)} kcal (Meta: ${profile?.targetCalories.toStringAsFixed(0) ?? 'N/A'})
- Proteínas: ${(totalProt / divisor).toStringAsFixed(1)} g (Meta: ${profile?.targetProtein.toStringAsFixed(0) ?? 'N/A'})
- Carbohidratos: ${(totalCarbs / divisor).toStringAsFixed(1)} g (Meta: ${profile?.targetCarbs.toStringAsFixed(0) ?? 'N/A'})
- Grasas: ${(totalFat / divisor).toStringAsFixed(1)} g (Meta: ${profile?.targetFat.toStringAsFixed(0) ?? 'N/A'})
- Fibra promedio: ${(totalFiber / divisor).toStringAsFixed(1)} g/día
- Sodio promedio: ${(totalSodium / divisor).toStringAsFixed(0)} mg/día
- Azúcar promedio: ${(totalSugar / divisor).toStringAsFixed(1)} g/día
Platos más frecuentes: $dishListStr.
''';
  }

  String _buildAdvisorPrompt(String metricsSummary, int days, UserProfile? profile) {
    final goal = profile?.bodyGoal ?? 'mantenimiento';
    return '''
Eres un nutricionista clínico experto en análisis de patrones alimentarios cotidianos.
Analiza el historial nutricional del comensal de los últimos $days días:

$metricsSummary

Objetivo del comensal: $goal.

Responde ÚNICAMENTE en JSON válido con este esquema exacto:
{
  "days_analyzed": $days,
  "fat_insight": "Diagnóstico de grasas, aceites y frituras, balance de saturadas vs insaturadas.",
  "protein_insight": "Diagnóstico proteico respecto a masa muscular y saciedad para $goal.",
  "fiber_insight": "Diagnóstico de fibra vegetal, granos y saciedad digestiva.",
  "sodium_insight": "Diagnóstico de sodio, quesos, embutidos y alimentos procesados.",
  "visual_hand_menu": [
    "Desayuno: [Alimento (palma/puño/pulgar)]",
    "Almuerzo: [Alimento (palma/puño/pulgar)]",
    "Cena: [Alimento (palma/puño/pulgar)]"
  ],
  "suggested_swaps": [
    "Sustitución 1 adaptada a alimentos locales accesibles",
    "Sustitución 2 de snack práctico y económico"
  ],
  "general_summary": "Resumen clínico claro y conciso de los hábitos observados."
}
''';
  }

  DietPatternInsight _parseInsightResponse(String responseText, int days) {
    try {
      var cleaned = responseText.trim();
      final fence = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```').firstMatch(cleaned);
      if (fence != null) {
        cleaned = fence.group(1)!.trim();
      } else {
        final b1 = cleaned.indexOf('{');
        final b2 = cleaned.lastIndexOf('}');
        if (b1 != -1 && b2 > b1) {
          cleaned = cleaned.substring(b1, b2 + 1).trim();
        }
      }
      final decoded = jsonDecode(cleaned) as Map<String, dynamic>;
      return DietPatternInsight.fromJson(decoded);
    } catch (_) {
      try {
        final repaired = JsonRepairHelper.repair(responseText);
        final decoded = jsonDecode(repaired) as Map<String, dynamic>;
        return DietPatternInsight.fromJson(decoded);
      } catch (_) {
        return DietPatternInsight.fallback(days: days);
      }
    }
  }
}
