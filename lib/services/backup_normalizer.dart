import 'dart:convert';
import 'dart:isolate';

/// Adaptive normalizer supporting legacy backups (v1.0.4 and prior) with translation of
/// Spanish keys, raw array wrapping, and background isolate execution.
class BackupNormalizer {
  /// Decodes and normalizes a backup JSON string into a standardized Map.
  /// Callable directly or via [Isolate.run].
  static Map<String, dynamic> decodeAndNormalize(String jsonString) {
    final dynamic decoded = json.decode(jsonString);

    if (decoded is List) {
      for (final element in decoded) {
        if (element is! Map) {
          throw const FormatException(
            'El archivo de respaldo no tiene el formato JSON esperado.',
          );
        }
      }
      return {
        'schema_version': 1,
        'export_date': DateTime.now().toIso8601String(),
        'meals': decoded
            .map((e) => _normalizeMealItem(Map<String, dynamic>.from(e as Map)))
            .toList(),
        'pantry_items': <Map<String, dynamic>>[],
        'weight_logs': <Map<String, dynamic>>[],
        'user_profile': null,
      };
    }

    if (decoded is! Map) {
      throw const FormatException(
        'El archivo de respaldo no tiene el formato JSON esperado.',
      );
    }

    final rawMap = Map<String, dynamic>.from(decoded);
    final normalized = <String, dynamic>{
      'app': rawMap['app'] ?? 'Victor Engineer Food Tracker',
      'version': rawMap['version'] ?? '2.0.0',
      'schema_version': rawMap['schema_version'] ?? 2,
      'export_date': rawMap['export_date'] ?? DateTime.now().toIso8601String(),
    };

    final rawMeals = rawMap['meals'] ??
        rawMap['comidas'] ??
        rawMap['registros'] ??
        rawMap['items'];
    if (rawMeals is List) {
      normalized['meals'] = rawMeals
          .whereType<Map>()
          .map((m) => _normalizeMealItem(Map<String, dynamic>.from(m)))
          .toList();
    } else {
      normalized['meals'] = <Map<String, dynamic>>[];
    }

    final rawPantry = rawMap['pantry_items'] ??
        rawMap['despensa'] ??
        rawMap['pantry'] ??
        rawMap['articulos_despensa'];
    if (rawPantry is List) {
      normalized['pantry_items'] = rawPantry
          .whereType<Map>()
          .map((m) => _normalizePantryItem(Map<String, dynamic>.from(m)))
          .toList();
    } else {
      normalized['pantry_items'] = <Map<String, dynamic>>[];
    }

    final rawWeights = rawMap['weight_logs'] ??
        rawMap['pesos'] ??
        rawMap['registros_peso'] ??
        rawMap['historial_peso'];
    if (rawWeights is List) {
      normalized['weight_logs'] = rawWeights
          .whereType<Map>()
          .map((m) => _normalizeWeightLog(Map<String, dynamic>.from(m)))
          .toList();
    } else {
      normalized['weight_logs'] = <Map<String, dynamic>>[];
    }

    final rawProfile = rawMap['user_profile'] ??
        rawMap['perfil'] ??
        rawMap['perfil_usuario'] ??
        rawMap['profile'];
    if (rawProfile is Map) {
      normalized['user_profile'] =
          _normalizeUserProfile(Map<String, dynamic>.from(rawProfile));
    } else {
      normalized['user_profile'] = null;
    }

    final rawTemplates = rawMap['meal_templates'] ??
        rawMap['plantillas'] ??
        rawMap['plantillas_comida'];
    if (rawTemplates is List) {
      normalized['meal_templates'] = rawTemplates
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    }

    final rawFasting =
        rawMap['fasting_logs'] ?? rawMap['ayuno'] ?? rawMap['registros_ayuno'];
    if (rawFasting is List) {
      normalized['fasting_logs'] = rawFasting
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    }

    final rawDishware = rawMap['calibrated_dishware'] ??
        rawMap['vajilla'] ??
        rawMap['platos'];
    if (rawDishware is List) {
      normalized['calibrated_dishware'] = rawDishware
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    }

    return normalized;
  }

  /// Convenience helper executing decode and normalization in background isolate.
  static Future<Map<String, dynamic>> decodeAndNormalizeAsync(String jsonString) {
    return Isolate.run(() => decodeAndNormalize(jsonString));
  }

