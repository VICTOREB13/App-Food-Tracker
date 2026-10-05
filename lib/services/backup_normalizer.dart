import 'dart:convert';
import 'dart:isolate';

/// Adaptive normalizer supporting legacy backups (v1.0.4 and prior) with translation of
/// Spanish keys, raw array wrapping, resilient truncated JSON repair, and background isolate execution.
class BackupNormalizer {
  /// Decodes and normalizes a backup JSON string into a standardized Map.
  /// Callable directly or via [Isolate.run].
  static Map<String, dynamic> decodeAndNormalize(String jsonString) {
    dynamic decoded;
    try {
      decoded = json.decode(jsonString);
    } on FormatException catch (originalException) {
      try {
        final repaired = _tryRepairTruncatedJson(jsonString);
        decoded = json.decode(repaired);
      } catch (_) {
        throw originalException;
      }
    }

    if (decoded is List) {
      for (final element in decoded) {
        if (element is! Map) {
          throw const FormatException('El archivo de respaldo no tiene el formato JSON esperado.');
        }
      }
      return {
        'schema_version': 1,
        'export_date': DateTime.now().toIso8601String(),
        'meals': decoded.map((e) => _normalizeMealItem(Map<String, dynamic>.from(e as Map))).toList(),
        'pantry_items': <Map<String, dynamic>>[],
        'weight_logs': <Map<String, dynamic>>[],
        'user_profile': null,
      };
    }

    if (decoded is! Map) {
      throw const FormatException('El archivo de respaldo no tiene el formato JSON esperado.');
    }

    final rawMap = Map<String, dynamic>.from(decoded);
    final rawMeals = rawMap['meals'] ?? rawMap['comidas'] ?? rawMap['registros'] ?? rawMap['items'];
    final rawPantry = rawMap['pantry_items'] ?? rawMap['despensa'] ?? rawMap['pantry'] ?? rawMap['articulos_despensa'];
    final rawWeights = rawMap['weight_logs'] ?? rawMap['pesos'] ?? rawMap['registros_peso'] ?? rawMap['historial_peso'];
    final rawProfile = rawMap['user_profile'] ?? rawMap['perfil'] ?? rawMap['perfil_usuario'] ?? rawMap['profile'];
    final rawTemplates = rawMap['meal_templates'] ?? rawMap['plantillas'] ?? rawMap['plantillas_comida'];
    final rawFasting = rawMap['fasting_logs'] ?? rawMap['ayuno'] ?? rawMap['registros_ayuno'];
    final rawDishware = rawMap['calibrated_dishware'] ?? rawMap['vajilla'] ?? rawMap['platos'];

    final normalized = <String, dynamic>{
      'app': rawMap['app'] ?? 'Victor Engineer Food Tracker',
      'version': rawMap['version'] ?? '2.0.0',
      'schema_version': rawMap['schema_version'] ?? 2,
      'export_date': rawMap['export_date'] ?? DateTime.now().toIso8601String(),
      'meals': (rawMeals is List)
          ? rawMeals.whereType<Map>().map((m) => _normalizeMealItem(Map<String, dynamic>.from(m))).toList()
          : <Map<String, dynamic>>[],
      'pantry_items': (rawPantry is List)
          ? rawPantry.whereType<Map>().map((m) => _normalizePantryItem(Map<String, dynamic>.from(m))).toList()
          : <Map<String, dynamic>>[],
      'weight_logs': (rawWeights is List)
          ? rawWeights.whereType<Map>().map((m) => _normalizeWeightLog(Map<String, dynamic>.from(m))).toList()
          : <Map<String, dynamic>>[],
      'user_profile': (rawProfile is Map) ? _normalizeUserProfile(Map<String, dynamic>.from(rawProfile)) : null,
    };

    if (rawTemplates is List) {
      normalized['meal_templates'] = rawTemplates.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
    }
    if (rawFasting is List) {
      normalized['fasting_logs'] = rawFasting.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
    }
    if (rawDishware is List) {
      normalized['calibrated_dishware'] = rawDishware.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
    }

    return normalized;
  }

  /// Convenience helper executing decode and normalization in background isolate.
  static Future<Map<String, dynamic>> decodeAndNormalizeAsync(String jsonString) {
    return Isolate.run(() => decodeAndNormalize(jsonString));
  }

