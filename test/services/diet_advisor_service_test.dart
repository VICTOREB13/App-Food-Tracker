import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:food_tracker/core/database/daos/database_schema.dart';
import 'package:food_tracker/core/database/database_service.dart';
import 'package:food_tracker/core/models/diet_pattern_insight.dart';
import 'package:food_tracker/core/services/ai/diet_advisor_service.dart';
import 'package:food_tracker/core/services/ai/gemini_rest_client.dart';
import 'package:food_tracker/core/services/storage/secure_storage_service.dart';
import 'package:food_tracker/features/dashboard/services/nutritional_recommendation_service.dart';
import 'package:food_tracker/features/food_entry/models/meal.dart';
import 'package:food_tracker/features/settings_profile/models/user_profile.dart';

class _FakeSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> data = {};
  @override
  Future<String?> read({required String key, AppleOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, AppleOptions? mOptions, WindowsOptions? wOptions}) async => data[key];
  @override
  Future<void> write({required String key, required String? value, AppleOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, AppleOptions? mOptions, WindowsOptions? wOptions}) async {
    if (value != null) { data[key] = value; } else { data.remove(key); }
  }
  @override
  Future<void> delete({required String key, AppleOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, AppleOptions? mOptions, WindowsOptions? wOptions}) async => data.remove(key);
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late _FakeSecureStorage fakeStorage;
  late SecureStorageService storageService;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 3,
        onCreate: (db, version) async {
          await DatabaseSchema.createAllTables(db);
        },
      ),
    );
    DatabaseService.instance.setDatabaseForTesting(db);

    fakeStorage = _FakeSecureStorage();
    storageService = SecureStorageService.withStorage(fakeStorage);
    SecureStorageService.setMockInstance(storageService);
  });

  tearDown(() async {
    await DatabaseService.instance.closeForTesting();
    SecureStorageService.resetInstance();
    DietAdvisorService.setMockInstance(null);
  });

  group('DietPatternInsight Model Tests', () {
    test('toJson and fromJson roundtrip preserves all clinical fields', () {
      final now = DateTime(2026, 11, 17, 20, 0, 0);
      final insight = DietPatternInsight(
        daysAnalyzed: 14,
        fatInsight: 'Grasas bien equilibradas.',
        proteinInsight: 'Excelente aporte de proteína magra.',
        fiberInsight: 'Incrementar legumbres.',
        sodiumInsight: 'Sodio dentro de límites.',
        visualHandMenu: const ['Desayuno: 2 huevos + avena', 'Almuerzo: Salmón con quinoa'],
        suggestedSwaps: const ['Cambiar patatas fritas por boniato asado'],
        generalSummary: 'Patrón mediterráneo óptimo.',
        analyzedAt: now,
      );

      final json = insight.toJson();
      expect(json['days_analyzed'], equals(14));
      expect(json['fat_insight'], equals('Grasas bien equilibradas.'));
      expect(json['visual_hand_menu'], hasLength(2));
      expect(json['suggested_swaps'], hasLength(1));

      final restored = DietPatternInsight.fromJson(json);
      expect(restored.daysAnalyzed, equals(14));
      expect(restored.fatInsight, equals(insight.fatInsight));
      expect(restored.proteinInsight, equals(insight.proteinInsight));
      expect(restored.fiberInsight, equals(insight.fiberInsight));
      expect(restored.sodiumInsight, equals(insight.sodiumInsight));
      expect(restored.visualHandMenu, equals(insight.visualHandMenu));
      expect(restored.suggestedSwaps, equals(insight.suggestedSwaps));
      expect(restored.generalSummary, equals(insight.generalSummary));
    });

    test('fallback factory produces comprehensive safe defaults', () {
      final fallback = DietPatternInsight.fallback(days: 30);
      expect(fallback.daysAnalyzed, equals(30));
      expect(fallback.fatInsight.isNotEmpty, isTrue);
      expect(fallback.proteinInsight.isNotEmpty, isTrue);
      expect(fallback.fiberInsight.isNotEmpty, isTrue);
      expect(fallback.sodiumInsight.isNotEmpty, isTrue);
      expect(fallback.visualHandMenu.isNotEmpty, isTrue);
      expect(fallback.suggestedSwaps.isNotEmpty, isTrue);
      expect(fallback.generalSummary.isNotEmpty, isTrue);
    });

    test('copyWith updates specified fields and preserves existing values', () {
      final original = DietPatternInsight.fallback(days: 7);
      final updated = original.copyWith(
        daysAnalyzed: 14,
        fatInsight: 'Grasas actualizadas.',
        visualHandMenu: ['Desayuno nuevo'],
      );
      expect(updated.daysAnalyzed, equals(14));
      expect(updated.fatInsight, equals('Grasas actualizadas.'));
      expect(updated.visualHandMenu, equals(['Desayuno nuevo']));
      expect(updated.proteinInsight, equals(original.proteinInsight));
      expect(updated.fiberInsight, equals(original.fiberInsight));
      expect(updated.generalSummary, equals(original.generalSummary));
    });
  });

  group('DietAdvisorService Unit Tests', () {
    test('returns deterministic fallback when meals are empty', () async {
      final service = DietAdvisorService(
        dbService: DatabaseService.instance,
        storageService: storageService,
      );

      final insight = await service.getDietPatternInsights(days: 7);
      expect(insight.daysAnalyzed, equals(7));
      expect(insight.visualHandMenu.length, greaterThanOrEqualTo(3));
    });

    test('returns deterministic fallback when API key is missing', () async {
      final now = DateTime.now();
      await DatabaseService.instance.insertMeal(
        Meal(
          id: 'meal_1',
          name: 'Pollo con arroz',
          mealType: 'Almuerzo',
          date: now,
          calories: 600,
          protein: 45,
          carbs: 65,
          fat: 15,
        ),
      );

      final service = DietAdvisorService(
        dbService: DatabaseService.instance,
        storageService: storageService,
      );

      final insight = await service.getDietPatternInsights(days: 7);
      expect(insight.daysAnalyzed, equals(7));
      expect(insight.generalSummary.isNotEmpty, isTrue);
    });

    test('queries Gemini AI and parses structured response correctly', () async {
      final now = DateTime.now();
      await DatabaseService.instance.saveUserProfile(
        UserProfile(
          name: 'Victor Test',
          age: 28,
          gender: 'male',
          height: 178,
          weight: 78,
          bmr: 1750,
          tdee: 2500,
          targetCalories: 2200,
          targetProtein: 150,
          targetCarbs: 220,
          targetFat: 70,
          bodyGoal: 'ganar_musculo',
        ),
      );

      await DatabaseService.instance.insertMeal(
        Meal(
          id: 'meal_1',
          name: 'Pechuga a la plancha con quinoa',
          mealType: 'Almuerzo',
          date: now,
          calories: 650,
          protein: 50,
          carbs: 60,
          fat: 18,
          fiber: 8,
          sodium: 450,
          sugar: 4,
        ),
      );

      await storageService.setGeminiApiKey('AIzaSyFakeKeyTest');

      final mockResponse = jsonEncode({
        'candidates': [
          {
            'content': {
              'parts': [
                {
                  'text': jsonEncode({
                    'days_analyzed': 7,
                    'fat_insight': 'Consumo óptimo de grasas insaturadas.',
                    'protein_insight': 'Excelente aporte proteico alineado a meta de hipertrofia.',
                    'fiber_insight': 'Fibra adecuada gracias a granos enteros.',
                    'sodium_insight': 'Sodio controlado bajo 2000mg.',
                    'visual_hand_menu': [
                      'Desayuno: Tortilla de 3 claras (palma) + avena (puño)',
                      'Almuerzo: Pechuga a la plancha (palma) + quinoa (puño) + ensalada (2 manos)',
                      'Cena: Salmón (palma) + brócoli (2 manos) + aceite de oliva (pulgar)',
                    ],
                    'suggested_swaps': [
                      'Sustituir aderezo comercial por vinagreta casera de limón y oliva.',
                    ],
                    'general_summary': 'Adherencia excelente a metas de composición corporal.',
                  })
                }
              ]
            }
          }
        ]
      });

      final mockHttp = MockClient((request) async {
        expect(request.url.toString(), contains('generativelanguage.googleapis.com'));
        return http.Response(mockResponse, 200, headers: {'content-type': 'application/json'});
      });

      final restClient = GeminiRestClient(client: mockHttp);
      final service = DietAdvisorService(
        dbService: DatabaseService.instance,
        storageService: storageService,
        restClient: restClient,
      );

      final insight = await service.getDietPatternInsights(days: 7);
      expect(insight.daysAnalyzed, equals(7));
      expect(insight.fatInsight, equals('Consumo óptimo de grasas insaturadas.'));
      expect(insight.proteinInsight, contains('hipertrofia'));
      expect(insight.visualHandMenu, hasLength(3));
      expect(insight.suggestedSwaps, hasLength(1));

      // Test multi-window caching: subsequent call returns identical object
      final cached = await service.getDietPatternInsights(days: 7);
      expect(identical(cached, insight), isTrue);

      // Multi-window cache: fetching 14 days does not evict 7 days cache
      await service.getDietPatternInsights(days: 14);
      final cached7Again = await service.getDietPatternInsights(days: 7);
      expect(identical(cached7Again, insight), isTrue);
    });

    test('parses conversational response without markdown fences via JsonRepairHelper', () async {
      final mockHttp = MockClient((request) async {
        const conversational = 'Claro, aquí tienes el análisis detallado:\n'
            '{"days_analyzed": 7, "fat_insight": "Grasas equilibradas.", "protein_insight": "Buena masa magra.", '
            '"fiber_insight": "Buena fibra.", "sodium_insight": "Sodio controlado.", '
            '"visual_hand_menu": ["Desayuno: Huevo (palma)"], "suggested_swaps": ["Swap 1"], '
            '"general_summary": "Excelente progreso."}\nEspero te sirva de ayuda.';
        return http.Response(jsonEncode({
          'candidates': [
            {'content': {'parts': [{'text': conversational}]}}
          ]
        }), 200, headers: {'content-type': 'application/json'});
      });

      final service = DietAdvisorService(
        dbService: DatabaseService.instance,
        storageService: storageService,
        restClient: GeminiRestClient(client: mockHttp),
      );
      final insight = await service.getDietPatternInsights(days: 7);
      expect(insight.daysAnalyzed, equals(7));
      expect(insight.fatInsight, equals('Grasas equilibradas.'));
      expect(insight.visualHandMenu, hasLength(1));
    });

    test('delegation through NutritionalRecommendationService works seamlessly', () async {
      final mockAdvisor = DietAdvisorService(
        dbService: DatabaseService.instance,
        storageService: storageService,
      );

      final recService = NutritionalRecommendationService(
        databaseService: DatabaseService.instance,
        storageService: storageService,
        dietAdvisorService: mockAdvisor,
      );

      final insight = await recService.getDietPatternInsights(days: 14);
      expect(insight.daysAnalyzed, equals(14));
      expect(insight.visualHandMenu.isNotEmpty, isTrue);
    });
  });
}
