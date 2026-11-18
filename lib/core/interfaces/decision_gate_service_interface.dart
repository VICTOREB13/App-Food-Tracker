import 'package:flutter/foundation.dart';

/// Immutable result returned by the Decision Gate evaluation.
@immutable
class DecisionGateResult {
  final bool isFood;
  final String imageQuality;
  final String dishComplexity;
  final String mealCategory;
  final bool failOpen;
  final String? reason;

  const DecisionGateResult({
    required this.isFood,
    required this.imageQuality,
    required this.dishComplexity,
    required this.mealCategory,
    this.failOpen = false,
    this.reason,
  });

  /// Deterministic fail-open constructor on network timeout (>2500ms), error, or missing BYOK key.
  factory DecisionGateResult.failOpen({String? reason}) => DecisionGateResult(
        isFood: true,
        imageQuality: 'high',
        dishComplexity: 'medium',
        mealCategory: 'meal',
        failOpen: true,
        reason: reason,
      );

  factory DecisionGateResult.fromJson(Map<String, dynamic> json) {
    bool parseBool(dynamic val) {
      if (val is bool) return val;
      if (val is String) {
        final lower = val.toLowerCase().trim();
        return lower == 'true' || lower == 'yes' || lower == 'si' || lower == '1';
      }
      return true;
    }

    String parseString(dynamic val, String fallback) {
      if (val is String && val.trim().isNotEmpty) return val.trim().toLowerCase();
      return fallback;
    }

    return DecisionGateResult(
      isFood: parseBool(json['is_food'] ?? json['isFood'] ?? true),
      imageQuality: parseString(json['image_quality'] ?? json['imageQuality'], 'high'),
      dishComplexity: parseString(json['dish_complexity'] ?? json['dishComplexity'], 'medium'),
      mealCategory: parseString(json['meal_category'] ?? json['mealCategory'], 'meal'),
      failOpen: false,
    );
  }

  Map<String, dynamic> toJson() => {
        'is_food': isFood,
        'image_quality': imageQuality,
        'dish_complexity': dishComplexity,
        'meal_category': mealCategory,
        'fail_open': failOpen,
        if (reason != null) 'reason': reason,
      };

  bool get isPass => isFood && imageQuality != 'low';
  bool get shouldWarn => !isFood || imageQuality == 'low';
  String get recommendedThinkingLevel {
    switch (dishComplexity.toLowerCase().trim()) {
      case 'simple':
        return 'LOW';
      case 'medium':
        return 'MEDIUM';
      case 'complex':
      case 'high':
        return 'HIGH';
      case 'extreme':
        return 'XHIGH';
      default:
        return 'MEDIUM';
    }
  }

  @override
  String toString() =>
      'DecisionGateResult(isFood: $isFood, quality: $imageQuality, complexity: $dishComplexity, category: $mealCategory, failOpen: $failOpen)';
}

/// Hexagonal interface contract for the Decision Gate Pre-filter.
abstract class IDecisionGateService {
  Future<DecisionGateResult> evaluatePhoto({
    required Uint8List photoBytes,
    String? userNotes,
  });
}
