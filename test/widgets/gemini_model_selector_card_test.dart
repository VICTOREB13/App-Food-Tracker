import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/models/gemini_model_info.dart';
import 'package:food_tracker/widgets/settings/gemini_model_selector_card.dart';

void main() {
  const sampleModels = [
    GeminiModelInfo(
      name: 'gemini-2.5-flash',
      displayName: 'Gemini 2.5 Flash',
      description: 'Ultrarrápido y recomendado para comidas caseras',
      isRecommended: true,
      recommendationLabel: 'RECOMENDADO (Ultrarrápido)',
      inputTokenLimit: 1048576,
    ),
    GeminiModelInfo(
      name: 'gemini-2.0-flash',
      displayName: 'Gemini 2.0 Flash',
      description: 'Estable y probado en producción',
      isRecommended: true,
      recommendationLabel: 'ESTABLE (Alta Velocidad)',
      inputTokenLimit: 1048576,
    ),
    GeminiModelInfo(
      name: 'gemini-2.5-pro',
      displayName: 'Gemini 2.5 Pro',
      description: 'Máxima precisión con razonamiento profundo',
      isRecommended: true,
      recommendationLabel: 'MÁXIMA PRECISIÓN (Razonamiento)',
      inputTokenLimit: 2097152,
    ),
  ];

  Widget buildWidget({
    String? apiKey,
    String? selectedModel,
    List<GeminiModelInfo>? models,
    bool isLoading = false,
    bool isOnline = false,
    ValueChanged<String>? onSelectModel,
    Future<void> Function()? onRefresh,
  }) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: GeminiModelSelectorCard(
            apiKey: apiKey,
            selectedModel: selectedModel,
            models: models,
            isLoading: isLoading,
            isOnline: isOnline,
            onSelectModel: onSelectModel,
            onRefresh: onRefresh,
          ),
        ),
      ),
    );
  }

  group('GeminiModelSelectorCard Widget Tests', () {
    testWidgets('Muestra banner informativo cuando la API Key no está configurada', (tester) async {
      await tester.pumpWidget(buildWidget(apiKey: null));
      await tester.pumpAndSettle();

      expect(
        find.text('Ingresa tu Gemini API Key para descubrir y seleccionar modelos'),
        findsOneWidget,
      );
      expect(find.text('MODELO DE IA (VISIÓN)'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsNothing);
      expect(find.byIcon(Icons.refresh), findsNothing);
    });

    testWidgets('Muestra modelos en línea y badges semánticos cuando hay API Key y conexión', (tester) async {
      await tester.pumpWidget(buildWidget(
        apiKey: 'AIzaSyValidKey',
        isOnline: true,
        selectedModel: 'gemini-2.5-flash',
        models: sampleModels,
      ));
      await tester.pumpAndSettle();

      // Verifica estado online
      expect(find.text('Modelos en línea desde Google AI Studio'), findsOneWidget);

      // Verifica título y selector
      expect(find.text('MODELO DE IA (VISIÓN)'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);

      // Verifica presencia del badge recomendado en la tarjeta activa
      expect(find.text('RECOMENDADO (Ultrarrápido)'), findsWidgets);
      expect(find.text('ID: gemini-2.5-flash'), findsOneWidget);
      expect(find.text('Ultrarrápido y recomendado para comidas caseras'), findsOneWidget);
    });

    testWidgets('Muestra estado offline cuando isOnline es false', (tester) async {
      await tester.pumpWidget(buildWidget(
        apiKey: 'AIzaSyValidKey',
        isOnline: false,
        selectedModel: 'gemini-2.0-flash',
        models: sampleModels,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Modo offline (modelos por defecto)'), findsOneWidget);
      expect(find.text('ESTABLE (Alta Velocidad)'), findsWidgets);
      expect(find.text('ID: gemini-2.0-flash'), findsOneWidget);
    });

    testWidgets('Muestra indicador de carga cuando isLoading es true', (tester) async {
      await tester.pumpWidget(buildWidget(
        apiKey: 'AIzaSyValidKey',
        isLoading: true,
        models: sampleModels,
      ));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsNothing);
    });

    testWidgets('Invocación de onRefresh al presionar botón de actualizar', (tester) async {
      bool refreshed = false;

      await tester.pumpWidget(buildWidget(
        apiKey: 'AIzaSyValidKey',
        models: sampleModels,
        onRefresh: () async {
          refreshed = true;
        },
      ));
      await tester.pumpAndSettle();

      final refreshBtn = find.byIcon(Icons.refresh);
      expect(refreshBtn, findsOneWidget);

      await tester.tap(refreshBtn);
      await tester.pumpAndSettle();

      expect(refreshed, isTrue);
    });

    testWidgets('Seleccionar modelo distinto en dropdown invoca callback onSelectModel', (tester) async {
      String? selected;

      await tester.pumpWidget(buildWidget(
        apiKey: 'AIzaSyValidKey',
        selectedModel: 'gemini-2.5-flash',
        models: sampleModels,
        onSelectModel: (val) => selected = val,
      ));
      await tester.pumpAndSettle();

      // Abrir dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      // Seleccionar gemini-2.5-pro
      final proOption = find.text('Gemini 2.5 Pro').last;
      await tester.tap(proOption);
      await tester.pumpAndSettle();

      expect(selected, equals('gemini-2.5-pro'));
    });

    testWidgets('Abrir ModelPickerBottomSheet al presionar Explorar y Cambiar Modelo', (tester) async {
      await tester.pumpWidget(buildWidget(
        apiKey: 'AIzaSyValidKey',
        selectedModel: 'gemini-2.5-flash',
        models: sampleModels,
      ));
      await tester.pumpAndSettle();

      final openPickerBtn = find.text('Explorar y Cambiar Modelo');
      expect(openPickerBtn, findsOneWidget);

      await tester.tap(openPickerBtn);
      await tester.pumpAndSettle();

      expect(find.text('Seleccionar Modelo Gemini'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Todos'), findsOneWidget);
      expect(find.text('Flash (Rápidos)'), findsOneWidget);
      expect(find.text('Pro (Razonamiento)'), findsOneWidget);
    });
  });
}

