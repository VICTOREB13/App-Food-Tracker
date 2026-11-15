import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import 'meal.dart';

enum AnalysisStatus { queued, processing, completed, failed }

/// Task model representing an image analysis unit in the background queue.
class AnalysisTask {
  final String id;
  String imagePath;
  Uint8List? rawImageBytes;
  double? dishwareDiameterCm;
  final String mealType;
  final DateTime date;
  final String? userContext;
  AnalysisStatus status;
  double progress;
  String stage;
  String? error;
  Meal? resultMeal;
  final DateTime createdAt;

  AnalysisTask({
    String? id,
    this.imagePath = '',
    this.rawImageBytes,
    this.dishwareDiameterCm,
    required this.mealType,
    required this.date,
    this.userContext,
    this.status = AnalysisStatus.queued,
    this.progress = 0.05,
    this.stage = 'Optimizando foto...',
    this.error,
    this.resultMeal,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  bool get isPending =>
      status == AnalysisStatus.queued || status == AnalysisStatus.processing;

  Map<String, dynamic> toDbMap() => {
        'id': id,
        'image_path': imagePath,
        'meal_type': mealType,
        'date': date.toIso8601String(),
        'status': status.name,
        'progress': progress,
        'stage': stage,
        'error': error,
        'result_meal_id': resultMeal?.id,
        'created_at': createdAt.toIso8601String(),
      };

  factory AnalysisTask.fromDbMap(Map<String, dynamic> r, {Meal? resultMeal}) {
    final status = AnalysisStatus.values.firstWhere(
      (s) => s.name == (r['status'] as String? ?? ''),
      orElse: () => AnalysisStatus.failed,
    );
    return AnalysisTask(
      id: r['id'] as String,
      imagePath: r['image_path'] as String? ?? '',
      mealType: r['meal_type'] as String,
      date: DateTime.tryParse(r['date'] as String? ?? '') ?? DateTime.now(),
      status: status,
      progress: (r['progress'] as num?)?.toDouble() ?? 0.0,
      stage: r['stage'] as String? ?? '',
      error: r['error'] as String?,
      resultMeal: resultMeal,
      createdAt: DateTime.tryParse(r['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
