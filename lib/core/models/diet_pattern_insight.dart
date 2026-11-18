import 'package:flutter/foundation.dart';
import 'package:food_tracker/core/models/model_sanitizer.dart';

/// Structured longitudinal diet pattern audit returned by Gemini AI.
@immutable
class DietPatternInsight {
  final int daysAnalyzed;
  final String fatInsight;
  final String proteinInsight;
  final String fiberInsight;
  final String sodiumInsight;
  final List<String> visualHandMenu;
  final List<String> suggestedSwaps;
  final String generalSummary;
  final DateTime analyzedAt;

  const DietPatternInsight({
    required this.daysAnalyzed,
    required this.fatInsight,
    required this.proteinInsight,
    required this.fiberInsight,
    required this.sodiumInsight,
    required this.visualHandMenu,
    required this.suggestedSwaps,
    required this.generalSummary,
    required this.analyzedAt,
  });

  DietPatternInsight copyWith({
    int? daysAnalyzed,
    String? fatInsight,
    String? proteinInsight,
    String? fiberInsight,
    String? sodiumInsight,
    List<String>? visualHandMenu,
    List<String>? suggestedSwaps,
    String? generalSummary,
    DateTime? analyzedAt,
  }) {
    return DietPatternInsight(
      daysAnalyzed: daysAnalyzed ?? this.daysAnalyzed,
      fatInsight: fatInsight ?? this.fatInsight,
      proteinInsight: proteinInsight ?? this.proteinInsight,
      fiberInsight: fiberInsight ?? this.fiberInsight,
      sodiumInsight: sodiumInsight ?? this.sodiumInsight,
      visualHandMenu: visualHandMenu ?? this.visualHandMenu,
      suggestedSwaps: suggestedSwaps ?? this.suggestedSwaps,
      generalSummary: generalSummary ?? this.generalSummary,
      analyzedAt: analyzedAt ?? this.analyzedAt,
    );
  }

  factory DietPatternInsight.fallback({int days = 7}) => DietPatternInsight(
        daysAnalyzed: days,
        fatInsight:
            'Prioriza grasas insaturadas (aguacate, aceite de oliva en crudo) y modera aceites de freír y frituras.',
        proteinInsight:
            'Asegura una porción del tamaño de la palma de la mano de proteína magra en cada comida principal.',
        fiberInsight:
            'Incrementa la ingesta de vegetales de hoja verde y legumbres para alcanzar la meta de 25-30g de fibra.',
        sodiumInsight:
            'Modera embutidos y quesos muy curados; sazona con hierbas aromáticas y especias.',
        visualHandMenu: const [
          'Desayuno: 2 huevos (palma) + 1 rebanada integral (puño) + 1/4 aguacate (pulgar)',
          'Almuerzo: Pechuga a la plancha (palma) + arroz integral (puño) + ensalada mixta (2 manos)',
          'Cena: Pescado blanco (palma) + verduras salteadas (2 manos) + 1 cdta aceite de oliva (pulgar)',
        ],
        suggestedSwaps: const [
          'Cambia embutidos grasos por pechuga de pavo horneada o lomo de atún.',
          'Sustituye mayonesa comercial por yogur griego con limón y hierbas.',
          'Opta por fruta fresca entera en lugar de jugos procesados.',
        ],
        generalSummary:
            'Tus patrones muestran una buena base. Ajustando el equilibrio de grasas y maximizando la proteína por porción alcanzarás tus objetivos.',
        analyzedAt: DateTime.now(),
      );

  factory DietPatternInsight.fromJson(Map<String, dynamic> json) {
    List<String> parseList(dynamic val) {
      if (val is List) {
        return val.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
      }
      if (val is String && val.trim().isNotEmpty) {
        return [val.trim()];
      }
      return const [];
    }

    return DietPatternInsight(
      daysAnalyzed: json['days_analyzed'] is int
          ? json['days_analyzed'] as int
          : (int.tryParse(json['days_analyzed']?.toString() ?? '') ?? 7),
      fatInsight: json['fat_insight']?.toString() ?? '',
      proteinInsight: json['protein_insight']?.toString() ?? '',
      fiberInsight: json['fiber_insight']?.toString() ?? '',
      sodiumInsight: json['sodium_insight']?.toString() ?? '',
      visualHandMenu: parseList(json['visual_hand_menu']),
      suggestedSwaps: parseList(json['suggested_swaps']),
      generalSummary: json['general_summary']?.toString() ?? '',
      analyzedAt: ModelSanitizer.parseDate(json['analyzed_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'days_analyzed': daysAnalyzed,
        'fat_insight': fatInsight,
        'protein_insight': proteinInsight,
        'fiber_insight': fiberInsight,
        'sodium_insight': sodiumInsight,
        'visual_hand_menu': visualHandMenu,
        'suggested_swaps': suggestedSwaps,
        'general_summary': generalSummary,
        'analyzed_at': analyzedAt.toIso8601String(),
      };
}