  /// Attempts to repair truncated JSON strings by closing unterminated strings,
  /// cleaning trailing dangling separators or unvalued keys, and closing
  /// pending braces and brackets in LIFO order.
  static String _tryRepairTruncatedJson(String jsonString) {
    var text = jsonString.trimRight();
    if (text.isEmpty) return text;

    // 1. Close unclosed string literal if an odd number of unescaped quotes exist
    bool inStr = false, isEsc = false;
    for (int i = 0; i < text.length; i++) {
      final c = text[i];
      if (inStr) {
        if (isEsc) {
          isEsc = false;
        } else if (c == r'\') {
          isEsc = true;
        } else if (c == '"') {
          inStr = false;
        }
      } else if (c == '"') {
        inStr = true;
      }
    }
    if (inStr) {
      if (isEsc) text = text.substring(0, text.length - 1);
      text = '$text"';
    }

    // 2. Clean dangling trailing tokens (commas, colons, unvalued keys)
    var changed = true;
    while (changed && text.isNotEmpty) {
      changed = false;
      text = text.trimRight();
      if (text.endsWith('.') || text.endsWith(',') || text.endsWith(':')) {
        text = text.substring(0, text.length - 1).trimRight();
        changed = true;
        continue;
      }
      if (text.endsWith('"')) {
        final tail = _scanTail(text);
        if (tail != null && tail.inObject && tail.prevChar != ':') {
          text = text.substring(0, tail.startIndex).trimRight();
          if (text.endsWith(',')) {
            text = text.substring(0, text.length - 1).trimRight();
          }
          changed = true;
        }
      }
    }

    // 3. Count unclosed brackets '{' and '[' and close in LIFO order
    final stack = <String>[];
    inStr = false;
    isEsc = false;
    for (int i = 0; i < text.length; i++) {
      final c = text[i];
      if (inStr) {
        if (isEsc) {
          isEsc = false;
        } else if (c == r'\') {
          isEsc = true;
        } else if (c == '"') {
          inStr = false;
        }
      } else {
        if (c == '"') {
          inStr = true;
        } else if (c == '{' || c == '[') {
          stack.add(c);
        } else if (c == '}' && stack.isNotEmpty && stack.last == '{') {
          stack.removeLast();
        } else if (c == ']' && stack.isNotEmpty && stack.last == '[') {
          stack.removeLast();
        }
      }
    }

    final buffer = StringBuffer(text);
    for (int i = stack.length - 1; i >= 0; i--) {
      buffer.write(stack[i] == '{' ? '}' : ']');
    }
    return buffer.toString();
  }

  /// Scans trailing structure to inspect if the last token is an unvalued key.
  static ({String? prevChar, bool inObject, int startIndex})? _scanTail(String s) {
    int lastStart = -1, lastEnd = -1;
    String? prevChar, runningPrev;
    final stack = <String>[];
    bool inStr = false, isEsc = false;

    for (int i = 0; i < s.length; i++) {
      final c = s[i];
      if (inStr) {
        if (isEsc) {
          isEsc = false;
        } else if (c == r'\') {
          isEsc = true;
        } else if (c == '"') {
          inStr = false;
          lastEnd = i;
        }
      } else {
        if (c == '"') {
          inStr = true;
          lastStart = i;
          prevChar = runningPrev;
        } else if (c == '{' || c == '[') {
          stack.add(c);
        } else if (c == '}' && stack.isNotEmpty && stack.last == '{') {
          stack.removeLast();
        } else if (c == ']' && stack.isNotEmpty && stack.last == '[') {
          stack.removeLast();
        }
        if (c != ' ' && c != '\t' && c != '\n' && c != '\r') {
          runningPrev = c;
        }
      }
    }

    if (lastStart != -1 && lastEnd == s.length - 1) {
      return (
        prevChar: prevChar,
        inObject: stack.isNotEmpty && stack.last == '{',
        startIndex: lastStart,
      );
    }
    return null;
  }

