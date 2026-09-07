import 'package:flutter/foundation.dart';

@immutable
class GeminiModelInfo {
  /// Normalized model identifier without 'models/' prefix (e.g., 'gemini-2.5-flash')
  final String name;

  /// Human-readable name provided by Google (e.g., 'Gemini 2.5 Flash')
  final String displayName;

  /// Model capabilities description
  final String description;

  /// Whether this model is marked as recommended for visual food analysis
  final bool isRecommended;

  /// Semantic badge label displayed in Settings (e.g., 'RECOMENDADO (Ultrarrápido)')
  final String? recommendationLabel;

  /// Maximum input tokens supported by the model
  final int inputTokenLimit;

  /// Maximum output tokens supported
  final int outputTokenLimit;

  /// List of supported generation methods (e.g., ['generateContent', 'countTokens'])
  final List<String> supportedGenerationMethods;

  /// Input modalities supported (e.g., ['TEXT', 'IMAGE'])
  final List<String> inputModalities;

  static const Object _sentinel = Object();

  const GeminiModelInfo({
    required this.name,
    required this.displayName,
    required this.description,
    required this.isRecommended,
    this.recommendationLabel,
    this.inputTokenLimit = 0,
    this.outputTokenLimit = 0,
    this.supportedGenerationMethods = const ['generateContent'],
    this.inputModalities = const ['TEXT', 'IMAGE'],
  });

  /// Factory to parse official Google Generative Language API model JSON object
  factory GeminiModelInfo.fromGoogleJson(
    Map<String, dynamic> json, {
    int? tierRank,
    String? recommendationLabel,
    bool? isRecommended,
  }) {
    final rawName = (json['name'] ?? '').toString();
    // Normalize: strip 'models/' prefix
    final cleanName = rawName.startsWith('models/') ? rawName.substring(7) : rawName;
    final displayName = (json['displayName'] ?? cleanName).toString();
    final description = (json['description'] ?? '').toString();
    final inputTokens = (json['inputTokenLimit'] as num?)?.toInt() ?? 0;
    final outputTokens = (json['outputTokenLimit'] as num?)?.toInt() ?? 0;

    final genMethods = (json['supportedGenerationMethods'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const ['generateContent'];

    final modalities = (json['inputModalities'] as List<dynamic>?)
            ?.map((e) => e.toString().toUpperCase())
            .toList() ??
        const [];

    return GeminiModelInfo(
      name: cleanName,
      displayName: displayName.isNotEmpty ? displayName : cleanName,
      description: description,
      isRecommended: isRecommended ?? false,
      recommendationLabel: recommendationLabel,
      inputTokenLimit: inputTokens,
      outputTokenLimit: outputTokens,
      supportedGenerationMethods: genMethods,
      inputModalities: modalities,
    );
  }

  GeminiModelInfo copyWith({
    String? name,
    String? displayName,
    String? description,
    bool? isRecommended,
    Object? recommendationLabel = _sentinel,
    int? inputTokenLimit,
    int? outputTokenLimit,
    List<String>? supportedGenerationMethods,
    List<String>? inputModalities,
  }) {
    return GeminiModelInfo(
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      description: description ?? this.description,
      isRecommended: isRecommended ?? this.isRecommended,
      recommendationLabel: identical(recommendationLabel, _sentinel)
          ? this.recommendationLabel
          : (recommendationLabel as String?),
      inputTokenLimit: inputTokenLimit ?? this.inputTokenLimit,
      outputTokenLimit: outputTokenLimit ?? this.outputTokenLimit,
      supportedGenerationMethods:
          supportedGenerationMethods ?? this.supportedGenerationMethods,
      inputModalities: inputModalities ?? this.inputModalities,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'displayName': displayName,
        'description': description,
        'isRecommended': isRecommended,
        'recommendationLabel': recommendationLabel,
        'inputTokenLimit': inputTokenLimit,
        'outputTokenLimit': outputTokenLimit,
        'supportedGenerationMethods': supportedGenerationMethods,
        'inputModalities': inputModalities,
      };

  factory GeminiModelInfo.fromJson(Map<String, dynamic> json) {
    return GeminiModelInfo(
      name: json['name']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      isRecommended: json['isRecommended'] == true,
      recommendationLabel: json['recommendationLabel']?.toString(),
      inputTokenLimit: (json['inputTokenLimit'] as num?)?.toInt() ?? 0,
      outputTokenLimit: (json['outputTokenLimit'] as num?)?.toInt() ?? 0,
      supportedGenerationMethods:
          (json['supportedGenerationMethods'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              const ['generateContent'],
      inputModalities: (json['inputModalities'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['TEXT', 'IMAGE'],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeminiModelInfo &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() =>
      'GeminiModelInfo(name: $name, displayName: $displayName, recommended: $isRecommended, badge: $recommendationLabel)';
}
