import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/models/pantry_item.dart';
import 'package:food_tracker/services/daos/database_schema.dart';
import 'package:food_tracker/services/daos/pantry_dao.dart';
import 'package:food_tracker/services/gemini_resilience_helper.dart';
import 'package:food_tracker/services/gemini_vision_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Pantry Prompt Context Tests', () {
    late Database db;
    late PantryDao pantryDao;

    setUp(() async {
      db = await databaseFactory.openDatabase(inMemoryDatabasePath);
      await DatabaseSchema.createPantryTable(db);
      pantryDao = PantryDao(() async => db);
    });

    tearDown(() async {
      await db.close();
    });

    test('returns empty string when pantry is empty', () async {
      final context = await pantryDao.getPantryPromptContext();
      expect(context, isEmpty);
    });

    test('formats pantry items into compact prompt context string', () async {
      await pantryDao.insertPantryItem(PantryItem(
        id: 'p1',
        name: 'Harina PAN',
        brand: 'Empresas Polar',
        calories: 365,
        protein: 7,
        carbs: 78,
        fat: 1.5,
        servingSize: 100,
        servingUnit: 'g',
        matchKeywords: 'arepa, masa',
      ));

      await pantryDao.insertPantryItem(PantryItem(
        id: 'p2',
        name: 'Avena en Hojuelas',
        brand: 'Quaker',
        calories: 370,
        protein: 13,
        carbs: 66,
        fat: 7,
        servingSize: 100,
        servingUnit: 'g',
      ));

      final context = await pantryDao.getPantryPromptContext();

      expect(context, startsWith('Despensa del usuario: '));
      expect(context, contains('Empresas Polar - Harina PAN (365 kcal/100g, P: 7.0g, C: 78.0g, F: 1.5g | arepa, masa)'));
      expect(context, contains('Quaker - Avena en Hojuelas (370 kcal/100g, P: 13.0g, C: 66.0g, F: 7.0g)'));
    });

    test('GeminiResilienceHelper injects pantry context into system prompt', () {
      const pantrySnippet = 'Despensa del usuario: Harina PAN (365 kcal/100g)';
      final systemPrompt = GeminiResilienceHelper.buildSystemPrompt(
        masterPrompt: 'Objetivo: Déficit calórico',
        pantryContext: pantrySnippet,
      );

      expect(systemPrompt, contains('--- DESPENSA Y MARCAS PERSONALES DEL COMENSAL ---'));
      expect(systemPrompt, contains(pantrySnippet));
      expect(systemPrompt, contains('utiliza prioritariamente los valores y proporciones de su despensa personal'));
    });

    test('GeminiVisionService builds system instruction with pantry context', () {
      const pantrySnippet = 'Despensa del usuario: Avena Quaker';
      final instruction = GeminiVisionService.buildSystemInstruction(
        null,
        pantrySnippet,
      );

      expect(instruction, contains('--- DESPENSA Y MARCAS PERSONALES DEL COMENSAL ---'));
      expect(instruction, contains(pantrySnippet));
    });
  });
}