  static Map<String, dynamic> _normalizeMealItem(Map<String, dynamic> item) => {
    ...item,
    'name': item['name'] ?? item['nombre'] ?? item['alimento'] ?? 'Comida',
    'meal_type': item['meal_type'] ?? item['tipo'] ?? item['tipo_comida'] ?? 'Almuerzo',
    'date': item['date'] ?? item['fecha'] ?? DateTime.now().toIso8601String(),
    'calories': item['calories'] ?? item['calorias'] ?? 0.0,
    'protein': item['protein'] ?? item['proteina'] ?? item['proteinas'] ?? 0.0,
    'carbs': item['carbs'] ?? item['carbohidratos'] ?? item['carbos'] ?? 0.0,
    'fat': item['fat'] ?? item['grasas'] ?? item['grasa'] ?? 0.0,
    'fiber': item['fiber'] ?? item['fibra'] ?? 0.0,
    'sodium': item['sodium'] ?? item['sodio'] ?? 0.0,
    'sugar': item['sugar'] ?? item['azucar'] ?? 0.0,
    'notes': item['notes'] ?? item['notas'],
    'image_path': item['image_path'] ?? item['imagen'] ?? item['foto'],
    'ai_breakdown_json': item['ai_breakdown_json'] ?? item['desglose_ia'],
  };

  static Map<String, dynamic> _normalizePantryItem(Map<String, dynamic> item) => {
    ...item,
    'name': item['name'] ?? item['nombre'] ?? 'Alimento',
    'brand': item['brand'] ?? item['marca'],
    'category': item['category'] ?? item['categoria'],
    'calories': item['calories'] ?? item['calorias'] ?? 0.0,
    'protein': item['protein'] ?? item['proteina'] ?? item['proteinas'] ?? 0.0,
    'carbs': item['carbs'] ?? item['carbohidratos'] ?? item['carbos'] ?? 0.0,
    'fat': item['fat'] ?? item['grasas'] ?? item['grasa'] ?? 0.0,
    'serving_size': item['serving_size'] ?? item['porcion'] ?? item['porcion_referencia'] ?? 100.0,
    'serving_unit': item['serving_unit'] ?? item['unidad'] ?? item['unidad_porcion'] ?? 'g',
    'package_weight': item['package_weight'] ?? item['peso_neto'] ?? item['peso_paquete'],
    'fiber': item['fiber'] ?? item['fibra'] ?? 0.0,
    'sodium': item['sodium'] ?? item['sodio'] ?? 0.0,
    'sugar': item['sugar'] ?? item['azucar'] ?? 0.0,
    'barcode': item['barcode'] ?? item['codigo_barras'],
    'is_favorite': item['is_favorite'] ?? item['favorito'] ?? item['es_favorito'] ?? 0,
  };

  static Map<String, dynamic> _normalizeWeightLog(Map<String, dynamic> item) => {
    ...item,
    'date': item['date'] ?? item['fecha'] ?? DateTime.now().toIso8601String(),
    'weight': item['weight'] ?? item['peso'] ?? 0.0,
    'notes': item['notes'] ?? item['notas'],
  };

  static Map<String, dynamic> _normalizeUserProfile(Map<String, dynamic> p) => {
    ...p,
    'name': p['name'] ?? p['nombre'],
    'age': p['age'] ?? p['edad'] ?? 25,
    'gender': p['gender'] ?? p['genero'] ?? 'male',
    'height': p['height'] ?? p['altura'] ?? p['altura_cm'] ?? 170.0,
    'weight': p['weight'] ?? p['peso'] ?? p['peso_kg'] ?? 70.0,
    'activity_level': p['activity_level'] ?? p['nivel_actividad'] ?? 'sedentary',
    'body_goal': p['body_goal'] ?? p['meta'] ?? p['objetivo'] ?? 'maintenance',
    'estimated_steps': p['estimated_steps'] ?? p['pasos_estimados'] ?? 8000,
    'bmr': p['bmr'] ?? p['tmb'] ?? 1600.0,
    'tdee': p['tdee'] ?? 2200.0,
    'target_calories': p['target_calories'] ?? p['calorias_objetivo'] ?? 2000.0,
    'target_protein': p['target_protein'] ?? p['proteina_objetivo'] ?? p['target_protein_g'] ?? 140.0,
    'target_carbs': p['target_carbs'] ?? p['carbos_objetivo'] ?? p['target_carbs_g'] ?? 200.0,
    'target_fat': p['target_fat'] ?? p['grasa_objetivo'] ?? p['target_fat_g'] ?? 60.0,
    'master_prompt': p['master_prompt'],
    'updated_at': p['updated_at'] ?? p['fecha_actualizacion'] ?? DateTime.now().toIso8601String(),
  };
}
