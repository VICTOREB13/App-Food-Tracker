import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/services/gemini_resilience_helper.dart';

void main() {
  group('Ingredient Substitution Prompt Tests', () {
    test('builds accurate user prompt with items and substitution', () {
      final prompt = GeminiResilienceHelper.buildSubstitutionUserPrompt(
        currentItemsSummary: [
          'Arroz blanco (150g - 195 kcal)',
          'Mortadela (60g - 180 kcal)',
          'Plátano maduro frito (80g - 210 kcal)',
        ],
        oldIngredient: 'Mortadela',
        newIngredient: 'Jamón de pavo bajo en sodio',
        userNotes: 'Sustituí el embutido por pechuga de pavo horneada',
        dishwareDiameterCm: 26.0,
      );

      expect(prompt, contains("El comensal corrigió el ingrediente 'Mortadela' por 'Jamón de pavo bajo en sodio'."));
      expect(prompt, contains('Conserva el volumen y la distribución espacial de la foto'));
      expect(prompt, contains('recalcula los macronutrientes y micronutrientes específicos'));
      expect(prompt, contains('26.0 cm de diámetro'));
      expect(prompt, contains('- Arroz blanco (150g - 195 kcal)'));
      expect(prompt, contains('- Mortadela (60g - 180 kcal)'));
      expect(prompt, contains('Notas del comensal: Sustituí el embutido por pechuga de pavo horneada'));
    });

    test('builds substitution prompt without optional dishware and notes', () {
      final prompt = GeminiResilienceHelper.buildSubstitutionUserPrompt(
        currentItemsSummary: [
          'Huevo frito (50g - 90 kcal)',
        ],
        oldIngredient: 'Huevo frito',
        newIngredient: 'Tofu revuelto',
      );

      expect(prompt, contains("El comensal corrigió el ingrediente 'Huevo frito' por 'Tofu revuelto'."));
      expect(prompt, contains('- Huevo frito (50g - 90 kcal)'));
      expect(prompt, isNot(contains('Escala métrica de referencia del plato')));
      expect(prompt, isNot(contains('Notas del comensal')));
    });
  });
}