  static Map<String, dynamic> _normalizeMealItem(Map<String, dynamic> item) {
    final map = <String, dynamic>{...item};
    map['name'] = item['name'] ?? item['nombre'] ?? item['alimento'] ?? 'Comida';
    map['meal_type'] =
        item['meal_type'] ?? item['tipo'] ?? item['tipo_comida'] ?? 'Almuerzo';
    map['date'] = item['date'] ?? item['fecha'] ?? DateTime.now().toIso8601String();
    map['calories'] = item['calories'] ?? item['calorias'] ?? 0.0;
    map['protein'] = item['protein'] ?? item['proteina'] ?? item['proteinas'] ?? 0.0;
    map['carbs'] =
        item['carbs'] ?? item['carbohidratos'] ?? item['carbos'] ?? 0.0;
    map['fat'] = item['fat'] ?? item['grasas'] ?? item['grasa'] ?? 0.0;
    map['fiber'] = item['fiber'] ?? item['fibra'] ?? 0.0;
    map['sodium'] = item['sodium'] ?? item['sodio'] ?? 0.0;
    map['sugar'] = item['sugar'] ?? item['azucar'] ?? 0.0;
    map['notes'] = item['notes'] ?? item['notas'];
    map['image_path'] = item['image_path'] ?? item['imagen'] ?? item['foto'];
    map['ai_breakdown_json'] = item['ai_breakdown_json'] ?? item['desglose_ia'];
    return map;
  }

  static Map<String, dynamic> _normalizePantryItem(Map<String, dynamic> item) {
    final map = <String, dynamic>{...item};
    map['name'] = item['name'] ?? item['nombre'] ?? 'Alimento';
    map['brand'] = item['brand'] ?? item['marca'];
    map['category'] = item['category'] ?? item['categoria'];
    map['calories'] = item['calories'] ?? item['calorias'] ?? 0.0;
    map['protein'] = item['protein'] ?? item['proteina'] ?? item['proteinas'] ?? 0.0;
    map['carbs'] =
        item['carbs'] ?? item['carbohidratos'] ?? item['carbos'] ?? 0.0;
    map['fat'] = item['fat'] ?? item['grasas'] ?? item['grasa'] ?? 0.0;
    map['serving_size'] = item['serving_size'] ??
        item['porcion'] ??
        item['porcion_referencia'] ??
        100.0;
    map['serving_unit'] =
        item['serving_unit'] ?? item['unidad'] ?? item['unidad_porcion'] ?? 'g';
    map['package_weight'] =
        item['package_weight'] ?? item['peso_neto'] ?? item['peso_paquete'];
    map['fiber'] = item['fiber'] ?? item['fibra'] ?? 0.0;
    map['sodium'] = item['sodium'] ?? item['sodio'] ?? 0.0;
    map['sugar'] = item['sugar'] ?? item['azucar'] ?? 0.0;
    map['barcode'] = item['barcode'] ?? item['codigo_barras'];
    map['is_favorite'] =
        item['is_favorite'] ?? item['favorito'] ?? item['es_favorito'] ?? 0;
    return map;
  }

  static Map<String, dynamic> _normalizeWeightLog(Map<String, dynamic> item) {
    final map = <String, dynamic>{...item};
    map['date'] = item['date'] ?? item['fecha'] ?? DateTime.now().toIso8601String();
    map['weight'] = item['weight'] ?? item['peso'] ?? 0.0;
    map['notes'] = item['notes'] ?? item['notas'];
    return map;
  }

  static Map<String, dynamic> _normalizeUserProfile(Map<String, dynamic> p) {
    final map = <String, dynamic>{...p};
    map['name'] = p['name'] ?? p['nombre'];
    map['age'] = p['age'] ?? p['edad'] ?? 25;
    map['gender'] = p['gender'] ?? p['genero'] ?? 'male';
    map['height'] = p['height'] ?? p['altura'] ?? p['altura_cm'] ?? 170.0;
    map['weight'] = p['weight'] ?? p['peso'] ?? p['peso_kg'] ?? 70.0;
    map['activity_level'] =
        p['activity_level'] ?? p['nivel_actividad'] ?? 'sedentary';
    map['body_goal'] =
        p['body_goal'] ?? p['meta'] ?? p['objetivo'] ?? 'maintenance';
    map['estimated_steps'] =
        p['estimated_steps'] ?? p['pasos_estimados'] ?? 8000;
    map['bmr'] = p['bmr'] ?? p['tmb'] ?? 1600.0;
    map['tdee'] = p['tdee'] ?? 2200.0;
    map['target_calories'] =
        p['target_calories'] ?? p['calorias_objetivo'] ?? 2000.0;
    map['target_protein'] = p['target_protein'] ??
        p['proteina_objetivo'] ??
        p['target_protein_g'] ??
        140.0;
    map['target_carbs'] = p['target_carbs'] ??
        p['carbos_objetivo'] ??
        p['target_carbs_g'] ??
        200.0;
    map['target_fat'] =
        p['target_fat'] ?? p['grasa_objetivo'] ?? p['target_fat_g'] ?? 60.0;
    map['master_prompt'] = p['master_prompt'];
    map['updated_at'] = p['updated_at'] ??
        p['fecha_actualizacion'] ??
        DateTime.now().toIso8601String();
    return map;
  }
}
